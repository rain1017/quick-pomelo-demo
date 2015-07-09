'use strict';

var EventEmitter = require('events').EventEmitter;
var util = require('util');
var _ = require('lodash');
var consts = require('../../game-server/app/consts');
var cardFormula = require('../../game-server/app/formula/cardFormula');
var logger = require('quick-pomelo').logger.getLogger('robot', __filename);

var PlayerCards = function(opts){
	this.knownCards = opts.knownCards || [];
	this.cardsCount = opts.cardsCount || -1;
	this.playedCards = opts.playedCards || [];
	this.playerId = opts.playerId;
	this.modelStore = opts.modelStore;

	var self = this;
	Object.defineProperty(this, 'isLandlord', {
		get: function(){
			return self.modelStore.area.landlord == self.playerId;
		}
	});
};

var AI = function (modelStore) {
	this.modelStore = modelStore;
	this.on('play', this.onPlay.bind(this));
	this.on('chooseLord', this.onPlay.bind(this));
	this.on('lordChoosed', this.onLordChoosed.bind(this));
	this.on('init', this.onInit.bind(this));
	this.on('clean', this.onClean.bind(this));

	this.mycards = null;
	this.playerCards = {};
	this.playedCards = [];
	this.leftCards = JSON.parse(JSON.stringify(consts.card.pack));
};

module.exports = AI;
util.inherits(AI, EventEmitter);

var proto = AI.prototype;

proto.isMeLandlord = function(){
	return this.modelStore.area && this.modelStore.me && this.modelStore.me.id == this.modelStore.area.landlord;
};

proto.isMeAtLandlordNext = function(){
	if(!this.modelStore.area || !this.modelStore.me) {
		return false;
	}
	var area = this.modelStore.area, landlordId = area.landlord, me = this.modelStore.me;
	return area.nextTurn(area.turnOfPlayer(landlordId)) == area.turnOfPlayer(me.id);
};

proto.onInit = function(areaData) {
	return;
	var modelStore = this.modelStore, area = modelStore.area, areaPlayers = modelStore.areaPlayers, me = modelStore.me;
	if(area.isWaitToStartState()) {
	} else if(area.isChoosingLordState()) {
		this.mycards = areaPlayers[me.id].cards;
		this.leftCards = _.difference(this.leftCards, this.mycards);
		for (let i = 0; i < areaData.areaPlayers.length; i++) {
			let areaPlayer = areaData.areaPlayers[i];
			if(areaPlayer.playerId != me.id) {
				logger.debug('create PlayerCards: %s', areaPlayer.playerId);
				this.playerCards[areaPlayer.playerId] = new PlayerCards({
					playerId: areaPlayer.playerId,
					cardsCount: areaPlayer.cardsCount,
					modelStore: this.modelStore,
				});
			}
		}
	} else if(area.isPlayingState()) {
		this.mycards = areaPlayers[me.id].cards;
		this.leftCards = _.difference(this.leftCards, this.mycards, area.lordCards);
		for (let i = 0; i < areaData.areaPlayers.length; i++) {
			let areaPlayer = areaData.areaPlayers[i];
			if(areaPlayer.playerId != me.id) {
				logger.debug('create PlayerCards: %s', areaPlayer.playerId);
				this.playerCards[areaPlayer.playerId] = new PlayerCards({
					playerId: areaPlayer.playerId,
					cardsCount: areaPlayer.cardsCount,
					modelStore: this.modelStore,
				});
				if(area.landlord == areaPlayer.playerId) {
					this.playerCards[areaPlayer.playerId].knownCards = area.lordCards;
				}
			}
		}
	}
};

proto.onPlay = function(playerId, cards) {
	return;
	var modelStore = this.modelStore, area = modelStore.area, areaPlayers = modelStore.areaPlayers, me = modelStore.me;
	if(playerId == me.id) {
		this.mycards = _.difference(this.mycards, cards);
		this.leftCards = _.difference(this.leftCards, cards);
		this.playedCards.push(cards);
	} else {
		var playerCards = this.playerCards[playerId];
		playerCards.knownCards = playerCards.knownCards.concat(cards);
		playerCards.playedCards.push(cards);
		playerCards.cardsCount -= cards.length;
	}
};

proto.onChooseLord = function(playerId, choosed) {
};

proto.onLordChoosed = function(landlord, lordCards) {
	return;
	if(this.isMeLandlord()){
		this.mycards = this.mycards.concat(lordCards);
		this.leftCards = _.difference(this.leftCards, this.mycards);
	} else {
		var playerCards = this.playerCards[landlord];
		playerCards.knownCards = playerCards.knownCards.concat(lordCards);
		playerCards.cardsCount += lordCards.length;
	}
};

proto.onClean = function() {
	this.mycards = null;
	this.playerCards = {};
	this.playedCards = [];
	this.leftCards = JSON.parse(JSON.stringify(consts.card.pack));
};


// hands count, how greater of a hand type
proto.shouldChooseLord = function(){
	if(Math.random() < 0.5) {
		return true;
	}
	return false;
};

proto.shouldPlay = function() {
	var me = this.modelStore.me, area = this.modelStore.area, areaPlayers = this.modelStore.areaPlayers;
	if(area.cardsStack.length == 0) {
		return [areaPlayers[me.id].cards[0]];
	} else {
		return [];
	}
};

