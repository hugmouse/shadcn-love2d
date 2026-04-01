local theme = require("theme")
local love = require("love")

local lg = love.graphics

local Badge = {}

function Badge.draw(text, x, y)
    local font = theme.fonts.small
    lg.setFont(font)

    local textW = font:getWidth(text)
    local textH = font:getHeight()
    local px, py = 8, 2
    local w = textW + px * 2
    local h = textH + py * 2

    -- Border
    lg.setColor(theme.colors.border)
    lg.rectangle("fill", x, y, w, h, theme.radii.badge, theme.radii.badge)

    -- Face
    lg.setColor(theme.colors.background)
    lg.rectangle("fill", x + 1, y + 1, w - 2, h - 2, theme.radii.badge, theme.radii.badge)

    -- Text
    lg.setColor(theme.colors.foreground)
    lg.print(text, x + px, y + py)

    return w, h
end

function Badge.getSize(text)
    local font = theme.fonts.small
    return font:getWidth(text) + 16, font:getHeight() + 4
end

return Badge
