var util = require('util');
var _ = require('lodash');
var consts = require('../app/consts');
var cardFormula = require('../app/formula/cardFormula');
var logger = require('quick-pomelo').logger.getLogger('robot', __filename);


var exp = module.exports;

exp.hasGreaterCards = function(played, left, cards) {
	var handType = cardFormula.getHandType(cards);
};

