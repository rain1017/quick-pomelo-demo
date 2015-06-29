'use strict';

var _ = require('lodash');
var consts = require('../consts');
var logger = require('pomelo-logger').getLogger('area', __filename);

var exp = module.exports;

exp.cardPoints = {};
exp.cardPoints[consts.card.jokerRed] = consts.card.points.length + 1;
exp.cardPoints[consts.card.joker] = consts.card.points.length;
consts.card.points.forEach(function(k, i){
	exp.cardPoints[k] = i;
});

exp.pointIdx2Point = function(i) {
	if (i === consts.card.points.length) {
		return consts.card.joker;
	} else if (i === consts.card.points.length + 1) {
		return consts.card.jokerRed;
	} else {
		return consts.card.points[i];
	}
};

exp._toPointIdx = function(c, isPoint) {
	var p = isPoint ? c : c.substring(1);
	return exp.cardPoints[p];
};

exp.sortCards = function(cards, isPoint) {
	return _.sortBy(cards, function(c){
		return exp._toPointIdx(c, isPoint);
	});
};

exp.autoPlay = function(cards, must) {
	return must ? [cards[0]] : [];
};

exp.isCardsValid = function(cards, isPoint, sorted) {
	var res = exp.getHandType(cards, isPoint, sorted) !== -1;
	//logger.debug('cardFormula.isCardsValid: cards=%j, isPoint=%s, sorted=%s, res=%s', cards, isPoint, sorted, res);
	return res;
};

exp.isCardsGreater = function(cards, compared, isPoint, sorted) {
	console.log('cards: %j, compared: %j', cards, compared);
	var handInfo = exp.getHandTypeInfo(cards, isPoint, sorted);
	var compHandInfo = exp.getHandTypeInfo(compared, isPoint, sorted);
	//logger.debug('handInfo: %j, compHandInfo: %j', handInfo, compHandInfo);
	if(handInfo.type === consts.card.handTypes.ROCKET) {
		return true;
	}
	if(compHandInfo.type === consts.card.handTypes.ROCKET) {
		return false;
	}
	if(handInfo.type === consts.card.handTypes.BOMB &&
		compHandInfo.type !== consts.card.handTypes.BOMB) {
		return true;
	}
	if(handInfo.type !== compHandInfo.type) {
		return false;
	}
	if(handInfo.info.required &&
		handInfo.info.required !== compHandInfo.info.required) {
		return false;
	}
 	return handInfo.info.main > compHandInfo.info.main;
};

var handTypes = _.keys(consts.card.handTypes);
var handFuncNames = handTypes.map((t) => 'isHand' + t.toLowerCase().split('_').map((s)=>s.charAt(0).toUpperCase() + s.slice(1)).join(''));
exp.getHandType = function(cards, isPoint, sorted) {
	for (var i = 0; i < handTypes.length; i++) {
		if(exp[handFuncNames[i]](cards, isPoint, sorted)) {
			return consts.card.handTypes[handTypes[i]];
		}
	}
	return -1;
};

exp.getHandTypeInfo = function(cards, isPoint, sorted) {
	for (var i = 0; i < handTypes.length; i++) {
		var info = exp[handFuncNames[i]](cards, isPoint, sorted);
		if(info) {
			return {type: consts.card.handTypes[handTypes[i]], info: info};
		}
	}
	return null;
};

exp.isHandRocket = function(cards, isPoint, sorted) {
	if(cards.length !== 2) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	if((ps[0] === consts.card.joker && ps[1] === consts.card.jokerRed) ||
		(ps[1] === consts.card.joker && ps[0] === consts.card.jokerRed)) {
		return {main: exp._toPointIdx(cards[cards.length-1], isPoint)};
	}
	return false;
};

exp.isHandBomb = function(cards, isPoint, sorted) {
	if(cards.length !== 4) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	if(ps[1] === ps[0] && ps[2] === ps[0] && ps[3] === ps[0]) {
		return {main: exp._toPointIdx(ps[0], true)};
	}
	return false;
};

exp.isHandSolo = function(cards, isPoint, sorted) {
	if(cards.length !== 1) {
		return false;
	}
	return {main: exp._toPointIdx(cards[0], isPoint)};
};

exp.isHandPair = function(cards, isPoint, sorted) {
	if(cards.length !== 2) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	if(ps[1] === ps[0]) {
		return {main: exp._toPointIdx(ps[0], true)};
	}
	return false;
};

exp.isHandStraight = function(cards, isPoint, sorted) {
	if(cards.length < 5) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	var idxs = ps.map((p) => exp._toPointIdx(p, true));
	for (let i = 1; i < idxs.length; i++) {
		if(idxs[i] !== idxs[i-1] + 1) {
			return false;
		}
	}
	if(idxs[idxs.length-1] >= consts.card.points.length - 1) {
		return false;
	}
	return {main: idxs[idxs.length-1], required: cards.length};
};

exp.isHandConsecutivePairs = function(cards, isPoint, sorted) {
	if(cards.length < 6 || cards.length % 2 !== 0) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	if(_.indexOf(['2', consts.card.joker, consts.card.jokerRed], ps[ps.length-1]) !== -1) {
		return false;
	}
	for (var i = 0; i < ps.length / 2; i++) {
		if(ps[i*2] !== ps[i*2 + 1]) {
			return false;
		}
		if(i > 0 && exp._toPointIdx(ps[i*2-1], true) + 1 !== exp._toPointIdx(ps[i*2], true)) {
			return false;
		}
	}
	return {main: exp._toPointIdx(ps[ps.length-1], true), required: cards.length/2};
};

exp.isHandTrio = function(cards, isPoint, sorted) {
	if(cards.length !== 3) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	if(ps[1] === ps[0] && ps[2] === ps[0]) {
		return {main: exp._toPointIdx(ps[0], true)};
	}
	return false;
};

exp.isHandTrioSolo = function(cards, isPoint, sorted) {
	if(cards.length !== 4) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	if(ps[1] === ps[0] ? (ps[2] === ps[0] && ps[3] !== ps[0]) : (ps[2] === ps[1] && ps[3] === ps[1])) {
		return {main: exp._toPointIdx(ps[1], true)};
	}
	return false;
};


exp.isHandTrioPair = function(cards, isPoint, sorted) {
	if(cards.length !== 5) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	if(ps[2] === ps[1] ? (ps[0] === ps[1] && ps[4] === ps[3] && ps[3] !== ps[2]) :
		(ps[0] === ps[1] && ps[3] === ps[2] && ps[4] === ps[2])) {
		return {main: exp._toPointIdx(ps[2], true)};
	}
	return false;
};

exp.isHandAirplane = function(cards, isPoint, sorted) {
	if(cards.length < 6 || cards.length % 3 !== 0) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	for (var i = 0; i < ps.length / 3; i++) {
		if(ps[i*3+2] !== ps[i*3] || ps[i*3+1] !== ps[i*3]) {
			return false;
		}
		if(i > 0 && exp._toPointIdx(ps[i*3-1], true) + 1 !== exp._toPointIdx(ps[i*3], true)) {
			return false;
		}
	}
	if(ps[ps.length -1] === '2') {
		return false;
	}
	return {main: exp._toPointIdx(ps[ps.length-1], true), required: cards.length/3};
};

exp.isHandAirplaneSolo = function(cards, isPoint, sorted) {
	if(cards.length < 8 || cards.length % 4 !== 0) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	var trios = [];
	for (let i = 2; i < ps.length; i++) {
		if(ps[i] === ps[i-2] && ps[i-1] === ps[i-2]) {
			if(_.indexOf(trios, ps[i]) === -1) {
				trios.push(ps[i]);
			}
		}
	}
	if(trios.length < 2) {
		return false;
	}
	if(trios[trios.length -1] === '2') {
		return false;
	}
	var trioIdxs = trios.map((p) => exp._toPointIdx(p, true));
	for (let i = 1; i < trioIdxs.length; i++) {
		if(trioIdxs[i] !== trioIdxs[i-1] + 1) {
			return false;
		}
	}
	return {main: trioIdxs[trioIdxs.length-1], required: cards.length/4};
};

exp.isHandAirplanePair = function(cards, isPoint, sorted) {
	if(cards.length < 10 || cards.length % 5 !== 0) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	var trios = [];
	for (let i = 2; i < ps.length; i++) {
		if(ps[i] === ps[i-2] && ps[i-1] === ps[i-2]) {
			if(_.indexOf(trios, ps[i]) === -1) {
				trios.push(ps[i]);
			}
		}
	}
	if(trios.length < 2) {
		return false;
	}
	if(trios[trios.length -1] === '2') {
		return false;
	}
	var trioIdxs = trios.map((p) => exp._toPointIdx(p, true));
	for (let i = 1; i < trioIdxs.length; i++) {
		if(trioIdxs[i] !== trioIdxs[i-1] + 1) {
			return false;
		}
	}
	var pairs = [];
	for (let i = 0; i < ps.length; i++) {
		if(_.indexOf(trios, ps[i]) === -1) {
			pairs.push(ps[i]);
		}
	}
	if(exp._isPairs(pairs)) {
		return {main: trioIdxs[trioIdxs.length-1], required: cards.length/5};
	}
	return false;
};

exp.isHandSpaceShuttleSolo = function(cards, isPoint, sorted) {
	if(cards.length !== 6) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	var fours = [];
	for (let i = 3; i < ps.length; i++) {
		if(ps[i] === ps[i-3] && ps[i-1] === ps[i-3] && ps[i-2] === ps[i-3]) {
			if(_.indexOf(fours, ps[i]) === -1) {
				fours.push(ps[i]);
			}
		}
	}
	if(fours.length < 1) {
		return false;
	}
	return {main: exp._toPointIdx(fours[fours.length-1], true)};
};

exp._isPairs = function(pairs) {
	if(pairs.length % 2 !== 0) {
		return false;
	}
	for (let i = 0; i < pairs.length/2; i++) {
		if(pairs[i*2] !== pairs[i*2+1]) {
			return false;
		}
	}
	return true;
};

exp.isHandSpaceShuttlePair = function(cards, isPoint, sorted) {
	if(cards.length !== 8) {
		return false;
	}
	var ps = isPoint ? cards : cards.map((c) => c.substring(1));
	ps = sorted ? ps : exp.sortCards(ps, true);
	var fours = [];
	for (let i = 3; i < ps.length; i++) {
		if(ps[i] === ps[i-3] && ps[i-1] === ps[i-3] && ps[i-2] === ps[i-3]) {
			if(_.indexOf(fours, ps[i]) === -1) {
				fours.push(ps[i]);
			}
		}
	}
	if(fours.length < 1) {
		return false;
	}
	var pairs = [];
	for (let i = 0; i < ps.length; i++) {
		if(_.indexOf(fours, ps[i]) === -1) {
			pairs.push(ps[i]);
		}
	}
	if(exp._isPairs(pairs)) {
		return {main: exp._toPointIdx(fours[fours.length-1], true)};
	}
	return false;
};

exp.arrangeCards = function(cards, sorted) {
	var trios = [], solos = [], pairs = [], straights = [], bombs = [];
	cards = sorted ? cards : exp.sortCards(cards, true);
	var ps = cards.map(exp._toPointIdx);
	for (var i = 0; i < ps.length; i++) {
		ps[i]
	}
};


