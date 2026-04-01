local screen          = require("screens.task_list")
local theme           = require("theme")
local Icon            = require("components.icon")
local profiler        = require("lib.profile")
local love            = require("love")

local focused         = true
local profilerEnabled = false
local profilerRows    = {}
local profilerFrame   = 0

local profCols        = {
    { label = "#",        width = 28,  align = "r" },
    { label = "Function", width = 180, align = "l" },
    { label = "Calls",    width = 64,  align = "r" },
    { label = "Time",     width = 72,  align = "r" },
    { label = "Source",   width = 200, align = "l" },
}

local function formatTime(t)
    if t >= 1 then
        return string.format("%.2fs", t)
    elseif t >= 0.001 then
        return string.format("%.2fms", t * 1000)
    else
        return string.format("%.0fus", t * 1000000)
    end
end

local function drawProfilerOverlay()
    local stats    = love.graphics.getStats()
    local font     = theme.fonts.mono
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(font)

    local pad       = 10
    local cellPadX  = 8
    local rowH      = 18
    local headerH   = 32
    local totalColW = 0
    for _, c in ipairs(profCols) do totalColW = totalColW + c.width end
    local panelW = totalColW + (#profCols + 1) * cellPadX + 2 * pad
    local rowCount = math.max(#profilerRows, 1)
    local tableH = (rowCount + 1) * rowH -- +1 for header row
    local panelH = headerH + tableH + pad * 3

    local ww = theme.screenW
    local px, py = ww - panelW - 10, 10

    -- panel background
    love.graphics.setColor(0.035, 0.035, 0.043, 0.92)
    love.graphics.rectangle("fill", px, py, panelW, panelH, 8, 8)
    love.graphics.setColor(0.153, 0.153, 0.165, 1)
    love.graphics.rectangle("line", px, py, panelW, panelH, 8, 8)

    -- stats bar
    love.graphics.setColor(0.980, 0.980, 0.980, 1)
    local header = string.format(
        "FPS: %d  |  Draw: %d  |  Canvas: %d  |  Mem: %.0f KB  |  Tex: %.0f KB",
        love.timer.getFPS(),
        stats.drawcalls,
        stats.canvasswitches,
        collectgarbage("count"),
        (stats.texturememory or 0) / 1024
    )
    love.graphics.print(header, px + pad, py + pad)

    -- table origin
    local tx = px + pad
    local ty = py + headerH

    -- draw column headers
    local cx = tx + cellPadX
    for _, col in ipairs(profCols) do
        love.graphics.setColor(0.980, 0.980, 0.980, 1)
        if col.align == "r" then
            local tw = font:getWidth(col.label)
            love.graphics.print(col.label, cx + col.width - tw, ty)
        else
            love.graphics.print(col.label, cx, ty)
        end
        cx = cx + col.width + cellPadX
    end

    -- header separator line
    ty = ty + rowH
    love.graphics.setColor(0.153, 0.153, 0.165, 1)
    love.graphics.line(tx, ty - 2, tx + panelW - pad * 2, ty - 2)

    -- draw rows
    for i, row in ipairs(profilerRows) do
        local cells = {
            tostring(row[1]),
            row[2],
            tostring(row[3]),
            formatTime(row[4]),
            row[5],
        }

        -- alternating row background
        if i % 2 == 0 then
            love.graphics.setColor(0.060, 0.060, 0.070, 0.5)
            love.graphics.rectangle("fill", tx, ty, panelW - pad * 2, rowH)
        end

        -- top row gets brighter text
        if i <= 3 then
            love.graphics.setColor(0.980, 0.980, 0.980, 1)
        else
            love.graphics.setColor(0.631, 0.631, 0.659, 1)
        end

        cx = tx + cellPadX
        for j, col in ipairs(profCols) do
            local text = cells[j] or ""
            -- truncate if too wide
            while font:getWidth(text) > col.width and #text > 1 do
                text = text:sub(1, #text - 1)
            end
            if col.align == "r" then
                local tw = font:getWidth(text)
                love.graphics.print(text, cx + col.width - tw, ty + 1)
            else
                love.graphics.print(text, cx, ty + 1)
            end
            cx = cx + col.width + cellPadX
        end
        ty = ty + rowH
    end

    if #profilerRows == 0 then
        love.graphics.setColor(0.631, 0.631, 0.659, 1)
        love.graphics.print("Collecting data...", tx + cellPadX, ty + 1)
    end

    love.graphics.setFont(prevFont)
    love.graphics.setColor(1, 1, 1, 1)
end

function love.load()
    love.keyboard.setKeyRepeat(true)
    Icon.load()
    screen.load()
end

function love.focus(f) focused = f end

function love.update(dt)
    if not focused then return end
    screen.update(dt)
    if profilerEnabled then
        profilerFrame = profilerFrame + 1
        if profilerFrame % 60 == 0 then
            profilerRows = profiler.query(20)
            profiler.reset()
        end
    end
end

function love.draw()
    screen.draw()
    if profilerEnabled then
        drawProfilerOverlay()
    end
end

function love.resize(w, h) screen.resize(w, h) end

function love.mousepressed(x, y, btn, ist, presses) screen.mousepressed(x, y, btn, presses) end

function love.mousereleased(x, y, btn) screen.mousereleased(x, y, btn) end

function love.mousemoved(x, y) screen.mousemoved(x, y) end

function love.keypressed(key, scancode, isRepeat)
    if key == "f3" then
        profilerEnabled = not profilerEnabled
        if profilerEnabled then
            profiler.start()
            profilerFrame = 0
            profilerReport = "Collecting data..."
        else
            profiler.stop()
            profiler.reset()
        end
        return
    end
    screen.keypressed(key, scancode, isRepeat)
end

function love.textinput(text) screen.textinput(text) end

function love.wheelmoved(x, y) screen.wheelmoved(x, y) end
