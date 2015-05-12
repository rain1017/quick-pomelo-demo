'use strict';

var consts = require('../consts');
var _ = require('lodash');

module.exports = function(app){
	var mdbgoose = app.memdb.goose;

	var areaPlayerSchema = new mdbgoose.Schema({
		_id: {type : String},
		areaId: {type: String, required: true},
		playerId: {type: Number, required: true},
		cards: [{type : String}],
		show: {type : Boolean, default: false},
		online: {type: Boolean, default: true},
		ready: {type: Boolean, default: false},
	}, {collection : 'area_players'});

	areaPlayerSchema.index({areaId : 1, playerId : 1}, {unique : true});

	areaPlayerSchema.statics.findByAreaIdAndPlayerIdAsync = function(areaId, playerId) {
		return this.findOneAsync({areaId: areaId, playerId: playerId});
	};

	areaPlayerSchema.statics.findByAreaIdAndPlayerIdLockedAsync = function(areaId, playerId) {
		return this.findOneLockedAsync({areaId: areaId, playerId: playerId});
	};

	areaPlayerSchema.virtual('cardsCount').get(function(){
		return this.cards.length;
	});

	areaPlayerSchema.methods.isLandlord = (area) => area.landlord === this.playerId;

	areaPlayerSchema.methods.toClientData = function(){
		return {
			cards: this.cards,
			cardsCount: this.cards.length,
			playerId: this.playerId,
			show: this.show,
			online: this.online,
			ready: this.ready,
		};
	};

	areaPlayerSchema.methods.toSimpleClientData = function(){
		return {
			cardsCount: this.cards.length,
			playerId: this.playerId,
			show: this.show,
			online: this.online,
			ready: this.ready,
		};
	};


	mdbgoose.model('AreaPlayer', areaPlayerSchema);
};
