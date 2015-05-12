local viewloader = import('..viewloader.viewloader')
local cardFormula = require('app.formula.cardFormula')
local consts = import('..consts')


local UILittleCards = class("UILittleCards", function()
    return display.newNode()
end)

UILittleCards.SUIT_PREFIX = "Module_Little_Card_Suit_"
UILittleCards.CARD_PREFIX = "Module_Little_Card_Num_"

UILittleCards.CARD_NUM_SIZE = {14,15}
UILittleCards.SUIT_SIZE = {10,10}
UILittleCards.BG_RECT = {85,469,30,40}
UILittleCards.BG_LITTLE_RECT = {142,289,22,30}
UILittleCards.CARD_GAP = 15
UILittleCards.CARD_GAP = 15

UILittleCards.SIZE_NORMAL = 0
UILittleCards.SIZE_SMALLER = 1

function UILittleCards:ctor(rect, align, size)
    self.rect_ = rect
    self.align_ = align
    self.cards = cards
    self.size_ = size
    self.bgImg_ = 'Module_Out_Card_BG'
    self.bgRect_ = UILittleCards.BG_RECT
    if self.size_ == UILittleCards.SIZE_SMALLER then
        self.bgImg_ = 'Module_Little_Card_BG0'
        self.bgRect_ = UILittleCards.BG_LITTLE_RECT
    end
    self:setContentSize(rect.width, rect.height)
end

function UILittleCards:setCards(cards)
    local rect, align, bgRect = self.rect_, self.align_, self.bgRect_
    local cardCountPerRow = math.floor((rect.width - bgRect[3]) / UILittleCards.CARD_GAP) + 1
    local leftStart = 0
    if align == 'right' then
        leftStart = rect.width - ((cardCountPerRow - 1) * UILittleCards.CARD_GAP + bgRect[3])
    end
    local rows = math.floor(#cards / cardCountPerRow)
    if #cards % cardCountPerRow ~= 0 then rows = rows + 1 end
    for i=1,rows do
        local localLeftStart = leftStart
        if i == rows then
            if align == 'right' then
                localLeftStart = rect.width - ((#cards % cardCountPerRow - 1) * UILittleCards.CARD_GAP + bgRect[3])
            elseif align == 'center' then
                localLeftStart = (rect.width - ((#cards % cardCountPerRow - 1) * UILittleCards.CARD_GAP + bgRect[3]))/2
            end
        end
        for j=1,cardCountPerRow do
            local idx = (i-1)*cardCountPerRow + j
            if idx > #cards then break end
            local card = cardFormula.unpackCard(cards[idx])
            local cardNode = self:createCard(card[1], card[2])
                :align(display.LEFT_BOTTOM, localLeftStart + (j - 1) * UILittleCards.CARD_GAP,
                    rect.height - (UILittleCards.CARD_NUM_SIZE[2] + UILittleCards.SUIT_SIZE[2]) * i)
                :addTo(self)
        end
    end
    return self
end

function UILittleCards:createCard(suit, point)
    local color, bgImg, bgRect = 'Red', self.bgImg_, self.bgRect_
    if suit == consts.card.suit.spade or suit == consts.card.suit.club then color = 'Black' end
    local cardNode = display.newNode()
    cardNode:setContentSize(bgRect[3], bgRect[4])
    viewloader:spriteByDesc('HLDDZ_MainGame0', bgImg, 'ui/MainGame.json')
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(cardNode)
    if point == 'X' then
        viewloader:spriteByDesc('HLDDZ_MainGame0', 'Module_Little_Black_Joker_Text', 'ui/MainGame.json')
            :align(display.LEFT_TOP, 2, bgRect[4] - 2)
            :addTo(cardNode)
        return cardNode
    elseif point == 'Y' then
        viewloader:spriteByDesc('HLDDZ_MainGame0', 'Module_Little_Red_Joker_Text', 'ui/MainGame.json')
            :align(display.LEFT_TOP, 2, bgRect[4] - 2)
            :addTo(cardNode)
        return cardNode
    end
    viewloader:spriteByDesc('HLDDZ_MainGame0', string.format('Module_Little_Card_Num_%s_%s', color, point), 'ui/MainGame.json')
        :align(display.LEFT_TOP, 2, bgRect[4] - 2)
        :addTo(cardNode)
    viewloader:spriteByDesc('HLDDZ_MainGame0', UILittleCards.SUIT_PREFIX .. suit, 'ui/MainGame.json')
        :align(display.LEFT_TOP, 4, bgRect[4] - UILittleCards.CARD_NUM_SIZE[2])
        :addTo(cardNode)
    return cardNode
end


return UILittleCards
