local love = require("love")
local theme = require("theme")
local Icon = require("components.icon")

local isMobile = love.system.getOS() == "iOS" or love.system.getOS() == "Android"

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(params)
    local self = setmetatable({}, Dropdown)
    self.options = params.options
    self.width = params.width
    self.onSelect = params.onSelect
    self.visible = false
    self.anchorX = 0
    self.anchorY = 0
    self.selected = {}
    self.searchText = ""
    self.hoveredIndex = nil
    self.searchRowH = 36
    self.optionH = 32
    return self
end

function Dropdown:open(x, y)
    self.anchorX = x
    self.anchorY = y
    self.searchText = ""
    self.hoveredIndex = nil
    self.visible = true
    love.keyboard.setTextInput(true)
end

function Dropdown:close()
    self.visible = false
    love.keyboard.setTextInput(false)
end

function Dropdown:isVisible()
    return self.visible
end

function Dropdown:getSelected()
    local result = {}
    for value in pairs(self.selected) do
        result[#result + 1] = value
    end
    return result
end

function Dropdown:setOptions(options)
    self.options = options
end

function Dropdown:_visibleOptions()
    if self.searchText == "" then
        return self.options
    end
    local lower = self.searchText:lower()
    local result = {}
    for _, opt in ipairs(self.options) do
        if opt.label:lower():find(lower, 1, true) then
            result[#result + 1] = opt
        end
    end
    return result
end

function Dropdown:_totalHeight(visibleOpts)
    return self.searchRowH + #visibleOpts * self.optionH
end

function Dropdown:_cardRect(visibleOpts)
    local h = self:_totalHeight(visibleOpts)
    return self.anchorX, self.anchorY, self.width, h
end

function Dropdown:update()
    if self.visible and not isMobile then
        love.keyboard.setTextInput(true) -- per-frame for macOS IME
    end
end

function Dropdown:draw()
    if not self.visible then return end

    local opts = self:_visibleOptions()
    local cx, cy, cw, ch = self:_cardRect(opts)
    local r = theme.radii.card
    local font = theme.fonts.body
    local smallFont = theme.fonts.small

    -- Card border
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", cx - 1, cy - 1, cw + 2, ch + 2, r, r)

    -- Card face
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", cx, cy, cw, ch, r, r)

    -- Search row
    local searchY = cy
    Icon.draw("search", cx + 8, searchY + (self.searchRowH - 16) / 2, 16, theme.colors.muted)

    love.graphics.setFont(font)
    if self.searchText == "" then
        love.graphics.setColor(theme.colors.muted)
        love.graphics.print("Search...", cx + 30, searchY + (self.searchRowH - theme.fontH.body) / 2)
    else
        love.graphics.setColor(theme.colors.foreground)
        love.graphics.print(self.searchText, cx + 30, searchY + (self.searchRowH - theme.fontH.body) / 2)
    end

    -- Separator below search
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", cx, searchY + self.searchRowH - 1, cw, 1)

    -- Options
    for i, opt in ipairs(opts) do
        local oy = cy + self.searchRowH + (i - 1) * self.optionH

        -- Hover highlight
        if self.hoveredIndex == i then
            love.graphics.setColor(theme.colors.hover)
            love.graphics.rectangle("fill", cx + 4, oy + 2, cw - 8, self.optionH - 4, 4, 4)
        end

        local ix = cx + 8

        -- Checkbox
        local cbSize = 16
        local cbY = oy + (self.optionH - cbSize) / 2
        if self.selected[opt.value] then
            love.graphics.setColor(theme.colors.foreground)
            love.graphics.rectangle("fill", ix, cbY, cbSize, cbSize, 3, 3)
            love.graphics.setColor(theme.colors.background)
            love.graphics.setLineWidth(2)
            love.graphics.line(ix + 3, cbY + cbSize / 2,
                ix + 6, cbY + cbSize / 2 + 3,
                ix + cbSize - 3, cbY + cbSize / 2 - 3)
            love.graphics.setLineWidth(1)
        else
            love.graphics.setColor(theme.colors.border)
            love.graphics.rectangle("fill", ix, cbY, cbSize, cbSize, 3, 3)
            love.graphics.setColor(theme.colors.background)
            love.graphics.rectangle("fill", ix + 1, cbY + 1, cbSize - 2, cbSize - 2, 3, 3)
        end
        ix = ix + cbSize + 8

        -- Icon
        if opt.icon then
            Icon.draw(opt.icon, ix, oy + (self.optionH - 16) / 2, 16, theme.colors.muted)
            ix = ix + 22
        end

        -- Label
        love.graphics.setFont(font)
        love.graphics.setColor(theme.colors.foreground)
        love.graphics.print(opt.label, ix, oy + (self.optionH - theme.fontH.body) / 2)

        -- Count (right aligned)
        if opt.count then
            love.graphics.setFont(smallFont)
            love.graphics.setColor(theme.colors.muted)
            local countStr = tostring(opt.count)
            local countW = theme.textWidth(smallFont, countStr)
            love.graphics.print(countStr, cx + cw - 12 - countW,
                oy + (self.optionH - theme.fontH.small) / 2)
        end
    end
end

function Dropdown:mousepressed(mx, my, btn)
    if not self.visible then return false end
    if btn ~= 1 then return false end

    local opts = self:_visibleOptions()
    local cx, cy, cw, ch = self:_cardRect(opts)

    -- Outside click
    if mx < cx or mx > cx + cw or my < cy or my > cy + ch then
        self:close()
        return true
    end

    -- Option click
    local optionsY = cy + self.searchRowH
    if my >= optionsY then
        local idx = math.floor((my - optionsY) / self.optionH) + 1
        if idx >= 1 and idx <= #opts then
            local value = opts[idx].value
            if self.selected[value] then
                self.selected[value] = nil
            else
                self.selected[value] = true
            end
            if self.onSelect then
                self.onSelect(self:getSelected())
            end
        end
    end

    return true
end

function Dropdown:mousemoved(mx, my)
    if not self.visible then return end

    local opts = self:_visibleOptions()
    local cx, cy, cw, ch = self:_cardRect(opts)
    local optionsY = cy + self.searchRowH

    if mx >= cx and mx <= cx + cw and my >= optionsY and my <= cy + ch then
        local idx = math.floor((my - optionsY) / self.optionH) + 1
        if idx >= 1 and idx <= #opts then
            self.hoveredIndex = idx
        else
            self.hoveredIndex = nil
        end
    else
        self.hoveredIndex = nil
    end
end

function Dropdown:keypressed(key)
    if not self.visible then return false end
    if key == "escape" then
        self:close()
        return true
    end
    if key == "backspace" then
        if #self.searchText > 0 then
            self.searchText = self.searchText:sub(1, #self.searchText - 1)
        end
        return true
    end
    return true
end

function Dropdown:textinput(text)
    if not self.visible then return false end
    self.searchText = self.searchText .. text
    return true
end

return Dropdown
