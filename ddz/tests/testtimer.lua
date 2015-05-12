local copas = require("copas.timer")

-- define timer callbacks
local arm_cb = nil
local expire_cb = function()
    print("executing the timer")
    copas.exitloop()
end
local cancel_cb = nil
-- define timer parameters
local recurring = false
local interval = 1  --> in seconds

local t = copas.newtimer(arm_cb, expire_cb, cancel_cb, recurring):arm(interval)

copas.loop()    --> start the scheduler and execute the timers
