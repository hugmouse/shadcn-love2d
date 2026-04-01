local theme = require("theme")
local Icon = require("components.icon")
local love = require("love")

local Button = {}
Button.__index = Button

local function drawDashedRect(x, y, w, h, r, dashLen, gapLen)
    dashLen = dashLen or 6
    gapLen = gapLen or 4
    local step = dashLen + gapLen

    -- Top edge
    local startX = x + r
    local endX = x + w - r
    local cx = startX
    while cx < endX do
        local dx = math.min(dashLen, endX - cx)
        love.graphics.line(cx, y, cx + dx, y)
        cx = cx + step
    end

    -- Bottom edge
    cx = startX
    while cx < endX do
        local dx = math.min(dashLen, endX - cx)
        love.graphics.line(cx, y + h, cx + dx, y + h)
        cx = cx + step
    end

    -- Left edge
    local startY = y + r
    local endY = y + h - r
    local cy = startY
    while cy < endY do
        local dy = math.min(dashLen, endY - cy)
        love.graphics.line(x, cy, x, cy + dy)
        cy = cy + step
    end

    -- Right edge
    cy = startY
    while cy < endY do
        local dy = math.min(dashLen, endY - cy)
        love.graphics.line(x + w, cy, x + w, cy + dy)
        cy = cy + step
    end

    -- Corners (solid arcs)
    local segments = 8
    love.graphics.arc("line", "open", x + r, y + r, r, math.pi, math.pi * 1.5, segments)
    love.graphics.arc("line", "open", x + w - r, y + r, r, -math.pi * 0.5, 0, segments)
    love.graphics.arc("line", "open", x + w - r, y + h - r, r, 0, math.pi * 0.5, segments)
    love.graphics.arc("line", "open", x + r, y + h - r, r, math.pi * 0.5, math.pi, segments)
end

function Button.new(params)
    local self = setmetatable({}, Button)
    self.text = params.text
    self.icon = params.icon
    self.variant = params.variant or "default"
    self.size = params.size or "default"
    self.x = params.x or 0
    self.y = params.y or 0
    self.onClick = params.onClick
    self.dashed = params.dashed or false
    self.hovered = false

    if self.size == "icon" then
        self.w = 32
        self.h = 32
    else
        self.h = self.size == "sm" and 32 or 36
        self.w = self:_computeWidth()
    end

    return self
end

function Button:_computeWidth()
    local font = theme.fonts.body
    self._textW = self.text and font:getWidth(self.text) or 0
    local iconW = self.icon and 20 or 0
    local px = self.size == "sm" and 12 or 16
    return self._textW + iconW + px * 2
end

function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hovered = mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + self.h
end

function Button:draw()
    local r = theme.radii.button

    if self.variant == "default" then
        love.graphics.setColor(theme.colors.border)
        love.graphics.rectangle("fill", self.x - 1, self.y - 1,
            self.w + 2, self.h + 2, r, r)
        if self.hovered then
            love.graphics.setColor(theme.colors.surface_hover)
        else
            love.graphics.setColor(theme.colors.surface)
        end
        love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, r, r)
    elseif self.variant == "outline" then
        love.graphics.setColor(theme.colors.border)
        if self.dashed then
            drawDashedRect(self.x, self.y, self.w, self.h, r)
        else
            love.graphics.rectangle("line", self.x, self.y, self.w, self.h, r, r)
        end
        if self.hovered then
            love.graphics.setColor(theme.colors.hover)
            love.graphics.rectangle("fill", self.x + 1, self.y + 1,
                self.w - 2, self.h - 2, r, r)
        end
    elseif self.variant == "ghost" then
        if self.hovered then
            love.graphics.setColor(theme.colors.hover)
            love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, r, r)
        end
    end

    local font = theme.fonts.body
    love.graphics.setFont(font)

    local contentW = 0
    if self.icon and self.text then
        contentW = 16 + 4 + self._textW
    elseif self.icon then
        contentW = 16
    elseif self.text then
        contentW = self._textW
    end

    local contentX = self.x + (self.w - contentW) / 2
    local iconY = self.y + (self.h - 16) / 2
    local textY = self.y + (self.h - theme.fontH.body) / 2

    local isDark = self.variant == "default"

    if self.icon then
        local iconColor = isDark and theme.colors.background or theme.colors.foreground
        Icon.draw(self.icon, contentX, iconY, 16, iconColor)
        contentX = contentX + 20
    end

    if self.text then
        if isDark then
            love.graphics.setColor(theme.colors.background)
        else
            love.graphics.setColor(theme.colors.foreground)
        end
        love.graphics.print(self.text, contentX, textY)
    end
end

function Button:mousepressed(mx, my, button)
    if button == 1 and self.hovered then
        if self.onClick then self.onClick() end
        return true
    end
    return false
end

return Button
