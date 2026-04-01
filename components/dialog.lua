local theme = require("theme")
local Badge = require("components.badge")
local love = require("love")

local Dialog = {}
Dialog.__index = Dialog

local statusLabels = {
    backlog = "Backlog",
    todo = "Todo",
    in_progress = "In Progress",
    done = "Done",
    canceled = "Canceled",
}

local priorityLabels = {
    low = "Low", medium = "Medium", high = "High",
}

function Dialog.new()
    local self = setmetatable({}, Dialog)
    self.visible = false
    self.task = nil
    self.width = 500
    self._closeRect = nil
    self._cardRect = nil
    return self
end

function Dialog:open(task)
    self.task = task
    self.visible = true
end

function Dialog:close()
    self.visible = false
    self.task = nil
end

function Dialog:draw()
    if not self.visible or not self.task then return end

    local sw, sh = theme.screenW, theme.screenH
    local task = self.task
    local padding = 24
    local w = self.width

    -- Measure description for height calc
    local bodyFont = theme.fonts.body
    local headingFont = theme.fonts.heading
    local descW = w - padding * 2
    local _, descLines = bodyFont:getWrap(task.description, descW)
    local descH = #descLines * theme.fontH.body

    local _, titleLines = headingFont:getWrap(task.title, descW)
    local titleH = #titleLines * theme.fontH.heading

    local h = padding + 20 + titleH + 12 + theme.fontH.body + 16 + descH + padding

    local x = (sw - w) / 2
    local y = (sh - h) / 2

    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, sw, sh)

    -- Card border
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2,
        theme.radii.card, theme.radii.card)

    -- Card face
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", x, y, w, h, theme.radii.card, theme.radii.card)

    -- Close X
    local closeX = x + w - padding - 12
    local closeY = y + padding
    local prevLineWidth = love.graphics.getLineWidth()
    love.graphics.setColor(theme.colors.muted)
    love.graphics.setLineWidth(2)
    love.graphics.line(closeX, closeY, closeX + 12, closeY + 12)
    love.graphics.line(closeX + 12, closeY, closeX, closeY + 12)
    love.graphics.setLineWidth(prevLineWidth)

    self._closeRect = { x = closeX - 4, y = closeY - 4, w = 20, h = 20 }
    self._cardRect = { x = x, y = y, w = w, h = h }

    -- Task ID + Badge
    love.graphics.setFont(theme.fonts.small)
    love.graphics.setColor(theme.colors.muted)
    love.graphics.print(task.id, x + padding, y + padding)
    local idW = theme.textWidth(theme.fonts.small, task.id)
    Badge.draw(task.label, x + padding + idW + 8, y + padding - 2)

    -- Title
    local titleY = y + padding + 24
    love.graphics.setFont(headingFont)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.printf(task.title, x + padding, titleY, descW)

    -- Status + Priority line
    local metaY = titleY + titleH + 8
    love.graphics.setFont(bodyFont)
    love.graphics.setColor(theme.colors.muted)
    local statusText = (statusLabels[task.status] or task.status)
        .. "  /  " .. (priorityLabels[task.priority] or task.priority)
    love.graphics.print(statusText, x + padding, metaY)

    -- Description
    local descY = metaY + theme.fontH.body + 16
    love.graphics.setColor(theme.colors.muted)
    love.graphics.printf(task.description, x + padding, descY, descW)
end

function Dialog:mousepressed(mx, my, button)
    if not self.visible then return false end
    if button ~= 1 then return false end

    -- Close button
    if self._closeRect then
        local r = self._closeRect
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            self:close()
            return true
        end
    end

    -- Backdrop click
    if self._cardRect then
        local c = self._cardRect
        if mx < c.x or mx > c.x + c.w or my < c.y or my > c.y + c.h then
            self:close()
            return true
        end
    end

    return true
end

function Dialog:keypressed(key)
    if not self.visible then return false end
    if key == "escape" then
        self:close()
        return true
    end
    return false
end

return Dialog
