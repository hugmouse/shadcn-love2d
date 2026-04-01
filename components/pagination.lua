local theme = require("theme")
local Icon = require("components.icon")
local Select = require("components.select")
local love = require("love")

local Pagination = {}
Pagination.__index = Pagination

function Pagination.new(params)
    local self = setmetatable({}, Pagination)
    self.x = params.x
    self.y = params.y
    self.w = params.w
    self.totalItems = params.totalItems
    self.selectedCount = params.selectedCount
    self.onPageChange = params.onPageChange

    self.page = 1
    self.rowsPerPage = params.defaultRowsPerPage or 10
    self.barH = 40

    -- Nav button state
    self._btnSize = 32
    self._btnGap = 4
    self._btnHovered = { false, false, false, false }
    self._btnRects = {}

    -- Rows per page select
    local rppOptions = {}
    for _, v in ipairs(params.rowsPerPageOptions or { 25, 50, 100 }) do
        rppOptions[#rppOptions + 1] = { value = tostring(v), label = tostring(v) }
    end
    self._rppSelect = Select.new({
        options = rppOptions,
        value = tostring(self.rowsPerPage),
        w = 70,
        h = 28,
        dropUp = true,
        onChange = function(val)
            self.rowsPerPage = tonumber(val)
            self.page = 1
            if self.onPageChange then
                self.onPageChange(self.page, self.rowsPerPage)
            end
        end,
    })

    return self
end

function Pagination:_totalPages()
    if self.totalItems <= 0 then return 1 end
    return math.ceil(self.totalItems / self.rowsPerPage)
end

function Pagination:setTotalItems(n)
    self.totalItems = n
    local tp = self:_totalPages()
    if self.page > tp then
        self.page = math.max(1, tp)
    end
end

function Pagination:setSelectedCount(n)
    self.selectedCount = n
end

function Pagination:getPage()
    return self.page
end

function Pagination:getRowsPerPage()
    return self.rowsPerPage
end

function Pagination:getPageSlice(items)
    local startIdx = (self.page - 1) * self.rowsPerPage + 1
    local endIdx = math.min(self.page * self.rowsPerPage, #items)
    local slice = {}
    for i = startIdx, endIdx do
        slice[#slice + 1] = items[i]
    end
    return slice
end

function Pagination:_layoutButtons()
    local bs = self._btnSize
    local gap = self._btnGap
    local rx = self.x + self.w - bs
    local by = self.y + (self.barH - bs) / 2

    -- Right to left: last, next, prev, first
    self._btnRects[4] = { x = rx, y = by, w = bs, h = bs }
    rx = rx - bs - gap
    self._btnRects[3] = { x = rx, y = by, w = bs, h = bs }
    rx = rx - bs - gap
    self._btnRects[2] = { x = rx, y = by, w = bs, h = bs }
    rx = rx - bs - gap
    self._btnRects[1] = { x = rx, y = by, w = bs, h = bs }

    return rx
end

function Pagination:update(dt)
    local mx, my = love.mouse.getPosition()
    for i = 1, 4 do
        local r = self._btnRects[i]
        if r then
            self._btnHovered[i] = mx >= r.x and mx <= r.x + r.w
                and my >= r.y and my <= r.y + r.h
        end
    end
end

function Pagination:draw()
    local font = theme.fonts.body
    love.graphics.setFont(font)

    local tp = self:_totalPages()
    local onFirst = self.page <= 1
    local onLast = self.page >= tp

    -- Layout buttons (right side)
    local btnLeftEdge = self:_layoutButtons()

    -- "Page X of Y" text (left of buttons)
    local pageText = string.format("Page %d of %d", self.page, tp)
    local pageTextW = theme.textWidth(font, pageText)
    local pageTextX = btnLeftEdge - 16 - pageTextW
    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print(pageText, pageTextX,
        self.y + (self.barH - theme.fontH.body) / 2)

    -- Rows per page select (left of page text)
    local rppLabelText = "Rows per page"
    local rppLabelW = theme.textWidth(font, rppLabelText)
    self._rppSelect.x = pageTextX - 16 - self._rppSelect.w
    self._rppSelect.y = self.y + (self.barH - self._rppSelect.h) / 2
    local rppLabelX = self._rppSelect.x - 8 - rppLabelW

    love.graphics.setColor(theme.colors.foreground)
    love.graphics.print(rppLabelText, rppLabelX,
        self.y + (self.barH - theme.fontH.body) / 2)

    self._rppSelect:draw()

    -- Navigation buttons
    local icons = { "chevrons-left", "chevron-left", "chevron-right", "chevrons-right" }
    local disabled = { onFirst, onFirst, onLast, onLast }
    local r = theme.radii.button

    for i = 1, 4 do
        local br = self._btnRects[i]
        local dis = disabled[i]

        if dis then
            love.graphics.setColor(theme.colors.border[1], theme.colors.border[2],
                theme.colors.border[3], 0.4)
            love.graphics.rectangle("line", br.x, br.y, br.w, br.h, r, r)
            Icon.draw(icons[i], br.x + (br.w - 16) / 2, br.y + (br.h - 16) / 2, 16,
                { theme.colors.muted[1], theme.colors.muted[2], theme.colors.muted[3], 0.4 })
        else
            love.graphics.setColor(theme.colors.border)
            love.graphics.rectangle("line", br.x, br.y, br.w, br.h, r, r)
            if self._btnHovered[i] then
                love.graphics.setColor(theme.colors.hover)
                love.graphics.rectangle("fill", br.x + 1, br.y + 1,
                    br.w - 2, br.h - 2, r, r)
            end
            Icon.draw(icons[i], br.x + (br.w - 16) / 2, br.y + (br.h - 16) / 2, 16,
                theme.colors.foreground)
        end
    end

    -- Left side: "N of M row(s) selected."
    love.graphics.setColor(theme.colors.muted)
    love.graphics.print(
        string.format("%d of %d row(s) selected.", self.selectedCount, self.totalItems),
        self.x, self.y + (self.barH - theme.fontH.body) / 2)
end

function Pagination:mousepressed(mx, my, btn)
    if btn ~= 1 then return false end

    -- Select dropdown (check first if open)
    if self._rppSelect:mousepressed(mx, my, btn) then
        return true
    end

    local tp = self:_totalPages()
    local onFirst = self.page <= 1
    local onLast = self.page >= tp
    local disabled = { onFirst, onFirst, onLast, onLast }
    local targets = { 1, self.page - 1, self.page + 1, tp }

    for i = 1, 4 do
        local r = self._btnRects[i]
        if r and not disabled[i] then
            if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
                self.page = targets[i]
                if self.onPageChange then
                    self.onPageChange(self.page, self.rowsPerPage)
                end
                return true
            end
        end
    end

    return false
end

function Pagination:mousemoved(mx, my)
    self._rppSelect:mousemoved(mx, my)
end

function Pagination:keypressed(key)
    if self._rppSelect:keypressed(key) then return true end
    return false
end

function Pagination:drawOverlay()
    self._rppSelect:drawOverlay()
end

return Pagination
