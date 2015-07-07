'use strict';

var util = require('util');


var exp = module.exports;

exp.sex = {
	MALE : 0,
	FEMALE : 1,
	UNKNOWN : 2
};

exp.binding = {
	types: {
		DEVICE: 0
	}
};

exp.card = {
	suit : {spade : 0, heart : 1, club : 2, diamond : 3, joker : 4},
	pack : [],
	points : ['3', '4', '5', '6', '7', '8', '9', '0', 'J', 'Q', 'K', 'A', '2'],
	joker: 'X',
	jokerRed: 'Y',
	handTypes: {
		ROCKET: 0,
		BOMB: 1,
		SOLO: 2,
		PAIR: 3,
		STRAIGHT: 4,
		CONSECUTIVE_PAIRS: 5,
		TRIO: 6,
		TRIO_SOLO: 7,
		TRIO_PAIR: 8,
		AIRPLANE: 9,
		AIRPLANE_SOLO: 10,
		AIRPLANE_PAIR: 11,
		SPACE_SHUTTLE_SOLO: 12,
		SPACE_SHUTTLE_PAIR:13,
	}
};


exp.card.points.forEach(function(p){
	exp.card.pack.push(util.format('%s%s', exp.card.suit.spade, p));
	exp.card.pack.push(util.format('%s%s', exp.card.suit.heart, p));
	exp.card.pack.push(util.format('%s%s', exp.card.suit.club, p));
	exp.card.pack.push(util.format('%s%s', exp.card.suit.diamond, p));
});
exp.card.pack.push(util.format('%s%s', exp.card.suit.joker, exp.card.joker));
exp.card.pack.push(util.format('%s%s', exp.card.suit.joker, exp.card.jokerRed));

exp.gameState = {
	waitToStart: 'waitToStart',
	choosingLord: 'choosingLord',
	playing: 'playing'
};

exp.gameStateChanging = {
	waitToStart: [exp.gameState.playing, exp.gameState.choosingLord],
	choosingLord: [exp.gameState.waitToStart],
	playing: [exp.gameState.choosingLord],
};

exp.routes = {
	client: {
		area: {
			JOIN: 'area.join',
			READY: 'area.ready',
			START: 'area.start',
			QUIT: 'area.quit',
			LORD_CHOOSED: 'area.lordChoosed',
			CHOOSE_LORD: 'area.chooseLord',
			PLAY: 'area.play',
			GAME_OVER: 'area.gameOver',
		},
        pomelo: {
            DISCONNECT: 'disconnect',
            TIMEOUT: 'timeout',
            ON_KICK: 'onKick',
        }
	},
	server: {
		gate: {
			GET_CONNECTOR: 'gate.gateHandler.getConnector',
		},
		connector: {
			LOGIN: 'connector.entryHandler.login',
			LOGOUT: 'connector.entryHandler.logout',
		},
		player: {
			UPDATE: 'player.playerHandler.update',
		},
		area: {
			CONNECT: 'area.areaHandler.connect',
			SEARCH_JOIN: 'area.areaHandler.searchAndJoin',
			JOIN: 'area.areaHandler.join',
			READY: 'area.areaHandler.ready',
			QUIT: 'area.areaHandler.quit',
            CHOOSE_LORD: 'area.areaHandler.chooseLord',
            PLAY: 'area.areaHandler.play',
		}
	}
};

exp.play = {
	WAIT_TIME: 5000,
	SERVER_TIME_DELAY: 2000,
};

exp.resp = {
	codes: {
		SUCCESS: 0,
		FAILURE: -1,
		INVALID_ACTION: -2,
	}
};

