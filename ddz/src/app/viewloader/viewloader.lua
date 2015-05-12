
local loader = {}

-- extend cc.Node to support viewconfig
local Node = cc.Node
function Node:setViewConfig(config)
    self._userdata = self._userdata or {}
    self._userdata.viewConfig = config
    return self
end

function Node:getViewConfig()
    self._userdata = self._userdata or {}
    return self._userdata.viewConfig
end

function Node:setRenderConfig(config)
    self._userdata = self._userdata or {}
    self._userdata.renderConfig = config
    return self
end

function Node:getRenderConfig()
    self._userdata = self._userdata or {}
    return self._userdata.renderConfig
end

function Node:addWithId(node, id)
    self._userdata = self._userdata or {}
    self._userdata.children = self._userdata.children or {}
    self._userdata.children[id] = node
    self:add(node)
    return self
end

function Node:addToWithId(node, id)
    node._userdata = node._userdata or {}
    node._userdata.children = node._userdata.children or {}
    node._userdata.children[id] = self
    node:add(self)
    return self
end

function Node:getChildById(id)
    self._userdata = self._userdata or {}
    self._userdata.children = self._userdata.children or {}
    return self._userdata.children[id]
end


local IMG_SCALE = 2
local SPRITE_SCALE = 1 / IMG_SCALE

local ViewLoader = class("ViewLoader")

ViewLoader.IMG_SCALE = IMG_SCALE
ViewLoader.SPRITE_SCALE = SPRITE_SCALE

function ViewLoader.img(imageName)
    return "textures/" .. imageName .. "_" .. IMG_SCALE .. "x.png"
end

function ViewLoader.font(fontName)
    return "fonts/" .. fontName .. ".ttf"
end

function ViewLoader.sprite(imageName, rect)
    local sharedTextureCache = cc.Director:getInstance():getTextureCache()
    local imgTexture = sharedTextureCache:addImage(ViewLoader.img(imageName))
    local rect = cc.rect(rect[1] * IMG_SCALE, rect[2] * IMG_SCALE, rect[3] * IMG_SCALE, rect[4] * IMG_SCALE)
    local sp = cc.Sprite:createWithTexture(imgTexture, rect)
    sp:setScale(SPRITE_SCALE, SPRITE_SCALE)
    return sp
end

function ViewLoader.spriteFrame(imageName, rect)
    local sharedTextureCache = cc.Director:getInstance():getTextureCache()
    local imgTexture = sharedTextureCache:addImage(ViewLoader.img(imageName))
    local rect = cc.rect(rect[1] * IMG_SCALE, rect[2] * IMG_SCALE, rect[3] * IMG_SCALE, rect[4] * IMG_SCALE)
    local sp = cc.SpriteFrame:createWithTexture(imgTexture, rect)
    return sp
end

function ViewLoader:ctor()
    self.views = {}
    self.commonViews = {}
end

function ViewLoader:loadCommonView(filename)
    filename = cc.FileUtils:getInstance():fullPathForFilename(filename)
    printInfo('load file: %s', filename)
    if self.commonViews[filename] then return self.commonViews[filename] end
    local config = json.decode(io.readfile(filename)).QUF
    config.sprites = {}
    if config.Fantasy and config.Fantasy.Sprite then
        for _,sprite in pairs(config.Fantasy.Sprite) do
            config.sprites[sprite.img] = config.sprites[sprite.img] or {}
            for __, mod in pairs(sprite.Module) do
                config.sprites[sprite.img][mod.desc] = mod
            end
        end
    end
    self.commonViews[filename] = config
    return config
end

function ViewLoader:loadView(filename)
    if self.views[filename] then
        return self.views[filename]
    end
    filename_ = cc.FileUtils:getInstance():fullPathForFilename(filename)
    local config = json.decode(io.readfile(filename_)).QUF
    config.sprites = {}
    if config.Fantasy and config.Fantasy.Sprite then
        for _,sprite in pairs(config.Fantasy.Sprite) do
            config.sprites[sprite.img] = config.sprites[sprite.img] or {}
            for __, mod in pairs(sprite.Module) do
                config.sprites[sprite.img][mod.desc] = mod
            end
        end
    end
    self.views[filename] = config
    return config
end

function ViewLoader:renderView(filename)
    local config = self:loadView(filename)
    local node = self:render_RootView(config.RootView, config)
    local rendered = {root_view=node}
    self:_renderView(node, config.RootView, config, rendered)
    --dump(table.keys(rendered))
    return node, rendered
end

function ViewLoader:_findRenderConfig(id, rootConfig)
    local config = rootConfig and rootConfig.Render and rootConfig.Render[id]
    if config then
        return config
    else
        for k,v in pairs(self.commonViews) do
            config = v.Render[id]
            if config then
                return config
            end
        end
    end
    printError('ViewLoader:_findRenderConfig render not found: %s', id)
    return nil
end

-- todo: refactor
function ViewLoader:render__(id, fileName)
    local config
    if fileName then
        config = self:loadView(fileName)
        return ViewLoader.renderRenderer(config.Render[id], config)
    end
    for k,v in pairs(self.commonViews) do
        config = v.Render and v.Render[id]
        if config then
            return ViewLoader.renderRenderer(config, self.commonViews[k])
        end
    end
    printError('ViewLoader:render id not found: %s', id)
    return nil
end

function ViewLoader:_spriteBySpriteConfig(spriteConfig, module, rect)
    if spriteConfig.Module[module] then
        return ViewLoader.sprite(spriteConfig.img, spriteConfig.Module[module].src)
    elseif spriteConfig.Frame[module] then
        local node = display.newNode()
        local keys = table.keys(spriteConfig.Frame[module].FModule)
        table.sort(keys)
        for _,fmoduleId in pairs(keys) do
            local fmodule = spriteConfig.Frame[module].FModule[fmoduleId]
            local sprite = ViewLoader.sprite(spriteConfig.img, spriteConfig.Module[fmodule.objid].src)
            if fmodule.flip == 'x' then
                sprite:setFlippedX(true)
            elseif fmodule.flip == 'y' then
                sprite:setFlippedY(true)
            end
            --printInfo('frame: %s, fmodule.dest: %s, rect: %s', spriteConfig.Frame[module].desc, json.encode(fmodule.dest), json.encode(rect))
            sprite:align(display.LEFT_TOP, fmodule.dest[1], rect[4] - fmodule.dest[2])
                :addTo(node)
        end
        return node
    end
end

function ViewLoader:spriteByDesc(img, desc, fileName)
    if fileName then
        local config = self:loadView(fileName)
        local mod = config.sprites[img][desc]
        if not mod then
            printInfo('spriteByDesc: img=%s, desc=%s, config.sprites=%s', img, desc, json.encode(mod))
        end
        return ViewLoader.sprite(img, mod.src)
    end
    for k,v in pairs(self.commonViews) do
        --printInfo('commonViews[%s]: %s', k, json.encode(v.sprites))
        local mod = v.sprites[img] and v.sprites[img][desc]
        if mod then
            return ViewLoader.sprite(img, mod.src)
        end
    end
    printError('ViewLoader:spriteByDesc desc not found: %s', desc)
    return nil
end

function ViewLoader:spriteById(id, module, fileName, rect)
    if fileName then
        local config = self:loadView(fileName)
        local spriteConfig = config.Fantasy.Sprite[id]
        return ViewLoader.sprite(spriteConfig.img, spriteConfig.Module[module].src)
    end
    for k,v in pairs(self.commonViews) do
        local spriteConfig = v.Fantasy and v.Fantasy.Sprite and v.Fantasy.Sprite[id]
        if spriteConfig then
            return self:_spriteBySpriteConfig(spriteConfig, module, rect)
        end
    end
    printError('ViewLoader:spriteById id not found: %s', id)
    return nil
end

function ViewLoader:spriteFrameById(id, module, fileName)
    if fileName then
        config = self:loadView(fileName)
        local spriteConfig = config.Fantasy.Sprite[id]
        return ViewLoader.spriteFrame(spriteConfig.img, spriteConfig.Module[module].src)
    end
    for k,v in pairs(self.commonViews) do
        spriteConfig = v.Fantasy and v.Fantasy.Sprite and v.Fantasy.Sprite[id]
        if spriteConfig then
            return ViewLoader.spriteFrame(spriteConfig.img, spriteConfig.Module[module].src)
        end
    end
    printError('ViewLoader:spriteById id not found: %s', id)
    return nil
end


-- render view
function ViewLoader:_renderView(parent, config, rootConfig, rendered)
    local panelTypes = {'TitlePanel', 'Label', 'ScrollTextView', 'TextButton', 'AvatarBtn'}
    for i,panelType in pairs(panelTypes) do
        if config[panelType] then
            for k,v in pairs(config[panelType]) do
                --printInfo('render %s: k=%s, v=', panelType, k)
                local node = ViewLoader['render_' .. panelType](self, parent, config, v, rootConfig, rendered)
                node:addTo(parent)
                if v.show == 'false' then
                    node:hide()
                end
                rendered[string.lower(k)] = node
            end
        end
    end
end

function ViewLoader:render_RootView(config, rootConfig)
    return display.newNode():setViewConfig(config)
end

function ViewLoader:render_Label(parent, parentConfig, config, rootConfig, rendered)
    local font, color = nil, nil
    if config.render then
        local renderConfig = self:_findRenderConfig(config.render, rootConfig)
        font = renderConfig.font
        color = renderConfig.color
    else
        font = config.font
        color = config.color
    end
    local opts = {
        text = config.id,
        color = cc.c3b(color[1], color[2], color[3]),
        dimensions = cc.size(config.rect[3], config.rect[4])
    }
    if font then
        opts.font = ViewLoader.font(font[2])
        opts.size = font[1]
    end

    --printInfo('config.viewalign: %s', config.viewalign)
    if config.viewalign == 'center' then
        opts.align = cc.TEXT_ALIGNMENT_CENTER
    elseif config.viewalign == 'right' then
        opts.align = cc.TEXT_ALIGNMENT_RIGHT
    else
        opts.align = cc.TEXT_ALIGNMENT_LEFT
        --printInfo('treat viewalign as left: ' .. (config.viewalign or ''))
    end
    local node = display.newTTFLabel(opts)
    node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    node:setContentSize(config.rect[3], config.rect[4])
    node:setViewConfig(config)
    return node
end

function ViewLoader:render_TitlePanel(parent, parentConfig, config, rootConfig, rendered)
    local node = nil
    if not config.render then
        --printInfo('render TitlePanel as node: %s', json.encode(config.rect))
        node = display.newNode()
    else
        local renderConfig = self:_findRenderConfig(config.render, rootConfig)
        node = self:renderRenderer(renderConfig, rootConfig, config.rect)
    end

    if parentConfig.rect then
        node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    else
        node:align(display.LEFT_BOTTOM, config.rect[1], config.rect[2])
    end
    node:setContentSize(config.rect[3], config.rect[4])
    node:setViewConfig(config)

    self:_renderView(node, config, rootConfig, rendered)
    return node
end

function ViewLoader:render_TextButton(parent, parentConfig, config, rootConfig, rendered)
    local renderConfig = self:_findRenderConfig(config.render, rootConfig)
    local node = self:renderRenderer(renderConfig, rootConfig, config.rect)
    node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    --printInfo('render_TextButton: id=%s, pos.x=%s, pos.y=%s', config.id, config.rect[1], parentConfig.rect[4] - config.rect[2])
    node:setContentSize(config.rect[3], config.rect[4])
    node:setViewConfig(config)
    self:_renderView(node, config, rootConfig, rendered)
    return node
end

function ViewLoader:render_AvatarBtn(parent, parentConfig, config, rootConfig, rendered)
    local node = display.newNode()
    node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    node:setContentSize(config.rect[3], config.rect[4])
    node:setViewConfig(config)
    self:_renderView(node, config, rootConfig, rendered)
    return node
end

function ViewLoader:render_ScrollTextView(parent, parentConfig, config, rootConfig, rendered)
    local node = cc.ui.UIScrollView.new()
    node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    node:setContentSize(config.rect[3], config.rect[4])
    node:setViewConfig(config)
    self:_renderView(node, config, rootConfig, rendered)
    return node
end


-- render renderer
function ViewLoader:renderRenderer(renderConfig, rootConfig, rect)
    local node, renderTypes = nil, {'FanGrid3Render', 'FanRender', 'FanGrid9Render', 'FanBtnRender'}
    if table.indexof(renderTypes, renderConfig.type) then
        node = ViewLoader['render_' .. renderConfig.type](self, renderConfig, rootConfig, rect)
    else
        printError('unsupported render type: %s, config: %s', renderConfig.type, json.encode(renderConfig))
    end
    return node
end

function ViewLoader:render_LabelRender(config, rootConfig, rect)
    local spriteConfig = rootConfig.Fantasy.Sprite[config.fantasy[2]]
    local moduleId = config.fantasy[4]
    return ViewLoader.sprite(spriteConfig.img, spriteConfig.Module[moduleId].src)
end

function ViewLoader:render_FanObj(config, rootConfig, rect)
    local spriteConfig = rootConfig.Fantasy.Sprite[config.fantasy[2]]
    if not spriteConfig then
         return self:spriteById(config.fantasy[2], config.fantasy[4], nil, rect)
    else
        local moduleId = config.fantasy[4]
        return self:_spriteBySpriteConfig(spriteConfig, moduleId, rect)
    end
end

function ViewLoader:render_FanRender(renderConfig, rootConfig, rect)
    return display.newNode()
        :add(self:render_FanObj(table.values(renderConfig.FanObj)[1], rootConfig, rect)
        :align(display.LEFT_BOTTOM, 0, 0))
        :setRenderConfig(renderConfig)
end

function ViewLoader:render_FanGrid3Render(renderConfig, rootConfig, rect)
    local node = display.newNode()
    for k,v in pairs(renderConfig.FanObj) do
        node:addWithId(self:render_FanObj(renderConfig.FanObj[k], rootConfig, rect), k)
    end
    node:align(display.LEFT_BOTTOM, 0, 0)
        :setRenderConfig(renderConfig)
    return node
end

function ViewLoader:render_FanGrid9Render(renderConfig, rootConfig, rect)
    local node = display.newNode()
    for k,v in pairs(renderConfig.FanObj) do
        node:addWithId(self:render_FanObj(renderConfig.FanObj[k], rootConfig, rect), k)
    end
    node:align(display.LEFT_BOTTOM, 0, 0)
        :setRenderConfig(renderConfig)
    return node
end

function ViewLoader:render_FanBtnRender(renderConfig, rootConfig, rect)
    local node = ddz.ui.UIPushButtonEx.new()
    for k,v in pairs(renderConfig.FanObj) do
        if string.sub(k, -1) == '0' or k == 'button' then
            node:setButtonImage(cc.ui.UIPushButton.NORMAL, {renderType = 'FanObj', args={renderConfig.FanObj[k], rootConfig, rect}})
        elseif string.sub(k, -1) == '1' or k == 'buttonpressed' then
            node:setButtonImage(cc.ui.UIPushButton.PRESSED, {renderType = 'FanObj', args={renderConfig.FanObj[k], rootConfig, rect}})
        elseif string.sub(k, -1) == '2' or k == 'buttondisabled' then
            node:setButtonImage(cc.ui.UIPushButton.DISABLED, {renderType = 'FanObj', args={renderConfig.FanObj[k], rootConfig, rect}})
        else
            printInfo('unsupported button image: %s', k)
        end
    end
    node:align(display.LEFT_BOTTOM, 0, 0)
        :setRenderConfig(renderConfig)
    return node
end

function ViewLoader.__render_FanGrid3Render(parent, parentConfig, config, rootConfig)
    if not parentConfig then
        printError('parentConfig must not be nil in render_FanGrid3Render')
    end
    local renderConfig = rootConfig.Render[config.render]
    local node = ddz.ui.UILoadingBar.new(
        self:render_FanObj(renderConfig.FanObj.FANOBJ_Render_Loading_bar_Left, rootConfig),
        self:render_FanObj(renderConfig.FanObj.FANOBJ_Render_Loading_bar_center, rootConfig),
        parentConfig.rect[3] - 2 * config.rect[1]
    )
    --printInfo('render_FanGrid3Render: parentConfig.rect=%s, config.rect=%s', json.encode(parentConfig.rect), json.encode(config.rect))
    node:align(display.LEFT_TOP, config.rect[1], parentConfig.rect[4] - config.rect[2])
    node:setContentSize(parentConfig.rect[3] - 2 * config.rect[1], config.rect[4])
    return node
end


local viewloader = ViewLoader.new()

return viewloader
