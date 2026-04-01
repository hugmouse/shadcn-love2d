local theme = require("theme")
local Icon = require("components.icon")
local love = require("love")

local Select = {}
Select.__index = Select

function Select.new(params)
    local self = setmetatable({}, Select)
    self.options = params.options
    self.value = params.value
    self.placeholder = params.placeholder or "Select..."
    self.x = params.x or 0
    self.y = params.y or 0
    self.w = params.w or 200
    self.h = params.h or 32
    self.onChange = params.onChange
    self.open = false
    self.hoveredIndex = nil
    self.optionH = 32
    self.dropUp = params.dropUp or false
    return self
end

function Select:getValue()
    return self.value
end

function Select:setValue(v)
    self.value = v
end

function Select:isOpen()
    return self.open
end

function Select:_getLabel()
    for _, opt in ipairs(self.options) do
        if opt.value == self.value then
            return opt.label
        end
    end
    return self.placeholder
end

function Select:_dropdownHeight()
    return #self.options * self.optionH
end

function Select:_triggerRect()
    return self.x, self.y, self.w, self.h
end

function Select:_dropdownRect()
    local dh = self:_dropdownHeight()
    if self.dropUp then
        return self.x, self.y - dh - 4, self.w, dh
    end
    return self.x, self.y + self.h + 4, self.w, dh
end

function Select:draw()
    local r = theme.radii.button
    local font = theme.fonts.body
    love.graphics.setFont(font)

    -- Trigger background
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, r, r)

    -- Trigger border
    if self.open then
        love.graphics.setColor(theme.colors.foreground)
    else
        love.graphics.setColor(theme.colors.border)
    end
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, r, r)

    -- Label text
    local label = self:_getLabel()
    if self.value then
        love.graphics.setColor(theme.colors.foreground)
    else
        love.graphics.setColor(theme.colors.muted)
    end
    love.graphics.print(label, self.x + 12,
        self.y + (self.h - theme.fontH.body) / 2)

    -- Chevron
    Icon.draw("chevron-down", self.x + self.w - 24,
        self.y + (self.h - 12) / 2, 12, theme.colors.muted)
end

function Select:drawOverlay()
    if not self.open then return end

    local font = theme.fonts.body
    love.graphics.setFont(font)
    local dx, dy, dw, dh = self:_dropdownRect()
    local cr = theme.radii.card

    -- Card border
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", dx - 1, dy - 1, dw + 2, dh + 2, cr, cr)

    -- Card face
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", dx, dy, dw, dh, cr, cr)

    for i, opt in ipairs(self.options) do
        local oy = dy + (i - 1) * self.optionH

        -- Hover
        if self.hoveredIndex == i then
            love.graphics.setColor(theme.colors.hover)
            love.graphics.rectangle("fill", dx + 4, oy + 2, dw - 8, self.optionH - 4, 4, 4)
        end

        -- Check icon for selected
        if opt.value == self.value then
            Icon.draw("check", dx + 8, oy + (self.optionH - 16) / 2, 16, theme.colors.foreground)
        end

        -- Label
        love.graphics.setFont(font)
        love.graphics.setColor(theme.colors.foreground)
        love.graphics.print(opt.label, dx + 30,
            oy + (self.optionH - theme.fontH.body) / 2)
    end
end

function Select:mousepressed(mx, my, btn)
    if btn ~= 1 then return false end

    local tx, ty, tw, th = self:_triggerRect()

    -- If dropdown is open
    if self.open then
        local dx, dy, dw, dh = self:_dropdownRect()

        -- Click inside dropdown
        if mx >= dx and mx <= dx + dw and my >= dy and my <= dy + dh then
            local idx = math.floor((my - dy) / self.optionH) + 1
            if idx >= 1 and idx <= #self.options then
                self.value = self.options[idx].value
                self.open = false
                if self.onChange then
                    self.onChange(self.value)
                end
            end
            return true
        end

        -- Click on trigger (toggle close)
        if mx >= tx and mx <= tx + tw and my >= ty and my <= ty + th then
            self.open = false
            return true
        end

        -- Click outside
        self.open = false
        return false
    end

    -- Click on trigger (open)
    if mx >= tx and mx <= tx + tw and my >= ty and my <= ty + th then
        self.open = true
        return true
    end

    return false
end

function Select:mousemoved(mx, my)
    if not self.open then return end

    local dx, dy, dw, dh = self:_dropdownRect()
    if mx >= dx and mx <= dx + dw and my >= dy and my <= dy + dh then
        local idx = math.floor((my - dy) / self.optionH) + 1
        if idx >= 1 and idx <= #self.options then
            self.hoveredIndex = idx
        else
            self.hoveredIndex = nil
        end
    else
        self.hoveredIndex = nil
    end
end

function Select:keypressed(key)
    if not self.open then return false end
    if key == "escape" then
        self.open = false
        return true
    end
    return false
end

return Select
