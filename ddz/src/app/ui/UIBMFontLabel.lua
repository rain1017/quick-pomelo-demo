local viewloader = import('..viewloader.viewloader')

local chars = {
    HLDDZ_Balance_0 = {
    },
    HLDDZ_Balance_1 = {
    }
}

chars.HLDDZ_Balance_0['+'] = {236,304,22,30}
chars.HLDDZ_Balance_0['-'] = {258,304,22,30}
chars.HLDDZ_Balance_0['0'] = {280,304,22,30}
chars.HLDDZ_Balance_0['1'] = {302,304,22,30}
chars.HLDDZ_Balance_0['2'] = {324,304,22,30}
chars.HLDDZ_Balance_0['3'] = {346,304,22,30}
chars.HLDDZ_Balance_0['4'] = {368,304,22,30}
chars.HLDDZ_Balance_0['5'] = {390,304,22,30}
chars.HLDDZ_Balance_0['6'] = {412,304,22,30}
chars.HLDDZ_Balance_0['7'] = {434,304,22,30}
chars.HLDDZ_Balance_0['8'] = {456,304,22,30}
chars.HLDDZ_Balance_0['9'] = {478,304,22,30}
chars.HLDDZ_Balance_0['/'] = {354,273,22,30}
chars.HLDDZ_Balance_1['+'] = {236,334,22,30}
chars.HLDDZ_Balance_1['-'] = {258,334,22,30}
chars.HLDDZ_Balance_1['0'] = {280,334,22,30}
chars.HLDDZ_Balance_1['1'] = {302,334,22,30}
chars.HLDDZ_Balance_1['2'] = {324,334,22,30}
chars.HLDDZ_Balance_1['3'] = {346,334,22,30}
chars.HLDDZ_Balance_1['4'] = {368,334,22,30}
chars.HLDDZ_Balance_1['5'] = {390,334,22,30}
chars.HLDDZ_Balance_1['6'] = {412,334,22,30}
chars.HLDDZ_Balance_1['7'] = {434,334,22,30}
chars.HLDDZ_Balance_1['8'] = {456,334,22,30}
chars.HLDDZ_Balance_1['9'] = {478,334,22,30}


local charProps = {
    balance = {imgFile = 'HLDDZ_Balance', width = 19, height = 30},
    main = {imgFile = 'HLDDZ_MainGame0', width = 13, height = 25},
    main_text = {imgFile = 'HLDDZ_MainGame0', width = 25, height = 28},
}



local UIBMFontLabel = class("UIBMFontLabel", function()
    return display.newNode()
end)

UIBMFontLabel.FONTTYPE_0 = 'HLDDZ_Balance_0'
UIBMFontLabel.FONTTYPE_1 = 'HLDDZ_Balance_1'
UIBMFontLabel.FONTTYPE_MAIN0 = 'Module_Num_0'
UIBMFontLabel.FONTTYPE_MAIN1 = 'Module_Num_1'
UIBMFontLabel.FONTTYPE_MAIN2 = 'Module_Num_2'
UIBMFontLabel.FONTTYPE_MAIN3 = 'Module_Num_3'
UIBMFontLabel.FONTTYPE_MAIN_TEXT = 'Module_Game_Text'
UIBMFontLabel.FONTTYPES = {
    UIBMFontLabel.FONTTYPE_0, UIBMFontLabel.FONTTYPE_1, UIBMFontLabel.FONTTYPE_MAIN0,
    UIBMFontLabel.FONTTYPE_MAIN1, UIBMFontLabel.FONTTYPE_MAIN2, UIBMFontLabel.FONTTYPE_MAIN3,
    UIBMFontLabel.FONTTYPE_MAIN_TEXT
}


function UIBMFontLabel:ctor(text, fontType, align, size, margin, scale)
    self.text_ = text
    self.fontType_ = fontType
    self.align_ = align
    self.size_ = size
    self.margin_ = margin or {left=0, right=0, top=0, bottom=0}
    self.scale_ = scale or 1
    if not table.indexof(UIBMFontLabel.FONTTYPES, fontType) then
        printError('unknown fontType: %s', fontType)
    end
    self:render()
    self:setContentSize(size.width, size.height)
end

function UIBMFontLabel:render()
    self:removeAllChildren()
    if not self.text_ or self.text_ == '' then return end
    local charsConf, strChars
    local xstart, scaledWidth = 0, 0
    if string.sub(self.fontType_, 1, 13) == 'HLDDZ_Balance' then
        strChars = string.split(self.text_, '')
        scaledWidth = charProps.balance.width * self.scale_
        charsConf = chars[self.fontType_]
    elseif self.fontType_ == UIBMFontLabel.FONTTYPE_MAIN_TEXT then
        strChars = string.split(self.text_, '_')
        scaledWidth = charProps.main_text.width * self.scale_
    else
        scaledWidth = charProps.main.width * self.scale_
        strChars = string.split(self.text_, '')
    end
    --printInfo('text: %s, strChars=%s', self.text_, json.encode(strChars))
    if self.align_ == 'center' then
        xstart = (self.size_.width - #strChars * scaledWidth)/2
    elseif self.align_ == 'right' then
        xstart = self.size_.width - #strChars * scaledWidth
    end
    for i, char in pairs(strChars) do
        local sp
        if string.sub(self.fontType_, 1, 13) == 'HLDDZ_Balance' then
            if not charsConf[char] then
                printError('char not found: %s', char)
            end
            sp = viewloader.sprite('HLDDZ_Balance', charsConf[char])
        elseif self.fontType_ == UIBMFontLabel.FONTTYPE_MAIN_TEXT then
            sp = viewloader:spriteByDesc(charProps.main_text.imgFile, self.fontType_ .. '_' .. char, 'ui/MainGame.json')
        else
            sp = viewloader:spriteByDesc(charProps.main.imgFile, self.fontType_ .. '_' .. char, 'ui/MainGame.json')
        end
        sp:setScale(sp:getScaleX() * self.scale_, sp:getScaleY() * self.scale_)
        sp:align(display.LEFT_CENTER, xstart + i * scaledWidth - scaledWidth, self.size_.height/2)
            :addTo(self)
    end
end

function UIBMFontLabel:setText(text)
    self.text_ = text
    self:render()
    return self
end


return UIBMFontLabel