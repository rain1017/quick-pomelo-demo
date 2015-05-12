EXPORT_ASSERT_TO_GLOBALS = true
package.path = package.path .. ';../src/?.lua'

require('puremvc.init')
require("framework.functions")
require("framework.debug")
require("cocos.cocos2d.json")

local copas_loop_time = tonumber(arg[#arg])
if not copas_loop_time then
    copas_loop_time = 0
else
    table.remove(arg, #arg)
end


local luaunit = require('luaunit')

require('mock')

ddz = {}
ddz.models = {me=nil, area=nil, areaPlayers=nil}
ddz.facade = pm.Facade.getInstance('AppFacade')

-- add test case requirement here
--require('proxies.TestAuthProxy')
require('TestCardFormula')



luaunit.LuaUnit.run()

local copas = require("copas.timer")

copas.delayedexecutioner(copas_loop_time, function()
    copas.exitloop()
end)

copas.loop()
