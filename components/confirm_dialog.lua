local theme = require("theme")
local love = require("love")

local ConfirmDialog = {}
ConfirmDialog.__index = ConfirmDialog

function ConfirmDialog.new(params)
    local self = setmetatable({}, ConfirmDialog)
    self.title = params.title or "Are you sure?"
    self.description = params.description or ""
    self.confirmLabel = params.confirmLabel or "Confirm"
    self.onConfirm = params.onConfirm
    self.onCancel = params.onCancel
    self.visible = false
    self.width = 400
    self._cardRect = nil
    self._cancelBtn = nil
    self._confirmBtn = nil
    return self
end

function ConfirmDialog:open()
    self.visible = true
end

function ConfirmDialog:close()
    self.visible = false
end

function ConfirmDialog:isVisible()
    return self.visible
end

function ConfirmDialog:draw()
    if not self.visible then return end

    local sw, sh = theme.screenW, theme.screenH
    local padding = 24
    local w = self.width
    local font = theme.fonts.body
    local headingFont = theme.fonts.heading
    local descW = w - padding * 2

    -- Measure content
    local titleH = theme.fontH.heading
    local _, descLines = font:getWrap(self.description, descW)
    local descH = #descLines * theme.fontH.body
    local footerH = 36
    local h = padding + titleH + 12 + descH + 24 + footerH + padding

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

    self._cardRect = { x = x, y = y, w = w, h = h }

    -- Title
    love.graphics.setFont(headingFont)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print(self.title, x + padding, y + padding)

    -- Description
    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.muted)
    love.graphics.printf(self.description, x + padding, y + padding + titleH + 12, descW)

    -- Footer buttons
    local footerY = y + h - padding - footerH

    -- Create buttons each frame with correct positions
    local confirmW = theme.textWidth(font, self.confirmLabel) + 32
    local cancelW = theme.textWidth(font, "Cancel") + 32

    -- Cancel (right-aligned, left of confirm)
    self._cancelRect = {
        x = x + w - padding - confirmW - 8 - cancelW,
        y = footerY,
        w = cancelW,
        h = footerH
    }
    -- Outline style
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("line", self._cancelRect.x, self._cancelRect.y,
        self._cancelRect.w, self._cancelRect.h, theme.radii.button, theme.radii.button)
    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print("Cancel",
        self._cancelRect.x + (self._cancelRect.w - theme.textWidth(font, "Cancel")) / 2,
        self._cancelRect.y + (self._cancelRect.h - theme.fontH.body) / 2)

    -- Confirm (right-aligned, destructive red)
    self._confirmRect = {
        x = x + w - padding - confirmW,
        y = footerY,
        w = confirmW,
        h = footerH
    }
    love.graphics.setColor(0.9, 0.3, 0.3)
    love.graphics.rectangle("fill", self._confirmRect.x, self._confirmRect.y,
        self._confirmRect.w, self._confirmRect.h,
        theme.radii.button, theme.radii.button)
    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print(self.confirmLabel,
        self._confirmRect.x + (self._confirmRect.w - theme.textWidth(font, self.confirmLabel)) / 2,
        self._confirmRect.y + (self._confirmRect.h - theme.fontH.body) / 2)
end

function ConfirmDialog:mousepressed(mx, my, btn)
    if not self.visible then return false end
    if btn ~= 1 then return false end

    -- Confirm button
    if self._confirmRect then
        local r = self._confirmRect
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            if self.onConfirm then self.onConfirm() end
            self:close()
            return true
        end
    end

    -- Cancel button
    if self._cancelRect then
        local r = self._cancelRect
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            if self.onCancel then self.onCancel() end
            self:close()
            return true
        end
    end

    -- Backdrop click
    if self._cardRect then
        local c = self._cardRect
        if mx < c.x or mx > c.x + c.w or my < c.y or my > c.y + c.h then
            if self.onCancel then self.onCancel() end
            self:close()
            return true
        end
    end

    return true
end

function ConfirmDialog:keypressed(key)
    if not self.visible then return false end
    if key == "escape" then
        if self.onCancel then self.onCancel() end
        self:close()
        return true
    end
    return true
end

return ConfirmDialog
