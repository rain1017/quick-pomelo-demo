'use strict';

var _ = require('lodash');
var consts = require('../consts');
var logger = require('quick-pomelo').logger.getLogger('area', __filename);

module.exports = function(app){
	var mdbgoose = app.memdb.goose;

	var areaSchema = new mdbgoose.Schema({
		_id: {type: String},
		name: {type: String},

		state: {type: String, enum: _.values(consts.gameState), default: consts.gameState.waitToStart},

		hostId: {type: Number, required: true},
		playerIds: [{type: Number}], // must ensure player's position
		createTime: {type: Number, default: ()=>Date.now()},

		lastPlayTime: {type: Number},
		lastTurn: {type: Number, default: -1, validate: function(val){
			return _.indexOf([-1, 0, 1, 2], val) !== -1;
		}},

		landlord: {type: Number, default: -1}, // player_id
		landlordChooseTimes: {type: Number, default: 0},
		firstChoosedLord: {type: Boolean, default: false},
		firstChoosePlayerId: {type: Number, default: -1},
		lastWinnerId: {type:Number, default:-1},
		lordCards:[{type : String}],
		odds: {type: Number, default: 1},

		cardsStack: [{type: String}],
		playedCards:[{type : mdbgoose.Schema.Types.Mixed}],

	}, {collection: 'areas'});

	areaSchema.methods.isWaitToStartState = () => this.state === consts.gameState.waitToStart;
	areaSchema.methods.isChoosingLordState = () => this.state === consts.gameState.choosingLord;
	areaSchema.methods.isPlayingState = () => this.state === consts.gameState.playing;
	areaSchema.methods.isOngoingState = () => this.isPlayingState() || this.isChoosingLordState();

	areaSchema.methods.playerCount = () => this.playerIds.filter((p) => !!p && p > 0).length;
	areaSchema.methods.availPos = function() {
		for (var i = 0; i < this.playerIds.length; i++) {
			if(!this.playerIds[i] || this.playerIds[i] === -1) {
				return i;
			}
		}
		if (this.playerIds.length < 3) {
			return true;
		}
		return false;
	};
	areaSchema.methods.farmerPlayerIds = function(){
		var self = this;
		return this.playerIds.filter((id) => !!id && id !== -1 && id !== self.landlord);
	};

	areaSchema.methods.changeStateTo = function(state) {
		var availPreStates = consts.gameStateChanging[state];
		if(_.indexOf(availPreStates, this.state) !== -1) {
			var statePre = this.state;
			this.state = state;
			if(state === consts.gameState.playing) {
				this.lastTurn = this.turnOfPlayer(this.landlord);
				this.lastPlayTime = null;
			} else if(state === consts.gameState.waitToStart) {
				this.initChoosingLord();
				this.cardsStack = [];
				this.playedCards = [];
			}
			logger.info('game state changed: from=%s, to=%s', statePre, state);
		} else {
			logger.error('can not changed to state: state=%s, availPreStates=%j', state, availPreStates);
			throw new Error('can not change state: from=' + this.state + ', to=' + state);
		}
	};

	areaSchema.methods.nextTurn = function(lastTurn) {
		if(lastTurn === undefined) {
			lastTurn = this.lastTurn;
		}
		return lastTurn + 1 >= 3 ? lastTurn + 1 - 3 : lastTurn + 1;
	};
	areaSchema.methods.playingPlayerId = () => this.playerIds[this.lastTurn];
	areaSchema.methods.turnOfPlayer = (playerId) => _.indexOf(this.playerIds, playerId);
	areaSchema.methods.isLordChoosed = () => this.landlord !== -1;
	areaSchema.methods.isChoosingLordDone = function(){
		return (this.firstChoosedLord && this.landlordChooseTimes >= 4) ||
			(this.firstChoosedLord && this.landlord === this.firstChoosePlayerId && this.landlordChooseTimes >= 3) ||
			(!this.firstChoosedLord && this.landlordChooseTimes >= 3);
	};
	areaSchema.methods.chooseLord = function(playerId, choosed) {
		if(this.landlordChooseTimes === 0) {
			this.firstChoosedLord = choosed;
			this.firstChoosePlayerId = playerId;
		}

		if(choosed) {
			this.landlord = playerId;
			if(this.landlordChooseTimes !== 0) {
				this.odds = this.odds + 1;
			}
		}
		this.lastTurn = this.nextTurn();
		this.landlordChooseTimes = this.landlordChooseTimes + 1;
		this.lastPlayTime = Date.now();
	};
	areaSchema.methods.initChoosingLord = function() {
		this.firstChoosedLord = false;
		this.firstChoosePlayerId = -1;
		this.lastWinnerId = -1;
		this.landlordChooseTimes = 0;
		this.odds = 1;
		this.lastTurn = -1;
		this.lastPlayTime = null;
		this.landlord = -1;
	};


	areaSchema.methods.lastPlayed = function() {
		if(!this.cardsStack.length) {
			return null;
		}
		for (var i = this.cardsStack.length - 1; i >= 0; i--) {
			var cardsPlayed = this.cardsPlayedOfCardsStack(i);
			if(cardsPlayed.cards.length) {
				return cardsPlayed;
			}
		}
	};
	areaSchema.methods.cardsPlayedOfCardsStack = function(i) {
		var idx = _.indexOf(this.cardsStack[i], '-');
		var cards = JSON.parse(this.cardsStack[i].substring(idx + 1));
		return {cards: cards, playerId: parseInt(this.cardsStack[i].substring(0, idx))};
	};
	areaSchema.methods.isCardsPlayedPass = function(i) {
		return this.cardsPlayedOfCardsStack(i).cards.length === 0;
	};
	areaSchema.methods.getRoundWinner = function() {
		if(this.cardsStack.length === 0) {
			return this.playingPlayerId();
		}
		if(this.cardsStack.length >= 3 && this.isCardsPlayedPass(this.cardsStack.length-1) &&
			this.isCardsPlayedPass(this.cardsStack.length-2)) {
			return this.cardsPlayedOfCardsStack(this.cardsStack.length-3).playerId;
		}
		return null;
	};
	areaSchema.methods.playCards = function(playerId, cards) {
		this.cardsStack.push(playerId + '-' + JSON.stringify(cards));
		this.lastPlayTime = Date.now();
		if(cards.length === 0 && this.cardsStack.length >= 3 &&
			this.isCardsPlayedPass(this.cardsStack.length-2)) {
			// win
			this.playedCards.push(this.cardsStack);
			this.markModified('playedCards');
			var winnerId = this.cardsPlayedOfCardsStack(this.cardsStack.length-3).playerId;
			this.lastTurn = this.turnOfPlayer(winnerId);
			this.lastWinnerId = winnerId;
			this.cardsStack = [];
			return winnerId;
		} else {
			this.lastTurn = this.nextTurn();
			return null;
		}
	};
	areaSchema.methods.onWin = function() {
		this.playedCards.push(this.cardsStack);
	};


	areaSchema.methods.toClientData = function(){
		return {
			id: this._id,
			name: this.name,

			state: this.state,

			hostId: this.hostId,
			playerIds: this.playerIds,
			createTime: this.createTime,

			lastPlayTime: this.lastPlayTime,
			lastTurn: this.lastTurn,

			landlord: this.landlord,
			landlordChooseTimes: this.landlordChooseTimes,
			firstChoosedLord: this.firstChoosedLord,
			firstChoosePlayerId: this.firstChoosePlayerId,
			lastWinnerId: this.lastWinnerId,
			lordCards: this.lordCards,
			odds: this.odds,

			cardsStack: this.cardsStack,
		};
	};

	areaSchema.methods.chooseHost = function(idx){
		for (var i = 0; i < this.playerIds.length; i++) {
			var j = idx + i + 1;
			j = j >= this.playerIds.length ? j - this.playerIds.length : j;
			if(this.playerIds[j] !== null) {
				return this.playerIds[j];
			}
		}
		return null;
	};

	mdbgoose.model('Area', areaSchema);
};

