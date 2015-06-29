'use strict';

var P = require('bluebird');
var env = require('../env');
var should = require('should');
var consts = require('../../app/consts');
var logger = require('quick-pomelo').logger.getLogger('test', __filename);

describe('team test', function(){
	beforeEach(env.beforeEach);
	afterEach(env.afterEach);

	it('team test', function(cb){
		var app = env.createApp('team-server-1', 'team');

		P.coroutine(function*(){
			yield P.promisify(app.start, app)();

			var teamController = app.controllers.team;
			var playerController = app.controllers.player;
			yield app.memdb.goose.transaction(P.coroutine(function*(){
				var playerId = yield playerController.createAsync({
					authInfo: {socialId : '123', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});
				var teamId = yield teamController.createAsync(playerId, {name : 'area1'});
				var players = yield teamController.getPlayersAsync(teamId);
				players.length.should.eql(1);
				players[0]._id.should.eql(playerId);

				yield playerController.connectAsync(playerId, 'c1');
				yield teamController.pushAsync(teamId, null, 'chat', 'hello', true);
				var msgs = yield teamController.getMsgsAsync(teamId, 0);
				msgs.length.should.eql(1);
				msgs[0].msg.should.eql('hello');

				var playerId1 = yield playerController.createAsync({
					authInfo: {socialId : '1234', socialType: consts.binding.types.DEVICE},
					name : 'rain1'
				});
				yield teamController.joinAsync(teamId, playerId1);

				var team = yield app.models.Team.findByIdAsync(teamId);
				team.playerIds.toObject().should.eql([playerId, playerId1]);

				yield teamController.quitAsync(teamId, playerId);
				yield playerController.removeAsync(playerId);

				players = yield teamController.getPlayersAsync(teamId);
				players.length.should.eql(1);
				should.not.exist(yield app.models.Area.findByIdAsync(teamId));
			}), app.getServerId());

			yield P.promisify(app.stop, app)();
		})()
		.nodeify(cb);
	});
});
