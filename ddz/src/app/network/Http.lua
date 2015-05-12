Http = {}

local WAITING = 0
local REQUSTING = 1


function Http:new() --私有方法,不要调用这个.请自觉...
    local ins = nil

    return function(self)
        if ins then return ins end

        local o = {}
        setmetatable(o, self)
        self.__index = self
        ins = o

        self.status = WAITING 
        return o
    end
end

Http.ins = Http:new() -- 用closure返回getInstance

function Http:request(url, param, callback)
    
    if not (url and type(url) == 'string') then
        print "***Http: 非法的url地址?!"
        return 
    end

    if self.status == REQUSTING then
        print "***Http: 请求服务器中.一次一个请求和response是比较科学的做法."
        return
    end
    print("***Http: 开始请求服务器")
    print("***Http: url ", url)
    print("***Http: param")
--    print_r(param)
    
    local request
    local responseFunc = function()
        print("***Http: call responseFunc .........")
        print("***Http: request:getState() = ", request:getState())
        if request:getState() == 3 and request:getResponseStatusCode() == 200 then
            print("***Http: response is\n" .. request:getResponseString())
            local reponseData = json.decode(request:getResponseString())
            if reponseData then
                if callback and type(callback) == 'function' then 
                    callback(reponseData)
                end
            end
        else 
        end
    end

    request = network.createHTTPRequest(responseFunc, url, "POST")
    -- request:addRequestHeader("Content-Type: application/json;charset=UTF-8")
    local data = json.encode(param)
    request:addRequestHeader("Content-Type: application/json")
    print("***Http: the request data is ", data)
    print("***Http: length is ",string.len(data))
    request:setPOSTData(data)

    -- for k,v in pairs(param) do
    --     print("k,v",k,v)
    --     request:addPOSTValue(k,v)
    -- end
  
    request:start()
end

return Http