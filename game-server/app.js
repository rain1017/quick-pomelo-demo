'use strict';

var P = require('bluebird');
var util = require('util');
var pomelo = require('pomelo');
var quick = require('quick-pomelo');
var RedisIDGenerator = require('redis-id-generator');
var pomeloConstants = require('pomelo/lib/util/constants');
var pomeloLogger = require('pomelo/node_modules/pomelo-logger');
var logger = pomeloLogger.getLogger('pomelo', __filename);

var app = pomelo.createApp();
app.set('name', 'quick-pomelo');

// configure for global
app.configure('all', function() {

	app.enable('systemMonitor');

	app.set('proxyConfig', {
		cacheMsg : true,
		interval : 30,
		lazyConnection : true,
		timeout : 10 * 1000,
		failMode : 'failfast',
	});

	app.set('remoteConfig', {
		cacheMsg : true,
		interval : 30,
		timeout : 10 * 1000,
	});

	// Load route component
	app.load(quick.components.routes);
	// Load controller component
    app.load(quick.components.controllers);

    // Configure logger
    var loggerConfig = app.getBase() + '/config/log4js.json';
    var loggerOpts = {
        serverId : app.getServerId(),
        base: app.getBase(),
    };
    quick.logger.configure(loggerConfig, loggerOpts);

	// Add beforeStop hook
	app.lifecycleCbs[pomeloConstants.LIFECYCLE.BEFORE_SHUTDOWN] = function(app, shutdown, cancelShutDownTimer){
		cancelShutDownTimer();

		if(app.getServerType() === 'master'){
			// Wait for all server stop
			var tryShutdown = function(){
				if(Object.keys(app.getServers()).length === 0){
					quick.logger.shutdown(shutdown);
				}
				else{
					setTimeout(tryShutdown, 200);
				}
			};
			tryShutdown();
			return;
		}

		quick.logger.shutdown(shutdown);
	};

	app.set('errorHandler', function(err, msg, resp, session, cb){
		resp = {
			code : 500,
			stack : err.stack,
			message : err.message,
		};
		cb(err, resp);
	});
});

// Connector settings
app.configure('all', 'gate|connector', function() {
	app.set('connectorConfig', {
		connector : pomelo.connectors.hybridconnector,
		heartbeat : 30,
	});

	app.set('sessionConfig', {
		singleSession : true,
	});
});

// Config backend servers
app.configure('all', 'player|area|team', function(){
	// Load memdb config
    app.loadConfigBaseApp('memdbConfig', 'memdb.json');
    // Load memdb component
    app.load(quick.components.memdb);
    // Load timer component
    app.load(quick.components.timer);

    // Add transaction filter
    app.filter(quick.filters.transaction(app));

	// Configure redis-id-generator
	app.loadConfigBaseApp('redisIdGeneratorConfig', 'redisIdGenerator.json');
	app.set('redisIdGenerator', new RedisIDGenerator(app.get('redisIdGeneratorConfig').redis));
});

// Config area server
app.configure('all', 'area', function(){
	// Load areaSearcher component
	app.load(require('./app/components/areaSearcher'));
});


app.configure('development', function(){
    // require('heapdump');
    // P.longStackTraces();
    // quick.Promise.longStackTraces();
    // quick.logger.setGlobalLogLevel(quick.logger.levels.DEBUG);
    // pomeloLogger.setGlobalLogLevel(pomeloLogger.levels.DEBUG);
    quick.logger.setGlobalLogLevel(quick.logger.levels.WARN);
    pomeloLogger.setGlobalLogLevel(pomeloLogger.levels.WARN);
});

app.configure('production', function(){
    quick.logger.setGlobalLogLevel(quick.logger.levels.WARN);
    pomeloLogger.setGlobalLogLevel(pomeloLogger.levels.WARN);
});

process.on('uncaughtException', function(err) {
	logger.error('Uncaught exception: %s', err.stack);
});

app.start();
