local consts = require('app.consts')


local UpdateCommand = class('UpdateCommand', pm.SimpleCommand)

function UpdateCommand:ctor()
    UpdateCommand.super.ctor(self)
    self.loadingParts = {
        update = 90,
        login = 10
    }
end

function UpdateCommand:execute(note)
    local facade = ddz.facade
    local loadingMediator = facade:retrieveMediator('LoadingSceneMediator')
    if note:getType() == 'update' then
        local progress = note:getBody()
        loadingMediator:setProgress("Updating Resource...", progress * 0.9)
        if progress == 100 then
            facade:retrieveProxy('AuthProxy'):login()
            loadingMediator:setStatus("Login...")
        end
    elseif note:getType() == 'login' then
        loadingMediator:setProgress("Login complete", 100)
        local mainMediator = facade:retrieveMediator('MainScenePreparingMediator')
        local playerInfo = note:getBody()
        local scene = mainMediator:onLoggedIn(playerInfo)
        local mediators = {'MainScenePreparingMediator', 'MainScenePlayingMediator', 'MainSceneChoosingLordMediator', 'MainSceneCommonMediator'}
        for k,v in pairs(mediators) do
            local md = facade:retrieveMediator(v)
            md:setViewComponent(scene)
            md:addListeners(scene)
        end
    end
end

return UpdateCommand
