'use strict';

var P = require('bluebird');
var uuid = require('node-uuid');
var _ = require('lodash');
var util = require('util');
var formula = require('../formula/formula');
var logger = require('pomelo-logger').getLogger('area', __filename);

var Controller = function(app){
	this.app = app;
};

var proto = Controller.prototype;


proto.dealCardsAsync = P.coroutine(function*(areaId){
	// send player cards, arrange choose lord
	yield P.resolve();
});


module.exports = function(app){
	return new Controller(app);
};
