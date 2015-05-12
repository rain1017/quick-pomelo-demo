local viewloader = import('..viewloader.viewloader')
local UICardButton = import('.UICardButton')
local cardFormula = require('app.formula.cardFormula')

local ifTrueThen = function(cond, this, that)
    if cond then return this else return that end
end

local UIMyCards = class("UIMyCards", function()
    return display.newNode()
end)

local BEGIN_X = 82
local SEP_WIDTH = 20
local CARD_WIDTH = 84

function UIMyCards:ctor(cards)
    self.cards = cards
    self.buttons = {}
    self:align(display.LEFT_BOTTOM, 0, 20)
    self:setContentSize(display.width, UICardButton.CARD_NUM_SIZE[2])
    self.pressBtnIdx = nil
end

function UIMyCards:onButtonTouched(event)
    local name, x, y = event.name, event.x, event.y
    if name == "began" then
        self.pressBtnIdx = math.ceil((x - BEGIN_X) / SEP_WIDTH)
    end

    if name == "ended" then
        local releaseBtnIdx = math.ceil((x - BEGIN_X) / SEP_WIDTH)
        printInfo('pressBtnIdx: %s, releaseBtnIdx: %s', self.pressBtnIdx, releaseBtnIdx)
        local max = ifTrueThen(self.pressBtnIdx > releaseBtnIdx, self.pressBtnIdx, releaseBtnIdx)
        local min = ifTrueThen(self.pressBtnIdx < releaseBtnIdx, self.pressBtnIdx, releaseBtnIdx)
        if not self.buttons[min] then min = #self.buttons end
        if not self.buttons[max] then max = #self.buttons end
        for i=min, max do
            self.buttons[i]:toggleSelect()
        end
        self.pressBtnIdx = nil
    end
end

function UIMyCards:deal(callback)
    --todo, deal cards as an animation
    printInfo('deal begin at %s', os.clock())
    for i = 1, #self.cards do
        v = cardFormula.unpackCard(self.cards[#self.cards - i + 1])
        self.buttons[i] = UICardButton.create(v[1], v[2], handler(self, self.onButtonTouched))
            :align(display.BOTTOM_CENTER, 82 + i * 20 - 20, 0)
            :addTo(self)
    end
    printInfo('deal end at %s', os.clock())
    if callback then callback() end
    return self
end

function UIMyCards:removeCards(cards)
    printInfo('removeCards: self.cards=%s, cards=%s', json.encode(self.cards), json.encode(cards))
    self.pressBtnIdx = nil
    local j = 1
    local newCards, btns = {}, {}
    for i,v in ipairs(self.cards) do
        if table.keyof(cards, v) == nil then
            newCards[#newCards+1] = v
            btns[#btns+1] = self.buttons[#self.cards+1-i]
        else
            self.buttons[#self.cards+1-i]:stopAllActions()
            self.buttons[#self.cards+1-i]:removeSelf()
        end
    end
    self.cards = newCards
    self.buttons = {}
    for i, v in ipairs(btns) do
        self.buttons[#self.buttons+1] = btns[#btns+1-i]
    end
    for i,v in pairs(self.cards) do
        self.buttons[i]:unselect()
        self.buttons[i]:align(display.BOTTOM_CENTER, BEGIN_X + i * SEP_WIDTH - SEP_WIDTH, 0)
    end
end

function UIMyCards:getChoosedCards()
    local cards = {}
    for i = 1, #self.cards do
        if self.buttons[i]:isSelected() then
            cards[#cards+1] = self.cards[#self.cards + 1 - i]
        end
    end
    return cards
end

function UIMyCards:setCards(cards)
    self.pressBtnIdx = nil
    self.cards = cards
    for i,v in ipairs(self.buttons) do
        v:stopAllActions()
        v:removeSelf()
    end
    self.buttons = {}
    for i = 1, #self.cards do
        v = cardFormula.unpackCard(self.cards[#self.cards - i + 1])
        self.buttons[i] = UICardButton.create(v[1], v[2], handler(self, self.onButtonTouched))
            :align(display.BOTTOM_CENTER, BEGIN_X + i * SEP_WIDTH - SEP_WIDTH, 0)
            :addTo(self)
    end
end

return UIMyCards