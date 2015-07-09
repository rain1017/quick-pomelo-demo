'use strict';

var P = require('bluebird');
P.longStackTraces();
var should = require('should');
var path = require('path');
var quick = require('quick-pomelo');
var RedisIDGenerator = require('redis-id-generator');
var redis = require('redis');
var child_process = require('child_process');
var logger = quick.logger.getLogger('test', __filename);

var memdbClusterPath = '/usr/local/bin/memdbcluster';

var execMemdbClusterSync = function(cmd){
    var configPath = path.join(__dirname, '.memdb.js');
    var output = child_process.execFileSync(process.execPath, [memdbClusterPath, cmd, '--conf=' + configPath]);
    logger.info(output.toString());
};

exports.initMemdbSync = function(){
    execMemdbClusterSync('drop');
    execMemdbClusterSync('start');
};

exports.closeMemdbSync = function(){
    execMemdbClusterSync('stop');
};


var memdbClientConfig = {
    shards : {
        'player-server-1' : {
            host : '127.0.0.1',
            port : 32017,
        },
        'area-server-1' : {
            host : '127.0.0.1',
            port : 32017,
        },
        'team-server-1' : {
            host : '127.0.0.1',
            port : 32017,
        },
    },
};

exports.redisIdGeneratorConfig = {
	redis : {host : '127.0.0.1', port : 6379, db : 2},
};

exports.createApp = function(serverId, serverType){
    var app = quick.mocks.app({serverId : serverId, serverType : serverType});

    app.setBase(path.join(__dirname, '..'));
    app.set('memdbConfig', memdbClientConfig);

	var idgen = new RedisIDGenerator(exports.redisIdGeneratorConfig.redis);
	idgen.initKey('player__id', 0, 1);
	app.set('redisIdGenerator', idgen);

    app.load(quick.components.memdb);
    app.load(quick.components.controllers);
    app.load(quick.components.timer);
	app.load(require('../app/components/areaSearcher'));

    return app;
};
