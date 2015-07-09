'use strict';

var path = require('path');
var logger = require('quick-pomelo').logger.getLogger('area', __filename);

var AreaSearcher = function(app, opts){
	opts = opts || {};
	this._app = app;
	this.areaIds = new Map();
};

var proto = AreaSearcher.prototype;

proto.name = 'areaSearcher';

proto.start = function(cb){
	cb();
};

proto.stop = function(force, cb){
	cb();
};

proto._ensureServer = function() {
	if(this._app.getServerType() !== 'area') {
		throw new Error('must be area server to enable AreaSearcher: current=' + this._app.getServerType());
	}
};

proto.setAreaAvail = function(areaId) {
	logger.debug('areaSearcher.setAreaAvail: areaId=%s', areaId);
	this._ensureServer();
	this.areaIds.set(areaId, true);
};

proto.deleteAvailArea = function(areaId) {
	logger.debug('areaSearcher.deleteAvailArea: areaId=%s', areaId);
	this._ensureServer();
	return this.areaIds.delete(areaId);
};

proto.getAvailAreaIds = function() {
	var areaIds = [];
	for(let id of this.areaIds.keys()){
		areaIds.push(id);
	}
	logger.debug('areaSearcher.getAvailAreaIds: areaIds=%j', areaIds);
	this._ensureServer();
	return this.areaIds.keys();
};

module.exports = function(app, opts){
	var areaSearcher = new AreaSearcher(app, opts);
	app.set(areaSearcher.name, areaSearcher, true);
	return areaSearcher;
};
