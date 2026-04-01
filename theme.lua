local theme = {}
local love = require("love")

theme.colors = {
    background    = { 0.035, 0.035, 0.043 }, -- zinc-950
    foreground    = { 0.980, 0.980, 0.980 }, -- zinc-50
    muted         = { 0.631, 0.631, 0.659 }, -- zinc-400
    border        = { 0.153, 0.153, 0.165 }, -- zinc-800
    hover         = { 0.110, 0.110, 0.118 }, -- zinc-900
    surface       = { 0.980, 0.980, 0.980 }, -- zinc-50
    surface_hover = { 0.957, 0.957, 0.961 }, -- zinc-100
}

theme.spacing = {
    base    = 8,
    padding = 32,
    cell    = 8,
    gap     = 16,
}

theme.radii = {
    card     = 8,
    badge    = 6,
    checkbox = 4,
    button   = 8,
}

theme.fonts = {}
theme.fontH = {}

local _widthCache = {}

function theme.textWidth(font, text)
    local fc = _widthCache[font]
    if not fc then
        fc = {}
        _widthCache[font] = fc
    end
    local w = fc[text]
    if not w then
        w = font:getWidth(text)
        fc[text] = w
    end
    return w
end

-- Cached screen dimensions -- updated in love.load and love.resize
theme.screenW = 1280
theme.screenH = 720

function theme.load()
    theme.fonts.body             = love.graphics.newFont(14)
    theme.fonts.heading          = love.graphics.newFont(24)
    theme.fonts.small            = love.graphics.newFont(12)
    theme.fonts.mono             = love.graphics.newFont(12)
    theme.fontH.body    = theme.fonts.body:getHeight()
    theme.fontH.heading = theme.fonts.heading:getHeight()
    theme.fontH.small   = theme.fonts.small:getHeight()
    theme.fontH.mono    = theme.fonts.mono:getHeight()
    _widthCache = {}
    theme.screenW, theme.screenH = love.graphics.getDimensions()
end

function theme.resize(w, h)
    theme.screenW = w
    theme.screenH = h
end

return theme
