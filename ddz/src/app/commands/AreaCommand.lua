local consts = require('app.consts')


local AreaCommand = class('AreaCommand', pm.SimpleCommand)

function AreaCommand:ctor()
    AreaCommand.super.ctor(self)
end

function AreaCommand:execute(note)
    local facade = ddz.facade
    local mainMediator = facade:retrieveMediator('MainSceneMediator')
    local noteName = note:getName()
    if noteName == consts.msgs.ON_JOIN then
        local player = note:getBody().player
        local me = ddz.models.me
        mainMediator:onAddPlayer(me:isLeft(ddz.models.area, player), player.sex == consts.sex.MALE)
        mainMediator:hideStatus()
    elseif noteName == consts.msgs.ON_READY then
    elseif noteName == consts.msgs.ON_START then
    elseif noteName == consts.msgs.ON_QUIT then
    elseif noteName == consts.msgs.ON_LORD_CHOOSED then
    elseif noteName == consts.msgs.ON_CHOOSE_LORD then
    elseif noteName == consts.msgs.ON_PLAY then
    elseif noteName == consts.msgs.ON_GAME_OVER then
    end
end

return AreaCommand
