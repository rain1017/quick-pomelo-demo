var EventEmitter = require('events').EventEmitter;
var util = require('util');
var _ = require('lodash');
var consts = require('../app/consts');
var logger = require('pomelo-logger').getLogger('robot', __filename);

var goose = require('quick-pomelo/node_modules/memdb/lib/mdbgoose');
var app = {memdb: {goose: goose}};

require('../app/models/area')(app);
require('../app/models/areaPlayer')(app);
require('../app/models/player')(app);

var Area = goose.model('Area');
var Player = goose.model('Player');
var AreaPlayer = goose.model('AreaPlayer');


var ModelStore = function () {
	this.models = {me: null, area: null, areaPlayers: {}};
	var self = this;
	Object.defineProperty(this, 'me', {
		get: function(){
			return self.models.me;
		}
	});
	Object.defineProperty(this, 'area', {
		get: function(){
			return self.models.area;
		}
	});
	Object.defineProperty(this, 'areaPlayers', {
		get: function(){
			return self.models.areaPlayers;
		}
	});
};

module.exports = ModelStore;
var proto = ModelStore.prototype;

proto.updateModels = function (data) {
	var self = this;
	if(data.areaPlayers) {
		_.map(data.areaPlayers, function (areaPlayer) {
			self.updateModels({areaPlayer: areaPlayer});
		});
	}
	if(data.players) {
		_.map(data.players, function (player) {
			self.updateModels({player: player});
		});
	}
	if(data.area) {
		if(!this.models.area) {
			this.models.area = new Area();
		}
		this.updateModel('Area', this.models.area, data.area);
	}
	if(data.areaPlayer) {
		if(!this.models.areaPlayers[data.areaPlayer.playerId]) {
			this.models.areaPlayers[data.areaPlayer.playerId] = new AreaPlayer();
		}
		this.updateModel('AreaPlayer', this.models.areaPlayers[data.areaPlayer.playerId], data.areaPlayer);
	}
	if(data.player) {
		if(!this.models.me) {
			this.models.me = new Player();
		}
		if(data.player.id == this.models.me.id) {
			this.updateModel('Player', this.models.me, data.player);
		}
	}
};

proto.updateModelMe = function(data) {
	if(data.player) {
		if(!this.models.me) {
			this.models.me = new Player();
		}
		this.updateModel('Player', this.models.me, data.player);
	}
};

proto.updateModel = function (name, model, data) {
	_.forIn(data, function (value, key) {
		if(model.schema.paths[key]) {
			model[key] = value;
		} else if(key == 'id') {
			model._id = value;
		} else {
			logger.info('no path found for model[%s]: path=%s', name, key);
		}
	});
};

proto.clean = function () {
	this.models.area = null;
	this.models.areaPlayers = {};
};
