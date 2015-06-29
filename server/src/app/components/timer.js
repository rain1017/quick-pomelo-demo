'use strict';

var path = require('path');
var logger = require('quick-pomelo').logger.getLogger('area', __filename);
var timer = require('../timer/timer');


var Timer = function(app, opts){
	opts = opts || {};
	this._app = app;
};

var proto = Timer.prototype;

proto.name = 'TimerComp';

proto.start = function(cb){
	timer.getTimerManager(this._app).init();
	cb();
};

proto.stop = function(force, cb){
	timer.getTimerManager(this._app).cancelAll();
	cb();
};

module.exports = function(app, opts){
	var timer = new Timer(app, opts);
	app.set(Timer.name, timer, true);
	return timer;
};
