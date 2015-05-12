
local LoadingScene = class("LoadingScene", function()
    return display.newScene("LoadingScene")
end)

LoadingScene.NAME = 'LoadingScene'

function LoadingScene:ctor()
    local viewloader = ddz.ui.viewloader
    local UILoadingBarController, UILoadingMaskController = ddz.ui.UILoadingBarController, ddz.ui.UILoadingMaskController

    local bg = viewloader.sprite('Common_BG1', {0, 0, 480, 320})
    bg:align(display.CENTER, display.cx, display.cy)
    bg:addTo(self)

    local node, rendered = viewloader:renderView('ui/Loading.json')
    node:addTo(self)
    self.rendered = rendered

    dump(rendered)

    self.controllers = {}
    self.controllers.panel_loading_bar = UILoadingBarController.new(rendered.panel_loading_bar)

    self.controllers.maskController = UILoadingMaskController:create()
    self.controllers.maskController:node()
        :align(display.CENTER, display.cx, display.cy + 30)
        :addTo(self)
    printInfo('cc.TEXT_ALIGNMENT_CENTER: %s', cc.TEXT_ALIGNMENT_CENTER)
    self.rendered.error_status = display.newTTFLabel({color = cc.c3b(230,26,26),dimensions = cc.size(480, 20),
        font = "fonts/STFONT.ttf",size=18,align=cc.TEXT_ALIGNMENT_CENTER})
            :align(display.CENTER, display.cx, display.cy)
            :addTo(self)
            :zorder(100)
            :hide()
end

function LoadingScene:setProgress(status, progress)
    self.rendered.hlddz_loading_text:setString(ddz.locale(status))
    self.controllers.panel_loading_bar:setPercent(progress)
end

function LoadingScene:setStatus(status)
    self.rendered.hlddz_loading_text:setString(ddz.locale(status))
end

function LoadingScene:showErrorStatus(status)
    printInfo('showErrorStatus: %s', status)
    self.rendered.error_status:setString(status)
    self.rendered.error_status:show()
end

function LoadingScene:update( ... )
    LoadingScene.super.update(self, ...)
end

function LoadingScene:onEnter()
    self.controllers.panel_loading_bar:setPercent(0)
    self.controllers.maskController:start()
end

function LoadingScene:onExit()
    self.controllers.panel_loading_bar:setPercent(0)
    self.controllers.maskController:stop()
end

return LoadingScene
