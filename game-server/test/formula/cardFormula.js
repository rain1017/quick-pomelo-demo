'use strict';

var P = require('bluebird');
var should = require('should');
var consts = require('../../app/consts');
var cardFormula = require('../../app/formula/cardFormula');
var logger = require('quick-pomelo').logger.getLogger('test', __filename);

describe('area test', function(){

    it('cardFormula test', function(cb){
        var self = this;
        var keyOfHandType = function(handType) {
            var keys = Object.keys(consts.card.handTypes);
            for (var i = 0; i < keys.length; i++) {
                if(consts.card.handTypes[keys[i]] === handType) {
                    return keys[i].toLowerCase().split('_').map((s)=>s.charAt(0).toUpperCase() + s.slice(1)).join(' ');
                }
            }
            return 'UNKNOWN';
        };
        var assertType = function(hands, handType) {
            hands.map(function(cards){
                var _cards = cards.split('');
                var _handType = cardFormula.getHandType(_cards, true, true);
                console.log('test cards: %s -> %s', cards, keyOfHandType(_handType));
                handType.should.eql(_handType);
            });
        };

        var assertInvalid = function(hands) {
            hands.map(function(cards){
                var _cards = cards.split('');
                var _handType = cardFormula.getHandType(_cards, true, true);
                console.log('test cards: %s -> %s', cards, keyOfHandType(_handType));
                _handType.should.equal(-1);
            });
        };

        var assertGreater = function(handPairs) {
            handPairs.map(function(handPair){
                var cards = handPair[0], comp = handPair[1];
                var _cards = cards.split(''), _compCards = comp.split('');
                console.log('compare cards: %s > %s', cards, comp);
                cardFormula.isCardsGreater(_cards, _compCards, true, true).should.be.true;
            });
        };

        var assertNotGreater = function(handPairs) {
            handPairs.map(function(handPair){
                var cards = handPair[0], comp = handPair[1];
                var _cards = cards.split(''), _compCards = comp.split('');
                console.log('compare cards: %s !> %s', cards, comp);
                cardFormula.isCardsGreater(_cards, _compCards, true, true).should.be.false;
            });
        };

        assertType(
            ['XY'],
            consts.card.handTypes.ROCKET);
        assertType(
            ['AAAA', 'JJJJ', '2222', '0000', '5555'],
            consts.card.handTypes.BOMB);
        assertType(
            ['3', '4', '8', '9', 'Q'],
            consts.card.handTypes.SOLO);
        assertType(
            ['33', '44', '88', '99', 'QQ', '22'],
            consts.card.handTypes.PAIR);
        assertType(
            ['34567', '0JQKA', '3456789'],
            consts.card.handTypes.STRAIGHT);
        assertType(
            ['334455', '445566', '77889900', '9900JJ', 'QQKKAA'],
            consts.card.handTypes.CONSECUTIVE_PAIRS);
        assertType(
            ['333', '444', '888', '999', 'QQQ', '222'],
            consts.card.handTypes.TRIO);
        assertType(
            ['3334', '3444', '4888', '9990', 'JQQQ', 'A222'],
            consts.card.handTypes.TRIO_SOLO);
        assertType(
            ['33344', '33444', '44888', '99900', 'JJQQQ', 'AA222'],
            consts.card.handTypes.TRIO_PAIR);
        assertType(
            ['333444', '444555', '777888', '999000', 'JJJQQQ', 'KKKAAA'],
            consts.card.handTypes.AIRPLANE);
        assertType(
            ['333444XY', '4445552X', '888999JA', '999000KK', '3QQQKKKA'],
            consts.card.handTypes.AIRPLANE_SOLO);
        assertType(
            ['3334445566', '3344455566', '4488899922', '999000AA22', '00JJJQQQKK', '00KKKAAA22'],
            consts.card.handTypes.AIRPLANE_PAIR);
        assertType(
            ['333345', '334444', '8888KX', '999922', '5QQQQK', '2222XY'],
            consts.card.handTypes.SPACE_SHUTTLE_SOLO);
        assertType(
            ['33334455', '33444466', '33448888', '999900KK', 'JJQQQQ22', '55AA2222'],
            consts.card.handTypes.SPACE_SHUTTLE_PAIR);

        assertInvalid([
            '2345', '234', '345', 'A23', 'KKAA22', '23444', '3AAA222X', 'AAA222',
            'QKA2X'
        ]);

        assertGreater([
            ['2', 'A'],
            ['Y', 'X'],
            ['Y', 'J'],
            ['44', '33'],
            ['22', 'AA'],
            ['45678', '34567'],
            ['QQKKAA', '445566'],
            ['QQQ', '444'],
            ['3QQQ', '4443'],
            ['33QQQ', '44433'],
            ['33QQQKKK', '000JJJ2X'],
            ['3344QQQKKK', '000JJJAA22'],
            ['344445', '333344'],
            ['33444455', '33334455'],
            ['5555', '4444'],
            ['2222', '4444'],
            ['XY', '4444'],
        ]);
        assertNotGreater([
            ['456789', '34567'],
            ['2', 'AA'],
            ['33', '22'],
        ]);

        cb();
    });

});
