'use strict';

module.exports = function(app){
    var mdbgoose = app.memdb.goose;

    var teamSchema = new mdbgoose.Schema({
        _id : {type : String},
        name : {type : String},
        hostId: {type: Number, required: true},
        playerIds: [{type: Number}],
    }, {collection : 'teams'});

    teamSchema.methods.chooseHost = function(idx){
        for (var i = 0; i < this.playerIds.length; i++) {
            var j = idx + i + 1;
            j = j >= this.playerIds.length ? j - this.playerIds.length : j;
            if(this.playerIds[j] !== null) {
                return this.playerIds[j];
            }
        }
        return null;
    };

    mdbgoose.model('Team', teamSchema);
};
