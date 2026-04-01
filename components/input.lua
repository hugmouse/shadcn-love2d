local theme = require("theme")
local InputField = require("lib.InputField")
local love = require("love")

local Input = {}
Input.__index = Input

function Input.new(params)
    local self = setmetatable({}, Input)
    self.placeholder = params.placeholder or ""
    self.x = params.x or 0
    self.y = params.y or 0
    self.w = params.w or 240
    self.h = params.h or 32
    self.onChange = params.onChange
    self.focused = false
    self._padX = 12
    self._prevText = ""

    self.multiline = params.multiline or false
    self.minH = params.minH or self.h
    self._resizing = false
    self._resizeStartY = 0
    self._resizeStartH = 0
    self._resizeHandleSize = 12

    self.field = InputField("")
    self.field:setType(self.multiline and "multiwrap" or "normal")

    return self
end

function Input:_initField()
    if self._fieldReady then return end
    self.field:setFont(theme.fonts.body)
    self.field:setWidth(self.w - self._padX * 2)
    if self.multiline then
        self.field:setHeight(self.h - 12)
    end
    self._fieldReady = true
end

function Input:getText()
    return self.field:getText()
end

function Input:setText(text)
    self.field:setText(text)
    self._prevText = text
end

function Input:focus()
    self:_initField()
    self.focused = true
    self.field:resetBlinking()
    love.keyboard.setTextInput(true)
end

function Input:blur()
    self.focused = false
    love.keyboard.setTextInput(false)
end

function Input:isFocused()
    return self.focused
end

function Input:_checkChanged()
    local text = self.field:getText()
    if text ~= self._prevText then
        self._prevText = text
        if self.onChange then
            self.onChange(text)
        end
    end
end

function Input:_hitTest(mx, my)
    return mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + self.h
end

function Input:update(dt)
    if self.focused then
        self:_initField()
        love.keyboard.setTextInput(true)
        self.field:update(dt)
    end
end

function Input:draw()
    self:_initField()
    local r = theme.radii.button

    -- Background fill
    love.graphics.setColor(theme.colors.background)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, r, r)

    -- Border
    if self.focused then
        love.graphics.setColor(theme.colors.foreground)
    else
        love.graphics.setColor(theme.colors.border)
    end
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h, r, r)

    -- Clip text to field bounds
    local textX = self.x + self._padX
    local textY
    if self.multiline then
        textY = self.y + 6
    else
        textY = self.y + (self.h - theme.fontH.body) / 2
    end
    love.graphics.setScissor(self.x + 2, self.y + 2, self.w - 4, self.h - 4)

    if self.focused then
        -- Selection highlights
        love.graphics.setColor(0.3, 0.3, 0.5, 0.5)
        for _, sx, sy, sw, sh in self.field:eachSelection() do
            love.graphics.rectangle("fill", textX + sx, textY + sy, sw, sh)
        end

        -- Text
        love.graphics.setFont(theme.fonts.body)
        love.graphics.setColor(theme.colors.foreground)
        for _, text, tx, ty in self.field:eachVisibleLine() do
            love.graphics.print(text, textX + tx, textY + ty)
        end

        -- Cursor (blink)
        local phase = self.field:getBlinkPhase()
        if phase < 0.5 then
            local cx, cy, ch = self.field:getCursorLayout()
            love.graphics.setColor(theme.colors.foreground)
            love.graphics.rectangle("fill", textX + cx, textY + cy, 1, ch)
        end
    else
        -- Show placeholder or text
        local text = self.field:getText()
        love.graphics.setFont(theme.fonts.body)
        if text == "" then
            love.graphics.setColor(theme.colors.muted)
            love.graphics.print(self.placeholder, textX, textY)
        else
            love.graphics.setColor(theme.colors.foreground)
            if self.multiline then
                love.graphics.printf(text, textX, textY, self.w - self._padX * 2)
            else
                love.graphics.print(text, textX, textY)
            end
        end
    end

    love.graphics.setScissor()

    -- Resize grip for multiline
    if self.multiline then
        local gx = self.x + self.w - self._resizeHandleSize
        local gy = self.y + self.h - self._resizeHandleSize
        love.graphics.setColor(theme.colors.muted)
        love.graphics.setLineWidth(1)
        -- Draw diagonal grip lines
        for i = 0, 2 do
            local offset = i * 4
            love.graphics.line(
                gx + self._resizeHandleSize - 2 - offset, gy + self._resizeHandleSize - 2,
                gx + self._resizeHandleSize - 2, gy + self._resizeHandleSize - 2 - offset)
        end
    end
end

function Input:keypressed(key, isRepeat)
    if not self.focused then return false end
    if key == "escape" then
        self:blur()
        return true
    end
    self.field:keypressed(key, isRepeat)
    self:_checkChanged()
    return true
end

function Input:textinput(text)
    if not self.focused then return false end
    self.field:textinput(text)
    self:_checkChanged()
    return true
end

function Input:mousepressed(mx, my, btn, pressCount)
    -- Check resize handle first
    if self.multiline and btn == 1 then
        local gx = self.x + self.w - self._resizeHandleSize
        local gy = self.y + self.h - self._resizeHandleSize
        if mx >= gx and mx <= gx + self._resizeHandleSize
            and my >= gy and my <= gy + self._resizeHandleSize then
            self._resizing = true
            self._resizeStartY = my
            self._resizeStartH = self.h
            return true
        end
    end

    if not self:_hitTest(mx, my) then return false end
    self:focus()
    local relX = mx - self.x - self._padX
    local textY = self.multiline and 6 or (self.h - theme.fontH.body) / 2
    local relY = my - self.y - textY
    self.field:mousepressed(relX, relY, btn, pressCount or 1)
    return true
end

function Input:mousemoved(mx, my)
    if self._resizing then
        local newH = self._resizeStartH + (my - self._resizeStartY)
        self.h = math.max(self.minH, newH)
        self._fieldReady = false -- force re-init with new height
        return
    end
    if not self.focused then return end
    local relX = mx - self.x - self._padX
    local textY = self.multiline and 6 or (self.h - theme.fontH.body) / 2
    local relY = my - self.y - textY
    self.field:mousemoved(relX, relY)
end

function Input:mousereleased(mx, my, btn)
    if self._resizing then
        self._resizing = false
        return
    end
    if not self.focused then return end
    local relX = mx - self.x - self._padX
    local textY = self.multiline and 6 or (self.h - theme.fontH.body) / 2
    local relY = my - self.y - textY
    self.field:mousereleased(relX, relY, btn)
end

return Input
