local theme = require("theme")
local Input = require("components.input")
local Select = require("components.select")
local love = require("love")

local TaskForm = {}
TaskForm.__index = TaskForm

local labelOptions = {
    { value = "Bug",           label = "Bug" },
    { value = "Feature",       label = "Feature" },
    { value = "Documentation", label = "Documentation" },
}

local statusOptions = {
    { value = "backlog",     label = "Backlog" },
    { value = "todo",        label = "Todo" },
    { value = "in_progress", label = "In Progress" },
    { value = "done",        label = "Done" },
    { value = "canceled",    label = "Canceled" },
}

local priorityOptions = {
    { value = "low",    label = "Low" },
    { value = "medium", label = "Medium" },
    { value = "high",   label = "High" },
}

function TaskForm.new(params)
    local self = setmetatable({}, TaskForm)
    self.onSave = params.onSave
    self.onCancel = params.onCancel
    self.visible = false
    self.mode = nil
    self.editTaskId = nil
    self.width = 500

    self.titleInput = Input.new({ placeholder = "Task title...", w = 452, h = 32 })
    self.descInput = Input.new({ placeholder = "Description...", w = 452, h = 80, multiline = true })
    self.labelSelect = Select.new({ options = labelOptions, placeholder = "Label", w = 452, h = 32 })
    self.statusSelect = Select.new({ options = statusOptions, placeholder = "Status", w = 452, h = 32 })
    self.prioritySelect = Select.new({ options = priorityOptions, placeholder = "Priority", w = 452, h = 32 })

    self._cardRect = nil
    return self
end

function TaskForm:openForCreate()
    self.mode = "create"
    self.editTaskId = nil
    self.visible = true
    self.titleInput:setText("")
    self.descInput:setText("")
    self.labelSelect:setValue("Feature")
    self.statusSelect:setValue("todo")
    self.prioritySelect:setValue("medium")
    self.labelSelect.open = false
    self.statusSelect.open = false
    self.prioritySelect.open = false
    self.titleInput:blur()
    self.descInput:blur()
end

function TaskForm:openForEdit(task)
    self.mode = "edit"
    self.editTaskId = task.id
    self.visible = true
    self.titleInput:setText(task.title)
    self.descInput:setText(task.description)
    self.labelSelect:setValue(task.label)
    self.statusSelect:setValue(task.status)
    self.prioritySelect:setValue(task.priority)
    self.labelSelect.open = false
    self.statusSelect.open = false
    self.prioritySelect.open = false
    self.titleInput:blur()
    self.descInput:blur()
end

function TaskForm:close()
    self.visible = false
    self.labelSelect.open = false
    self.statusSelect.open = false
    self.prioritySelect.open = false
    self.titleInput:blur()
    self.descInput:blur()
end

function TaskForm:isVisible()
    return self.visible
end

function TaskForm:_layoutFields(x, y, w)
    local padding = 24
    local fieldX = x + padding
    local fieldW = w - padding * 2
    local gap = 12
    local font = theme.fonts.body
    local labelH = theme.fontH.body + 4
    local fieldH = 32

    self.titleInput.w = fieldW
    self.descInput.w = fieldW
    self.labelSelect.w = fieldW
    self.statusSelect.w = fieldW
    self.prioritySelect.w = fieldW

    local headingFont = theme.fonts.heading
    local headerH = theme.fontH.heading + theme.fontH.body + 8

    -- Calculate fixed overhead (everything except description height)
    -- header + titleLabel + titleInput + descLabel + 3*(selectLabel+select) + gaps + footer + padding
    local fixedH = padding + headerH + 16
        + labelH + self.titleInput.h + gap -- title
        + labelH + gap                     -- desc label (desc height added separately)
        + (labelH + fieldH + gap) * 3      -- 3 selects
        - gap + 24 + 36 + padding          -- last gap replaced with 24 + footer + bottom padding

    -- Clamp description height so form fits in screen with 32px margin
    local sh = theme.screenH
    local maxDescH = sh - fixedH - 32
    if self.descInput.h > maxDescH then
        self.descInput.h = math.max(self.descInput.minH, maxDescH)
    end

    local fy = y + padding + headerH + 16

    self._titleLabelY = fy
    fy = fy + labelH
    self.titleInput.x = fieldX
    self.titleInput.y = fy
    fy = fy + self.titleInput.h + gap

    self._descLabelY = fy
    fy = fy + labelH
    self.descInput.x = fieldX
    self.descInput.y = fy
    fy = fy + self.descInput.h + gap

    self._labelLabelY = fy
    fy = fy + labelH
    self.labelSelect.x = fieldX
    self.labelSelect.y = fy
    fy = fy + fieldH + gap

    self._statusLabelY = fy
    fy = fy + labelH
    self.statusSelect.x = fieldX
    self.statusSelect.y = fy
    fy = fy + fieldH + gap

    self._priorityLabelY = fy
    fy = fy + labelH
    self.prioritySelect.x = fieldX
    self.prioritySelect.y = fy
    fy = fy + fieldH + 24

    self._footerY = fy
    local totalH = fy + 36 + padding - y
    return totalH
end

function TaskForm:draw()
    if not self.visible then return end

    local sw, sh = theme.screenW, theme.screenH
    local padding = 24
    local w = self.width
    local font = theme.fonts.body
    local headingFont = theme.fonts.heading

    local tempH = self:_layoutFields((sw - w) / 2, 0, w)
    local x = (sw - w) / 2
    local y = (sh - tempH) / 2
    local h = self:_layoutFields(x, y, w)

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

    -- Header
    love.graphics.setFont(headingFont)
    love.graphics.setColor(theme.colors.foreground)
    local title = self.mode == "create" and "Add Task" or "Edit Task"
    love.graphics.print(title, x + padding, y + padding)

    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.muted)
    local subtitle = self.mode == "create"
        and "Fill in the details for your new task."
        or "Update the task details below."
    love.graphics.print(subtitle, x + padding, y + padding + theme.fontH.heading + 4)

    -- Field labels
    love.graphics.setFont(font)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print("Title", x + padding, self._titleLabelY)
    love.graphics.print("Description", x + padding, self._descLabelY)
    love.graphics.print("Label", x + padding, self._labelLabelY)
    love.graphics.print("Status", x + padding, self._statusLabelY)
    love.graphics.print("Priority", x + padding, self._priorityLabelY)

    -- Fields
    self.titleInput:draw()
    self.descInput:draw()
    self.labelSelect:draw()
    self.statusSelect:draw()
    self.prioritySelect:draw()

    -- Footer buttons
    local btnH = 36
    local saveLabel = self.mode == "create" and "Create" or "Save"
    local saveW = theme.textWidth(font, saveLabel) + 32
    local cancelW = theme.textWidth(font, "Cancel") + 32

    self._cancelRect = {
        x = x + w - padding - saveW - 8 - cancelW,
        y = self._footerY,
        w = cancelW,
        h = btnH
    }
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("line", self._cancelRect.x, self._cancelRect.y,
        self._cancelRect.w, self._cancelRect.h, theme.radii.button, theme.radii.button)
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print("Cancel",
        self._cancelRect.x + (self._cancelRect.w - theme.textWidth(font, "Cancel")) / 2,
        self._cancelRect.y + (self._cancelRect.h - theme.fontH.body) / 2)

    self._saveRect = {
        x = x + w - padding - saveW,
        y = self._footerY,
        w = saveW,
        h = btnH
    }
    love.graphics.setColor(theme.colors.border)
    love.graphics.rectangle("fill", self._saveRect.x - 1, self._saveRect.y - 1,
        self._saveRect.w + 2, self._saveRect.h + 2, theme.radii.button, theme.radii.button)
    love.graphics.setColor(theme.colors.surface)
    love.graphics.rectangle("fill", self._saveRect.x, self._saveRect.y,
        self._saveRect.w, self._saveRect.h, theme.radii.button, theme.radii.button)
    love.graphics.setColor(theme.colors.background)
    love.graphics.print(saveLabel,
        self._saveRect.x + (self._saveRect.w - theme.textWidth(font, saveLabel)) / 2,
        self._saveRect.y + (self._saveRect.h - theme.fontH.body) / 2)

    -- Draw select overlays on top of everything (z-index fix)
    self.labelSelect:drawOverlay()
    self.statusSelect:drawOverlay()
    self.prioritySelect:drawOverlay()
end

function TaskForm:update(dt)
    if not self.visible then return end
    self.titleInput:update(dt)
    self.descInput:update(dt)
end

function TaskForm:mousepressed(mx, my, btn, pressCount)
    if not self.visible then return false end
    if btn ~= 1 then return false end

    -- Save button
    if self._saveRect then
        local r = self._saveRect
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            local data = {
                title = self.titleInput:getText(),
                description = self.descInput:getText(),
                label = self.labelSelect:getValue(),
                status = self.statusSelect:getValue(),
                priority = self.prioritySelect:getValue(),
            }
            if data.title ~= "" and self.onSave then
                if self.mode == "edit" then
                    data.id = self.editTaskId
                end
                self.onSave(data, self.mode)
                self:close()
            end
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
            self:close()
            return true
        end
    end

    -- Select dropdowns (check before inputs since they overlay)
    if self.prioritySelect:isOpen() then
        if self.prioritySelect:mousepressed(mx, my, btn) then return true end
    end
    if self.statusSelect:isOpen() then
        if self.statusSelect:mousepressed(mx, my, btn) then return true end
    end
    if self.labelSelect:isOpen() then
        if self.labelSelect:mousepressed(mx, my, btn) then return true end
    end

    -- Close all selects when clicking elsewhere in the form
    self.labelSelect.open = false
    self.statusSelect.open = false
    self.prioritySelect.open = false

    -- Selects (trigger click to open)
    if self.labelSelect:mousepressed(mx, my, btn) then
        self.titleInput:blur()
        self.descInput:blur()
        return true
    end
    if self.statusSelect:mousepressed(mx, my, btn) then
        self.titleInput:blur()
        self.descInput:blur()
        return true
    end
    if self.prioritySelect:mousepressed(mx, my, btn) then
        self.titleInput:blur()
        self.descInput:blur()
        return true
    end

    -- Text inputs
    local hitTitle = self.titleInput:mousepressed(mx, my, btn, pressCount)
    if hitTitle then
        self.descInput:blur()
        return true
    end
    local hitDesc = self.descInput:mousepressed(mx, my, btn, pressCount)
    if hitDesc then
        self.titleInput:blur()
        return true
    end

    -- Click inside card but not on any field
    self.titleInput:blur()
    self.descInput:blur()
    return true
end

function TaskForm:mousemoved(mx, my)
    if not self.visible then return end
    self.titleInput:mousemoved(mx, my)
    self.descInput:mousemoved(mx, my)
    self.labelSelect:mousemoved(mx, my)
    self.statusSelect:mousemoved(mx, my)
    self.prioritySelect:mousemoved(mx, my)
end

function TaskForm:mousereleased(mx, my, btn)
    if not self.visible then return end
    self.titleInput:mousereleased(mx, my, btn)
    self.descInput:mousereleased(mx, my, btn)
end

function TaskForm:keypressed(key, isRepeat)
    if not self.visible then return false end
    if key == "escape" then
        if self.labelSelect:isOpen() or self.statusSelect:isOpen() or self.prioritySelect:isOpen() then
            self.labelSelect.open = false
            self.statusSelect.open = false
            self.prioritySelect.open = false
            return true
        end
        self:close()
        return true
    end
    if self.titleInput:keypressed(key, isRepeat) then return true end
    if self.descInput:keypressed(key, isRepeat) then return true end
    if self.labelSelect:keypressed(key) then return true end
    if self.statusSelect:keypressed(key) then return true end
    if self.prioritySelect:keypressed(key) then return true end
    return true
end

function TaskForm:textinput(text)
    if not self.visible then return false end
    if self.titleInput:textinput(text) then return true end
    if self.descInput:textinput(text) then return true end
    return true
end

return TaskForm
