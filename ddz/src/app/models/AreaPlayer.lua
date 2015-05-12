local ModelBase = require('app.models.ModelBase')
local consts = require('app.consts')

local AreaPlayer = class('AreaPlayer', ModelBase)

local props = {
    playerId = {type='Number'},
    name = {type='String'},
    cards = {{type='String'}},
    cardsCount = {type='Number', default=17},
    online = {type='Boolean', default=true},
    show = {type='Boolean', default=false},
    ready = {type='Boolean', default=false},
}

local statics = {}
local methods = {}

function AreaPlayer:ctor(data)
    AreaPlayer.super.ctor(self, props, statics, methods, data)
end

return AreaPlayer