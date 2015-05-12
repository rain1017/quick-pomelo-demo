local consts = require('app.consts')
local cardFormula = require('app.formula.cardFormula')
local MainScene = require('app.scenes.MainScene')

local MainSceneChoosingLordMediator = class('MainSceneChoosingLordMediator', pm.Mediator)

MainSceneChoosingLordMediator.NAME = 'MainSceneChoosingLordMediator'

function MainSceneChoosingLordMediator:ctor(...)
    MainSceneChoosingLordMediator.super.ctor(self, ...)
end

function MainSceneChoosingLordMediator:addListeners(scene)
    scene:addButtonListener('maingame_order_btn', handler(self, self.onOrderBtnClicked))
    scene:addButtonListener('maingame_no_order_btn', handler(self, self.onNoOrderBtnClicked))
    scene:addButtonListener('maingame_rob_btn', handler(self, self.onRobBtnClicked))
    scene:addButtonListener('maingame_no_rob_btn', handler(self, self.onNoRobBtnClicked))
end

function MainSceneChoosingLordMediator:_onChooseLord(choosed)
    ddz.facade:retrieveProxy('AreaProxy'):chooseLord(choosed)
    local scene = self:_checkScene()
    scene.rendered.maingame_order_btn:hide()
    scene.rendered.maingame_no_order_btn:hide()
    scene.rendered.maingame_rob_btn:hide()
    scene.rendered.maingame_no_rob_btn:hide()

end

function MainSceneChoosingLordMediator:onOrderBtnClicked()
    self:_onChooseLord(true)
end

function MainSceneChoosingLordMediator:onNoOrderBtnClicked()
    self:_onChooseLord(false)
end

function MainSceneChoosingLordMediator:onRobBtnClicked()
    self:_onChooseLord(true)
end

function MainSceneChoosingLordMediator:onNoRobBtnClicked()
    self:_onChooseLord(false)
end

function MainSceneChoosingLordMediator:listNotificationInterests()
    return {
        consts.msgs.ON_CHOOSE_LORD_START, consts.msgs.ON_LORD_CHOOSED, consts.msgs.ON_CHOOSE_LORD,
        consts.msgs.RECONNECT_AT_CHOOSINGLORD
    }
end

function MainSceneChoosingLordMediator:handleNotification(notification)
    local nm = notification:getName()
    local body = notification:getBody()
    local me = ddz.models.me
    local area = ddz.models.area
    local scene = self:_checkScene()

    if nm == consts.msgs.ON_CHOOSE_LORD_START then
        local areaPlayer = ddz.models.areaPlayers[area:playingPlayerId()]
        printInfo('areaPlayer.playerId=%s[%s], me.id=%s[%s], turn=%s', areaPlayer.playerId,
            type(areaPlayer.playerId), ddz.models.me.id, type(me.id), area.lastTurn)
        if areaPlayer.playerId == me.id then
            scene.rendered.maingame_order_btn:show()
            scene.rendered.maingame_no_order_btn:show()
        end
        scene:removeNameAndMoney(true)
        scene:removeNameAndMoney(false)

        scene:showClock(me:isLeft(area.playerIds, areaPlayer.playerId))
    elseif nm == consts.msgs.ON_CHOOSE_LORD then
        local playerId, choosed, rob = body.playerId, body.choosed, body.rob
        if playerId == me.id then
            -- hide buttons
            scene.rendered.maingame_order_btn:hide()
            scene.rendered.maingame_no_order_btn:hide()
            scene.rendered.maingame_rob_btn:hide()
            scene.rendered.maingame_no_rob_btn:hide()
        end
        -- show status and remove clock
        printInfo('playerId=%s[%s], me.id=%s[%s], turn=%s', playerId, type(playerId), me.id, type(me.id), area.lastTurn)
        local status
        if choosed and rob then status = 'Rob_Land_Lord'
        elseif choosed and not rob then status = 'Call_Land_Lord'
        elseif not choosed and rob then status = 'No_Rob'
        else status = 'No_Call' end
        scene:showPlayStatus(me:isLeft(area.playerIds, playerId), status)
        scene:removeClock()
        if area:isChoosingLordDone() then
            return
        end
        -- show buttons and clock
        local playingPlayerId = area:playingPlayerId()
        printInfo('playingPlayerId=%s[%s], me.id=%s[%s], turn=%s', playingPlayerId, type(playingPlayerId), me.id, type(me.id), area.lastTurn)
        if playingPlayerId == me.id then
            if area.landlord and area.landlord ~= -1 then
                scene.rendered.maingame_rob_btn:show()
                scene.rendered.maingame_no_rob_btn:show()
            else
                scene.rendered.maingame_order_btn:show()
                scene.rendered.maingame_no_order_btn:show()
            end
        end
        scene:showClock(me:isLeft(area.playerIds, playingPlayerId))
    elseif nm == consts.msgs.ON_LORD_CHOOSED then
        -- hide buttons
        scene.rendered.maingame_order_btn:hide()
        scene.rendered.maingame_no_order_btn:hide()
        scene.rendered.maingame_rob_btn:hide()
        scene.rendered.maingame_no_rob_btn:hide()
        -- update avatar
        for i,v in ipairs(area.playerIds) do
            local player = ddz.models.players[v]
            scene:updatePlayer(me:isLeft(area.playerIds, player.id), player.sex == consts.sex.MALE, player.id == area.landlord)
        end
        -- show cards
        scene:showLandlordCards(area.lordCards)
        local areaPlayer = ddz.models.areaPlayers[area.landlord]
        if area.landlord == me.id then
            scene.rendered.cards_panel:setCards(areaPlayer.cards)
        else
            scene:showPlayerCards(me:isLeft(area.playerIds, area.landlord), areaPlayer.cardsCount)
        end
        -- show btns and clock
        local playingPlayerId = area:playingPlayerId()
        if playingPlayerId == me.id then
            scene:showMyCards(ddz.models.areaPlayers[me.id].cards)
            scene.rendered.maingame_no_out_btn:hide()
            scene.rendered.maingame_hint_btn:show()
            scene.rendered.maingame_out_card_btn:show()
        end
        scene:showClock(me:isLeft(area.playerIds, playingPlayerId))
        scene:removePlayStatus()
        scene:removePlayStatus(true)
        scene:removePlayStatus(false)
    elseif nm == consts.msgs.RECONNECT_AT_CHOOSINGLORD then
        scene.rendered.maingame_start_btn:hide()
        scene.rendered.maingame_ming_pai_btn:hide()
        scene:hideToolBar()
        scene:removeLoading()
        scene:hideStatus()
        local areaPlayer = ddz.models.areaPlayers[me.id]
        scene:showMyCards(areaPlayer.cards)
        scene:showPlayerCards(true, 17)
        scene:showPlayerCards(false, 17)
        local playingPlayerId = area:playingPlayerId()
        if playingPlayerId == me.id then
            if area.landlord and area.landlord ~= -1 then
                scene.rendered.maingame_rob_btn:show()
                scene.rendered.maingame_no_rob_btn:show()
            else
                scene.rendered.maingame_order_btn:show()
                scene.rendered.maingame_no_order_btn:show()
            end
        end
        for k,v in pairs(area.playerIds) do
            local player = ddz.models.players[v]
            scene:addPlayer(me:isLeft(area.playerIds, v), player.sex == consts.sex.MALE)
        end
        scene:showClock(me:isLeft(area.playerIds, playingPlayerId))
        if area.landlord ~= -1 then
            scene:showPlayerStatus(me:isLeft(area.playerIds, area.landlord), 'Call_Land_Lord')
        end
    end
end

function MainSceneChoosingLordMediator:_checkScene()
    return self.viewComponent
    --[[
    local scene = display.getRunningScene()
    if scene.NAME ~= MainScene.NAME then
        printError('current scene is not MainScene!')
    end
    return scene
    --]]
end

return MainSceneChoosingLordMediator