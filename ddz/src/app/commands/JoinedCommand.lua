local consts = require('app.consts')


local JoinedCommand = class('JoinedCommand', pm.SimpleCommand)

function JoinedCommand:ctor()
    JoinedCommand.super.ctor(self)
end

function JoinedCommand:execute(note)
    local facade = ddz.facade
    local mainMediator = facade:retrieveMediator('MainSceneMediator')
    if note:getName() == consts.msgs.JOINED then
    end
end

return JoinedCommand
