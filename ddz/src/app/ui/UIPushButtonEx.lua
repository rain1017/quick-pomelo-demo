
local UIPushButton = cc.ui.UIPushButton
local UIPushButtonEx = class("UIPushButtonEx", UIPushButton)

local viewloader = import('..viewloader.viewloader')

function UIPushButtonEx:updateButtonImage_()
    local state = self.fsm_:getState()
    local image = self.images_[state]

    if not image then
        for _, s in pairs(self:getDefaultState_()) do
            image = self.images_[s]
            if image then break end
        end
    end
    if image then
        if self.currentImage_ ~= image then
            for i,v in ipairs(self.sprite_) do
                v:removeFromParent(true)
            end
            self.sprite_ = {}
            self.currentImage_ = image

            self.sprite_[1] = viewloader['render_' .. image.renderType](viewloader, unpack(image.args))
            if self.sprite_[1].setFlippedX then
                if self.flipX_ then
                    self.sprite_[1]:setFlippedX(self.flipX_ or false)
                end
                if self.flipY_ then
                    self.sprite_[1]:setFlippedY(self.flipY_ or false)
                end
            end
            self:addChild(self.sprite_[1], UIPushButtonEx.super.super.IMAGE_ZORDER)
        end

        for i,v in ipairs(self.sprite_) do
            v:align(display.LEFT_BOTTOM, 0, 0)
        end
    elseif not self.labels_ then
        printError("UIPushButtonEx:updateButtonImage_() - not set image for state %s", state)
    end
end

return UIPushButtonEx
