local consts = require('app.consts')
local Player = require('app.models.Player')
local Area = require('app.models.Area')
local AreaPlayer = require('app.models.AreaPlayer')

local AreaProxy = class('AreaProxy', pm.Proxy)

function AreaProxy:ctor(...)
    AreaProxy.super.ctor(self, ...)
end

local updateModels
updateModels = function(data)
    if data.areaPlayers then
        for i, v in pairs(data.areaPlayers) do
            if v then
                updateModels({areaPlayer = v})
            end
        end
    end
    if data.area then
        if ddz.models.area then
            ddz.models.area:update(data.area)
        else
            ddz.models.area = Area.new(data.area)
        end
    end
    if data.players then
        for i, v in pairs(data.players) do
            if v then
                updateModels({player = v})
            end
        end
    end
    if data.player then
        if ddz.models.me and data.player.id == ddz.models.me.id then
            ddz.models.me:update(data.player)
        end
        if not ddz.models.players then ddz.models.players = {} end
        if ddz.models.players[data.player.id] then
            ddz.models.players[data.player.id]:update(data.player)
        else
            ddz.models.players[data.player.id] = Player.new(data.player)
        end
    end
    if data.areaPlayer then
        if not ddz.models.areaPlayers then ddz.models.areaPlayers = {} end
        if ddz.models.areaPlayers[data.areaPlayer.playerId] then
            ddz.models.areaPlayers[data.areaPlayer.playerId]:update(data.areaPlayer)
        else
            ddz.models.areaPlayers[data.areaPlayer.playerId] = AreaPlayer.new(data.areaPlayer)
        end
    end
end

function AreaProxy:searchAndJoin()
    local rpc = RPC:ins()
    rpc:request(consts.routes.server.area.SEARCH_JOIN, {}, handler(self, function(self, msg)
        printInfo('searchAndJoin.callback called')
        updateModels(msg.data)
        if ddz.models.area:isWaitToStartState() then
            ddz.facade:sendNotification(consts.msgs.JOINED_GAME,
                {area=ddz.models.area, players=ddz.models.players, areaPlayers=ddz.models.areaPlayers})
        elseif ddz.models.area:isChoosingLordState() then
            ddz.facade:sendNotification(consts.msgs.RECONNECT_AT_CHOOSINGLORD,
                {area=ddz.models.area, players=ddz.models.players, areaPlayers=ddz.models.areaPlayers})
        end
    end))
end

function AreaProxy:connect(areaId)
    local rpc = RPC:ins()
    rpc:request(consts.routes.server.area.CONNECT, {areaId=areaId}, handler(self, function(self, msg)
        updateModels(msg.data)
        if ddz.models.area:isWaitToStartState() then
            ddz.facade:sendNotification(consts.msgs.RECONNECT_AT_WAITING,
                {area=ddz.models.area, players=ddz.models.players, areaPlayers=ddz.models.areaPlayers})
        elseif ddz.models.area:isChoosingLordState() then
            ddz.facade:sendNotification(consts.msgs.RECONNECT_AT_CHOOSINGLORD,
                {area=ddz.models.area, players=ddz.models.players, areaPlayers=ddz.models.areaPlayers})
        else
            ddz.facade:sendNotification(consts.msgs.RECONNECT_AT_PLAYING,
                {area=ddz.models.area, players=ddz.models.players, areaPlayers=ddz.models.areaPlayers})
        end
    end))
end

function AreaProxy:ready()
    local rpc = RPC:ins()
    rpc:request(consts.routes.server.area.READY, {areaId=ddz.models.area.id}, handler(self, function(self)
        printInfo('ready.callback called')
    end))
end

function AreaProxy:play(cards)
    printInfo('play cards: %s', json.encode(cards))
    local rpc = RPC:ins()
    rpc:request(consts.routes.server.area.PLAY, {areaId=ddz.models.area.id, cards=cards}, handler(self, function(self)
        printInfo('play.callback called')
    end))
end

function AreaProxy:quit(areaId)
    local rpc = RPC:ins()
    rpc:request(consts.routes.server.area.QUIT, {areaId=areaId}, handler(self, function(self, msg)
        printInfo('quit.callback called')
    end))
end

function AreaProxy:chooseLord(choosed)
    local rpc = RPC:ins()
    local msg = {areaId=ddz.models.area.id, playerId=ddz.models.me.id, choosed=choosed}
    rpc:request(consts.routes.server.area.CHOOSE_LORD, msg, handler(self, function()
        printInfo('chooseLord.callback called')
    end))
end

function AreaProxy:onJoin(msg)
    -- {area: {playerIds: area.playerIds}, areaPlayer: areaPlayer.toClientData(), player: player.toClientData()}
    updateModels(msg.data)
    local playerId = msg.data.player.id
    ddz.facade:sendNotification(consts.msgs.ON_JOIN, {player=ddz.models.players[playerId], areaPlayer=ddz.models.areaPlayers[playerId]})
end

function AreaProxy:onReady(msg)
    -- {areaPlayer: {playerId: areaPlayer.playerId, ready: true}}
    updateModels(msg.data)
    ddz.facade:sendNotification(consts.msgs.ON_READY, {ddz.models.players})
end

function AreaProxy:onStart(msg)
    -- {areaPlayer: {cards: playerCards[i], playerId: area.playerIds[i]}, area: {lastTurn: area.lastTurn}}
    local hasArea = not not ddz.models.area
    updateModels(msg.data)
    local playingAreaPlayer = ddz.models.areaPlayers[ddz.models.area:playingPlayerId()]
    if hasArea then
        ddz.facade:sendNotification(consts.msgs.ON_START, areaPlayer)
        ddz.facade:sendNotification(consts.msgs.ON_CHOOSE_LORD_START, playingAreaPlayer)
    end
end

function AreaProxy:onQuit(msg)
    -- {quitedPlayer: {id: playerId, name: player.name}, player: retPlayerData[area.playerIds[i]]}
    updateModels(msg.data)
    ddz.facade:sendNotification(consts.msgs.ON_QUIT, msg.data)
    if msg.data.quitedPlayer.id == ddz.models.me.id then
        ddz.models.area = nil
        ddz.models.areaPlayers = nil
        ddz.models.players = nil
    else
        ddz.models.areaPlayers[msg.data.quitedPlayer.id] = nil
        ddz.models.players[msg.data.quitedPlayer.id] = nil
    end
end

function AreaProxy:onLordChoosed(msg)
    -- {area: {landlord: area.landlord, lordCards: area.lordCards, odds: area.odds}, areaPlayer: {cards: landlord.cards}}
    updateModels(msg.data)
    for k,v in pairs(ddz.models.areaPlayers) do
        if k == ddz.models.area.landlord then
            v.cardsCount = 20
        else
            v.cardsCount = 17
        end
    end
    ddz.facade:sendNotification(consts.msgs.ON_LORD_CHOOSED, ddz.models.area)
end

function AreaProxy:onChooseLord(msg)
    -- {playerId: playerId, choosed: choosed, rob: true, area: {lastTurn: area.lastTurn}}
    updateModels(msg.data)
    ddz.facade:sendNotification(consts.msgs.ON_CHOOSE_LORD, msg.data)
end

function AreaProxy:onPlay(msg)
    -- {area: {lastTurn: area.lastTurn}, playerId: playerId, cards: cards};
    updateModels(msg.data)
    printInfo('playerId: %s[%s]', msg.data.playerId, type(msg.data.playerId))
    ddz.facade:sendNotification(consts.msgs.ON_PLAY, msg.data)
end

function AreaProxy:onGameOver(msg)
    -- {winner: playerId, player: retPlayerData[playerId]}
    updateModels(msg.data)
    ddz.facade:sendNotification(consts.msgs.ON_GAME_OVER, msg.data)
end


return AreaProxy
