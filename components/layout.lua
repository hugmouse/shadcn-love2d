local theme = require("theme")
local love = require("love")

local Layout = {}

function Layout.header(title, subtitle, x, y)
    love.graphics.setFont(theme.fonts.heading)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print(title, x, y)

    local titleH = theme.fontH.heading

    love.graphics.setFont(theme.fonts.body)
    love.graphics.setColor(theme.colors.muted)
    love.graphics.print(subtitle, x, y + titleH + 4)

    return titleH + 4 + theme.fontH.body
end

function Layout.footer(text, x, y)
    love.graphics.setFont(theme.fonts.body)
    love.graphics.setColor(theme.colors.muted)
    love.graphics.print(text, x, y)
end

return Layout
