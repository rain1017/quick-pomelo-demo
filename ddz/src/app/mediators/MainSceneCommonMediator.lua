local consts = require('app.consts')
local MainScene = require('app.scenes.MainScene')

local MainSceneCommonMediator = class('MainSceneCommonMediator', pm.Mediator)

MainSceneCommonMediator.NAME = 'MainSceneCommonMediator'

function MainSceneCommonMediator:ctor(...)
    MainSceneCommonMediator.super.ctor(self, ...)
end

function MainSceneCommonMediator:addListeners(scene)
    scene:addButtonListener('maingame_float_exit_btn', handler(self, self.onExitBtnClicked))
end

function MainSceneCommonMediator:onExitBtnClicked()
    ddz.facade:retrieveProxy('AreaProxy'):quit(ddz.models.area.id)
end


function MainSceneCommonMediator:listNotificationInterests()
    return {
        consts.msgs.ON_QUIT, consts.msgs.ON_DISCONNECT, consts.msgs.ON_TIMEOUT, consts.msgs.ON_KICK
    }
end

function MainSceneCommonMediator:handleNotification(notification)
    local nm = notification:getName()
    local body = notification:getBody()
    local me = ddz.models.me
    local area = ddz.models.area
    local scene = self:_checkScene()

    if nm == consts.msgs.ON_QUIT then
        if body.quitedPlayer.id == me.id then
            -- TODO: show punishment or something
            scene:resetSceneLoggedin()
        else
            scene:resetSceneWaitToStart()
        end
    elseif nm == consts.msgs.ON_DISCONNECT then
        display.getRunningScene():showErrorStatus('Sorry, U\'r disconnected, please restart.')
    elseif nm == consts.msgs.ON_TIMEOUT then
        display.getRunningScene():showErrorStatus('Sorry, request timeout, please restart.')
    elseif nm == consts.msgs.ON_KICK then
        display.getRunningScene():showErrorStatus('Sorry, U\'r kicked out, please restart.')
    end
end

function MainSceneCommonMediator:_checkScene()
    return self.viewComponent
    --[[
    local scene = display.getRunningScene()
    if scene.NAME ~= MainScene.NAME then
        printError('current scene is not MainScene!')
    end
    return scene
    --]]
end

return MainSceneCommonMediator