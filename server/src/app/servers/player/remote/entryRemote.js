'use strict';
var P = require('bluebird');
var logger = require('pomelo-logger').getLogger('player', __filename);

var Remote = function(app){
	this.app = app;
};

Remote.prototype.login = function(msg, frontendId, cb){
	var self = this;
	var controllers = this.app.controllers;
	var rpc = this.app.rpc;
	var authInfo = msg.authInfo;
	self.app.memdb.goose.transaction(P.coroutine(function*(){
		logger.info('login.msg: %j', msg);
		var playerId = yield controllers.player.authAsync(authInfo);
		if(!playerId){
			playerId = yield controllers.player.createAsync({authInfo: authInfo});
		}

		var data = yield controllers.player.connectAsync(playerId, frontendId);
		data.playerId = playerId;
		if(data.oldConnectorId){
			logger.warn('player %s already connected on %s, will kick', playerId, data.oldConnectorId);
			// kick original connector
			var entryRemote = rpc.connector.entryRemote;
			yield P.promisify(entryRemote.kick, entryRemote)({frontendId : data.oldConnectorId}, playerId);
		}

		logger.info('player %s login', playerId);
		return data;
	})).nodeify(cb);
};

Remote.prototype.logout = function(playerId, cb) {
	var self = this;
	var controllers = this.app.controllers;
	self.app.memdb.goose.transaction(P.coroutine(function*(){
		yield controllers.player.disconnectAsync(playerId);
		logger.info('player %s logout', playerId);
    })).nodeify(cb);
};


module.exports = function(app){
	return new Remote(app);
};
