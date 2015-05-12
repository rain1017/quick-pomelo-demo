require('app.network.rpc')

local copas = require("copas.timer")
local consts = require("app.consts")

PomeloClient = {}
function PomeloClient:new()
    local instance = nil
    return function()
        if instance then return instance end
        local o = {}
        setmetatable(o, self)
        self.__index = self
        instance = o

        self.handler = nil

        self.responses = {}
        self.responses[consts.routes.server.gate.GET_CONNECTOR] = {code = 0, data = {host = '127.0.0.1', port = 3010}}

        return o
    end
end
PomeloClient.getInstance = PomeloClient:new()

function PomeloClient:connect(ip, port)
    printInfo('PomeloClient.connect: ip=%s, port=%s', ip, port)
    return 0
end

function PomeloClient:disconnect()
    printInfo('PomeloClient.disconnect')
end

function PomeloClient:unregisterScriptHandler()
end

function PomeloClient:registerScriptHandler(handler)
    self.handler = handler
end

function PomeloClient:request(route, params)
    copas.delayedexecutioner(0, handler(self, function()
        if self.responses[route] then
            self.handler(route, json.encode(self.responses[route]))
        else
            printError("no response to request: route=%s, params=%s", route, params)
        end
    end))
end

function PomeloClient:addResponseMsg(route, response)
    self.responses[route] = response
end
