'use strict';

var domain = require('domain');
var path = require('path');
var Robot = require(path.join(global.basedir, 'app/robot'));
var logger = require('quick-pomelo').logger.getLogger('robot', path.join(global.basedir, 'app/start.js'));

global.actor = actor;
if(!global.actor){
	throw new Error('must run in pomelo robot context');
}

var d = domain.create();
d.on('error', function(e){
	logger.error(e.stack);
});

d.run(function(){
	logger.warn('start actor %s', global.actor.id);

	var start = function(){
		var robot = new Robot({
			host : global.config.host,
			port : global.config.port,
			deviceid : global.actor.id,
		});
		d.add(robot);

		robot.on('stopped', function(){
			logger.warn('restart actor %s', global.actor.id);
			start();
		});
		robot.emit('run');
	};

	start();
});
