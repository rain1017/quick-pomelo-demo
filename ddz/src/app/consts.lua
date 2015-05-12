local consts = {
    card = {
        suit = {spade = 0, heart = 1, club = 2, diamond = 3, joker = 4},
        points = {'3', '4', '5', '6', '7', '8', '9', '0', 'J', 'Q', 'K', 'A', '2'},
        joker = 'X',
        jokerRed = 'Y',
        handTypes = {
            ROCKET = 0,
            BOMB = 1,
            SOLO = 2,
            PAIR = 3,
            STRAIGHT = 4,
            CONSECUTIVE_PAIRS = 5,
            TRIO = 6,
            TRIO_SOLO = 7,
            TRIO_PAIR = 8,
            AIRPLANE = 9,
            AIRPLANE_SOLO = 10,
            AIRPLANE_PAIR = 11,
            SPACE_SHUTTLE_SOLO = 12,
            SPACE_SHUTTLE_PAIR =13,
        }
    }
}

consts.binding = {
    types = {
        DEVICE = 0
    }
}

consts.sex = {
    MALE = 0,
    FEMALE = 1,
    UNKNOWN = 2
}

consts.gameState = {
    waitToStart = 'waitToStart',
    choosingLord = 'choosingLord',
    playing = 'playing'
}

consts.gameStateChanging = {
    waitToStart = {consts.gameState.playing, consts.gameState.choosingLord},
    choosingLord = {consts.gameState.waitToStart},
    playing = {consts.gameState.choosingLord},
}

consts.routes = {
    client = {
        area = {
            JOIN = 'area.join',
            READY = 'area.ready',
            START = 'area.start',
            QUIT = 'area.quit',
            LORD_CHOOSED = 'area.lordChoosed',
            CHOOSE_LORD = 'area.chooseLord',
            PLAY = 'area.play',
            GAME_OVER = 'area.gameOver',
        },
        pomelo = {
            DISCONNECT = 'disconnect',
            TIMEOUT = 'timeout',
            ON_KICK = 'onKick',
        }
    },
    server = {
        gate = {
            GET_CONNECTOR = 'gate.gateHandler.getConnector',
        },
        connector = {
            LOGIN = 'connector.entryHandler.login',
            LOGOUT = 'connector.entryHandler.logout',
        },
        player = {
            UPDATE = 'player.playerHandler.update',
        },
        area = {
            CONNECT = 'area.areaHandler.connect',
            SEARCH_JOIN = 'area.areaHandler.searchAndJoin',
            JOIN = 'area.areaHandler.join',
            READY = 'area.areaHandler.ready',
            QUIT = 'area.areaHandler.quit',
            CHOOSE_LORD = 'area.areaHandler.chooseLord',
            PLAY = 'area.areaHandler.play',
        }
    }
}


consts.msgs = {
    -- commands
    START = 'start',
    UPDATE = 'update',
    LOGGEDIN = 'loggedin',

    -- MainSceneCommonMediator
    ON_QUIT = 'onQuit',
    ON_DISCONNECT = 'onDisconnect',
    ON_TIMEOUT = 'onTimeout',
    ON_KICK = 'onKick',

    -- MainScenePreparingMediator
    JOIN_GAME = 'joinGame',

    JOINED_GAME = 'joinedGame',
    ON_JOIN = 'onJoin',
    ON_READY = 'onReady',
    ON_START = 'onStart',
    RECONNECT_AT_WAITING = 'reconnectAtWaiting',

    -- MainSceneChoosingLordMediator
    ON_CHOOSE_LORD_START = 'onChooseLordStart',
    ON_CHOOSE_LORD = 'onChooseLord',
    ON_LORD_CHOOSED = 'onLordChoosed',
    RECONNECT_AT_CHOOSINGLORD = 'reconnectAtChoosingLord',

    -- MainScenePlayingMediator
    ON_PLAY = 'onPlay',
    ON_GAME_OVER = 'onGameOver',
    RECONNECT_AT_PLAYING = 'reconnectAtPlaying',
}

return consts