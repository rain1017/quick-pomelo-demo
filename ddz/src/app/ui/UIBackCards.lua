local viewloader = import('..viewloader.viewloader')
local UIBMFontLabel = import('.UIBMFontLabel')


local UIBackCards = class("UIBackCards", function()
    return display.newNode()
end)

UIBackCards.CARD_SPRITE_CONFIG = {img="HLDDZ_MainGame0", desc="Module_Little_Card_Back"}
UIBackCards.CARD_RECT = {429,3,43,19}

UIBackCards.POS_LEFT = 0
UIBackCards.POS_RIGHT = 1

function UIBackCards:ctor(pos, rect, count)
    if pos ~= UIBackCards.POS_LEFT and pos ~= UIBackCards.POS_RIGHT then
        printError('pos must be left or right: %s', pos)
    end
    self.pos = pos
    self.rect = rect
    self.count = count
    self.cardNodes = {}
    if self.pos == UIBackCards.POS_LEFT then
        self.countNode = UIBMFontLabel.new("", UIBMFontLabel.FONTTYPE_MAIN1, "right", {width=60, height=20})
            :align(display.RIGHT_CENTER, rect.width/2 + 25, rect.height/2 + 25)
            :addTo(self)
            :zorder(1)
    else
        self.countNode = UIBMFontLabel.new("", UIBMFontLabel.FONTTYPE_MAIN1, "left", {width=60, height=20})
            :align(display.LEFT_CENTER, rect.width/2 - 25, rect.height/2 + 25)
            :addTo(self)
            :zorder(1)
    end
    self:setContentSize(rect.width, rect.height)
    self:updateUI(self.count)
end

function UIBackCards:updateUI(count)
    local count_pre = #self.cardNodes
    local added = count - count_pre
    printInfo('UIBackCards.updateUI called from %s, count=%s, added=%s', getCallerFuncPos(), count, added)
    if added > 0 then
        for i=#self.cardNodes+1,#self.cardNodes+added do
            local gap = 3
            local cardNode = viewloader:spriteByDesc(UIBackCards.CARD_SPRITE_CONFIG.img, UIBackCards.CARD_SPRITE_CONFIG.desc, 'ui/MainGame.json')
                :addTo(self)
            if self.pos == UIBackCards.POS_LEFT then
                cardNode:align(display.RIGHT_TOP, self.rect.width - (i-1) * gap * 0.86, self.rect.height - (i-1) * gap)
            else
                cardNode:setFlippedX(true)
                cardNode:align(display.LEFT_TOP, (i-1) * gap * 0.86, self.rect.height - (i-1) * gap)
            end
            self.cardNodes[#self.cardNodes+1] = cardNode
        end
    elseif added < 0 then
        for i=1,-added do
            local cardNode = self.cardNodes[#self.cardNodes]
            self.cardNodes[#self.cardNodes] = nil
            cardNode:removeSelf()
        end
    end
    self.countNode:setText(tostring(count))
    return self
end

function UIBackCards:setCount(count)
    self:updateUI(count)
    return self
end

function UIBackCards:deal()
    -- todo, do this as an animation
    --for i=1,self.count do
    --    self:setCount(i)
    --end
    return self
end

return UIBackCards