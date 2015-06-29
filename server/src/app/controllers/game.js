'use strict';

var P = require('bluebird');
var uuid = require('node-uuid');
var _ = require('lodash');
var util = require('util');
var formula = require('../formula/formula');
var cardFormula = require('../formula/cardFormula');
var consts = require('../consts');
var resp = require('../resp');
var timer = require('../timer/timer');
var logger = require('quick-pomelo').logger.getLogger('area', __filename);

var Controller = function(app){
	this.app = app;
};

var proto = Controller.prototype;


proto.dealCardsAsync = P.coroutine(function*(areaId){
	// send player cards, arrange choose lord
	var pack = _.shuffle(consts.card.pack);
	var area = _.isString(areaId) ? yield this.app.models.Area.findByIdAsync(areaId) : areaId;
	var playerCards = [], i, self = this, msg;
	areaId = area._id;
	if(area.playerIds.length !== 3) {
		throw new Error('area.playerIds.length must equals 3 when dealCards');
	}
	for (i = 0; i < area.playerIds.length; i++) {
		var areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, area.playerIds[i]);
		areaPlayer.cards = cardFormula.sortCards(_.slice(pack, i * 17, i * 17 + 17));
		playerCards.push(areaPlayer.cards);
		yield areaPlayer.saveAsync();
	}
	area.lordCards = _.slice(pack, 51, 54);
	area.lastTurn = _.random(0, 2);

	for (i = 0; i < area.playerIds.length; i++) {
		msg = {
			areaPlayer: {cards: playerCards[i], playerId: area.playerIds[i]},
			area: {state: area.state, lastTurn: area.lastTurn}
		};
		yield this.app.controllers.area.pushAsync(areaId, [area.playerIds[i]], consts.routes.client.area.START, msg);
	}

	yield area.saveAsync();

	var nextPlayerId = area.playerIds[area.lastTurn];
	var timerId = util.format('area-timeoutchooselord-%s-%s', areaId, nextPlayerId);
	timer.getTimerManager(this.app).delay(timerId, consts.play.WAIT_TIME + consts.play.SERVER_TIME_DELAY, function(){
		return self._timeoutChooseLordAsync(areaId, nextPlayerId);
	});

	logger.info('game.dealCardsAsync: areaId=%s', areaId);
});

proto._timeoutChooseLordAsync = P.coroutine(function*(areaId, playerId){
	logger.info('game._timeoutChooseLordAsync: areaId=%s, playerId=%s', areaId, playerId);
	var area = yield this.app.models.Area.findByIdReadOnlyAsync(areaId);
	if (area.landlordChooseTimes === 0 && area.lastTurn === playerId) {
		yield this.chooseLordAsync(areaId, playerId, true);
	} else {
		yield this.chooseLordAsync(areaId, playerId, false);
	}
});

proto.chooseLordAsync = P.coroutine(function*(areaId, playerId, choosed){
	playerId = parseInt(playerId), choosed = !!choosed;
	var area = yield this.app.models.Area.findByIdAsync(areaId);
	var timerId, msg, self = this;
	if(!area.isOngoingState() || area.playingPlayerId() !== playerId ||
		area.isChoosingLordDone()) {
		logger.debug('invalid choose lord action: playerId=%s, playingPlayerId=%s, state=%s, landlordChooseTimes=%s',
			playerId, area.playingPlayerId(), area.state, area.landlordChooseTimes);
		return resp.errorResp(consts.resp.codes.INVALID_ACTION);
	}

	var rob = area.landlord !== -1;
	area.chooseLord(playerId, choosed);

	// push CHOOSE_LORD msg
	msg = {
		playerId: playerId,
		choosed: choosed,
		rob: rob,
		area: {
			landlord: area.landlord,
			landlordChooseTimes: area.landlordChooseTimes,
			firstChoosedLord: area.firstChoosedLord,
			firstChoosePlayerId: area.firstChoosePlayerId,
			lastTurn: area.lastTurn
		}
	};
	yield this.app.controllers.area.pushAsync(areaId, null, consts.routes.client.area.CHOOSE_LORD, msg);

	logger.info('game.chooseLordAsync: areaId=%s, playerId=%s, choose=%s', areaId, playerId, choosed);

	if(area.isChoosingLordDone()) {
		if(area.isLordChoosed()) {
			// choseingLord done: change state to playing, add lordCards to landlord, push LORD_CHOOSED msg, client landlord must start to play
			area.changeStateTo(consts.gameState.playing);
			var landlord = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, area.landlord);
			landlord.cards = cardFormula.sortCards(landlord.cards.concat(area.lordCards));
			msg = {
				area: {
					state: area.state,
					landlord: area.landlord,
					lordCards: area.lordCards,
					odds: area.odds,
					lastTurn: area.lastTurn,
				},
				areaPlayer: {
					cards: landlord.cards,
					playerId: area.landlord,
				}
			};
			yield this.app.controllers.area.pushAsync(areaId, [area.landlord], consts.routes.client.area.LORD_CHOOSED, msg);
			msg = {
				area: {
					state: area.state,
					landlord: area.landlord,
					lordCards: area.lordCards,
					odds: area.odds,
					lastTurn: area.lastTurn,
				}
			};
			yield this.app.controllers.area.pushAsync(areaId, area.farmerPlayerIds(), consts.routes.client.area.LORD_CHOOSED, msg);
			var playingPlayerId = landlord.playerId;
			timerId = util.format('area-timeoutplay-%s-%s', areaId, playingPlayerId);
			timer.getTimerManager(this.app).delay(timerId, consts.play.WAIT_TIME + consts.play.SERVER_TIME_DELAY, function(){
				return self._timeoutPlayAsync(areaId, playingPlayerId);
			});
			yield landlord.saveAsync();
		} else {
			area.initChoosingLord();
			yield this.dealCardsAsync(area);
		}
	} else {
		msg = {
			choosed: choosed,
			area: {
				odds: area.odds,
				lastTurn: area.lastTurn,
				firstChoosedLord: area.firstChoosedLord,
			}
		};
		var nextPlayerId = area.playerIds[area.lastTurn];
		timerId = util.format('area-timeoutchooselord-%s-%s', areaId, nextPlayerId);
		timer.getTimerManager(this.app).delay(timerId, consts.play.WAIT_TIME + consts.play.SERVER_TIME_DELAY, function(){
			return self._timeoutChooseLordAsync(areaId, nextPlayerId);
		});
	}
	yield area.saveAsync();

	timerId = util.format('area-timeoutchooselord-%s-%s', areaId, playerId);
	timer.getTimerManager(this.app).cancel(timerId);

	return resp.successResp();
});

proto._timeoutPlayAsync = P.coroutine(function*(areaId, playerId){
	logger.info('game._timeoutPlayAsync: areaId=%s, playerId=%s', areaId, playerId);
	var area = yield this.app.models.Area.findByIdAsync(areaId);
	var areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, playerId);
	var cards = cardFormula.autoPlay(areaPlayer.cards, area.getRoundWinner() === playerId);
	yield this.playAsync(areaId, playerId, cards);
});

proto.playAsync = P.coroutine(function*(areaId, playerId, cards){
	// check cards, check win, arrange next play
	playerId = parseInt(playerId);
	cards = cards.length === undefined ? [] : cards;
	var area = yield this.app.models.Area.findByIdAsync(areaId);
	if(!area.isPlayingState() || area.playingPlayerId() !== playerId) {
		logger.debug('invalid play card action: playerId=%s, playingPlayerId=%s, state=%s',
			playerId, area.playingPlayerId(), area.state);
		return resp.errorResp(consts.resp.codes.INVALID_ACTION);
	}

	var self = this, timerId;

	var areaPlayer = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(areaId, playerId);

	var lastCards = area.lastPlayed();
	if(lastCards && cards.length && (!cardFormula.isCardsValid(cards) || !cardFormula.isCardsGreater(cards, lastCards.cards))) {
		throw new Error('invalid cards!');
	}

	if(cards.length) {
		var cardsPreLength = areaPlayer.cards.length;
		logger.debug('cards before: %j, cards=%j', areaPlayer.cards, cards);
		areaPlayer.cards = areaPlayer.cards.filter((c) => _.indexOf(cards, c) === -1);
		logger.debug('cards after: %j', areaPlayer.cards);

		if(cardsPreLength - areaPlayer.cards.length !== cards.length) {
			throw new Error('invalid cards!');
		}
		areaPlayer.markModified('cards');
		yield areaPlayer.saveAsync();
	}

	var winnerId = area.playCards(playerId, cards);

	// push PLAY msg
	var msg = {
		area: {lastTurn: area.lastTurn, cardsStack: area.cardsStack},
		areaPlayer: {cardsCount: areaPlayer.cardsCount, playerId: areaPlayer.playerId},
		playerId: playerId,
		winnerId: winnerId,
		cards: cards
	};
	yield this.app.controllers.area.pushAsync(areaId, area.playerIds.filter((x) => x !== playerId), consts.routes.client.area.PLAY, msg);
	msg = {
		area: {lastTurn: area.lastTurn, cardsStack: area.cardsStack},
		areaPlayer: {cards: areaPlayer.cards, playerId: areaPlayer.playerId},
		playerId: playerId,
		winnerId: winnerId,
		cards: cards
	};
	yield this.app.controllers.area.pushAsync(areaId, [playerId], consts.routes.client.area.PLAY, msg);

	logger.info('game.playAsync: areaId=%s, playerId=%s, cards=%j', areaId, playerId, cards);

	if(!areaPlayer.cards.length) {
		// player wins!
		area.onWin();
		yield this._onWinAsync(area, areaPlayer);
	} else {
		// wait for next one play
		var nextPlayerId = area.playerIds[area.lastTurn];
		timerId = util.format('area-timeoutplay-%s-%s', areaId, nextPlayerId);
		timer.getTimerManager(this.app).delay(timerId, consts.play.WAIT_TIME + consts.play.SERVER_TIME_DELAY, function(){
			return self._timeoutPlayAsync(areaId, nextPlayerId);
		});
	}

	yield area.saveAsync();
	yield areaPlayer.saveAsync();

	timerId = util.format('area-timeoutplay-%s-%s', areaId, playerId);
	timer.getTimerManager(this.app).cancel(timerId);

	return resp.successResp();
});

proto._onWinAsync = P.coroutine(function*(area, winner){
	// set everyone's ready to false
	logger.info('game.win: areaId=%s, winnerId=%s, playedCards=%j', area._id, winner.playerId, area.playedCards);

	area.changeStateTo(consts.gameState.waitToStart);
	var retPlayerData = {}, retAreaPlayers = {}, player, playerId, route, i, msg, self = this, timerId, areaId = area._id;


	for (i = area.playerIds.length - 1; i >= 0; i--) {
		playerId = area.playerIds[i];
		var ap = yield this.app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(area._id, playerId);
		ap.ready = false;
		ap.cards = [];
		ap.show = false;
		retAreaPlayers[playerId] = ap.toClientData();

		player = yield this.app.models.Player.findByIdAsync(playerId);
		if(playerId === winner.playerId) {
			retPlayerData[playerId] =  yield this.app.controllers.player.applyRewardAsync(player,
				formula.reward.win(area.odds, area.landlord === playerId));
		} else {
			retPlayerData[playerId] =  yield this.app.controllers.player.applyPunishmentAsync(player,
				formula.punishment.lose(area.odds, area.landlord === playerId));
		}

		yield player.saveAsync();
		yield ap.saveAsync();
	}

	yield area.saveAsync();

	for (i = area.playerIds.length - 1; i >= 0; i--) {
		playerId = area.playerIds[i];
		route = consts.routes.client.area.GAME_OVER;
		msg = {
			area: area.toClientData(),
			winner: winner.playerId,
			players: retPlayerData,
			areaPlayers: retAreaPlayers,
		};
		yield this.app.controllers.area.pushAsync(area._id, [playerId], route, msg);

		// set ready timeout for all
		timerId = util.format('area-timeoutready-%s-%s', areaId, playerId);
		timer.getTimerManager(this.app).delay(timerId, consts.play.WAIT_TIME + consts.play.SERVER_TIME_DELAY, (function(areaId, playerId){
			return function(){
				return self._timeoutReadyAsync(areaId, playerId);
			};
		})(areaId, playerId)); //jshint ignore:line
	}

});

proto._timeoutReadyAsync = P.coroutine(function*(areaId, playerId){
	yield this.app.controllers.area.quitAsync(areaId, playerId);
});

module.exports = function(app){
	return new Controller(app);
};
