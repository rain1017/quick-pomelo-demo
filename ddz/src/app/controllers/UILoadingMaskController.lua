local viewloader = import('..viewloader.viewloader')

local UILoadingMaskController = class("UILoadingMaskController")

function UILoadingMaskController:create()
    return UILoadingMaskController.new(
        viewloader:spriteById("2000002", "85"),
        viewloader:spriteById("2000002", "86"),
        {
            viewloader:spriteFrameById("2000002", "86"), viewloader:spriteFrameById("2000002", "87"),
            viewloader:spriteFrameById("2000002", "88"), viewloader:spriteFrameById("2000002", "89"),
            viewloader:spriteFrameById("2000002", "90"), viewloader:spriteFrameById("2000002", "91"),
        })
end

function UILoadingMaskController:ctor(point, bean, beanFrames)
    self.root = display.newNode()
    self.root:setContentSize(display.width, display.height)

    self:_initPoints(point)
    self:_initBeans(bean, beanFrames)
end

function UILoadingMaskController:_initPoints(point)
    self.pointNode = display.newNode()
    self.pointNode:align(display.CENTER, display.cx, display.cy)
    self.pointNode:setContentSize(display.width, display.height)
    self.pointNode:addTo(self.root)

    local r, opacityStart, opacityStep = 40, 255 * 0.2, 255 * 0.8 / 7
    local i = 1
    for i=1,8 do
        local rad = math.pi * 2 * i / 8
        local p = point:clone():opacity(math.floor(opacityStart + (i - 1) * opacityStep))
            :align(display.CENTER, display.cx + r * math.sin(rad), display.cy + r * math.cos(rad))
            :addTo(self.pointNode)
    end
end

function UILoadingMaskController:_initBeans(bean, beanFrames)
    bean:align(display.CENTER, display.cx, display.cy):addTo(self.root)
    self.bean = bean
    self.beanFrames = beanFrames
end

function UILoadingMaskController:node()
    return self.root
end

function UILoadingMaskController:start()
    local action = cc.RepeatForever:create(cc.RotateBy:create(0.4, 360/8))
    self.pointNode:runAction(action)

    local ani = display.newAnimation(self.beanFrames, 1.5 / 8)
    self.bean:playAnimationForever(ani, 0)
end

function UILoadingMaskController:stop()
    self.pointNode:stopAllActions()
    self.bean:stopAllActions()
end

return UILoadingMaskController