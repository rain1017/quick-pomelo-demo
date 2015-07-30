'use strict';

var P = require('bluebird');
var uuid = require('node-uuid');
var _ = require('lodash');
var logger = require('quick-pomelo').logger.getLogger('player', __filename);

var Controller = function(app){
    this.app = app;
};

var proto = Controller.prototype;

proto.authAsync = P.coroutine(function*(authInfo){
    var models = this.app.models;
    var socialId = String(authInfo.socialId), socialType = authInfo.socialType;
    var binding = yield models.Binding.findOneAsync({socialId: socialId, socialType: socialType});
    if(!binding) {
        return false;
    }
    return binding.playerId;
});

proto.createAsync = P.coroutine(function*(opts){
    var models = this.app.models;
    var binding = new models.Binding({
        _id: uuid.v4(),
        socialId: opts.authInfo.socialId,
        socialType: opts.authInfo.socialType
    });
    var player = new this.app.models.Player({name: opts.name, money: 1000});
    var playerId = binding.playerId = player._id = yield this.app.get('redisIdGenerator').nextId('player__id');
    yield player.saveAsync();
    yield binding.saveAsync();
    var channelId = 'p:' + playerId;
    yield this.app.controllers.push.joinAsync(channelId, playerId);
    logger.info('createAsync %j => %s', opts, playerId);
    return playerId;
});

proto.updateAsync = P.coroutine(function*(playerId, opts){
    var player = yield this.app.models.Player.findByIdAsync(playerId);
    if(!player){
        throw new Error('player ' + playerId + ' not exist');
    }
    this.app.models.Player.getUpdatableKeys().forEach(function(key){
        if(opts[key]) {
            player[key] = opts[key];
        }
    });
});

proto.removeAsync = P.coroutine(function*(playerId){
    var player = yield this.app.models.Player.findByIdAsync(playerId);
    if(!player){
        throw new Error('player ' + playerId + ' not exist');
    }
    if(!!player.areaId){
        yield this.app.controllers.area.quitAsync(player.areaId, playerId);
    }
    if(!!player.teamId){
        yield this.app.controllers.team.quitAsync(player.teamId, playerId);
    }
    var channelId = 'p:' + playerId;
    yield this.app.controllers.push.quitAsync(channelId, playerId);
    yield player.removeAsync();

    yield this.app.models.Binding.removeAsync({playerId: playerId});

    logger.info('removeAsync %s', playerId);
});

proto.applyPunishmentAsync = P.coroutine(function*(playerId, punishment){
    var player;
    if(_.isNumber(playerId) || _.isString(playerId)) {
        player = yield this.app.models.Player.findByIdAsync(playerId);
    } else {
        player = playerId;
    }
    player.money -= punishment;
    if(player.money < 0) {
        player.money = 0;
    }
    yield player.saveAsync();
    return player.toClientData();
});

proto.applyRewardAsync = P.coroutine(function*(playerId, reward){
    var player;
    if(_.isNumber(playerId) || _.isString(playerId)) {
        player = yield this.app.models.Player.findByIdAsync(playerId);
    } else {
        player = playerId;
    }
    player.money += reward;
    yield player.saveAsync();
    return player.toClientData();
});

proto.connectAsync = P.coroutine(function*(playerId, connectorId){
    var oldConnectorId = null;
    var player = yield this.app.models.Player.findByIdAsync(playerId);
    if(!player){
        throw new Error('player ' + playerId + ' not exist');
    }
    oldConnectorId = player.connectorId;
    player.connectorId = connectorId;
    yield player.saveAsync();
    yield this.app.controllers.push.connectAsync(playerId, connectorId);
    logger.info('connectAsync %s %s => %s', playerId, connectorId, oldConnectorId);
    return {oldConnectorId: oldConnectorId, data: {player: player.toClientData()}};
});

proto.disconnectAsync = P.coroutine(function*(playerId){
    var player = yield this.app.models.Player.findByIdAsync(playerId);
    if(!player){
        throw new Error('player ' + playerId + ' not exist');
    }
    player.connectorId = '';
    yield player.saveAsync();
    yield this.app.controllers.push.disconnectAsync(playerId);
    logger.info('disconnectAsync %s', playerId);
});

proto.pushAsync = P.coroutine(function*(playerId, route, msg, persistent){
    var channelId = 'p:' + playerId;
    yield this.app.controllers.push.pushAsync(channelId, null, route, msg, persistent);
});

proto.getMsgsAsync = P.coroutine(function*(playerId, seq, count){
    var channelId = 'p:' + playerId;
    return yield this.app.controllers.push.getMsgsAsync(channelId, seq, count);
});

module.exports = function(app){
    return new Controller(app);
};

