local ModelBase = require('app.models.ModelBase')
local consts = require('app.consts')

local Player = class('Player', ModelBase)

local props = {
    id = {type='Number'},
    areaId = {type='String'},
    teamId = {type='String'},
    name = {type='String', random={"天堂在左", "我在右"}},
    sex = {type='Number', default=consts.sex.MALE, random={consts.sex.MALE, consts.sex.FEMALE}},
    money = {type='Number'}
}

local statics = {}
local methods = {}

methods.isLeft = function(self, playerIds, playerId)
    if self.id == playerId then return nil end
    for i = 1, #playerIds do
        playerIds[i] = tonumber(playerIds[i])
    end
    local thisIdx, otherIdx
    for k ,v in pairs(playerIds) do
        if v == self.id then
            thisIdx = k
        elseif v == playerId then
            otherIdx = k
        end
    end
    if thisIdx == 1 then
        return otherIdx == 3
    elseif thisIdx == 2 then
        return otherIdx == 1
    elseif thisIdx == 3 then
        return otherIdx == 2
    else
        if not thisIdx then
            printError('player index not found: playerIds=%s, playerId=%s', json.encode(playerIds), self.id)
        else
            printError('error player index: %s', thisIdx)
        end
    end
end

function Player:ctor(data)
    Player.super.ctor(self, props, statics, methods, data)
end

return Player