local UIButton = cc.ui.UIButton
local UIPushButtonEx = import('.UIPushButtonEx')
local cardFormula = require('app.formula.cardFormula')
local viewloader = import('..viewloader.viewloader')


local UICardButton = class("UIPushButtonEx", UIPushButtonEx)

UICardButton.SUIT_PREFIX = "Module_Card_Suit_"
UICardButton.SUIT_HEART = "Module_Card_Suit_1"
UICardButton.SUIT_SPADE = "Module_Card_Suit_0"
UICardButton.SUIT_CLUB = "Module_Card_Suit_2"
UICardButton.SUIT_DIAMOND = "Module_Card_Suit_3"
UICardButton.SUIT_JOKER = "Module_Card_Suit_4"

UICardButton.BG_RECT = {438,88,65,84}
UICardButton.CARD_NUM_SIZE = {19,21}

function UICardButton:ctor(...)
    UICardButton.super.ctor(self, ...)
    self.selected = false
    self.suit = nil
    self.point = nil
    self.touchCb = nil
end

function UICardButton:setCardInfo(suit, point)
    self.suit = suit
    self.point = point
    if point == 'X' then
        viewloader:spriteByDesc('HLDDZ_MainGame0', 'Module_Black_Joker_Text', 'ui/MainGame.json')
            :align(display.LEFT_TOP, 2, UICardButton.BG_RECT[4] - 4)
            :zorder(UIPushButtonEx.super.super.LABEL_ZORDER)
            :addTo(self)
    elseif point == 'Y' then
        viewloader:spriteByDesc('HLDDZ_MainGame0', 'Module_Red_Joker_Text', 'ui/MainGame.json')
            :align(display.LEFT_TOP, 2, UICardButton.BG_RECT[4] - 4)
            :zorder(UIPushButtonEx.super.super.LABEL_ZORDER)
            :addTo(self)
    else
        local color = 'Red'
        suit = UICardButton.SUIT_PREFIX .. suit
        if suit == UICardButton.SUIT_SPADE or suit == UICardButton.SUIT_CLUB then color = 'Black' end
        viewloader:spriteByDesc('HLDDZ_MainGame0', string.format('Module_Card_Num_%s_%s', color, point), 'ui/MainGame.json')
            :align(display.LEFT_TOP, 2, UICardButton.BG_RECT[4] - 4)
            :zorder(UIPushButtonEx.super.super.LABEL_ZORDER)
            :addTo(self)
        viewloader:spriteByDesc('HLDDZ_MainGame0', suit, 'ui/MainGame.json')
            :align(display.LEFT_TOP, 5, UICardButton.BG_RECT[4] - 4 - UICardButton.CARD_NUM_SIZE[2])
            :zorder(UIPushButtonEx.super.super.LABEL_ZORDER)
            :addTo(self)
    end
end

function UICardButton:onTouch_(event)
    local ret = UICardButton.super.onTouch_(self, event)
    if self.touchCb then
        self.touchCb(event)
    end
    return ret
end

function UICardButton:toggleSelect(noAni)
    local x, y = self:getPosition()
    if self.selected then
        y = y - 10
    else
        y = y + 10
    end
    if noAni then
        self:setPositionY(y)
    else
        transition.moveTo(self, {y=y, time=0.1})
    end
    self.selected = not self.selected
end

function UICardButton:unselect()
    if self.selected then
        self:toggleSelect(true)
    end
end

function UICardButton:isSelected()
    return self.selected
end

function UICardButton:updateButtonImage_()
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
            self.sprite_[1] = viewloader:spriteByDesc(unpack(image.args))
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


function UICardButton.create(suit, point, touchCb)
    local btn = ddz.ui.UICardButton.new()
    btn:setButtonImage(cc.ui.UIPushButton.NORMAL, {args={'HLDDZ_ShareAni', 'Module_Card_BG0', 'ui/MainGame.json'}})
    btn:setCardInfo(suit, point)
    btn.touchCb = touchCb
    return btn
end


return UICardButton