'use strict';

var consts = require('../consts');
var _ = require('lodash');

module.exports = function(app){
	var mdbgoose = app.memdb.goose;

	var playerSchema = new mdbgoose.Schema({
		_id : {type : Number},
		areaId : {type : String},
		teamId : {type : String},
		connectorId : {type : String},
		name : {type : String, default: ''},
        sex : {type : Number, default: consts.sex.MALE, validate: function(val){
            return _.indexOf(_.values(consts.sex), val) !== -1;
        }},
        money : {type : Number, min : 0},
	}, {collection : 'players'});

    playerSchema.statics.getUpdatableKeys = function() {
        return ['name', 'sex'];
    };

    playerSchema.methods.toClientData = function(){
        return {
            name: this.name,
            sex: this.sex,
            money: this.money,
            areaId: this.areaId,
            teamId: this.teamId,
            id: this._id
        };
    };

	mdbgoose.model('Player', playerSchema);
};
