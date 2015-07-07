'use strict';

var path = require('path');
var P = require('bluebird');
var Robot = require(path.join(global.basedir, 'app/robot'));
var logger = require('quick-pomelo').logger.getLogger('robot', path.join(global.basedir, 'app/start.js'));

P.try(function(){
	logger.info('start actor %s', actor.id);

	var robot = new Robot({
		host : global.config.host,
		port : global.config.port,
		deviceid : actor.id,
	});
	robot.emit('run');
})
.catch(function(e){
	logger.error(e.stack);
});
