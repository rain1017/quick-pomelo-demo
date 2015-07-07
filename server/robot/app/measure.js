'use strict';
/*
 * var measure = Measure(actor);
 * measure('action1', func);
 */
var P = require('bluebird');
var uuid = require('node-uuid');
var logger = require('quick-pomelo').logger.getLogger('robot', __filename);

module.exports = function(actor){
	return function(actionId, func){
		var reqId = uuid.v4();

		actor.emit('start', actionId, reqId);
		logger.debug('start %s %s', actionId, reqId);

		P.try(function(){
			return func();
		})
		.finally(function(){
			actor.emit('end', actionId, reqId);
			logger.debug('end %s %s', actionId, reqId);
		});
	};
};
