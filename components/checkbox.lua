local theme = require("theme")
local love = require("love")
local lg = love.graphics

local Checkbox = {}
Checkbox.__index = Checkbox

function Checkbox.new(params)
    local self = setmetatable({}, Checkbox)
    self.x = params.x
    self.y = params.y
    self.size = 16
    self.checked = false
    self.onToggle = params.onToggle
    return self
end

function Checkbox:draw()
    local s = self.size
    local r = theme.radii.checkbox

    if self.checked then
        lg.setColor(theme.colors.foreground)
        lg.rectangle("fill", self.x, self.y, s, s, r, r)
        local prevLineWidth = lg.getLineWidth()
        lg.setColor(theme.colors.background)
        lg.setLineWidth(2)
        lg.line(
            self.x + 3, self.y + s / 2,
            self.x + 6, self.y + s / 2 + 3,
            self.x + s - 3, self.y + s / 2 - 3
        )
        lg.setLineWidth(prevLineWidth)
    else
        lg.setColor(theme.colors.border)
        lg.rectangle("fill", self.x, self.y, s, s, r, r)
        lg.setColor(theme.colors.background)
        lg.rectangle("fill", self.x + 1, self.y + 1, s - 2, s - 2, r, r)
    end
end

function Checkbox:hitTest(mx, my)
    return mx >= self.x and mx <= self.x + self.size
        and my >= self.y and my <= self.y + self.size
end

function Checkbox:mousepressed(mx, my, button)
    if button == 1 and self:hitTest(mx, my) then
        self.checked = not self.checked
        if self.onToggle then
            self.onToggle(self.checked)
        end
        return true
    end
    return false
end

return Checkbox
