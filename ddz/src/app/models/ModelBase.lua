local ModelBase = class('ModelBase')

local checkVal
checkVal = function(name, prop, val)
    local realVal = nil

    if type(prop) ~= 'table' then
        prop = {type = prop}
    elseif not prop.type and prop[1] and prop[1].type then
        prop = {type = 'Array', ele = prop[1]}
    end

    if val then realVal = val end
    if prop.type == 'String' then
        if val ~= nil and type(val) ~= 'string' then
            val = tostring(val)
        end
        if val ~= nil then realVal = val else realVal = prop.default or '' end
    elseif prop.type == 'Number' then
        if val ~= nil and type(val) ~= 'number' then
            val = tonumber(val)
        end
        if val ~= nil then realVal = val else realVal = prop.default or 0 end
    elseif prop.type == 'Boolean' then
        if val ~= nil and type(val) ~= 'boolean' then
            val = not not val
        end
        if val ~= nil then realVal = val else realVal = prop.default or false end
    elseif prop.type == 'Array' then
        if val and type(val) ~= 'table' then
            printError('value must be table: name=%s, prop=%s, val=%s', name, json.encode(prop), json.encode(val))
        end
        if val then
            realVal ={}
            for k,v in pairs(val) do
                realVal[k] = checkVal(name .. '[]', prop.ele, v)
            end
        else
            realVal = prop.default or {}
        end
    elseif prop.type == 'Mixed' then
        if val then realVal = val else realVal = prop.default or nil end
    else
        printError('unknown prop: name=%s, prop=%s', name, json.encode(prop))
    end
    if prop.validate and type(prop.validate) == 'function' then
        if not prop.validate(realVal) then
            printError('validate property failed: name=%s, val=%s', name, realVal)
        end
    end
    if prop.random then
        realVal = prop.random[math.random(1, #prop.random)]
        printInfo('choosed random val: name=%s, val=%s', name, realVal)
    end
    return realVal
end

function ModelBase:ctor(props, statics, methods, data)
    self.__props = props
    local k, v
    for k, v in pairs(statics) do
        self[k] = v
    end
    for k, v in pairs(methods) do
        self[k] = v
    end
    for k, v in pairs(self.__props) do
        self[k] = checkVal(k, v)
    end
    self:update(data)
end

function ModelBase:update(data)
    for k,v in pairs(data) do
        if type(k) == 'string' and self.__props[k] then
            if not self.__props[k].random then
                self[k] = checkVal(k, self.__props[k], v)
            end
        else
            printInfo('unknown property: k=%s, v=%s', k, json.encode(v))
        end
    end
end

return ModelBase