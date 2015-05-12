
local consts = require('app.consts')

AuthProxy = require('app.proxies.AuthProxy')

TestAuthProxy = {}

    function TestAuthProxy:test_test()

        PomeloClient.getInstance():addResponseMsg(consts.routes.server.connector.LOGIN, {
            code = 0,
            data = {player={name='asdf', id=1}}
        })

        local p = AuthProxy.new()
        p:login()

        local Area = require('app.models.Area')
        local area = Area.new({id='asdf', lordCards={'3A'}})
        local AreaPlayer = require('app.models.AreaPlayer')
        local ap = AreaPlayer.new({id='asdf', name='xx', cards={'3A'}})
    end


