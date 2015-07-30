'use strict';

// Index definitions

module.exports =  {
    // Collection name
    area_players : {
        indexes : [
            {
                keys : ['areaId', 'playerId'],
                unique : true,
            },
        ]
    },

    bindings : {
        indexes : [
            {
                keys : ['playerId'],
            },
            {
                keys : ['socialId', 'socialType'],
                unique : true,
            },
        ]
    },

    players : {
        indexes : [
        ]
    },
};
