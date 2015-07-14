'use strict';

var should = require('should');
var consts = require('../../game-server/app/consts');
var cardArranger = require('../app/cardArranger');

describe('cardArranger', function(){

	it('_findAndRemoveCards', function(cb){
		var cards = ['03', '13', '14', '24', '25', '35','17'], found;
		found = cardArranger._findAndRemoveCards([0, 1, 2], cards, true);
		found.should.eql(['03', '13', '14', '24', '25', '35']);
		cards.should.eql(['17']);

		cards = ['03', '13', '14', '24', '25', '35','17'];
		found = cardArranger._findAndRemoveCards([0, 1, 2], cards, true, true);
		found.should.eql(['03', '14', '25']);
		cards.should.eql(['13', '24', '35', '17']);

		cb();
	});

	it('_findMulti', function(cb){
		var cards = [0, 0, 2, 2, 5, 5, 5, 7, 7, 7, 7, 9], found;
		found = cardArranger._findMulti(cards, 2);
		found.should.eql([0, 2, 5, 7]);
		found = cardArranger._findMulti(cards, 3);
		found.should.eql([5, 7]);
		found = cardArranger._findMulti(cards, 4);
		found.should.eql([7]);
		found = cardArranger._findMulti(cards, 1);
		found.should.eql([0, 2, 5, 7, 9]);
		cb();
	});

	it('_findStraits', function(cb){
		var cards = [0, 0, 2, 2, 3, 3, 3, 3, 4, 4, 6, 6, 6, 7, 8, 9, 10, 11, 12, 13], found;
		found = cardArranger._findStraits(cards, 5);
		found.should.eql([[6, 7, 8, 9, 10]]);
		found = cardArranger._findStraits(cards, 3, true);
		found.should.eql([[2, 3, 4]]);
		found = cardArranger._findStraits(cards, 3);
		found.should.eql([[2, 3, 4], [6, 7, 8], [9, 10, 11]]);
		cb();
	});

	it('_removeValues', function(cb){
		var cards = [0, 0, 2, 2, 3, 3, 3, 3, 4, 4, 6, 6, 6, 7, 8, 9, 10, 11, 12, 13], found;
		var removed = cardArranger._removeValues(cards, [0, 3, 4]);
		removed.should.eql([2, 2, 6, 6, 6, 7, 8, 9, 10, 11, 12, 13]);
		removed = cardArranger._removeValues(cards, [0, 3, 4], true);
		removed.should.eql([0, 2, 2, 3, 3, 3, 4, 6, 6, 6, 7, 8, 9, 10, 11, 12, 13]);
		cb();
	});

	it('_addCardToStraits', function(cb){
		var idxs = [0, 5, 7, 8, 14], straits = [[1, 2, 3, 4], [10, 11, 12, 13]];
		idxs = cardArranger._addCardToStraits(idxs, straits);
		idxs.should.eql([7, 8, 14]);
		straits.should.eql([[0, 1, 2, 3, 4, 5], [10, 11, 12, 13]]);

		idxs = [0, 1, 2, 5, 7, 8, 14], straits = [[1, 2, 3, 4], [10, 11, 12, 13]];
		idxs = cardArranger._addCardToStraits(idxs, straits);
		idxs.should.eql([1, 2, 7, 8, 14]);
		straits.should.eql([[0, 1, 2, 3, 4, 5], [10, 11, 12, 13]]);

		idxs = [0], straits = [[2, 3, 4], [10, 11, 12, 13]];
		idxs = cardArranger._addCardToStraits(idxs, straits);
		idxs.should.eql([0]);
		straits.should.eql([[2, 3, 4], [10, 11, 12, 13]]);
		cb();
	});

	it('_joinStraits', function(cb){
		var straits = [[1, 2, 3, 4], [10, 11, 12, 13]];
		cardArranger._joinStraits(straits);
		straits.should.eql([[1, 2, 3, 4], [10, 11, 12, 13]]);

		straits = [[1, 2, 3, 4], [5, 6, 7, 8]];
		cardArranger._joinStraits(straits);
		straits.should.eql([[1, 2, 3, 4, 5, 6, 7, 8]]);

		straits = [[2, 3, 4], [3, 4, 5, 6]];
		cardArranger._joinStraits(straits);
		straits.should.eql([[2, 3, 4], [3, 4, 5, 6]]);

		straits = [[2, 3, 4], [5, 6], [5, 6, 7], [7, 8], [8, 9, 10]];
		cardArranger._joinStraits(straits);
		straits.should.eql([[2, 3, 4, 5, 6, 7, 8], [5, 6, 7, 8, 9, 10]]);
		cb();
	});

	it('_insertStraits', function(cb){
		var straits = [[1, 2, 3, 4], [10, 11, 12, 13]];
		cardArranger._insertStraits(straits, [0, 1, 2]);
		straits.should.eql([[0, 1, 2], [1, 2, 3, 4], [10, 11, 12, 13]]);

		straits = [[1, 2, 3, 4], [5, 6, 7, 8]];
		cardArranger._insertStraits(straits, [9, 10, 11]);
		straits.should.eql([[1, 2, 3, 4], [5, 6, 7, 8], [9, 10, 11]]);

		straits = [[2, 3, 4], [3, 4, 5, 6]];
		cardArranger._insertStraits(straits, [2, 3, 4, 5]);
		straits.should.eql([[2, 3, 4], [2, 3, 4, 5], [3, 4, 5, 6]]);

		straits = [[2, 3, 4], [3, 4, 5, 6]];
		cardArranger._insertStraits(straits, [3, 4, 5]);
		straits.should.eql([[2, 3, 4], [3, 4, 5], [3, 4, 5, 6]]);
		cb();
	});

	it('_addToIdxs', function(cb){
		var idxs = [1,2,3,5,7];
		cardArranger._addToIdxs(idxs, 0, 3);
		idxs.should.eql([0,0,0,1,2,3,5,7]);

		idxs = [1,2,3,5,7];
		cardArranger._addToIdxs(idxs, 2, 3);
		idxs.should.eql([1,2,2,2,2,3,5,7]);
		idxs = [1,2,3,5,7];
		cardArranger._addToIdxs(idxs, 4, 3);
		idxs.should.eql([1,2,3,4,4,4,5,7]);
		idxs = [1,2,3,5,7];
		cardArranger._addToIdxs(idxs, 10, 3);
		idxs.should.eql([1,2,3,5,7,10,10,10]);
		cb();
	});

	it('_addTrioAndCardToStraits', function(cb){
		var idxs = [1, 1, 2, 2, 10, 11], trios=[3, 9, 12], straits = [[4,5,6,7], [4,5,6]];
		var res = cardArranger._addTrioAndCardToStraits(idxs, 3, straits);
		res.should.eql(true);
		idxs.should.eql([3,10,11]);
		cb();
	});

	it('_arrangeStraits', function(cb){
		var idxs = [1, 2, 3, 3, 4, 4, 5, 5, 6, 7, 9, 10, 11], trios=[8, 12];
		var res = cardArranger._arrangeStraits(idxs, trios);
		res.straits.should.eql([[1,2,3,4,5], [3,4,5,6,7,8,9,10,11]]);
		res.consPairs.should.eql([]);
		res.pairs.should.eql([8]);
		trios.should.eql([12]);
		cb();
	});

	it('_promoteSolos', function(cb){
		var straits = [[4,5,6,7,8,9]], pairs = [7], solos = [9];
		cardArranger._promoteSolos(straits, solos, pairs);
		straits.should.eql([[4,5,6,7,8]]);
		solos.should.eql([]);
		pairs.should.eql([7,9]);
		cb();
	});

	it('arrangeCards', function(cb){
		var cards = '031323,04050617271819,102030,0J2J2Q3Q2K3K,0212,0X,0Y';
		cards = cards.split(',').join('').match(/\w\w/g);
		var res = cardArranger.arrangeCards(cards);
		console.log('res: %j', res);
		res.rocket.should.eql([['0X', '0Y']]);
		res.bombs.should.eql([]);
		res.airplanes.should.eql([]);
		res.trios.should.eql([['03', '13', '23'], ['10', '20', '30']]);
		res.straits.should.eql([['04','05','06','17','18','19']]);
		res.consPairs.should.eql([['0J','2J','2Q','3Q','2K','3K']]);
		res.pairs.should.eql([['02', '12']]);
		res.solos.should.eql([['27']]);
		cb();
	});

});
