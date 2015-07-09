'use strict';

var P = require('bluebird');
var uuid = require('node-uuid');
var _ = require('lodash');
var util = require('util');
var consts = require('../consts');
var resp = require('../resp');
var formula = require('../formula/formula');
var logger = require('quick-pomelo').logger.getLogger('area', __filename);

var Controller = function(app){
	this.app = app;
};

var proto = Controller.prototype;

proto.searchAndJoinAsync = P.coroutine(function*(playerId, opts){
	for(let areaId of this.app.areaSearcher.getAvailAreaIds()) {
		var area = yield this.app.models.Area.findByIdAsync(areaId);
		if(!area || area.playerCount() >= 3) {
			this.app.areaSearcher.deleteAvailArea(areaId);
			continue;
		} else {
			return yield this.joinAsync(area._id, playerId);
		}
	}
	return yield this.createAsync(playerId);
});

proto.createAsync = P.coroutine(function*(playerId, opts){
	opts = opts || {};
	var area = new this.app.models.Area(opts);
	if(!area._id){
		area._id = uuid.v4();
	}
	if(!area.name) {
		area.name = 'Auto';
	}
	area.hostId = playerId;
	yield area.saveAsync();
	var res = yield this.joinAsync(area._id, playerId);
	logger.info('area.createAsync: playerId=%s areaId=%s', playerId, area._id);
	return res;
});

proto.removeAsync = P.coroutine(function*(areaId){
	var area = yield this.app.models.Area.findByIdAsync(areaId);
	if(!area){
		throw new Error('area ' + areaId + ' not exist');
	}
	var playerIds = area.playerIds.filter((playerId) => playerId !== null);
	if(playerIds.length > 0){
		throw new Error('area is not empty');
	}
	yield area.removeAsync();
	logger.info('area.removeAsync: areaId=%s', areaId);
	// TODO: stop timer
});

proto.connectAsync = P.coroutine(function*(playerId, areaId) {
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	areaId = area._id;
	if(!area) {
		throw new Error('area ' + areaId + ' not exist');
	}
	if(_.indexOf(area.playerIds, playerId) === -1) {
		throw new Error('player ' + playerId + ' not in area ' + areaId);
	}
	var res = {area: area.toClientData()};
	var areaPlayers = [];
	var players = [];
	var areaPlayer, player;
	for (var i = 0; i < area.playerIds.length; i++) {
		if(area.playerIds[i]) {
			if(area.playerIds[i] === playerId) {
				areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, area.playerIds[i]);
				areaPlayer.online = true;
				yield areaPlayer.saveAsync();
			} else {
				areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdReadOnlyAsync(areaId, area.playerIds[i]);
			}
			if (areaPlayer.playerId === playerId) {
				areaPlayers.push(areaPlayer.toClientData());
			} else {
				areaPlayers.push(areaPlayer.toSimpleClientData());
			}
			player = yield this.app.models.Player.findByIdReadOnlyAsync(area.playerIds[i]);
			players.push(player.toClientData());
		} else {
			areaPlayers.push(null);
		}
	}
	res.areaPlayers = areaPlayers;
	res.players = players;
	logger.info('area.connectAsync: playerId=%s, areaId=%s', playerId, areaId);
	return resp.successResp(res);
});

proto.disconnectAsync = P.coroutine(function*(playerId, areaId){
	// TODO: playing -> let a robot to replace the player, waitToStart -> area.quit
	var area = yield this.app.models.Area.findByIdAsync(areaId);
	if(_.indexOf(area.playerIds, playerId) === -1) {
		throw new Error(util.format('player not exist in area: areaId=%s, playerId=%s', areaId, playerId));
	}
	if(area.isWaitToStartState()){
		yield this.quitAsync(area, playerId);
		return;
	} else if(area.isOngoingState()) {
		var areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, playerId);
		areaPlayer.online = false;
		yield areaPlayer.saveAsync();
	}
});

proto.getPlayersAsync = P.coroutine(function*(areaId){
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	if(!area){
		throw new Error('area ' + areaId + ' not exist');
	}
	var players = [];

	for(let playerId of area.playerIds){
		if(playerId !== null){
			players.push(yield this.app.models.Player.findByIdAsync(playerId));
		}
	}
	return players;
});

proto.joinAsync = P.coroutine(function*(areaId, playerId){
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	playerId = parseInt(playerId);
	areaId = area._id;
	if(!area){
		throw new Error('area ' + areaId + ' not exist');
	}
	var player = yield this.app.models.Player.findByIdAsync(playerId);
	if(!player){
		throw new Error('player ' + playerId + ' not exist');
	}
	player.areaId = areaId;
	yield player.saveAsync();

	var availPos = area.availPos();
	if(availPos === false) {
		throw new Error('area has no available pos: playerIds=%j', area.playerIds);
	} else if(availPos === true) {
		area.playerIds = area.playerIds.concat(playerId);
	} else {
		area.playerIds[availPos] = playerId;
		area.markModified('playerIds');
	}
	yield area.saveAsync();

	var areaPlayer = new this.app.models.AreaPlayer({areaId: areaId, playerId: playerId, _id: uuid.v4()});
	yield areaPlayer.saveAsync();

	var channelId = 'a:' + areaId;
	yield this.app.controllers.push.joinAsync(channelId, playerId, player.connectorId);

	var pushedPlayerIds = area.playerIds.filter((id) => id !== null && id !== playerId);
	yield this.pushAsync(areaId, pushedPlayerIds, consts.routes.client.area.JOIN, {area: {playerIds: area.playerIds}, areaPlayer: areaPlayer.toClientData(), player: player.toClientData()}, false);

	yield this.readyAsync(areaId, playerId);

	if(area.playerCount() >= 3) {
		this.app.areaSearcher.deleteAvailArea(area._id);
	} else {
		this.app.areaSearcher.setAreaAvail(area._id);
	}
	logger.info('area.joinAsync: playerId=%s, areaId=%s', playerId, areaId);
	return yield this.connectAsync(playerId, areaId);
});

proto.readyAsync = P.coroutine(function*(areaId, playerId){
	// change area.state to waitToStart, when everyone ready, start the game
	var player = _.isNumber(playerId) || _.isString(playerId) ? yield this.app.models.Player.findByIdAsync(playerId) : playerId;
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	areaId = area._id, playerId = player._id;

	var areaPlayer = yield this.app.models.AreaPlayer.findOneAsync({areaId: area._id, playerId: player._id});
	areaPlayer.ready = true;
	yield areaPlayer.saveAsync();

	var pushedPlayerIds = area.playerIds.filter((id) => id !== null && id !== playerId);
	var msg = {areaPlayer: {playerId: areaPlayer.playerId, ready: true}};
	yield this.pushAsync(areaId, pushedPlayerIds, 'area.ready', msg, false);

	logger.debug('area.playerIds: %j', area.playerIds);

	if(area.playerIds.length === 3 && !area.playerIds.filter((id => id === null)).length) {
		var allReady = true;
		for (var i = 0; i < area.playerIds.length; i++) {
			areaPlayer = yield this.app.models.AreaPlayer.findOneReadOnlyAsync({areaId: area._id, playerId: area.playerIds[i]});
			if(!areaPlayer.ready) {
				logger.debug('player is not ready: %s', areaPlayer.playerId);
				allReady = false;
			}
		}
		if(allReady) {
			this.app.areaSearcher.deleteAvailArea(area._id);
			area.changeStateTo(consts.gameState.choosingLord);
			yield area.saveAsync();
			yield this.app.controllers.game.dealCardsAsync(area._id);
		}
	}

	var timerId = util.format('area-timeoutready-%s-%s', areaId, playerId);
	this.app.timer.clear(timerId);
});

proto.quitAsync = P.coroutine(function*(areaId, playerId){
	var player = _.isNumber(playerId) || _.isString(playerId) ? yield this.app.models.Player.findByIdAsync(playerId) : playerId;
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	var i;
	if(!player){
		throw new Error('player ' + playerId + ' not exist');
	}
	areaId = area._id, playerId = player._id;
	if(player.areaId !== area._id){
		throw new Error('player ' + playerId + ' not in area ' + areaId);
	}

	var idx = _.indexOf(area.playerIds, playerId);
	if(idx === -1) {
		throw new Error('player id must in area.playerIds: areaId=' + areaId + ', playerId=' + playerId);
	}

	player.areaId = '';
	yield player.saveAsync();

	var retPlayerData = {}, retAreaPlayers = {}, msg;
	if(area.isOngoingState()) {
		area.changeStateTo(consts.gameState.waitToStart);
		yield area.saveAsync();
		// apply punishment and reward when force quit
		retPlayerData[playerId] = yield this.app.controllers.player.applyPunishmentAsync(player,
			formula.punishment.forceQuitGame(area.odds, area.landlord === playerId));
		for (i = 0; i < area.playerIds.length; i++) {
			if(area.playerIds[i] && area.playerIds[i] !== playerId) {
				var reward = formula.reward.otherForceQuitGame(area.odds, area.landlord === area.playerIds[i]);
				retPlayerData[area.playerIds[i]] = yield this.app.controllers.player.applyRewardAsync(area.playerIds[i], reward);
			}
			if(area.playerIds[i]) {
				var ap = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdReadOnlyAsync(areaId, area.playerIds[i]);
				retAreaPlayers[ap.playerId] = ap.toSimpleClientData();
			}
		}
	}

	area.playerIds[idx] = null;
	area.markModified('playerIds');
	yield area.saveAsync();

	var areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, playerId);
	yield areaPlayer.removeAsync();

	for (i = 0; i < area.playerIds.length; i++) {
		if(!area.playerIds[i]) {
			continue;
		}
		msg = {
			quitedPlayer: {id: playerId, name: player.name},
			area: area.toClientData(),
			players: retPlayerData,
			areaPlayers: retAreaPlayers,
		};
		yield this.pushAsync(areaId, [area.playerIds[i]], consts.routes.client.area.QUIT, msg, false);
	}
	msg = {
		quitedPlayer: {id: playerId, name: player.name},
		player: retPlayerData[playerId],
	};
	yield this.pushAsync(areaId, [playerId], consts.routes.client.area.QUIT, msg, false);

	var channelId = 'a:' + areaId;
	yield this.app.controllers.push.quitAsync(channelId, playerId);

	var playerIds = area.playerIds.filter((playerId) => playerId !== null);
	if(playerIds.length === 0) {
		// if no one left in the area, remove the area
		yield this.removeAsync(areaId);
		this.app.areaSearcher.deleteAvailArea(area._id);
	} else {
		if (playerId === area.hostId) {
			// if host left, choose another host
			area.hostId = area.chooseHost(idx);
			if(!area.hostId) {
				throw new Error(util.format('chooseHost return null: areaId=%s, idx=%s', areaId, idx));
			}
			yield area.saveAsync();
		}
		this.app.areaSearcher.setAreaAvail(area._id);
	}

	this.app.timer.clear(util.format('area-timeoutchooselord-%s-%s', areaId, playerId));
	this.app.timer.clear(util.format('area-timeoutplay-%s-%s', areaId, playerId));
	this.app.timer.clear(util.format('area-timeoutready-%s-%s', areaId, playerId));

	logger.info('area.quitAsync: playerId=%s, areaId=%s', playerId, areaId);
});

/**
 * playerIds - [playerId], set null to push all
 */
proto.pushAsync = P.coroutine(function*(areaId, playerIds, route, msg, persistent){
	var channelId = 'a:' + areaId;
	return yield this.app.controllers.push.pushAsync(channelId, playerIds, route, msg, persistent);
});

proto.getMsgsAsync = P.coroutine(function*(areaId, seq, count){
	var channelId = 'a:' + areaId;
	return yield this.app.controllers.push.getMsgsAsync(channelId, seq, count);
});

module.exports = function(app){
	return new Controller(app);
};
