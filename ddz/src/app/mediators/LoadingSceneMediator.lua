local consts = require('app.consts')
local LoadingScene = require('app.scenes.LoadingScene')

local LoadingSceneMediator = class('LoadingSceneMediator', pm.Mediator)

LoadingSceneMediator.NAME = 'LoadingSceneMediator'

function LoadingSceneMediator:ctor(...)
    LoadingSceneMediator.super.ctor(self, ...)
end

function LoadingSceneMediator:show()
    ddz.app:enterScene("LoadingScene")
end

function LoadingSceneMediator:listNotificationInterests()
    --return {consts.msgs.LOADING_PROGRESS, consts.msgs.LOADING_SUCCESS, consts.msgs.LOADING_FAIL}
    return {}
end

function LoadingSceneMediator:handleNotification(notification)
    --[[
    if notification.getName() == consts.msgs.LOADING_PROGRESS then
        local data = notification:getBody()
        scene:setProgress(data.status, data.progress)
    elseif notification.getName() == consts.msgs.LOADING_SUCCESS then

    elseif notification.getName() == consts.msgs.LOADING_FAIL then
        scene:setStatus('Sorry, load game failed.')
    end
    --]]
end

function LoadingSceneMediator:_checkScene()
    local scene = display.getRunningScene()
    if scene.NAME ~= LoadingScene.NAME then
        printError('current scene is not LoadingScene!')
    end
    return scene
end

function LoadingSceneMediator:setProgress(status, progress)
    self:_checkScene():setProgress(status, progress)
end

function LoadingSceneMediator:setStatus(status)
    self:_checkScene():setStatus(status)
end

return LoadingSceneMediator