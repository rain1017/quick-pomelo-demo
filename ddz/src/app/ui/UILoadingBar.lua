

local UILoadingBar = class("UILoadingBar", function()
    return display.newNode()
    --return display.newColorLayer(cc.c4b(255,0,0, 255))
end)

function UILoadingBar:ctor(spriteLeft, spriteCenter, width)
    self.spriteLeft = spriteLeft
    self.spriteCenter = spriteCenter
    self.spriteRight = self:_createSpriteRight(spriteLeft)
    local slSize = spriteLeft:getContentSize()
    local scSize = spriteCenter:getContentSize()
    self.centerScaleTotal = (width - slSize.width * spriteLeft:getScaleX() * 2) / (scSize.width * spriteCenter:getScaleX())
    self.centerScaleTotal = self.centerScaleTotal * spriteLeft:getScaleX() + 0.3
    self.width = width
    self.percent = 0
end

function UILoadingBar:_createSpriteRight(sprite)
    local rs = sprite:clone()
    rs:setFlippedX(true)
    return rs
end

function UILoadingBar:setPercent(percent)
    self:removeAllChildren()
    if percent > 0 and percent <= 1 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteLeft:addTo(self)
    elseif percent > 1 and percent < 100 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteLeft:addTo(self)
        self.spriteCenter:setScaleX(self.centerScaleTotal * (percent - 2) / 100)
        self.spriteCenter:align(display.LEFT_BOTTOM, self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteCenter:addTo(self)
    elseif percent >= 100 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteLeft:addTo(self)
        self.spriteCenter:setScaleX(self.centerScaleTotal)
        self.spriteCenter:align(display.LEFT_BOTTOM, self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteCenter:addTo(self)
        self.spriteRight:align(display.LEFT_BOTTOM, self.width - self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteRight:addTo(self)
    end
end

return UILoadingBar