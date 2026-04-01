local love = require("love")
local theme = require("theme")
local Layout = require("components.layout")
local Input = require("components.input")
local Toolbar = require("components.toolbar")
local Button = require("components.button")
local DataTable = require("components.table")
local Dialog = require("components.dialog")
local Dropdown = require("components.dropdown")
local ContextMenu = require("components.context_menu")
local Store = require("data.store")
local TaskForm = require("components.task_form")
local ConfirmDialog = require("components.confirm_dialog")
local Pagination = require("components.pagination")
require("lib.batteries"):export()

local screen = {}

local screenW, screenH
local dataTable, dialog, toolbar, filterInput
local statusDropdown, priorityDropdown, contextMenu, headerMenu
local statusButton, priorityButton
local filterText = ""
local sortColumn, sortDirection
local taskForm, confirmDialog
local deleteTargetId = nil
local pagination
local filteredTasks = {}
local bgCanvas = nil

local function countByField(field)
    local counts = {}
    for _, task in ipairs(Store.getTasks()) do
        local val = task[field]
        counts[val] = (counts[val] or 0) + 1
    end
    return counts
end

local statusOptions = {
    { value = "backlog",     label = "Backlog",     icon = "question-circle" },
    { value = "todo",        label = "Todo",        icon = "circle" },
    { value = "in_progress", label = "In Progress", icon = "timer" },
    { value = "done",        label = "Done",        icon = "check-circle" },
    { value = "canceled",    label = "Canceled",    icon = "circle-slash" },
}

local priorityOptions = {
    { value = "low",    label = "Low",    icon = "arrow-down" },
    { value = "medium", label = "Medium", icon = "arrow-right" },
    { value = "high",   label = "High",   icon = "arrow-up" },
}

local function refreshOptionCounts()
    local sc = countByField("status")
    for _, opt in ipairs(statusOptions) do
        opt.count = sc[opt.value] or 0
    end
    local pc = countByField("priority")
    for _, opt in ipairs(priorityOptions) do
        opt.count = pc[opt.value] or 0
    end
end

local function applyFilters()
    local filtered = {}
    local statusSel = statusDropdown.selected
    local prioritySel = priorityDropdown.selected
    local hasStatusFilter = next(statusSel) ~= nil
    local hasPriorityFilter = next(prioritySel) ~= nil
    local hasTextFilter = filterText ~= ""
    local lower = hasTextFilter and filterText:lower() or ""

    for _, task in ipairs(Store.getTasks()) do
        local pass = true
        if hasTextFilter then
            if not (task.title:lower():find(lower, 1, true)
                    or task.id:lower():find(lower, 1, true)
                    or task.label:lower():find(lower, 1, true)) then
                pass = false
            end
        end
        if pass and hasStatusFilter and not statusSel[task.status] then
            pass = false
        end
        if pass and hasPriorityFilter and not prioritySel[task.priority] then
            pass = false
        end
        if pass then
            filtered[#filtered + 1] = task
        end
    end
    -- Apply sorting
    if sortColumn and sortDirection then
        local fieldMap = { task = "id", title = "title", status = "status", priority = "priority" }
        local field = fieldMap[sortColumn]
        local asc = sortDirection == "asc"
        local ordinals = {
            priority = { low = 1, medium = 2, high = 3 },
            status = { backlog = 1, todo = 2, in_progress = 3, done = 4, canceled = 5 },
        }
        local ordinal = ordinals[field]
        table.stable_sort(filtered, function(a, b)
            local va, vb
            if ordinal then
                va, vb = ordinal[a[field]] or 0, ordinal[b[field]] or 0
            else
                va, vb = a[field] or "", b[field] or ""
            end
            if asc then
                return va < vb
            else
                return va > vb
            end
        end)
    end

    filteredTasks = filtered

    if pagination then
        pagination:setTotalItems(#filteredTasks)
        pagination:setSelectedCount(dataTable:getSelectedCount())
        dataTable:setTasks(pagination:getPageSlice(filteredTasks))
    else
        dataTable:setTasks(filteredTasks)
    end
end

local function applyPage()
    if pagination then
        pagination:setSelectedCount(dataTable:getSelectedCount())
        dataTable:setTasks(pagination:getPageSlice(filteredTasks))
    end
end

local function closeAllPopups()
    if statusDropdown then statusDropdown:close() end
    if priorityDropdown then priorityDropdown:close() end
    if contextMenu then contextMenu:close() end
    if headerMenu then headerMenu:close() end
end

local function refreshAll()
    refreshOptionCounts()
    applyFilters()
end

function screen.load()
    love.graphics.setBackgroundColor(theme.colors.background)
    theme.load()
    Store.load()

    screenW, screenH = love.graphics.getDimensions()

    local padding = theme.spacing.padding
    local tableW = screenW - padding * 2
    local tableY = 140
    local tableH = screenH - 64 - tableY

    refreshOptionCounts()

    statusDropdown = Dropdown.new({
        options = statusOptions,
        width = 200,
        onSelect = function()
            if pagination then pagination.page = 1 end
            applyFilters()
        end,
    })

    priorityDropdown = Dropdown.new({
        options = priorityOptions,
        width = 200,
        onSelect = function()
            if pagination then pagination.page = 1 end
            applyFilters()
        end,
    })

    contextMenu = ContextMenu.new({
        items = {
            {
                label = "Edit",
                icon = "circle",
                action = function(task)
                    closeAllPopups()
                    taskForm:openForEdit(task)
                end
            },
            {
                label = "Make a copy",
                action = function(task)
                    Store.copyTask(task.id)
                    refreshAll()
                end
            },
            { label = "Favorite", action = function(task) end },
            { type = "separator" },
            {
                label = "Delete",
                action = function(task)
                    closeAllPopups()
                    deleteTargetId = task.id
                    confirmDialog:open()
                end,
                variant = "destructive"
            },
        },
        width = 160,
    })

    local function setSortAndApply(col, dir)
        sortColumn = col
        sortDirection = dir
        dataTable.sortColumn = col
        dataTable.sortDirection = dir
        if pagination then pagination.page = 1 end
        applyFilters()
    end

    headerMenu = ContextMenu.new({
        items = {
            {
                label = "Asc",
                icon = "arrow-up",
                action = function()
                    setSortAndApply(headerMenu._colId, "asc")
                end
            },
            {
                label = "Desc",
                icon = "arrow-down",
                action = function()
                    setSortAndApply(headerMenu._colId, "desc")
                end
            },
            { type = "separator" },
            { label = "Hide",    icon = "eye-off", action = function() end },
        },
        width = 150,
    })

    dataTable = DataTable.new({
        x = padding,
        y = tableY,
        w = tableW,
        h = tableH,
        tasks = Store.getTasks(),
        onRowClick = function(task)
            closeAllPopups()
            dialog:open(task)
        end,
        onEllipsisClick = function(task, x, y)
            closeAllPopups()
            contextMenu:open(x, y, task)
        end,
        onHeaderClick = function(colId, x, y)
            closeAllPopups()
            headerMenu._colId = colId
            headerMenu:open(x, y)
        end,
    })

    dialog = Dialog.new()

    taskForm = TaskForm.new({
        onSave = function(data, mode)
            if mode == "create" then
                Store.addTask(data)
            else
                Store.updateTask(data.id, data)
            end
            refreshAll()
        end,
    })

    confirmDialog = ConfirmDialog.new({
        title = "Are you sure?",
        description = "This action cannot be undone. This will permanently delete this task.",
        confirmLabel = "Delete",
        onConfirm = function()
            if deleteTargetId then
                Store.deleteTask(deleteTargetId)
                deleteTargetId = nil
                refreshAll()
            end
        end,
    })

    filterInput = Input.new({
        placeholder = "Filter tasks...",
        w = 240,
        h = 32,
        onChange = function(text)
            filterText = text
            if pagination then pagination.page = 1 end
            applyFilters()
        end,
    })

    statusButton = Button.new({
        text = "Status",
        icon = "plus-circle",
        variant = "outline",
        size = "sm",
        dashed = true,
        onClick = function()
            if statusDropdown:isVisible() then
                statusDropdown:close()
            else
                closeAllPopups()
                statusDropdown:open(statusButton.x, statusButton.y + statusButton.h + 4)
            end
        end,
    })

    priorityButton = Button.new({
        text = "Priority",
        icon = "plus-circle",
        variant = "outline",
        size = "sm",
        dashed = true,
        onClick = function()
            if priorityDropdown:isVisible() then
                priorityDropdown:close()
            else
                closeAllPopups()
                priorityDropdown:open(priorityButton.x, priorityButton.y + priorityButton.h + 4)
            end
        end,
    })

    local addTaskButton = Button.new({
        text = "Add Task",
        variant = "default",
        size = "sm",
        onClick = function()
            closeAllPopups()
            taskForm:openForCreate()
        end,
    })

    toolbar = Toolbar.new({
        left = { filterInput, statusButton, priorityButton },
        right = { addTaskButton },
        x = padding,
        y = 94,
        w = tableW,
    })

    pagination = Pagination.new({
        x = padding,
        y = screenH - 48,
        w = tableW,
        totalItems = #Store.getTasks(),
        selectedCount = 0,
        rowsPerPageOptions = { 25, 50, 100 },
        defaultRowsPerPage = 25,
        onPageChange = function(page, rowsPerPage)
            applyPage()
        end,
    })

    -- Apply initial pagination
    applyFilters()
end

function screen.update(dt)
    pagination:setSelectedCount(dataTable:getSelectedCount())

    if confirmDialog:isVisible() then return end
    if taskForm:isVisible() then
        taskForm:update(dt)
        return
    end
    if not dialog.visible then
        dataTable:update(dt)
        toolbar:update(dt)
        statusDropdown:update(dt)
        priorityDropdown:update(dt)
        pagination:update(dt)
    end
end

local function drawBackground()
    local padding = theme.spacing.padding

    Layout.header("Welcome back!",
        "Here's a list of your tasks.", padding, 32)

    toolbar:draw()
    dataTable:draw()
    pagination:draw()

    if statusDropdown:isVisible() then statusDropdown:draw() end
    if priorityDropdown:isVisible() then priorityDropdown:draw() end
    if contextMenu:isVisible() then contextMenu:draw() end
    if headerMenu:isVisible() then headerMenu:draw() end

    pagination:drawOverlay()
end

function screen.draw()
    local modalVisible = dialog.visible or taskForm:isVisible() or confirmDialog:isVisible()

    if modalVisible then
        if not bgCanvas then
            bgCanvas = love.graphics.newCanvas()
            love.graphics.setCanvas(bgCanvas)
            love.graphics.clear(theme.colors.background[1],
                theme.colors.background[2],
                theme.colors.background[3], 1)
            drawBackground()
            love.graphics.setCanvas()
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(bgCanvas)
    else
        bgCanvas = nil
        drawBackground()
    end

    -- Modal overlays (topmost, always drawn)
    if dialog.visible then dialog:draw() end
    if taskForm:isVisible() then taskForm:draw() end
    if confirmDialog:isVisible() then confirmDialog:draw() end
end

function screen.mousepressed(x, y, button, pressCount)
    if confirmDialog:mousepressed(x, y, button) then return end
    if taskForm:mousepressed(x, y, button, pressCount) then return end
    if dialog:mousepressed(x, y, button) then return end

    -- Popups get priority
    if statusDropdown:mousepressed(x, y, button) then return end
    if priorityDropdown:mousepressed(x, y, button) then return end
    if contextMenu:mousepressed(x, y, button) then return end
    if headerMenu:mousepressed(x, y, button) then return end

    -- Focus management: blur input if click lands outside it
    if filterInput:isFocused() then
        local hitInput = (x >= filterInput.x and x <= filterInput.x + filterInput.w
            and y >= filterInput.y and y <= filterInput.y + filterInput.h)
        if not hitInput then
            filterInput:blur()
        end
    end

    toolbar:mousepressed(x, y, button, pressCount)
    if pagination:mousepressed(x, y, button) then return end
    dataTable:mousepressed(x, y, button)
end

function screen.keypressed(key, scancode, isRepeat)
    if confirmDialog:keypressed(key) then return end
    if taskForm:keypressed(key, isRepeat) then return end
    if dialog:keypressed(key) then return end
    if statusDropdown:keypressed(key) then return end
    if priorityDropdown:keypressed(key) then return end
    if contextMenu:keypressed(key) then return end
    if headerMenu:keypressed(key) then return end
    if pagination:keypressed(key) then return end
    if toolbar:keypressed(key, isRepeat) then return end
end

function screen.resize(w, h)
    bgCanvas = nil
    screenW, screenH = w, h
    theme.resize(w, h)
    local padding = theme.spacing.padding
    local tableW = screenW - padding * 2
    local tableH = screenH - 64 - 140
    dataTable:resize(tableW, tableH)
    toolbar:resize(tableW)
    pagination.y = screenH - 48
    pagination.w = tableW
end

function screen.wheelmoved(x, y)
    if not dialog.visible then
        dataTable:wheelmoved(x, y)
    end
end

function screen.textinput(text)
    if confirmDialog:isVisible() then return end
    if taskForm:textinput(text) then return end
    if dialog.visible then return end
    if statusDropdown:textinput(text) then return end
    if priorityDropdown:textinput(text) then return end
    toolbar:textinput(text)
end

function screen.mousemoved(x, y)
    if confirmDialog:isVisible() then return end
    if taskForm:isVisible() then
        taskForm:mousemoved(x, y)
        return
    end
    if dialog.visible then return end
    statusDropdown:mousemoved(x, y)
    priorityDropdown:mousemoved(x, y)
    contextMenu:mousemoved(x, y)
    headerMenu:mousemoved(x, y)
    pagination:mousemoved(x, y)
    toolbar:mousemoved(x, y)
end

function screen.mousereleased(x, y, button)
    if confirmDialog:isVisible() then return end
    if taskForm:isVisible() then
        taskForm:mousereleased(x, y, button)
        return
    end
    if dialog.visible then return end
    toolbar:mousereleased(x, y, button)
end

return screen
