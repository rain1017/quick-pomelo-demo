local UILoadingBarController = class("UILoadingBarController", function()
    return {}
end)

function UILoadingBarController:ctor(renderedNode)
    self.renderedNode = renderedNode
    self.spriteLeft = renderedNode:getChildById('FANOBJ_Render_Loading_bar_Left')
    self.spriteCenter = renderedNode:getChildById('FANOBJ_Render_Loading_bar_center')
    self.spriteRight = self:_createSpriteRight(self.spriteLeft)
    local slSize = self.spriteLeft:getContentSize()
    local scSize = self.spriteCenter:getContentSize()
    local viewConfig = renderedNode:getViewConfig()
    local parentViewConfig = renderedNode:getParent():getViewConfig()
    local width = parentViewConfig.rect[3] - 2 * viewConfig.rect[1]
    self.centerScaleTotal = (width - slSize.width * self.spriteLeft:getScaleX() * 2) / (scSize.width * self.spriteCenter:getScaleX())
    self.centerScaleTotal = self.centerScaleTotal * self.spriteLeft:getScaleX() + 0.3
    self.width = width
    renderedNode:setContentSize(width, viewConfig.rect[4])
    self.spriteRight:addTo(self.renderedNode)
    self.spriteLeft:hide()
    self.spriteCenter:hide()
    self.spriteRight:hide()
    self:setPercent(0)
end

function UILoadingBarController:_createSpriteRight(sprite)
    local rs = sprite:clone()
    rs:setFlippedX(true)
    return rs
end

function UILoadingBarController:setPercent(percent)
    if percent > 0 and percent <= 1 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteLeft:show()
        self.spriteCenter:hide()
        self.spriteRight:hide()
    elseif percent > 1 and percent < 100 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteCenter:setScaleX(self.centerScaleTotal * (percent - 2) / 100)
        self.spriteCenter:align(display.LEFT_BOTTOM, self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteLeft:show()
        self.spriteCenter:show()
        self.spriteRight:hide()
    elseif percent >= 100 then
        self.spriteLeft:align(display.LEFT_BOTTOM, 0, 0)
        self.spriteCenter:setScaleX(self.centerScaleTotal)
        self.spriteCenter:align(display.LEFT_BOTTOM, self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteRight:align(display.LEFT_BOTTOM, self.width - self.spriteLeft:getContentSize().width * self.spriteLeft:getScaleX(), 0)
        self.spriteLeft:show()
        self.spriteCenter:show()
        self.spriteRight:show()
    end
end

return UILoadingBarController