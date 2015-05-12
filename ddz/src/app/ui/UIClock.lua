local viewloader = import('..viewloader.viewloader')
local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local consts = import('..consts')


local UIClock = class("UIClock", function()
    return display.newNode()
end)

function UIClock:ctor(time, size, callback)
    self.time_ = time
    self.callback_ = callback
    viewloader:spriteByDesc('HLDDZ_MainGame0', 'Module_Clock', 'ui/MainGame.json')
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(self)
    self.timeLabel = display.newTTFLabel(
        {align=cc.TEXT_ALIGNMENT_CENTER, dimensions=cc.size(22, 16), font='STFONT', color=display.COLOR_RED, text=tostring(time), size=16})
        :align(display.CENTER, size.width/2-1, size.height/2-3)
        :addTo(self)
    self:size(size.width, size.height)
    self.scheduled = scheduler.scheduleGlobal(handler(self, self.updateTime), 1)
end

function UIClock:updateTime()
    self.time_ = self.time_ - 1
    if self.time_ == 0 then
        scheduler.unscheduleGlobal(self.scheduled)
        self.callback_()
    else
        self.timeLabel:setString(tostring(self.time_))
    end
end

function UIClock:stop()
    scheduler.unscheduleGlobal(self.scheduled)
end

return UIClock