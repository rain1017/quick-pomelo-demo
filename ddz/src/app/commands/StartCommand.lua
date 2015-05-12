local consts = require('app.consts')


local StartCommand = class('StartCommand', pm.SimpleCommand)

function StartCommand:ctor()
    StartCommand.super.ctor(self)
    self.executed = false
end

function StartCommand:execute(note)

    math.randomseed(os.time())

    cc.FileUtils:getInstance():setPopupNotify(false)
    cc.FileUtils:getInstance():addSearchPath("res/")
    cc.FileUtils:getInstance():addSearchPath("res/textures")

    ddz.ui.viewloader:loadCommonView('ui/Common_Render.json')

    self:initLocale()

    local facade = ddz.facade

    facade:retrieveMediator('LoadingSceneMediator'):show()

    local State = cc.utils.State
    State.init(function(opts)
        printInfo('state event: name=%s, opts=%s', opts.name, json.encode(opts))
        if opts.name == 'load' and not opts.errorCode then
            printInfo('state loaded: values=%s', opts.name, json.encode(opts.values))
            return opts.values
        elseif opts.name == 'load' then
            if opts.errorCode ~= State.ERROR_STATE_FILE_NOT_FOUND then
                display.getRunningScene():showErrorStatus('Load data error: ' .. opts.errorCode)
            end
            return {}
        elseif opts.name == 'save' then
            return opts.values
        end
    end, 'ddzstate', 'ddzstate')
    ddz.state = State.load()

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
