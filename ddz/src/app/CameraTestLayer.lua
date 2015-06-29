local CameraTestLayer = class("CameraTestLayer", function()
        return display.newLayer()
    end)

function CameraTestLayer:ctor()

    local spr = display.newSprite("num.png")
    spr:setPosition(cc.p(100, 100))
    local move = cc.MoveTo:create(100, cc.p(10000, 100))
    spr:runAction(move)
    self:addChild(spr)
    self.spr = spr

    local camera = cc.Camera:createOrthographic(display.width, display.height, 0, 1)
    camera:setCameraFlag(2)
    self:addChild(camera)
    -- camera:setPosition3D({x = 0, y = 0, z = 0})
    self.camera = camera 
    self:setCameraMask(2)

    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, handler(self, self.update))
    self:scheduleUpdate()
end

function CameraTestLayer:update()
    -- local scene = cc.Director:getInstance():getRunningScene()
    -- local camera = scene:getDefaultCamera()
    -- camera:setPositionX(self.spr:getPositionX())
    self.camera:setPositionX(self.spr:getPositionX())
    -- print("self.cameraX = ", self.camera:getPositionX())
end

return CameraTestLayer