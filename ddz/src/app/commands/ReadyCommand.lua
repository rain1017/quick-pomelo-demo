local consts = require('app.consts')


local ReadyCommand = class('ReadyCommand', pm.SimpleCommand)

function ReadyCommand:ctor()
    ReadyCommand.super.ctor(self)
    self.loadingParts = {
        update = 90,
        login = 10
    }
end

function ReadyCommand:execute(note)
    local facade = ddz.facade
    local mainMediator = facade:retrieveMediator('MainSceneMediator')
    if note:getName() == consts.msgs.JOIN_GAME then
        local areaProxy = facade:retrieveProxy('AreaProxy')
        areaProxy:searchAndJoin()
    end
end

return ReadyCommand
