'use strict';

var route = {};

route.handler = function(session, method, msg){
	//return msg.areaId;
	return 1;
};

route.remote = function(routeParam, method, args){
	//return routeParam;
	return 1;
};

module.exports = route;
