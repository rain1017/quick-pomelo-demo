'use strict';

var P = require('bluebird');
var env = require('../env');
var should = require('should');
var consts = require('../../app/consts');
var timer = require('../../app/timer/timer');
var logger = require('quick-pomelo').logger.getLogger('test', __filename);

describe('area test', function(){
	beforeEach(env.beforeEach);
	afterEach(env.afterEach);

	it('area player create/connect/join/quit/remove/getPlayers test', function(cb){
		var app = env.createApp('area-server-1', 'area');
		P.coroutine(function*(){
			yield P.promisify(app.start, app)();

			var areaController = app.controllers.area;
			var playerController = app.controllers.player;
			yield app.memdb.goose.transaction(P.coroutine(function*(){
				var playerId = yield playerController.createAsync({
					authInfo: {socialId : '123', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});
				var areaId = yield areaController.searchAndJoinAsync(playerId, {name : 'area1'});
				console.log('searchAndJoinAsync return: %j', areaId);
				areaId = areaId.data.area.id;
				var players = yield areaController.getPlayersAsync(areaId);
				players.length.should.eql(1);
				players[0]._id.should.eql(playerId);

				yield playerController.connectAsync(playerId, 'c1');
				yield areaController.pushAsync(areaId, null, 'chat', 'hello', true);
				var msgs = yield areaController.getMsgsAsync(areaId, 0);
				msgs.length.should.eql(1);
				msgs[0].msg.should.eql('hello');

				var playerId1 = yield playerController.createAsync({
					authInfo: {socialId : '1234', socialType: consts.binding.types.DEVICE},
					name : 'rain1'
				});
				yield areaController.joinAsync(areaId, playerId1);

				yield areaController.disconnectAsync(playerId1, areaId);

				var area = yield app.models.Area.findById(areaId);
				area.playerIds.toObject().should.eql([playerId, null]);

				yield areaController.quitAsync(areaId, playerId);
				yield playerController.removeAsync(playerId);

				players = yield areaController.getPlayersAsync(areaId);
				players.length.should.eql(0);
				should.not.exist(yield app.models.Area.findById(areaId));

				timer.getTimerManager(app).cancelAll();
			}), app.getServerId());

			yield P.promisify(app.stop, app)();
		})()
		.nodeify(cb);
	});


	it('area player chooseLord test', function(cb){
		this.timeout(10000);
		var app = env.createApp('area-server-1', 'area');
		P.coroutine(function*(){
			yield P.promisify(app.start, app)();

			var areaController = app.controllers.area;
			var playerController = app.controllers.player;
			var gameController = app.controllers.game;
			yield app.memdb.goose.transaction(P.coroutine(function*(){
				var playerId = yield playerController.createAsync({
					authInfo: {socialId : '123', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});
				var areaId = yield areaController.createAsync(playerId, {name : 'area1'});
				areaId = areaId.data.area.id;
				var playerId1 = yield playerController.createAsync({
					authInfo: {socialId : '123-1', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});
				var playerId2 = yield playerController.createAsync({
					authInfo: {socialId : '123-2', socialType: consts.binding.types.DEVICE},
					name : 'rain'
				});

				// waitToStart
				var area = yield app.models.Area.findById(areaId);
				area.state.should.eql(consts.gameState.waitToStart);

				yield areaController.joinAsync(areaId, playerId1);
				yield areaController.joinAsync(areaId, playerId2); // should auto deal cards

				// choosingLord
				area = yield app.models.Area.findById(areaId);
				area.state.should.eql(consts.gameState.choosingLord);
				var playingPlayerId = area.playingPlayerId();
				var testPlayingPlayerId = area.playerIds.filter((id) => id !== playingPlayerId)[0];

				var res = yield gameController.chooseLordAsync(areaId, testPlayingPlayerId, false);
				res.code.should.eql(consts.resp.codes.INVALID_ACTION);

				res = yield gameController.chooseLordAsync(areaId, playingPlayerId, true);
				res.code.should.eql(consts.resp.codes.SUCCESS);

				yield gameController.chooseLordAsync(areaId, area.playerIds[area.nextTurn()], false);
				area = yield app.models.Area.findById(areaId);
				yield gameController.chooseLordAsync(areaId, area.playingPlayerId(), false);

				// playing
				area = yield app.models.Area.findById(areaId);
				area.state.should.eql(consts.gameState.playing);

				var landlord = yield app.models.AreaPlayer.findByAreaIdAndPlayerIdAsync(area._id, area.landlord);
				var landlordRightId = area.playerIds[area.nextTurn()];
				var landlordLeftId = area.playerIds.filter((id) => id !== landlord.playerId && id !== landlordRightId)[0];
				for (var i = 0; i < landlord.cards.length; i++) {
					logger.debug('round: %s', i + 1);
					res = yield gameController.playAsync(areaId, landlord.playerId, [landlord.cards[i]]);
					res.code.should.eql(consts.resp.codes.SUCCESS);
					res = yield gameController.playAsync(areaId, landlordRightId, []);
					res.code.should.eql(i === landlord.cards.length - 1 ? consts.resp.codes.INVALID_ACTION : consts.resp.codes.SUCCESS);
					res = yield gameController.playAsync(areaId, landlordLeftId, []);
					res.code.should.eql(i === landlord.cards.length - 1 ? consts.resp.codes.INVALID_ACTION : consts.resp.codes.SUCCESS);
				}

				area = yield app.models.Area.findById(areaId);
				area.state.should.eql(consts.gameState.waitToStart);

				timer.getTimerManager(app).cancelAll();
			}), app.getServerId());
			yield P.promisify(app.stop, app)();
		})()
		.nodeify(cb);
	});

});
