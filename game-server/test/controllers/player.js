'use strict';

var P = require('bluebird');
var env = require('../env');
var consts = require('../../app/consts');
var logger = require('quick-pomelo').logger.getLogger('test', __filename);

describe('player test', function(){
    beforeEach(env.initMemdbSync);
    afterEach(env.closeMemdbSync);

	it('create/remove/connect/disconnect', function(cb){
		var app = env.createApp('player-server-1', 'player');

		P.coroutine(function*(){
			yield P.promisify(app.start, app)();

			var playerController = app.controllers.player;

			yield app.memdb.goose.transaction(P.coroutine(function*(){
				var playerId = yield playerController.createAsync({
					authInfo: {socialId : '123', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});
				yield playerController.connectAsync(playerId, 'c1');

				yield playerController.pushAsync(playerId, 'notify', 'content', true);
				var ret = yield playerController.getMsgsAsync(playerId, 0);
				ret.length.should.eql(1);
				ret[0].msg.should.eql('content');

				yield playerController.disconnectAsync(playerId);
				yield playerController.removeAsync(playerId);
			}), app.getServerId());

			yield P.promisify(app.stop, app)();
		})()
		.nodeify(cb);
	});
});
