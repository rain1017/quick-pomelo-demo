local consts = require('app.consts')
local cardFormula = require('app.formula.cardFormula')
local MainScene = require('app.scenes.MainScene')

local MainScenePreparingMediator = class('MainScenePreparingMediator', pm.Mediator)

MainScenePreparingMediator.NAME = 'MainScenePreparingMediator'

function MainScenePreparingMediator:ctor(...)
    MainScenePreparingMediator.super.ctor(self, ...)
    self.scene = nil
end

function MainScenePreparingMediator:onLoggedIn(player)
    printInfo('MainScenePreparingMediator.onLoggedIn')
    local scene = require('app.scenes.MainScene').new()
    scene.rendered.player_bean_count_label:setText(tostring(player.money))
    scene.rendered.maingame_start_btn:show()
    scene.rendered.maingame_ming_pai_btn:show()
    scene:showMyAvatar(player.sex == consts.sex.MALE)

    display.replaceScene(scene, "slideInR", 1, display.COLOR_WHITE)

    if player.areaId ~= '' then
        ddz.facade:retrieveProxy('AreaProxy'):connect(player.areaId)
        scene:showLoading('Joining area...')
    end
    self.scene = scene
    return scene
end

function MainScenePreparingMediator:addListeners(scene)
    scene:addButtonListener('maingame_start_btn', handler(self, self.onStartBtnClicked))
    scene:addButtonListener('maingame_ming_pai_btn', handler(self, self.onStartShowBtnClicked))
end

function MainScenePreparingMediator:_onStartBtnClicked(show)
    show = not not show
    local scene = self:_checkScene()
    scene.rendered.maingame_start_btn:hide()
    scene.rendered.maingame_ming_pai_btn:hide()
    if not ddz.models.area then
        scene:showLoading('Searching and joining area')
        ddz.facade:retrieveProxy('AreaProxy'):searchAndJoin(show)
    else
        scene:removeLoading()
        scene:showStatus('Waiting to start...')
        ddz.facade:retrieveProxy('AreaProxy'):ready()
    end
end

function MainScenePreparingMediator:onStartBtnClicked(show)
    self:_onStartBtnClicked(false)
end

function MainScenePreparingMediator:onStartShowBtnClicked()
    self:_onStartBtnClicked(true)
end


function MainScenePreparingMediator:listNotificationInterests()
    return {
        consts.msgs.JOINED_GAME, consts.msgs.ON_JOIN, consts.msgs.ON_READY,
        consts.msgs.ON_START, consts.msgs.RECONNECT_AT_WAITING
    }
end

function MainScenePreparingMediator:handleNotification(notification)
    local nm = notification:getName()
    local body = notification:getBody()
    local scene = self:_checkScene()
    local me = ddz.models.me
    local area = ddz.models.area
    if nm == consts.msgs.JOINED_GAME then
        scene:removeLoading()
        scene:hideToolBar()
        scene:showPlayersStatusWaitToStart()
    elseif nm == consts.msgs.ON_JOIN then
        local player = body.player
        scene:addPlayer(me:isLeft(area.playerIds, player.id), player.sex == consts.sex.MALE)
        if area:playerCount() == 3 then
            scene:showStatus('Waiting to start...')
        end
    elseif nm == consts.msgs.ON_READY then
        local areaPlayer = body
        scene:showStatus('Waiting to start...')
        scene:showOkGesture(me:isLeft(area.playerIds, areaPlayer.playerId))
    elseif nm == consts.msgs.ON_START then
        scene:removeOkGesture()
        scene:removeOkGesture(true)
        scene:removeOkGesture(false)
        scene:hideStatus()
        local areaPlayer = ddz.models.areaPlayers[me.id]
        dump(areaPlayer.cards)
        scene:showMyCards(areaPlayer.cards)
        scene:showPlayerCards(true, 17)
        scene:showPlayerCards(false, 17)
    elseif nm == consts.msgs.RECONNECT_AT_WAITING then
        scene.rendered.maingame_start_btn:hide()
        scene.rendered.maingame_ming_pai_btn:hide()
        scene:removeLoading()
        scene:hideToolBar()
        scene:showPlayersStatusWaitToStart()
    end
end



function MainScenePreparingMediator:_checkScene()
    return self.viewComponent
    --[[
    local scene = display.getRunningScene()
    if scene.NAME ~= MainScene.NAME then
        printError('current scene is not MainScene!')
    end
    return scene
    --]]
end

return MainScenePreparingMediator