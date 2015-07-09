'use strict';

var P = require('bluebird');
var logger = require('quick-pomelo').logger.getLogger('test', __filename);
var cardFormula = require('../../app/formula/cardFormula')

describe('area test', function(){
    it('yield', function(done){
        P.coroutine(function*(){
            yield P.delay(1000);
            console.log('123');
            console.log('isHandPair: %j', cardFormula.isHandPair(['36', '16']));
        })().nodeify(done);
    });
});
