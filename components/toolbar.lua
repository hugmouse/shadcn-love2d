local Toolbar = {}
Toolbar.__index = Toolbar

function Toolbar.new(params)
    local self = setmetatable({}, Toolbar)
    self.left = params.left or {}
    self.right = params.right or {}
    self.x = params.x or 0
    self.y = params.y or 0
    self.w = params.w or 800
    self.gap = params.gap or 8
    self:_layout()
    return self
end

function Toolbar:_layout()
    -- Position left items flowing left-to-right
    local cx = self.x
    for _, item in ipairs(self.left) do
        item.x = cx
        item.y = self.y
        cx = cx + item.w + self.gap
    end

    -- Position right items flowing right-to-left
    local rx = self.x + self.w
    for i = #self.right, 1, -1 do
        local item = self.right[i]
        rx = rx - item.w
        item.x = rx
        item.y = self.y
        rx = rx - self.gap
    end
end

function Toolbar:resize(w)
    self.w = w
    self:_layout()
end

function Toolbar:update(dt)
    for _, item in ipairs(self.left) do
        if item.update then item:update(dt) end
    end
    for _, item in ipairs(self.right) do
        if item.update then item:update(dt) end
    end
end

function Toolbar:draw()
    for _, item in ipairs(self.left) do
        item:draw()
    end
    for _, item in ipairs(self.right) do
        item:draw()
    end
end

function Toolbar:mousepressed(mx, my, button, pressCount)
    for _, item in ipairs(self.left) do
        if item.mousepressed and item:mousepressed(mx, my, button, pressCount) then
            return true
        end
    end
    for _, item in ipairs(self.right) do
        if item.mousepressed and item:mousepressed(mx, my, button, pressCount) then
            return true
        end
    end
    return false
end

function Toolbar:mousemoved(mx, my)
    for _, item in ipairs(self.left) do
        if item.mousemoved then item:mousemoved(mx, my) end
    end
    for _, item in ipairs(self.right) do
        if item.mousemoved then item:mousemoved(mx, my) end
    end
end

function Toolbar:mousereleased(mx, my, button)
    for _, item in ipairs(self.left) do
        if item.mousereleased then item:mousereleased(mx, my, button) end
    end
    for _, item in ipairs(self.right) do
        if item.mousereleased then item:mousereleased(mx, my, button) end
    end
end

function Toolbar:textinput(text)
    for _, item in ipairs(self.left) do
        if item.textinput and item:textinput(text) then return true end
    end
    for _, item in ipairs(self.right) do
        if item.textinput and item:textinput(text) then return true end
    end
    return false
end

function Toolbar:keypressed(key, isRepeat)
    for _, item in ipairs(self.left) do
        if item.keypressed and item:keypressed(key, isRepeat) then return true end
    end
    for _, item in ipairs(self.right) do
        if item.keypressed and item:keypressed(key, isRepeat) then return true end
    end
    return false
end

return Toolbar
