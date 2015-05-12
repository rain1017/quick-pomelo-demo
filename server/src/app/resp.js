'use strict';

var consts = require('./consts');
var _ = require('lodash');

var exp = module.exports;

exp.errorResp = function(code, data) {
	return {code: code, data: data};
};

exp.successResp = function(data) {
	return {code: consts.resp.codes.SUCCESS, data: data};
};
