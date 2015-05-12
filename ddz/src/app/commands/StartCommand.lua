local consts = require('app.consts')


local StartCommand = class('StartCommand', pm.SimpleCommand)

function StartCommand:ctor()
    StartCommand.super.ctor(self)
    self.executed = false
end

function StartCommand:execute(note)

    cc.FileUtils:getInstance():setPopupNotify(false)
    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.FileUtils:getInstance():addSearchPath("res/textures")

    ddz.ui.viewloader:loadCommonView('ui/Common_Render.json')

    self:initLocale()

    local facade = ddz.facade

    facade:retrieveMediator('LoadingSceneMediator'):show()

    facade:retrieveProxy('UpdateProxy'):update()
end

function StartCommand:initLocale()
    local localeModule = 'app.locales.en'
    ddz.locale = function(fmt, ...)
        local locale = require(localeModule)
        return string.format(locale[fmt] or fmt, ...)
    end
end

return StartCommand
