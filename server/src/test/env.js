'use strict';

var P = require('bluebird');
P.longStackTraces();
var should = require('should');
var path = require('path');
var fs = require('fs');
var quick = require('quick-pomelo');
var RedisIDGenerator = require('redis-id-generator');
var mongodb = P.promisifyAll(require('mongodb'));
var redis = require('redis');
var child_process = require('child_process');
var logger = quick.logger.getLogger('test', __filename);


var memdbd = '/usr/local/bin/memdbd';
var _servers = {}; // {shardId : server}
var memdbServerConfigPath = path.join(__dirname, './.memdb.js');
var memdbServerConfig = require(memdbServerConfigPath);

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
	redis : {host : '127.0.0.1', port : 6379, db : 1},
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
	app.load(require('../app/components/areaSearcher'));

    return app;
};

exports.startMemdbCluster = function(shardIds){
    if(!shardIds){
        shardIds = Object.keys(memdbServerConfig.shards);
    }
    if(!Array.isArray(shardIds)){
        shardIds = [shardIds];
    }

    return P.map(shardIds, function(shardId){
        if(!memdbServerConfig.shards[shardId]){
            throw new Error('shard ' + shardId + ' not configured');
        }
        if(!!_servers[shardId]){
            throw new Error('shard ' + shardId + ' already started');
        }

        var args = ['--conf=' + memdbServerConfigPath, '--shard=' + shardId];
        if(!fs.existsSync(memdbd)){
        	throw new Error('memdbd not found, please install memdb first');
        }
        var server = child_process.fork(memdbd, args);

        var deferred = P.defer();
        server.on('message', function(msg){
            if(msg === 'start'){
                deferred.resolve();
                logger.warn('shard %s started', shardId);
            }
        });

        _servers[shardId] = server;
        return deferred.promise;
    });
};

exports.stopMemdbCluster = function(){
    return P.map(Object.keys(_servers), function(shardId){
        var server = _servers[shardId];

        var deferred = P.defer();
        server.on('exit', function(code, signal){
            if(code === 0){
                deferred.resolve();
            }
            else{
                deferred.reject('shard ' + shardId + ' returned non-zero code');
            }
            delete _servers[shardId];
            logger.warn('shard %s stoped', shardId);
        });
        server.kill();
        return deferred.promise;
    });
};

exports.flushMemdb = P.coroutine(function*(){
	var db = yield P.promisify(mongodb.MongoClient.connect)(memdbServerConfig.backend.url);
	yield db.dropDatabaseAsync();
	yield db.closeAsync();
	logger.info('flushed db');
});

exports.beforeEach = function(cb){
	P.coroutine(function*(){
		yield exports.flushMemdb();
		yield exports.startMemdbCluster();
	})()
	.nodeify(cb);
};

exports.afterEach = function(cb){
	P.coroutine(function*(){
		yield exports.stopMemdbCluster();
		yield exports.flushMemdb();
	})()
	.nodeify(cb);;
};
