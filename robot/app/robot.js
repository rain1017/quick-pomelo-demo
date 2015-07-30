'use strict';

var P = require('bluebird');
var quick = require('quick-pomelo');
var EventEmitter = require('events').EventEmitter;
var util = require('util');
var uuid = require('node-uuid');
var AI = require('./ai');
var ModelStore = require('./modelStore');
var consts = require('../../game-server/app/consts');
var logger = quick.logger.getLogger('robot', __filename);

var randomTime = function (min, max) {
    if(!max) {
        max = min;
        min = 0;
    }
    return (Math.random() * (max - min) + min) * 1000;
};

var TEST_WAIT_TIME = 3;

function Robot(opts) {
    opts = opts || {};

    this.modelStore = new ModelStore();
    this.ai = new AI(this.modelStore);
    this.client = null;

    this.status = 'inited'; // inited running stopping stopped

    this.on('run', this.run.bind(this));
    this.on('stop', this.stop.bind(this));
    //this.on('stopped', this.onRobotStoped.bind(this));

    this.config = {
        host : opts.host || '127.0.0.1',
        port : opts.port || 3010,
        deviceid : opts.deviceid || '',
    };
};

util.inherits(Robot, EventEmitter);

var proto = Robot.prototype;

proto.run = function(){
    this.status = 'running';

    var gateServer = {host : this.config.host, port : this.config.port};
    var playerId, areaId, ai = this.ai, self = this, modelStore = this.modelStore;

    P.coroutine(function*(){
        var client = quick.mocks.client(gateServer);
        yield client.connect();
        var connectorServer = yield client.request(consts.routes.server.gate.GET_CONNECTOR, null);
        client.disconnect();

        // Connect to connector
        client = self.client = quick.mocks.client(connectorServer.data);
        process.domain.add(client);

        // Measure
        if(global.actor){
            var originalRequest = client.request;
            client.request = function(route, msg){
                if(self.status !== 'running'){
                    throw new Error(util.format('robot %s not running', global.actor.id));
                }

                var reqId = uuid.v4();
                global.actor.emit('start', route, reqId);

                return originalRequest.call(client, route, msg)
                .finally(function(){
                    global.actor.emit('end', route, reqId);
                });
            };

            var originalOn = client.on;
            client.on = function(route, func){
                originalOn.call(client, route, function(msg){
                    P.try(function(){
                        var reqId = uuid.v4();
                        var actionId = 'on:' + route;
                        global.actor.emit('start', actionId, reqId);
                        global.actor.emit('end', actionId, reqId);

                        return func(msg);
                    })
                    .catch(function(e){
                        logger.error(e.stack);
                    });
                });
            };
        }

        yield client.connect();

        // set listeners for server message
        client.on(consts.routes.client.pomelo.DISCONNECT, self.onDisconnect.bind(self));
        client.on(consts.routes.client.pomelo.TIMEOUT, self.onTimeout.bind(self));
        client.on(consts.routes.client.pomelo.ON_KICK, self.onKick.bind(self));
        client.on(consts.routes.client.area.JOIN, self.onJoin.bind(self));
        client.on(consts.routes.client.area.READY, self.onReady.bind(self));
        client.on(consts.routes.client.area.START, self.onStart.bind(self));
        client.on(consts.routes.client.area.QUIT, self.onQuit.bind(self));
        client.on(consts.routes.client.area.LORD_CHOOSED, self.onLordChoosed.bind(self));
        client.on(consts.routes.client.area.CHOOSE_LORD, self.onChooseLord.bind(self));
        client.on(consts.routes.client.area.PLAY, self.onPlay.bind(self));
        client.on(consts.routes.client.area.GAME_OVER, self.onGameOver.bind(self));

        // login and update data
        var authInfo = {socialId : self.config.deviceid, socialType: consts.binding.types.DEVICE};
        var loginData = yield client.request(consts.routes.server.connector.LOGIN, {authInfo : authInfo});
        modelStore.updateModelMe(loginData.data);

        if (Math.random() < 0.1) {
            yield P.delay(randomTime(TEST_WAIT_TIME));
            yield client.request(consts.routes.server.player.UPDATE, {opts : {name : 'rain'}});
        }

        yield self.joinArea();
    })()
    .catch(function(err){
        logger.error(err.stack);
        self.emit('stop');
    });
};

proto.stop = function () {
    this.status = 'stopping';
};

proto.joinArea = P.coroutine(function*(){
    var client = this.client, modelStore = this.modelStore, ai = this.ai;
    // connect or searchAndJoin
    yield P.delay(randomTime(TEST_WAIT_TIME));
    var areaData;
    if(modelStore.me.areaId) {
        areaData = yield client.request(consts.routes.server.area.CONNECT, {areaId: modelStore.me.areaId});
        modelStore.updateModels(areaData.data);
    } else {
        areaData = yield client.request(consts.routes.server.area.SEARCH_JOIN, {});
        modelStore.updateModels(areaData.data);
    }
    logger.debug('models: %j', modelStore.models);
    this.ai.emit('init', areaData.data);
    // check game state
    if(modelStore.area.isWaitToStartState()) {
    } else if(modelStore.area.isChoosingLordState()) {
        logger.debug('playingPlayerId: %s, me.id=%s', modelStore.area.playingPlayerId(), modelStore.me.id);
        if(modelStore.me.id == modelStore.area.playingPlayerId()) {
            let msg = {areaId: modelStore.me.areaId, playerId: modelStore.me.id, choosed: ai.shouldChooseLord()}
            yield client.request(consts.routes.server.area.CHOOSE_LORD, msg);
        }
    } else if(modelStore.area.isPlayingState()) {
        logger.debug('playingPlayerId: %s, me.id=%s', modelStore.area.playingPlayerId(), modelStore.me.id);
        if(modelStore.me.id == modelStore.area.playingPlayerId()) {
            let msg = {areaId: modelStore.me.areaId, cards: ai.shouldPlay()}
            yield client.request(consts.routes.server.area.PLAY, msg);
        }
    }
});

proto.onDisconnect = proto.onTimeout = proto.onKick = P.coroutine(function*(msg) {
    this.status = 'stopped';
    logger.info('player robot stopped: %s', this.modelStore.me && this.moduleStore.me.id);
    this.emit('stopped');
    this.ai.emit('clean');
});

proto.onJoin = proto.onReady = P.coroutine(function*(msg) {
    msg = msg.msg;
    this.modelStore.updateModels(msg);
});

proto.onStart = proto.onChooseLord = P.coroutine(function*(msg) {
    if(msg.route == consts.routes.client.area.CHOOSE_LORD) {
        this.ai.emit('chooseLord', msg.msg.playerId, msg.msg.choosed);
    }

    msg = msg.msg;
    var client = this.client, modelStore = this.modelStore, ai = this.ai;

    this.modelStore.updateModels(msg);
    logger.debug('playingPlayerId: %s, me.id=%s', modelStore.area.playingPlayerId(), modelStore.me.id);
    if(!modelStore.area.isChoosingLordDone() &&
        this.modelStore.area.playingPlayerId() == this.modelStore.me.id) {
        yield P.delay(randomTime(TEST_WAIT_TIME));
        let msg = {areaId: modelStore.me.areaId, playerId: modelStore.me.id, choosed: ai.shouldChooseLord()}
        yield client.request(consts.routes.server.area.CHOOSE_LORD, msg);
    }
});

proto.onQuit = P.coroutine(function*(msg) {
    msg = msg.msg;
    var client = this.client, modelStore = this.modelStore, ai = this.ai;
    this.modelStore.updateModels(msg);
    this.ai.emit('clean');
    if(msg.quitedPlayer.id == this.modelStore.me.id) {
        this.modelStore.clean();
        this.modelStore.me.areaId = null;
        if(this.status == 'stopping') {
            this.status = 'stopped';
            this.client.disconnect();
            logger.info('player robot stopped: %s', this.modelStore.me.id);
            this.emit('stopped');
        } else {
            yield P.delay(randomTime(TEST_WAIT_TIME));
            yield this.joinArea();
        }
    } else {
        if(this.status == 'stopping') {
            yield client.request(consts.routes.server.area.QUIT, {areaId: this.modelStore.area.id});
        }
    }
});

proto.onLordChoosed = proto.onPlay = P.coroutine(function*(msg) {
    if(msg.route == consts.routes.client.area.PLAY) {
        this.ai.emit('play', msg.msg.playerId, msg.msg.cards);
    } else if(msg.route == consts.routes.client.area.LORD_CHOOSED) {
        this.ai.emit('lordChoosed', msg.msg.area.landlord, msg.msg.area.lordCards);
    }
    msg = msg.msg;
    var client = this.client, modelStore = this.modelStore, ai = this.ai;
    this.modelStore.updateModels(msg);
    logger.debug('playingPlayerId: %s, me.id=%s', modelStore.area.playingPlayerId(), modelStore.me.id);
    if(modelStore.me.id == modelStore.area.playingPlayerId()) {
        yield P.delay(randomTime(TEST_WAIT_TIME));
        if(!!modelStore.area){
            let msg = {areaId: modelStore.area.id, cards: ai.shouldPlay()};
            yield client.request(consts.routes.server.area.PLAY, msg);
        }
    }
});

proto.onGameOver = P.coroutine(function*(msg) {
    msg = msg.msg;
    var client = this.client, modelStore = this.modelStore, ai = this.ai;
    this.modelStore.updateModels(msg);
    ai.emit('clean');
    if(this.status == 'stopping') {
        yield client.request(consts.routes.server.area.QUIT, {areaId: this.modelStore.area.id});
    } else {
        if(Math.random() < 0.2) {
            // change area
            yield client.request(consts.routes.server.area.QUIT, {areaId: this.modelStore.area.id});
        } else {
            yield client.request(consts.routes.server.area.READY, {areaId: this.modelStore.area.id});
        }
    }
});

module.exports = Robot;
