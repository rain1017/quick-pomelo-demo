local scheduler = require(cc.PACKAGE_NAME .. ".scheduler")
local viewloader = ddz.ui.viewloader
local consts = import('..consts')
local UILoadingBarController = ddz.ui.UILoadingBarController
local UILoadingMaskController = ddz.ui.UILoadingMaskController
local UIBMFontLabel = ddz.ui.UIBMFontLabel
local UICardButton = ddz.ui.UICardButton
local UIBackCards = ddz.ui.UIBackCards
local UIMyCards = ddz.ui.UIMyCards
local UILittleCards = ddz.ui.UILittleCards
local UIClock = ddz.ui.UIClock


local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

MainScene.NAME = 'MainScene'

--TitlePanel TextButton AvatarBtn ScrollTextView

function MainScene:ctor()

    local node, rendered = viewloader:renderView('ui/MainGame.json')
    node:addTo(self)
    self.rendered = rendered

    -- background
    viewloader.sprite('Common_BG1', {0, 0, 480, 320})
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)
        :zorder(-1000)
    -- chairs
    viewloader.sprite('HLDDZ_MainGame1', {0,218,72,39})
        :align(display.LEFT_BOTTOM, 0, 218/2)
        :addTo(self)
        :zorder(-1000)
    viewloader.sprite('HLDDZ_MainGame1', {0,218,72,39})
        :align(display.LEFT_BOTTOM, 480-72, 218/2)
        :addTo(self)
        :zorder(-1000)
    -- desk
    viewloader.sprite('HLDDZ_MainGame1', {0,0,480,218})
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(self)
        :zorder(-900)

    -- player beans
    self.rendered.player_bean_icon = viewloader.sprite('HLDDZ_Common2', {56,86,31,31})
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(self)
        :zorder(-899)
    self.rendered.player_bean_count_label = UIBMFontLabel.new("", UIBMFontLabel.FONTTYPE_MAIN3, "right", {width=60, height=20})
        :align(display.LEFT_BOTTOM, 31, 0)
        :addTo(self)
        :zorder(-899)

    -- current times
    self.rendered.current_times_icon = viewloader.sprite('HLDDZ_MainGame0', {387,242,24,24})
        :align(display.LEFT_BOTTOM, 360, -2)
        :addTo(self)
        :zorder(-899)
    self.rendered.current_times_label = UIBMFontLabel.new("000000", UIBMFontLabel.FONTTYPE_MAIN2, "left", {width=60, height=20})
        :align(display.LEFT_BOTTOM, 360 + 24, 0)
        :addTo(self)
        :zorder(-899)

    self.rendered.maingame_float_up_btn:zorder(-1000)
    self.rendered.maingame_float_down_btn:zorder(-1000)

    --dump(rendered)

    self.controllers = {}

    self.rendered.maingame_float_up_btn:onButtonClicked(handler(self, function()
        self.rendered.maingame_float_up_btn:hide()
        self.rendered.maingame_float_down_btn:show()
        local y = self.rendered.panel_maingame_float:getPositionY()
        transition.moveTo(self.rendered.panel_maingame_float,
            {y = y + 40, time = 0.5})
    end))
    self.rendered.maingame_float_down_btn:onButtonClicked(handler(self, function()
        self.rendered.maingame_float_up_btn:show()
        self.rendered.maingame_float_down_btn:hide()
        local y = self.rendered.panel_maingame_float:getPositionY()
        transition.moveTo(self.rendered.panel_maingame_float,
            {y = y - 40, time = 0.5})
    end))

    self.rendered.error_status = display.newTTFLabel({color = cc.c3b(230,26,26),dimensions = cc.size(480, 20),
        font = "fonts/STFONT.ttf",size = 18,align=cc.TEXT_ALIGNMENT_CENTER})
        :align(display.CENTER, display.cx, display.cy)
        :addTo(self)
        :zorder(100)
        :hide()

    -- for test
    --[[
    scheduler.performWithDelayGlobal(function()
        self:onConnected(false, 1786)
    end, 0.1)
    scheduler.performWithDelayGlobal(function()
        self:onReadyForGame()
    end, 0.2)
    scheduler.performWithDelayGlobal(function()
        self:onAddPlayer(true, true)
    end, 0.3)
    scheduler.performWithDelayGlobal(function()
        self:onAddPlayer(false, false)
    end, 0.4)
    scheduler.performWithDelayGlobal(function()
        self:onStartGame()
    end, 0.5)
    --]]
end

function MainScene:addButtonListener(buttonId, callback)
    self.rendered[buttonId]:onButtonClicked(callback)
end

function MainScene:showLoading(status)
    self:showStatus(status)
    self.controllers.maskController = UILoadingMaskController:create()
    self.controllers.maskController:node()
        :align(display.CENTER, display.cx, display.cy + 30)
        :addTo(self)
    self.controllers.maskController:start()
end

function MainScene:showErrorStatus(status)
    self.rendered.error_status:setString(status)
    self.rendered.error_status:show()
end

function MainScene:showStatus(status)
    self.rendered.hlddz_loading_text:setString(ddz.locale(status))
    self.rendered.hlddz_loading_text:show()
end

function MainScene:hideStatus()
    self.rendered.hlddz_loading_text:hide()
end

function MainScene:hideToolBar()
    if self.rendered.maingame_float_up_btn:isVisible() then
        self.rendered.maingame_float_up_btn:hide()
        self.rendered.maingame_float_down_btn:show()
        local y = self.rendered.panel_maingame_float:getPositionY()
        transition.moveTo(self.rendered.panel_maingame_float,
            {y = y + 40, time = 0.5})
    end
end

function MainScene:showToolBar()
    if self.rendered.maingame_float_down_btn:isVisible() then
        self.rendered.maingame_float_up_btn:show()
        self.rendered.maingame_float_down_btn:hide()
        local y = self.rendered.panel_maingame_float:getPositionY()
        transition.moveTo(self.rendered.panel_maingame_float,
            {y = y - 40, time = 0.5})
    end
end

function MainScene:removeLoading()
    self:hideStatus()
    self.controllers.maskController:stop()
    self.controllers.maskController:node():hide()
end

function MainScene:showMyAvatar(male)
    local femaleConf = {92,152,92,107}
    local maleConf = {0,107,92,107}
    local conf = femaleConf
    if male then conf = maleConf end
    -- avatars
    if self.rendered.avatar_me then
        self.rendered.avatar_me:removeSelf()
    end
    self.rendered.avatar_me = viewloader.sprite('HLDDZ_Avatar', conf)
        :align(display.LEFT_BOTTOM, -10, 15)
        :addTo(self)
        :zorder(-800)
end

function MainScene:addPlayer(left, male)
    local femaleConf = {92,152,92,107}
    local maleConf = {0,107,92,107}
    local conf = femaleConf
    if male then conf = maleConf end
    if left then
        if self.rendered.avatar_left then
            self.rendered.avatar_left:removeSelf()
        end
        self.rendered.avatar_left = viewloader.sprite('HLDDZ_Avatar', conf)
            :align(display.LEFT_BOTTOM, -20, 218/2+25)
            :addTo(self)
            :zorder(-999)
    else
        if self.rendered.avatar_right then
            self.rendered.avatar_right:removeSelf()
        end
        self.rendered.avatar_right = viewloader.sprite('HLDDZ_Avatar', conf)
            :align(display.LEFT_BOTTOM, 480-72, 218/2+25)
            :addTo(self)
            :flipX(true)
            :zorder(-999)
    end
end

function MainScene:updatePlayer(left, male, isLandlord)
    local sex, role, img, descPrefix, file = '', '_Landlord', 'HLDDZ_MainGame1', 'Module_Game_Avatar', 'ui/MainGame.json'
    if not male then sex, img = '_female', 'HLDDZ_Avatar' end
    if not isLandlord then role = '_Farmer' end
    if left == nil then
        if self.rendered.avatar_me then
            self.rendered.avatar_me:removeSelf()
        end
        self.rendered.avatar_me = viewloader:spriteByDesc(img, descPrefix  .. role .. sex, file)
            :align(display.LEFT_BOTTOM, -10, 15)
            :addTo(self)
            :zorder(-800)
    elseif left then
        if self.rendered.avatar_left then
            self.rendered.avatar_left:removeSelf()
        end
        self.rendered.avatar_left = viewloader:spriteByDesc(img, descPrefix  .. role .. sex, file)
            :align(display.LEFT_BOTTOM, -20, 218/2+25)
            :addTo(self)
            :zorder(-999)
    else
        if self.rendered.avatar_right then
            self.rendered.avatar_right:removeSelf()
        end
        self.rendered.avatar_right = viewloader:spriteByDesc(img, descPrefix  .. role .. sex, file)
            :align(display.LEFT_BOTTOM, 480-72, 218/2+25)
            :addTo(self)
            :flipX(true)
            :zorder(-999)
    end
end

function MainScene:removePlayer(left)
    if left and self.rendered.avatar_left then
        self.rendered.avatar_left:removeSelf()
        self.rendered.avatar_left = nil
    elseif self.rendered.avatar_right then
        self.rendered.avatar_right:removeSelf()
        self.rendered.avatar_right = nil
    end
end

function MainScene:showOkGesture(left)
    local img, desc, file = 'HLDDZ_MainGame0', 'Module_Ready', 'ui/MainGame.json'
    local name, x, y
    if left == nil then
        name = 'okgesture_me'
        x, y = display.cx - 140, 320-216.5
    elseif left then
        name = 'okgesture_left'
        x, y = display.cx - 120, display.cy+40
    else
        name = 'okgesture_right'
        x, y = display.cx + 120, display.cy+40
    end
    if self.rendered[name] then self.rendered[name]:show() return end
    self.rendered[name] = viewloader:spriteByDesc(img, desc, file)
        :align(display.CENTER, x, y)
        :addTo(self)
        :zorder(-799)
end

function MainScene:removeOkGesture(left)
    if left == nil then
        name = 'okgesture_me'
    elseif left then
        name = 'okgesture_left'
    else
        name = 'okgesture_right'
    end
    if self.rendered[name] then self.rendered[name]:hide() return end
end

function MainScene:showNameAndMoney(left, name, money)
    local img, desc, file = 'HLDDZ_MainGame0', 'Module_Little_Bean', 'ui/MainGame.json'
    local nameName, nameMoney, nameIcon, x, y
    if left then
        nameName, nameMoney, nameIcon = 'playername_left', 'playermoney_left', 'playermoney_icon_left'
        x, y = display.cx - 155, display.cy
    else
        nameName, nameMoney, nameIcon = 'playername_right', 'playermoney_right', 'playermoney_icon_right'
        x, y = display.cx + 105, display.cy
    end
    if self.rendered[nameName] then
        self.rendered[nameName]:show()
        self.rendered[nameName]:setString(name)
    else
        local labelOpts = {
            color = cc.c3b(82, 20, 3),
            dimensions = cc.size(100, 20),
            font = "fonts/STFONT.ttf",
            size = 18,
            text = name,
        }
        self.rendered[nameName] = display.newTTFLabel(labelOpts)
            :align(display.LEFT_BOTTOM, x, y)
            :addTo(self)
            :zorder(-799)
    end
    if self.rendered[nameIcon] then
        self.rendered[nameIcon]:show()
        self.rendered[nameMoney]:show()
        self.rendered[nameMoney]:setText(money)
    else
        self.rendered[nameIcon] = viewloader:spriteByDesc(img, desc, file)
            :align(display.LEFT_BOTTOM, x, y-20)
            :addTo(self)
            :zorder(-799)
        self.rendered[nameMoney] = UIBMFontLabel.new(tostring(money), UIBMFontLabel.FONTTYPE_MAIN3, "left", {width=60, height=20})
            :align(display.LEFT_BOTTOM, x+13, y-20)
            :addTo(self)
            :zorder(-799)
    end
end

function MainScene:removeNameAndMoney(left)
    if left then
        nameName, nameMoney, nameIcon = 'playername_left', 'playermoney_left', 'playermoney_icon_left'
    else
        nameName, nameMoney, nameIcon = 'playername_right', 'playermoney_right', 'playermoney_icon_right'
    end
    if self.rendered[nameIcon] and self.rendered[nameIcon]:isVisible() then
        self.rendered[nameIcon]:hide()
        self.rendered[nameMoney]:hide()
        self.rendered[nameName]:hide()
    end
end

function MainScene:showMyCards(cards)
    if self.rendered.cards_panel then
        self.rendered.cards_panel:setCards(cards)
    else
        self.rendered.cards_panel = UIMyCards.new(cards)
            :addTo(self)
            :deal()
    end
end

function MainScene:removeMyCards()
    if self.rendered.cards_panel then
        self.rendered.cards_panel:removeSelf()
        self.rendered.cards_panel = nil
    end
end

function MainScene:showPlayerCards(left, cardsCount)
    if left then
        if not self.rendered.backcards_panel_left then
            self.rendered.backcards_panel_left = UIBackCards.new(UIBackCards.POS_LEFT, {width=100, height=100}, cardsCount)
                :align(display.LEFT_CENTER, 3, display.cy - 42)
                :addTo(self)
                :zorder(-899)
                :deal()
        else
            self.rendered.backcards_panel_left:setCount(cardsCount)
        end
    else
        if not self.rendered.backcards_panel_right then
            self.rendered.backcards_panel_right = UIBackCards.new(UIBackCards.POS_RIGHT, {width=100, height=100}, cardsCount)
                :align(display.RIGHT_CENTER, display.width-3, display.cy-42)
                :addTo(self)
                :zorder(-899)
                :deal()
        else
            self.rendered.backcards_panel_right:setCount(cardsCount)
        end
    end
end

function MainScene:removePlayerCards(left)
    if left then
        if self.rendered.backcards_panel_left then
            self.rendered.backcards_panel_left:removeSelf()
            self.rendered.backcards_panel_left = nil
        end
    else
        if self.rendered.backcards_panel_right then
            self.rendered.backcards_panel_right:removeSelf()
            self.rendered.backcards_panel_right = nil
        end
    end
end

function MainScene:showLandlordCards(cards)
    if not cards then
        if self.rendered.added_cards_landloard then
            self.rendered.added_cards_landloard:removeSelf()
            self.rendered.added_cards_landloard = nil
        end
    else
        self.rendered.added_cards_landloard = UILittleCards.new({width=66, height=30}, 'left', UILittleCards.SIZE_SMALLER)
            :align(display.LEFT_TOP, 5, display.height-5)
            :addTo(self)
            :setCards(cards)
    end
end

function MainScene:showClock(left)
    self:removeClock()
    local x, y
    if left == nil then
        x, y = display.cx, 320-186.5
        if self.rendered.maingame_hint_btn:isVisible() then
            x = 200
        end
        printInfo('showClock mine')
    elseif left then
        x, y = display.cx - 100, display.cy
        printInfo('showClock left')
    else
        x, y = display.cx + 100, display.cy
        printInfo('showClock right')
    end
    self.clock_view = UIClock.new(15, {width=46, height=50}, function()
            printInfo('time is up')
        end)
        :align(display.CENTER, x, y)
        :addTo(self)
end

function MainScene:removeClock()
    if self.clock_view then
        self.clock_view:stop()
        self.clock_view:removeSelf()
        self.clock_view = nil
    end
end

function MainScene:showOutCards(left, cards)
    if left == nil then
        if self.rendered.outcards_board then
            self.rendered.outcards_board:removeSelf()
            self.rendered.outcards_board = nil
        end
        if not cards or #cards == 0 then return end
        self.rendered.outcards_board = UILittleCards.new({width=320, height=40}, 'center')
            :align(display.CENTER_BOTTOM, display.cx, 87)
            :addTo(self)
            :setCards(cards)
    elseif left then
        if self.rendered.outcards_board_left then
            self.rendered.outcards_board_left:removeSelf()
            self.rendered.outcards_board_left = nil
        end
        if not cards or #cards == 0 then return end
        self.rendered.outcards_board_left = UILittleCards.new({width=140, height=80}, 'left')
            :align(display.RIGHT_BOTTOM, display.cx - 10, 120)
            :addTo(self)
            :setCards(cards)
    else
        if self.rendered.outcards_board_right then
            self.rendered.outcards_board_right:removeSelf()
            self.rendered.outcards_board_right = nil
        end
        if not cards or #cards == 0 then return end
        self.rendered.outcards_board_right = UILittleCards.new({width=140, height=80}, 'left')
            :align(display.LEFT_BOTTOM, display.cx + 10, 120)
            :addTo(self)
            :setCards(cards)
    end
end

function MainScene:showPlayStatus(left, status)
    local labelName, x, y
    if left == nil then labelName, x, y = 'play_status_me', display.cx, display.cy - 40
    elseif left then labelName, x, y = 'play_status_left', display.cx - 120, display.cy+40
    else labelName, x, y = 'play_status_right', display.cx + 110, display.cy+40 end
    if self.rendered[labelName] then
        self.rendered[labelName]:setText(status)
        self.rendered[labelName]:show()
    else
        self.rendered[labelName] = UIBMFontLabel.new(status, UIBMFontLabel.FONTTYPE_MAIN_TEXT, "left", {width=60, height=20})
            :align(display.CENTER, x, y)
            :addTo(self)
            :zorder(-799)
    end
end

function MainScene:removePlayStatus(left)
    local labelName
    if left == nil then labelName = 'play_status_me'
    elseif left then labelName = 'play_status_left'
    else labelName = 'play_status_right' end
    if self.rendered[labelName] then
        self.rendered[labelName]:hide()
    end
end


function MainScene:resetSceneLoggedin()
    local me = ddz.models.me
    self:showMyAvatar(me.sex == consts.sex.MALE)
    self.rendered.player_bean_count_label:setText(me.money)
    self.rendered.current_times_label:setText('000000')
    self.rendered.maingame_start_btn:show()
    self.rendered.maingame_ming_pai_btn:show()
    self:showToolBar()

    self:removeOkGesture()
    self:removeOkGesture(true)
    self:removeOkGesture(false)

    self:removeLoading()
    self:hideStatus()
    self:removeClock()

    self:removePlayer(true)
    self:removePlayer(false)
    self:removeNameAndMoney(true)
    self:removeNameAndMoney(false)

    self:removePlayStatus()
    self:removePlayStatus(true)
    self:removePlayStatus(false)

    self:removePlayerCards(true)
    self:removePlayerCards(false)
    self:removeMyCards()
    self:showLandlordCards()
    self.rendered.maingame_order_btn:hide()
    self.rendered.maingame_no_order_btn:hide()
    self.rendered.maingame_rob_btn:hide()
    self.rendered.maingame_no_rob_btn:hide()

    self:showOutCards(nil, nil)
    self:showOutCards(true, nil)
    self:showOutCards(false, nil)
    self.rendered.maingame_no_out_btn:hide()
    self.rendered.maingame_hint_btn:hide()
    self.rendered.maingame_out_card_btn:hide()

end

function MainScene:resetSceneWaitToStart()
    local me = ddz.models.me
    self:showMyAvatar(me.sex == consts.sex.MALE)
    self.rendered.player_bean_count_label:setText(me.money)
    self.rendered.current_times_label:setText('000000')
    self.rendered.maingame_start_btn:hide()
    self.rendered.maingame_ming_pai_btn:hide()
    self:showToolBar()

    self:removeLoading()
    self:hideStatus()
    self:removeClock()

    self:showPlayersStatusWaitToStart()

    self:removePlayStatus()
    self:removePlayStatus(true)
    self:removePlayStatus(false)

    self:removePlayerCards(true)
    self:removePlayerCards(false)
    self:removeMyCards()
    self:showLandlordCards()
    self.rendered.maingame_order_btn:hide()
    self.rendered.maingame_no_order_btn:hide()
    self.rendered.maingame_rob_btn:hide()
    self.rendered.maingame_no_rob_btn:hide()

    self:showOutCards(nil, nil)
    self:showOutCards(true, nil)
    self:showOutCards(false, nil)
    self.rendered.maingame_no_out_btn:hide()
    self.rendered.maingame_hint_btn:hide()
    self.rendered.maingame_out_card_btn:hide()

end

function MainScene:showPlayersStatusWaitToStart()
    local area = ddz.models.area
    local me = ddz.models.me
    self:removePlayer(true)
    self:removePlayer(false)
    for k,v in pairs(area.playerIds) do
        local left = me:isLeft(area.playerIds, v)
        if v and v ~= -1 and v ~= me.id then
            printInfo('playerId=%s, ddz.models.players=%s', v, json.encode(table.keys(ddz.models.players)))
            local player = ddz.models.players[v]
            self:addPlayer(left, player.sex == consts.sex.MALE)
            self:showNameAndMoney(left, player.name, player.money)
        end
        if v and v ~= -1 then
            printInfo('playerId=%s, ddz.models.areaPlayers=%s', v, json.encode(table.keys(ddz.models.areaPlayers)))
            local areaPlayer = ddz.models.areaPlayers[v]
            if areaPlayer.ready then
                self:showOkGesture(left)
            else
                self:removeOkGesture(left)
            end
        end
    end
    if area:playerCount() == 3 then
        self:showStatus('Waiting to start...')
    else
        self:showStatus('Waiting for others...')
    end
end


return MainScene
