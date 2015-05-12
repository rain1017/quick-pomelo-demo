require("config")
require("puremvc.init")
require("cocos.init")
require("framework.init")
require('app.network.rpc')
local consts = require("app.consts")
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")


ddz = {}
ddz.ui = import('app.ui.init')
ddz.models = {me=nil, area=nil, areaPlayers=nil, players=nil}

ddz.facade = pm.Facade.getInstance('AppFacade')

local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    local facade = ddz.facade

    facade:registerCommand(consts.msgs.START, require('app.commands.StartCommand'))
    facade:registerCommand(consts.msgs.UPDATE, require('app.commands.UpdateCommand'))

    facade:registerMediator(require('app.mediators.LoadingSceneMediator').new('LoadingSceneMediator'))
    facade:registerMediator(require('app.mediators.MainScenePreparingMediator').new('MainScenePreparingMediator'))
    facade:registerMediator(require('app.mediators.MainScenePlayingMediator').new('MainScenePlayingMediator'))
    facade:registerMediator(require('app.mediators.MainSceneChoosingLordMediator').new('MainSceneChoosingLordMediator'))
    facade:registerMediator(require('app.mediators.MainSceneCommonMediator').new('MainSceneCommonMediator'))

    local areaProxy = require('app.proxies.AreaProxy').new('AreaProxy')
    facade:registerProxy(areaProxy)
    facade:registerProxy(require('app.proxies.UpdateProxy').new('UpdateProxy'))
    facade:registerProxy(require('app.proxies.AuthProxy').new('AuthProxy'))

    local rpc = RPC:ins()

    rpc:addListener(consts.routes.client.pomelo.DISCONNECT, function (msg)
        printError('pomelo disconnected');
        facade:sendNotification(consts.msgs.ON_DISCONNECT, msg)
    end)

    rpc:addListener(consts.routes.client.pomelo.TIMEOUT, function (msg)
        printError('pomelo timeout');
        facade:sendNotification(consts.msgs.ON_TIMEOUT, msg)
    end)

    rpc:addListener(consts.routes.client.pomelo.ON_KICK, function (msg)
        printError('pomelo player has been kicked out');
        facade:sendNotification(consts.msgs.ON_KICK, msg)
    end)

    rpc:addListener(consts.routes.client.area.JOIN, handler(areaProxy, areaProxy.onJoin))
    rpc:addListener(consts.routes.client.area.READY, handler(areaProxy, areaProxy.onReady))
    rpc:addListener(consts.routes.client.area.START, handler(areaProxy, areaProxy.onStart))
    rpc:addListener(consts.routes.client.area.QUIT, handler(areaProxy, areaProxy.onQuit))
    rpc:addListener(consts.routes.client.area.LORD_CHOOSED, handler(areaProxy, areaProxy.onLordChoosed))
    rpc:addListener(consts.routes.client.area.CHOOSE_LORD, handler(areaProxy, areaProxy.onChooseLord))
    rpc:addListener(consts.routes.client.area.PLAY, handler(areaProxy, areaProxy.onPlay))
    rpc:addListener(consts.routes.client.area.GAME_OVER, handler(areaProxy, areaProxy.onGameOver))


    facade:sendNotification(consts.msgs.START)


    --self:enterScene("LoadingScene")
    --self:enterScene("MainScene")
    --[[
    local rpc = RPC:ins()
    rpc:setOnConnected(function()
        print('onConnectedCallback called')
        local authInfo = {socialId='1234', socialType=consts.binding.types.DEVICE};
        rpc:request(consts.routes.server.connector.LOGIN, {authInfo=authInfo}, function(route, res)
            rpc:request(consts.routes.server.area.SEARCH_JOIN, {}, function(route, res)
                printInfo('searchAndJoin return: %s', json.encode(res))
            end)
        end)
    end)
    rpc:connectGate('127.0.0.1', 3010)
    --]]
    --[[
    scheduler.performWithDelayGlobal(handler(self, function()
        self:enterScene("MainScene", nil, "fade", 0.6, display.COLOR_WHITE)
    end), 5)
    --]]
end

ddz.app = MyApp.new()

return MyApp
