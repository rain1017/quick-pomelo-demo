'use strict';

var P = require('bluebird');
var quick = require('quick-pomelo');
var should = require('should');
var consts = require('../../app/consts');
var logger = quick.logger.getLogger('test', __filename);

P.longStackTraces();

var main = function(){
	var gateServer = {host : '127.0.0.1', port : 3010};
	var playerId, areaId;

	P.coroutine(function*(){
		var client = quick.mocks.client(gateServer);
		yield client.connect();
		var connectorServer = yield client.request('gate.gateHandler.getConnector', null);
		client.disconnect();

		// Connect to connector
		client = quick.mocks.client(connectorServer.data);
		yield client.connect();

		var authInfo = {socialId : '1234', socialType: consts.binding.types.DEVICE};
		yield client.request('connector.entryHandler.login', {authInfo : authInfo});
		yield client.request('player.playerHandler.update', {opts : {name : 'rain'}});

		areaId = yield client.request('area.areaHandler.create', {opts : {name : 'area1'}});
		areaId = areaId.data.area.id;
		client.on('notify', function(msg){
			logger.info('on notify %j', msg);
		});
		yield client.request('area.areaHandler.push', {areaId : areaId, route : 'notify', msg : 'hello', persistent : true});
		var msgs = yield client.request('area.areaHandler.getMsgs', {areaId : areaId, seq : 0});
		logger.info('%j', msgs);
		yield client.request('area.areaHandler.quit', {areaId : areaId});
		yield client.request('player.playerHandler.remove', {});
		client.disconnect();
	})()
	.finally(function(){
		process.exit();
	});
};

if (require.main === module) {
	main();
}
