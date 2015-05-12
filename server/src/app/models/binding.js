'use strict';

var _ = require('lodash');
var consts = require('../consts');

module.exports = function(app){
	var mdbgoose = app.memdb.goose;

	var bindingSchema = new mdbgoose.Schema({
		_id : {type : String},
		playerId : {type : Number, index : true},
		socialId : {type : String, index : true},
		socialType : {type : Number, validate: function(val){
			return _.indexOf(_.values(consts.binding.types), val) !== -1;
		}},
	}, {collection : 'bindings'});

	bindingSchema.index({socialId : 1, socialType : 1}, {unique : true});

	mdbgoose.model('Binding', bindingSchema);
};
