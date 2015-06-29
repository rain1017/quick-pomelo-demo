'use strict';

var P = require('bluebird');
var uuid = require('node-uuid');
var _ = require('lodash');
var util = require('util');
var consts = require('../consts');
var logger = require('quick-pomelo').logger.getLogger('team', __filename);

var Controller = function(app){
	this.app = app;
};

var proto = Controller.prototype;

proto.createAsync = P.coroutine(function*(playerId, opts){
	var team = new this.app.models.Team(opts);
	if(!team._id){
		team._id = uuid.v4();
	}
	if(!team.name) {
		team.name = 'Auto';
	}
	team.hostId = playerId;
	yield team.saveAsync();
	yield this.joinAsync(team._id, playerId);
	logger.info('team.createAsync: playerId=%s teamId=%s', playerId, team._id);
	return team._id;
});

proto.removeAsync = P.coroutine(function*(teamId){
	var team = yield this.app.models.Team.findByIdAsync(teamId);
	if(!team){
		throw new Error('team ' + teamId + ' not exist');
	}
	var players = yield this.getPlayersAsync(teamId);
	if(players.length > 0){
		throw new Error('team is not empty');
	}
	yield team.removeAsync();
	logger.info('team.removeAsync: teamId=%s', teamId);
	// TODO: stop timer
});

proto.getPlayersAsync = P.coroutine(function*(teamId){
	return yield this.app.models.Player.findReadOnlyAsync({teamId: teamId});
});

proto.joinAsync = P.coroutine(function*(teamId, playerId){
	var team = yield this.app.models.Team.findByIdAsync(teamId);
	if(!team){
		throw new Error('team ' + teamId + ' not exist');
	}
	var player = yield this.app.models.Player.findByIdAsync(playerId);
	if(!player){
		throw new Error('player ' + playerId + ' not exist');
	}
	player.teamId = teamId;
	yield player.saveAsync();

	team.playerIds = team.playerIds.concat(playerId);
	yield team.saveAsync();

	var channelId = 't:' + teamId;
	yield this.app.controllers.push.joinAsync(channelId, playerId, player.connectorId);

	var pushedPlayerIds = team.playerIds.filter((id) => id !== null && id !== playerId);
	yield this.pushAsync(teamId, pushedPlayerIds, 'team.joinAsync', {playerIds: team.playerIds, player: player.toClientData()}, false);
	logger.info('team.joinAsync: playerId=%s, teamId=%s', playerId, teamId);
});

proto.quitAsync = P.coroutine(function*(teamId, playerId){
	var player = _.isNumber(playerId) || _.isString(playerId) ? yield this.app.models.Player.findByIdAsync(playerId) : playerId;
	var team = _.isString(teamId) ? yield this.app.models.Team.findByIdAsync(teamId) : teamId;
	if(!player){
		throw new Error('player ' + playerId + ' not exist');
	}
	teamId = team._id, playerId = player._id;
	if(player.teamId !== team._id){
		throw new Error('player ' + playerId + ' not in team ' + teamId);
	}

	player.teamId = '';
	yield player.saveAsync();

	var channelId = 't:' + teamId;
	yield this.app.controllers.push.quitAsync(channelId, playerId);

	var idx = _.indexOf(team.playerIds, playerId);
	if(idx === -1) {
		throw new Error('player id must in team.playerIds: teamId=' + teamId + ', playerId=' + playerId);
	}
	team.playerIds.splice(_.indexOf(team.playerIds, playerId), 1);
	team.markModified('playerIds');
	yield team.saveAsync();

	var playerIds = team.playerIds.filter((playerId) => playerId !== null);
	if(playerIds.length === 0) {
		// if no one left in the team, remove the team
		yield this.removeAsync(teamId);
	} else {
		if (playerId === team.hostId) {
			// if host left, choose another host
			team.hostId = team.chooseHost(idx);
			if(!team.hostId) {
				throw new Error(util.format('chooseHost return null: teamId=%s, idx=%s', teamId, idx));
			}
			yield team.saveAsync();
		}
	}
	logger.info('team.quitAsync: playerId=%s, teamId=%s', playerId, teamId);
});
/**
 * playerIds - [playerId], set null to push all
 */
proto.pushAsync = P.coroutine(function*(teamId, playerIds, route, msg, persistent){
	var channelId = 't:' + teamId;
	return yield this.app.controllers.push.pushAsync(channelId, playerIds, route, msg, persistent);
});

proto.getMsgsAsync = P.coroutine(function*(teamId, seq, count){
	var channelId = 't:' + teamId;
	return yield this.app.controllers.push.getMsgsAsync(channelId, seq, count);
});

module.exports = function(app){
	return new Controller(app);
};
