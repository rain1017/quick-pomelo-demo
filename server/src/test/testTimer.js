var P = require('bluebird');
var domain = require('domain');


var timers = new Map();

var wrap = function(id, f) {
	return function() {
		var d = domain.create();
		d.id = Math.random();
		console.log('[%s] created domain: %s', id, d.id);
		d.run(function(){
			P.delay(1).then(f);
		})
	}
};

var inter = setInterval(function(){
	for(let k of timers.keys()) {
		var cb = timers.get(k);
		setTimeout(wrap(k, cb), 3);
		timers.delete(k);
		clearInterval(inter);
	}
}, 1);

timers.set(1, function(){
	console.log('[1] domain: ' + (process.domain ? process.domain.id : null));
});


timers.set(2, function(){
	console.log('[2] domain: ' + (process.domain ? process.domain.id : null));
});


timers.set(3, function(){
	console.log('[3] domain: ' + (process.domain ? process.domain.id : null));
});
