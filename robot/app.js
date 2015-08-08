'use strict';

var path = require('path');
var P = require('bluebird');
var EventEmitter = require('events').EventEmitter;
var quick = require('quick-pomelo');
var logger = quick.logger.getLogger('robot', __filename);
var Getopt = require('node-getopt');
var envConfig = require('./app/config/env.json');

//P.longStackTraces();
quick.logger.setGlobalLogLevel(quick.logger.levels.WARN);

var getopt = new Getopt([
  ['e', 'env=ARG', 'Environment: dev | prod'],
  ['m', 'mode=ARG', 'Mode: master | client'],
  ['h', 'help', 'Display this help'],
]).bindHelp();

var opt = getopt.parseSystem();

var mode = opt.options.mode || opt.argv[0];
var env = opt.options.env || envConfig.env;
envConfig.env = env;

if (mode !== 'master' && mode !== 'client'){
    getopt.showHelp();
    process.exit(1);
}

var config = require('./app/config/' + env + '/config');
var Robot = require('pomelo-robot').Robot;
var robot = new Robot(config);

if (mode === 'master') {
    robot.runMaster(__filename);
}
else if (mode === 'client') {
    global.config = config.robot;
    global.basedir = __dirname;
    var scriptPath = path.join(__dirname, envConfig.script);
    robot.runAgent(scriptPath);
}

process.on('uncaughtException', function(err) {
    logger.error(err.stack);
});
