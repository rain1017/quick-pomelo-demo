local ModelBase = require('app.models.ModelBase')
local consts = require('app.consts')

local Area = class('Area', ModelBase)

local props = {
    id = {type='String'},
    name = {type='String'},

    state = {type='String', default=consts.gameState.waitToStart},

    hostId = {type='Number', required=true},
    playerIds = {{type='Number', default=-1}},
    createTime = {type='Number'},

    lastPlayTime = {type='Number'},
    lastTurn = {type='Number', default=-1, validate=function(val)
        return table.keyof({-1, 0, 1, 2}, val) ~= nil
    end},

    landlord = {type='Number', default=-1},
    landlordChooseTimes = {type='Number', default=0},
    firstChoosedLord = {type='Boolean', default=false},
    firstChoosePlayerId = {type='Number'},
    lastWinnerId = {type='Number', default=-1},
    lordCards = {{type='String'}},
    odds = {type='Number', default=1},

    cardsStack = {{type='String'}},
}

local statics = {}
local methods = {}

methods.isWaitToStartState = function(self)
    return self.state == consts.gameState.waitToStart
end

methods.isChoosingLordState = function(self)
    return self.state == consts.gameState.choosingLord
end

methods.isPlayingState = function(self)
    return self.state == consts.gameState.playing
end

methods.isOngoingState = function(self)
    return self:isPlayingState() or self:isChoosingLordState()
end

methods.previousPlayerId = function(self, playerId)
    local idx
    for k,v in pairs(self.playerIds) do
        if v == playerId then idx = v end
    end
    if idx == 1 then return self.playerIds[3]
    elseif idx == 2 then return self.playerIds[1]
    elseif idx == 3 then return self.playerIds[2]
    else printError('unknown player idx: playerIds=%s, playerId=%s', json.encode(self.playerIds), playerId) end
end

methods.playerCount = function(self)
    local count = 0
    for i,v in ipairs(self.playerIds) do
        if v and v ~= -1 then count = count + 1 end
    end
    return count
end

methods.playingPlayerId = function(self)
    printInfo('playerIds=%s, me.id=%s, turn=%s', json.encode(self.playerIds), ddz.models.me.id, self.lastTurn)
    return self.playerIds[self.lastTurn + 1]
end

methods.isChoosingLordDone = function(self)
    return (self.firstChoosedLord and self.landlordChooseTimes >= 4) or
        (self.firstChoosedLord and self.landlord == self.firstChoosePlayerId and self.landlordChooseTimes >= 3) or
        (not self.firstChoosedLord and self.landlordChooseTimes >= 3);
end

methods.cardsPlayedOfCardsStack = function(self, i)
    local idx = string.find(self.cardsStack[i], '-')
    local cards = json.decode(string.sub(self.cardsStack[i], idx+1))
    return {cards=cards, playerId=tonumber(string.sub(self.cardsStack[i], 1, idx-1))}
end

methods.lastPlayed = function(self)
    if #self.cardsStack == 0 then
        return nil
    end
    for i=1,#self.cardsStack do
        local cardsPlayed = self:cardsPlayedOfCardsStack(#self.cardsStack+1-i)
        if #cardsPlayed.cards ~= 0 then
            return cardsPlayed
        end
    end
end

function Area:ctor(data)
    Area.super.ctor(self, props, statics, methods, data)
end

return Area