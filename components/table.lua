local theme = require("theme")
local Icon = require("components.icon")
local Badge = require("components.badge")
local Checkbox = require("components.checkbox")
local love = require("love")

local lg = love.graphics
local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

local DataTable = {}
DataTable.__index = DataTable

local statusIcons = {
    backlog     = "question-circle",
    todo        = "circle",
    in_progress = "timer",
    done        = "check-circle",
    canceled    = "circle-slash",
}

local statusLabels = {
    backlog     = "Backlog",
    todo        = "Todo",
    in_progress = "In Progress",
    done        = "Done",
    canceled    = "Canceled",
}

local priorityIcons = {
    low    = "arrow-down",
    medium = "arrow-right",
    high   = "arrow-up",
}

local priorityLabels = {
    low    = "Low",
    medium = "Medium",
    high   = "High",
}

function DataTable.new(params)
    local self = setmetatable({}, DataTable)
    self.x = params.x
    self.y = params.y
    self.w = params.w
    self.h = params.h
    self.tasks = params.tasks
    self.onRowClick = params.onRowClick
    self.onEllipsisClick = params.onEllipsisClick
    self.onSort = params.onSort
    self.onHeaderClick = params.onHeaderClick

    self.rowHeight = 44
    self.headerHeight = 40
    self.hoveredRow = nil
    self.scrollY = 0
    self.sortColumn = nil    -- "task" | "title" | "status" | "priority"
    self.sortDirection = nil -- "asc" | "desc"

    self.columns = {
        { id = "checkbox", width = 40 },
        { id = "task",     width = 90 },
        { id = "title",    width = self.w - 410 },
        { id = "status",   width = 130 },
        { id = "priority", width = 110 },
        { id = "actions",  width = 40 },
    }

    self.headerCheckbox = Checkbox.new({ x = 0, y = 0 })
    self.rowCheckboxes = {}
    for i = 1, #self.tasks do
        self.rowCheckboxes[i] = Checkbox.new({ x = 0, y = 0 })
    end

    self.headerCheckbox.onToggle = function(checked)
        for _, cb in ipairs(self.rowCheckboxes) do
            cb.checked = checked
        end
    end

    self:_initColPositions()

    return self
end

function DataTable:resize(w, h)
    self.w = w
    self.h = h
    -- Recalculate flexible title column
    for _, col in ipairs(self.columns) do
        if col.id == "title" then
            col.width = self.w - 410
        end
    end
    -- Invalidate title cache since column widths changed
    self._titleCache = nil
    self:_initColPositions()
end

function DataTable:_initColPositions()
    self._cellX = {}
    self._colStart = {}
    local cx = self.x
    for _, col in ipairs(self.columns) do
        self._colStart[col.id] = cx
        self._cellX[col.id] = cx + theme.spacing.cell
        cx = cx + col.width
    end
    for _, col in ipairs(self.columns) do
        if col.id == "title" then
            self._titleColWidth = col.width
            break
        end
    end
end

function DataTable:setTasks(tasks)
    self.tasks = tasks
    self.hoveredRow = nil
    self.scrollY = 0
    self._titleCache = nil
    self.headerCheckbox.checked = false
    self.rowCheckboxes = {}
    for i = 1, #self.tasks do
        self.rowCheckboxes[i] = Checkbox.new({ x = 0, y = 0 })
    end
end

function DataTable:getSelectedCount()
    local count = 0
    for _, cb in ipairs(self.rowCheckboxes) do
        if cb.checked then count = count + 1 end
    end
    return count
end

function DataTable:update(dt)
    local mx, my = love.mouse.getPosition()
    local bodyY = self.y + self.headerHeight

    if mx >= self.x and mx <= self.x + self.w
        and my >= bodyY and my <= self.y + self.h then
        local relY = my - bodyY + self.scrollY
        local row = floor(relY / self.rowHeight) + 1
        if row >= 1 and row <= #self.tasks then
            self.hoveredRow = row
        else
            self.hoveredRow = nil
        end
    else
        self.hoveredRow = nil
    end
end

function DataTable:draw()
    local font = theme.fonts.body
    lg.setFont(font)

    lg.setColor(theme.colors.border)
    lg.rectangle("line", self.x, self.y, self.w, self.h,
        theme.radii.card, theme.radii.card)

    self:_drawHeader(font)

    local bodyY = self.y + self.headerHeight
    local bodyH = self.h - self.headerHeight
    lg.setScissor(self.x, bodyY, self.w, bodyH)

    -- Collect visible rows
    local visible = {}
    local rh = self.rowHeight
    for i, task in ipairs(self.tasks) do
        local rowY = bodyY + (i - 1) * rh - self.scrollY
        if rowY + rh > bodyY and rowY < bodyY + bodyH then
            visible[#visible + 1] = { i, task, rowY }
        end
    end

    if #visible > 0 then
        local cx = self._cellX
        local colStart = self._colStart
        local h = rh
        local cellPad = theme.spacing.cell
        local cellYOff = (h - theme.fontH.body) / 2
        local iconYOff = (h - 16) / 2
        local badgeFont = theme.fonts.small
        local badgeRad = theme.radii.badge
        local cbRad = theme.radii.checkbox
        local colBorder = theme.colors.border
        local colBg = theme.colors.background
        local colFg = theme.colors.foreground
        local colMuted = theme.colors.muted
        local colHover = theme.colors.hover
        local tableX = self.x
        local tableW = self.w

        -- Pass 1: All rectangle("fill") draws — batches into minimal GPU draw calls
        if not self._ellipsisRects then self._ellipsisRects = {} end
        for _, row in ipairs(visible) do
            local idx, task, y = row[1], row[2], row[3]
            if self.hoveredRow == idx then
                lg.setColor(colHover)
                lg.rectangle("fill", tableX + 1, y, tableW - 2, h)
            end
            lg.setColor(colBorder)
            lg.rectangle("fill", tableX, y + h - 1, tableW, 1)
            local cb = self.rowCheckboxes[idx]
            cb.x = cx.checkbox
            cb.y = y + iconYOff
            if cb.checked then
                lg.setColor(colFg)
                lg.rectangle("fill", cb.x, cb.y, 16, 16, cbRad, cbRad)
            else
                lg.setColor(colBorder)
                lg.rectangle("fill", cb.x, cb.y, 16, 16, cbRad, cbRad)
                lg.setColor(colBg)
                lg.rectangle("fill", cb.x + 1, cb.y + 1, 14, 14, cbRad, cbRad)
            end
            local bw = badgeFont:getWidth(task.label) + 16
            local bh = badgeFont:getHeight() + 4
            local by = y + (h - bh) / 2
            lg.setColor(colBorder)
            lg.rectangle("fill", cx.title, by, bw, bh, badgeRad, badgeRad)
            lg.setColor(colBg)
            lg.rectangle("fill", cx.title + 1, by + 1, bw - 2, bh - 2, badgeRad, badgeRad)
            self._ellipsisRects[idx] = { x = colStart.actions, y = y, w = 40, h = h }
        end

        -- Pass 2a: Badge text (small font atlas)
        lg.setFont(badgeFont)
        lg.setColor(colFg)
        for _, row in ipairs(visible) do
            local bh = badgeFont:getHeight() + 4
            lg.print(row[2].label, cx.title + 8, row[3] + (h - bh) / 2 + 2)
        end

        -- Pass 2b: Body text (body font atlas)
        lg.setFont(font)
        if not self._titleCache then self._titleCache = {} end
        local titleColW = self._titleColWidth
        for _, row in ipairs(visible) do
            local task, y = row[2], row[3]
            local cellY = y + cellYOff
            lg.setColor(colMuted)
            lg.print(task.id, cx.task, cellY)
            local bw = badgeFont:getWidth(task.label) + 16
            local titleX = cx.title + bw + 8
            local maxW = titleColW - bw - cellPad * 2 - 8
            local cacheKey = task.id .. "_title"
            if not self._titleCache[cacheKey] then
                local title = task.title
                if font:getWidth(title) > maxW then
                    local lo, hi = 1, #title
                    while lo < hi do
                        local mid = ceil((lo + hi) / 2)
                        if font:getWidth(title:sub(1, mid) .. "...") <= maxW then
                            lo = mid
                        else
                            hi = mid - 1
                        end
                    end
                    title = title:sub(1, lo) .. "..."
                end
                self._titleCache[cacheKey] = title
            end
            lg.setColor(colFg)
            lg.print(self._titleCache[cacheKey], titleX, cellY)
            lg.print(statusLabels[task.status] or task.status, cx.status + 22, cellY)
            lg.print(priorityLabels[task.priority] or task.priority, cx.priority + 22, cellY)
        end

        -- Pass 3: Icons (lines, circles, arcs)
        for _, row in ipairs(visible) do
            local idx, task, y = row[1], row[2], row[3]
            local iconY = y + iconYOff
            if self.rowCheckboxes[idx].checked then
                local cb = self.rowCheckboxes[idx]
                local prevLW = lg.getLineWidth()
                lg.setColor(colBg)
                lg.setLineWidth(2)
                lg.line(cb.x + 3, cb.y + 8, cb.x + 6, cb.y + 11, cb.x + 13, cb.y + 5)
                lg.setLineWidth(prevLW)
            end
            local si = statusIcons[task.status]
            if si then Icon.draw(si, cx.status, iconY, 16, colMuted) end
            local pi = priorityIcons[task.priority]
            if pi then Icon.draw(pi, cx.priority, iconY, 16, colMuted) end
            Icon.draw("ellipsis", cx.actions, iconY, 16, colMuted)
        end
    end

    lg.setScissor()
end

local sortableColumns = { task = "Task", title = "Title", status = "Status", priority = "Priority" }

function DataTable:_drawHeader(font)
    local y = self.y
    local h = self.headerHeight
    local cx = self._cellX
    local colStart = self._colStart
    local colBorder = theme.colors.border
    local colBg = theme.colors.background
    local colFg = theme.colors.foreground
    local colMuted = theme.colors.muted
    local cbRad = theme.radii.checkbox
    local iconYOff = (h - 16) / 2
    local cellY = y + (h - theme.fontH.body) / 2
    self._headerRects = {}

    -- Pass 1: All fills (border + checkbox)
    lg.setColor(colBorder)
    lg.rectangle("fill", self.x, y + h - 1, self.w, 1)
    local cb = self.headerCheckbox
    cb.x = cx.checkbox
    cb.y = y + iconYOff
    if cb.checked then
        lg.setColor(colFg)
        lg.rectangle("fill", cb.x, cb.y, 16, 16, cbRad, cbRad)
    else
        lg.setColor(colBorder)
        lg.rectangle("fill", cb.x, cb.y, 16, 16, cbRad, cbRad)
        lg.setColor(colBg)
        lg.rectangle("fill", cb.x + 1, cb.y + 1, 14, 14, cbRad, cbRad)
    end

    -- Pass 2: All text (column labels)
    lg.setFont(font)
    lg.setColor(colFg)
    for _, col in ipairs(self.columns) do
        if sortableColumns[col.id] then
            lg.print(sortableColumns[col.id], cx[col.id], cellY)
            self._headerRects[col.id] = { x = colStart[col.id], y = y, w = col.width, h = h }
        end
    end

    -- Pass 3: All icons (sort indicators + checkbox checkmark)
    for _, col in ipairs(self.columns) do
        if col.id == "checkbox" then
            if cb.checked then
                local prevLW = lg.getLineWidth()
                lg.setColor(colBg)
                lg.setLineWidth(2)
                lg.line(cb.x + 3, cb.y + 8, cb.x + 6, cb.y + 11, cb.x + 13, cb.y + 5)
                lg.setLineWidth(prevLW)
            end
        elseif sortableColumns[col.id] then
            local labelW = theme.textWidth(font, sortableColumns[col.id])
            local iconName = "chevrons-up-down"
            if self.sortColumn == col.id then
                iconName = self.sortDirection == "asc" and "chevron-up" or "chevron-down"
            end
            Icon.draw(iconName, cx[col.id] + labelW + 4, y + (h - 12) / 2, 12, colMuted)
        end
    end
end

function DataTable:mousepressed(mx, my, button)
    if button ~= 1 then return false end

    -- Header column click
    if self._headerRects then
        for colId, rect in pairs(self._headerRects) do
            if mx >= rect.x and mx <= rect.x + rect.w
                and my >= rect.y and my <= rect.y + rect.h then
                if self.onHeaderClick then
                    self.onHeaderClick(colId, rect.x, rect.y + rect.h)
                end
                return true
            end
        end
    end

    if self.headerCheckbox:mousepressed(mx, my, button) then
        return true
    end

    for i, cb in ipairs(self.rowCheckboxes) do
        if cb:mousepressed(mx, my, button) then
            return true
        end
    end

    -- Ellipsis click (takes priority over row click)
    if self.hoveredRow and self.onEllipsisClick and self._ellipsisRects then
        local er = self._ellipsisRects[self.hoveredRow]
        if er and mx >= er.x and mx <= er.x + er.w and my >= er.y and my <= er.y + er.h then
            local task = self.tasks[self.hoveredRow]
            self.onEllipsisClick(task, er.x, er.y + er.h)
            return true
        end
    end

    if self.hoveredRow and self.onRowClick then
        self.onRowClick(self.tasks[self.hoveredRow])
        return true
    end

    return false
end

function DataTable:wheelmoved(x, y)
    local maxScroll = max(0,
        #self.tasks * self.rowHeight - (self.h - self.headerHeight))
    self.scrollY = max(0, min(maxScroll, self.scrollY - y * 30))
end

return DataTable
