'use strict';

var P = require('bluebird');
var quick = require('quick-pomelo');
var should = require('should');
var consts = require('../../app/consts');
var logger = quick.logger.getLogger('test', __filename);

var main = function(){
    var connector1 = {host : '127.0.0.1', port : 3100};
    var connector2 = {host : '127.0.0.1', port : 3101};

    var client1 = quick.mocks.client(connector1);
    var client2 = quick.mocks.client(connector2);
    var client3 = quick.mocks.client(connector1);
    var client4 = quick.mocks.client(connector2);

    var playerId = 'p1';

    P.coroutine(function*(){
        var authInfo = {socialId : '1234', socialType: consts.binding.types.DEVICE};
        yield client1.connect();
        yield client1.request('connector.entryHandler.login', {authInfo : authInfo});
        yield client1.request('player.playerHandler.update', {opts : {name : 'rain'}});
        yield client2.connect();
        // Client1 should be kicked out
        yield client2.request('connector.entryHandler.login', {authInfo : authInfo});
        // Explicitly call logout
        yield client2.request('connector.entryHandler.logout');
        yield client3.connect();
        yield client3.request('connector.entryHandler.login', {authInfo : authInfo});
        // Auto logout on disconnect
        client3.disconnect();
        yield P.delay(100);
        yield client4.connect();
        yield client4.request('connector.entryHandler.login', {authInfo : authInfo});
        // Remove and logout
        yield client4.request('player.playerHandler.remove');
        client4.disconnect();
    })()
    .catch(function(e){
        logger.error('error raised: ', e);
    })
    .finally(function(){
        process.exit();
    });
};

if (require.main === module) {
    main();
}
