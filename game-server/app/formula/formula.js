'use strict';

var _ = require('lodash');

var exp = module.exports;

var punish = exp.punishment = {};
var reward = exp.reward = {};

var base = 10;

punish.forceQuitGame = function(odds, isLandlord) {
	return base * odds * 2;
};

reward.otherForceQuitGame = function(odds, isLandlord) {
	return base * odds;
};


reward.win = function(odds, isLandlord) {
	return isLandlord ? base * odds * 2 : base * odds;
};

punish.lose = function(odds, isLandlord) {
	return isLandlord ? base * odds * 2 : base * odds;
};

