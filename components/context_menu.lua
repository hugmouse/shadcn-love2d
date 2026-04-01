local love = require("love")
local theme = require("theme")
local Icon = require("components.icon")

local ContextMenu = {}
ContextMenu.__index = ContextMenu

function ContextMenu.new(params)
    local self = setmetatable({}, ContextMenu)
    self.items = params.items
    self.width = params.width
    self.visible = false
    self.anchorX = 0
    self.anchorY = 0
    self.task = nil
    self.hoveredIndex = nil
    self.itemH = 32
    self.separatorH = 9
    self.padding = 4
    return self
end

function ContextMenu:open(x, y, task)
    self.anchorX = x
    self.anchorY = y
    self.task = task
    self.hoveredIndex = nil
    self:_updateLayout()
    self.visible = true
end

function ContextMenu:close()
    self.visible = false
    self.task = nil
end

function ContextMenu:isVisible()
    return self.visible
end

function ContextMenu:_updateLayout()
    local h = self.padding * 2
    for _, item in ipairs(self.items) do
        if item.type == "separator" then
            h = h + self.separatorH
        else
            h = h + self.itemH
        end
    end

    local sw, sh = theme.screenW, theme.screenH
    -- Anchor from right edge to prevent horizontal overflow
    local x = self.anchorX - self.width
    if x + self.width > sw - 8 then x = sw - self.width - 8 end
    if x < 8 then x = 8 end
    -- Flip upward if would overflow bottom
    local y = self.anchorY
    if y + h > sh - 8 then
        y = self.anchorY - h
    end
    if y < 8 then y = 8 end

    self.cx, self.cy, self.cw, self.ch = x, y, self.width, h

    self.itemY = {}
    local iy = y + self.padding
    for i, item in ipairs(self.items) do
        self.itemY[i] = iy
        if item.type == "separator" then
            iy = iy + self.separatorH
        else
            iy = iy + self.itemH
        end
    end
end

function ContextMenu:_itemAtY(my)
    for i, item in ipairs(self.items) do
        local iy = self.itemY[i]
        local h = (item.type == "separator") and self.separatorH or self.itemH
        if my >= iy and my < iy + h then
            return i
        end
    end
    return nil
end

function ContextMenu:draw()
    if not self.visible then return end

    local cx, cy, cw, ch = self.cx, self.cy, self.cw, self.ch
    local r = theme.radii.card
    local font = theme.fonts.body

    -- Card border
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", cx - 1, cy - 1, cw + 2, ch + 2, r, r)

    -- Card face
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", cx, cy, cw, ch, r, r)

    -- Hover Backgrounds
    if self.hoveredIndex then
        local i = self.hoveredIndex
        local item = self.items[i]
        if item and item.type ~= "separator" then
            love.graphics.setColor(theme.colors.hover)
            love.graphics.rectangle("fill", cx + self.padding, self.itemY[i],
                cw - self.padding * 2, self.itemH, 4, 4)
        end
    end

    -- Group draw calls by state to maximize LOVE2D auto-batching
    -- Separators
    love.graphics.setColor(theme.colors.border)
    for i, item in ipairs(self.items) do
        if item.type == "separator" then
            love.graphics.rectangle("fill", cx + 4, self.itemY[i] + 4, cw - 8, 1)
        end
    end

    -- Icons
    for i, item in ipairs(self.items) do
        if item.type ~= "separator" and item.icon then
            local labelX = cx + self.padding + 8
            Icon.draw(item.icon, labelX, self.itemY[i] + (self.itemH - 16) / 2, 16, theme.colors.muted)
        end
    end

    -- Normal Text
    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.foreground)
    for i, item in ipairs(self.items) do
        if item.type ~= "separator" and item.variant ~= "destructive" then
            local labelX = cx + self.padding + 8
            if item.icon then labelX = labelX + 22 end
            love.graphics.print(item.label, labelX, self.itemY[i] + (self.itemH - theme.fontH.body) / 2)
        end
    end

    -- Destructive Text
    love.graphics.setColor(0.9, 0.3, 0.3)
    for i, item in ipairs(self.items) do
        if item.type ~= "separator" and item.variant == "destructive" then
            local labelX = cx + self.padding + 8
            if item.icon then labelX = labelX + 22 end
            love.graphics.print(item.label, labelX, self.itemY[i] + (self.itemH - theme.fontH.body) / 2)
        end
    end
end

function ContextMenu:mousepressed(mx, my, btn)
    if not self.visible then return false end
    if btn ~= 1 then return false end

    local cx, cy, cw, ch = self.cx, self.cy, self.cw, self.ch

    -- Outside click
    if mx < cx or mx > cx + cw or my < cy or my > cy + ch then
        self:close()
        return true
    end

    -- Item click
    local idx = self:_itemAtY(my)
    if idx then
        local item = self.items[idx]
        if item.type ~= "separator" and item.action then
            item.action(self.task)
        end
        self:close()
    end

    return true
end

function ContextMenu:mousemoved(mx, my)
    if not self.visible then return end

    local cx, cy, cw, ch = self.cx, self.cy, self.cw, self.ch
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
        local idx = self:_itemAtY(my)
        if idx and self.items[idx].type ~= "separator" then
            self.hoveredIndex = idx
        else
            self.hoveredIndex = nil
        end
    else
        self.hoveredIndex = nil
    end
end

function ContextMenu:keypressed(key)
    if not self.visible then return false end
    if key == "escape" then
        self:close()
        return true
    end
    return true
end

return ContextMenu
