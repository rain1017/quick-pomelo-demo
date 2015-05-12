local consts = require('app.consts')

RPC = {}

function RPC:new()
    local instance = nil

    return function()
        if instance then return instance end
        local o = {}
        setmetatable(o, self)
        self.__index = self
        instance = o

        self.pomeloCallback = nil
        self.currentRoute = nil
        self.listeners = {}

        self.onConnectedCallback = nil
        return o
    end 
end

RPC.ins = RPC:new()


function RPC:setOnConnected(cb)
    self.onConnectedCallback = cb
end

function RPC:register(url, username, passwd, cb)
    Http:ins():request(url, {username = username, passwd = passwd}, cb)
end

function RPC:login(url, username, passwd, cb)
    Http:ins():request(url, {username = username, passwd = passwd}, cb)
end

function RPC:connectGate(ip, port, username)
    local pc = PomeloClient:getInstance()
    if pc:connect(ip, port) == 0 then
        printInfo("Connect gate succceed: ip=%s, port=%s", ip, port)
        pc:registerScriptHandler(handler(self, self.onGateResponse))
        RPC:ins():request("gate.gateHandler.getConnector", {})
        return true
    else
        printError("Connect gate server failed: ip=%s, port=%s", ip, port)
        if self.onConnectedCallback then
            self.onConnectedCallback(false)
        end
    end
end

-- after connect gate, we should close gate client.
function RPC:onGateResponse(route, msg)
    printInfo("Server data: route = %s, msg = %s", route, msg)

    -- destory the gate handler
    local pc = PomeloClient:getInstance()
    pc:unregisterScriptHandler()
    pc:disconnect()

    -- connect the connector
    local result = json.decode(msg)
    if result.code == 0 then
        local ip = result.data.host
        local port = result.data.port
        if pc:connect(ip, port) == 0 then
            printInfo("Connect connector succeed: ip=%s, port=%s", ip, port)
            for k,v in pairs(self.listeners) do
                pc:addListener(k)
            end
            pc:registerScriptHandler(handler(self,self.onServerData))
            if self.onConnectedCallback then
                self.onConnectedCallback(true)
            end
            return
            -- register callback functon for connector's request
        else
            printError("Connect connectorfailed: ip=%s, port=%s", ip, port)
        end
    else
        printError("Connect gate failed, error_code: %s", result.code)
    end

    if self.onConnectedCallback then
        self.onConnectedCallback(false)
    end
end

function RPC:onServerData(route, msg)
    printInfo('Server data: route=%s, msg=%s', route, msg)
    local res = json.decode(msg)
    if table.keyof(consts.routes.client.area, route) ~= nil then
        res = {code = 0, data = res.msg}
    end
    if table.keyof(consts.routes.client.pomelo, route) ~= nil then
        res = {code = 0, data = res}
    end
    if res.code ~= 0 then
        printError('Server data: route=%s, msg=%s', route, msg)
    end
    local callback
    if route == self.currentRoute and self.pomeloCallback then
        callback = self.pomeloCallback
    elseif route ~= self.currentRoute then
        callback = self.listeners[route]
    end
    if callback then
        callback(res)
    end
end

function RPC:addListener(route, callback)
    self.listeners[route] = callback
end

function RPC:request(route, params, callback)
    local requestData = json.encode(params)
    self.currentRoute = route
    printInfo("Request: route=%s, data=%s", route, requestData)
    self.pomeloCallback = callback
    PomeloClient:getInstance():request(route, requestData)
end

function RPC:notify(route, params)
    local notifydata = json.encode(params)
    printInfo("Notify: route=%s, data=%s", route, notifydata)
    PomeloClient:getInstance():notify(route, notifydata)
end

return RPC