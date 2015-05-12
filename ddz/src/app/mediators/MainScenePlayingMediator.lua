local consts = require('app.consts')
local MainScene = require('app.scenes.MainScene')
local cardFormula = require('app.formula.cardFormula')

local MainScenePlayingMediator = class('MainScenePlayingMediator', pm.Mediator)

MainScenePlayingMediator.NAME = 'MainScenePlayingMediator'

function MainScenePlayingMediator:ctor(...)
    MainScenePlayingMediator.super.ctor(self, ...)
end

function MainScenePlayingMediator:addListeners(scene)
    scene:addButtonListener('maingame_no_out_btn', handler(self, self.onNoOutBtnClicked))
    scene:addButtonListener('maingame_hint_btn', handler(self, self.onHintBtnClicked))
    scene:addButtonListener('maingame_out_card_btn', handler(self, self.onOutBtnClicked))
end

function MainScenePlayingMediator:_onPlay(cards)
    ddz.facade:retrieveProxy('AreaProxy'):play(cards)
    local scene = self:_checkScene()
    scene.rendered.maingame_no_out_btn:hide()
    scene.rendered.maingame_hint_btn:hide()
    scene.rendered.maingame_out_card_btn:hide()

end

function MainScenePlayingMediator:onNoOutBtnClicked()
    self:_onPlay({})
end

function MainScenePlayingMediator:onHintBtnClicked()
    -- TODO:
end

function MainScenePlayingMediator:onOutBtnClicked()
    local scene = self:_checkScene()
    local cards = scene.rendered.cards_panel:getChoosedCards()
    local lastPlayed = ddz.models.area:lastPlayed()
    printInfo('cardsStack: %s, lastPlayed: %s', json.encode(ddz.models.area.cardsStack), json.encode(lastPlayed))
    if #cards == 0 then
        if lastPlayed == nil then return end
        self:_onPlay(cards)
    end
    if lastPlayed == nil and cardFormula.isCardsValid(cards) then
        self:_onPlay(cards)
    elseif lastPlayed ~= nil and #cards ~= 0 and cardFormula.isCardsGreater(cards, lastPlayed.cards) then
        self:_onPlay(cards)
    else
        printInfo('cards invalid or smaller: cards=%s, lastPlayed=%s', json.encode(cards), json.encode(lastPlayed))
        -- TODO: show status invalid/smaller
    end
end

function MainScenePlayingMediator:listNotificationInterests()
    return {
        consts.msgs.ON_LORD_CHOOSED, consts.msgs.RECONNECT_AT_PLAYING,
        consts.msgs.ON_PLAY, consts.msgs.ON_GAME_OVER
    }
end

function MainScenePlayingMediator:handleNotification(notification)
    local nm = notification:getName()
    local body = notification:getBody()
    local me = ddz.models.me
    local area = ddz.models.area
    local scene = self:_checkScene()

    if nm == consts.msgs.ON_LORD_CHOOSED then
    elseif nm == consts.msgs.ON_PLAY then
        local playerId, cards, winnerId = body.playerId, body.cards, body.winnerId
        if winnerId == nil then winnerId = -1 end
        scene.rendered.maingame_no_out_btn:hide()
        scene.rendered.maingame_hint_btn:hide()
        scene.rendered.maingame_out_card_btn:hide()
        if playerId == me.id then
            scene.rendered.cards_panel:removeCards(cards)
        else
            local areaPlayer = ddz.models.areaPlayers[playerId]
            scene:showPlayerCards(me:isLeft(area.playerIds, playerId), areaPlayer.cardsCount)
        end
        local playingPlayerId = area:playingPlayerId()
        if #cards == 0 then
            scene:showPlayStatus(me:isLeft(area.playerIds, playerId), 'No_Out')
        else
            scene:removePlayStatus()
        end
        printInfo('playingPlayerId=%s, winnerId=%s, me.id=%s', playingPlayerId, winnerId, me.id)
        if playingPlayerId == me.id then
            if winnerId ~= me.id then
                scene.rendered.maingame_no_out_btn:show()
            else
                scene.rendered.maingame_no_out_btn:hide()
            end
            scene.rendered.maingame_hint_btn:show()
            scene.rendered.maingame_out_card_btn:show()
        end
        scene:showOutCards(me:isLeft(area.playerIds, playerId), cards)
        if winnerId and winnerId ~= -1 then
            scene:showOutCards()
            scene:showOutCards(true)
            scene:showOutCards(false)
        end
        if #area.cardsStack == 1 then
            scene:removePlayStatus()
            scene:removePlayStatus(true)
            scene:removePlayStatus(false)
        end
        scene:showClock(me:isLeft(area.playerIds, playingPlayerId))
        if playingPlayerId == me.id then
            scene:showOutCards()
        end
    elseif nm == consts.msgs.ON_GAME_OVER then
        local winnerId = body.winner
        scene:resetSceneWaitToStart()
        scene:showStatus('Winner: ' .. winnerId)
        scene.rendered.maingame_start_btn:show()
        scene.rendered.maingame_ming_pai_btn:show()
        -- TODO: show win ui
    elseif nm == consts.msgs.RECONNECT_AT_PLAYING then
        scene.rendered.maingame_start_btn:hide()
        scene.rendered.maingame_ming_pai_btn:hide()
        scene:hideToolBar()
        scene:removeLoading()
        scene:hideStatus()
        -- show cards
        local areaPlayer = ddz.models.areaPlayers[me.id]
        scene:showMyCards(areaPlayer.cards)
        for k,v in pairs(area.playerIds) do
            local left = me:isLeft(area.playerIds, v)
            if left == true then
                local leftPlayer = ddz.models.areaPlayers[v]
                scene:showPlayerCards(true, leftPlayer.cardsCount)
            elseif left == false then
                local rightPlayer = ddz.models.areaPlayers[v]
                scene:showPlayerCards(false, rightPlayer.cardsCount)
            end
        end
        -- show buttons
        local playingPlayerId = area:playingPlayerId()
        if playingPlayerId == me.id then
            if area.lastWinnerId ~= me.id then
                scene.rendered.maingame_no_out_btn:show()
            else
                scene.rendered.maingame_no_out_btn:hide()
            end
            scene.rendered.maingame_hint_btn:show()
            scene.rendered.maingame_out_card_btn:show()
        end
        -- show cardsStack
        if area.cardsStack[#area.cardsStack] then
            local cardInfo = area:cardsPlayedOfCardsStack(#area.cardsStack)
            scene:showOutCards(me:isLeft(area.playerIds, cardInfo.playerId))
        end
        if area.cardsStack[#area.cardsStack-1] then
            local cardInfo = area:cardsPlayedOfCardsStack(#area.cardsStack-1)
            scene:showOutCards(me:isLeft(area.playerIds, cardInfo.playerId))
        end
        --show player status
        for i,v in ipairs(area.playerIds) do
            local player = ddz.models.players[v]
            printInfo('updatePlayer: playerId=%s, landlord=%s', player.id, area.landlord)
            scene:updatePlayer(me:isLeft(area.playerIds, player.id), player.sex == consts.sex.MALE, player.id == area.landlord)
        end
        -- show clock
        scene:showClock(me:isLeft(area.playerIds, playingPlayerId))
    end
end

function MainScenePlayingMediator:_checkScene()
    return self.viewComponent
    --[[
    local scene = display.getRunningScene()
    if scene.NAME ~= MainScene.NAME then
        printError('current scene is not MainScene!')
    end
    return scene
    --]]
end

return MainScenePlayingMediator