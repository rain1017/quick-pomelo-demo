'use strict';

var logger = require('quick-pomelo').logger.getLogger('area', __filename);
var P = require('bluebird');
var exp = module.exports;

var TimerManager = function(app){
	this.app = app;
	this.timer = null;
	this.pendingTimers = new Map();
	this.timers = new Map();
};

var proto = TimerManager.prototype;

proto.init = function() {
	var self = this;
	this.timer = setInterval(function(){
		for(let id of self.pendingTimers.keys()) {
			var timerInfo = self.pendingTimers.get(id);
			self.pendingTimers.delete(id);
			var timer;
			if(timerInfo.loop) {
				timer = setInterval(self._wrapTimer(id, timerInfo.cb), timerInfo.time * 1000);
				self.timers.set(id, timer);
			} else {
				timer = setTimeout(self._wrapTimer(id, timerInfo.cb, true), timerInfo.time * 1000);
				self.timers.set(id, timer);
			}
		}
	}, 1);
};

proto._wrapTimer = function(id, cb, autoRemove) {
	var app = this.app;
	var self = this;
	return function(){
		P.coroutine(function*(){
			logger.debug('timer called: %s', id);
			yield self.app.memdb.goose.transaction(cb, self.app.getServerId());
		})()
		.catch(function(e){
			logger.error('error raised in timer[%s]: ', id, e);
		})
		.finally(function(){
			if(!autoRemove) {
				return;
			}
			self.timers.delete(id);
		});
	};
};

proto.delay = function(id, time, cb) {
	if(this.timers.has(id)) {
		logger.warn('id already exists in timers map, will replace: id=%s', id);
	}
	this.pendingTimers.set(id, {cb: cb, time: time, loop: false});
};

proto.loop = function(id, time, cb) {
	if(this.timers.has(id) || this.pendingTimers.has(id)) {
		logger.warn('id already exists in timers map, will replace: id=%s', id);
	}
	this.pendingTimers.set(id, {cb: cb, time: time, loop: true});
};

proto.cancel = function(id) {
	var timer = this.timers.get(id);
	if(timer) {
		clearTimeout(timer);
		clearInterval(timer);
		this.timers.delete(id);
		return true;
	}
	timer = this.pendingTimers.get(id);
	if(timer) {
		this.pendingTimers.delete(id);
		return true;
	}
	return false;
};

proto.cancelAll = function() {
	var self = this;
	for(let key of this.timers.keys()) {
		this.cancel(key);
	}
};

var timerManager;

exp.getTimerManager = function(app) {
	if(!timerManager) {
		timerManager = new TimerManager(app);
	}
	return timerManager;
};

