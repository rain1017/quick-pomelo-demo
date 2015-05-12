'use strict';

var P = require('bluebird');
var util = require('util');
var resp = require('../../../resp');
var logger = require('pomelo-logger').getLogger('connector', __filename);

var Handler = function(app){
	this.app = app;
};

var proto = Handler.prototype;

/**
 * msg.auth - authentication data
 */
proto.login = function(msg, session, next){
	if(!!session.uid){
		return next(new Error('session already logged in with playerId ' + session.uid));
	}

	var authInfo = msg.authInfo;
	if(!authInfo){
		return next(new Error('authInfo is missing'));
	}

	var self = this;
	P.coroutine(function*(){
		var playerEntryRemote = self.app.rpc.player.entryRemote;
		var data = yield P.promisify(playerEntryRemote.login, playerEntryRemote)(session, msg, session.frontendId);
        yield P.promisify(session.bind, session)(data.playerId);

		// OnDisconnect
		session.on('closed', function(session, reason){
			if(reason === 'kick' || !session.uid){
				return;
			}
			// auto logout on disconnect
			self.app.memdb.goose.transaction(function(){
				return P.promisify(self.logout, self)({closed : true}, session);
			})
			.catch(function(e){
				logger.warn(e);
			});
		});

		return resp.successResp(data.data);
	})().nodeify(next);
};

proto.logout = function(msg, session, next){
	var playerId = session.uid;
	if(!playerId){
		return next(new Error('playerId is missing'));
	}

	var self = this;
	P.coroutine(function*(){
		var playerEntryRemote = self.app.rpc.player.entryRemote;
		var data = yield P.promisify(playerEntryRemote.logout, playerEntryRemote)(session, playerId);
		if(!msg.closed) {
			yield P.promisify(session.unbind, session)(playerId);
		}
	})().nodeify(next);
};

module.exports = function(app){
	return new Handler(app);
};
