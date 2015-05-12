local consts = require('app.consts')

local UpdateProxy = class('UpdateProxy', pm.Proxy)

function UpdateProxy:ctor(...)
    UpdateProxy.super.ctor(self, ...)
end

function UpdateProxy:update()
    -- update lua files and other resources
    -- send notification to report download progress
    local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
    local progress = 0
    local timer
    timer = scheduler.scheduleGlobal(function()
        progress = progress + 10
        ddz.facade:sendNotification(consts.msgs.UPDATE, progress, 'update')
        if progress == 100 then
            scheduler.unscheduleGlobal(timer)
        end
    end, 0.1)
end

function UpdateProxy:timerFunc()
end

return UpdateProxy
