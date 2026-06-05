local love = require("love")
local svglover = require("lib.svglover")

local lg = love.graphics
local compile = loadstring or load

local Icon = {}

-- Cached draw data per icon: { func = compiled_fn, extdata = {...} }
local cache = {}

local function cache_icon(name, path)
    local svg = svglover.load(path)
    local cmds = svg.drawcommands

    -- Allows us to change color and lines at runtime (muted/disabled icons)
    cmds = cmds:gsub("love%.graphics%.setColor%([^%)]+%)\n?", "")
    cmds = cmds:gsub("love%.graphics%.setLineWidth%([^%)]+%)\n?", "")

    cache[name] = {
        func = assert(compile(cmds)),
        extdata = svg.extdata,
    }
end

function Icon.load()
    for _, file in ipairs(love.filesystem.getDirectoryItems("assets/icons")) do
        local name = file:match("^(.*)%.svg$")
        if name then
            cache_icon(name, "assets/icons/" .. file)
        end
    end
end

function Icon.draw(name, x, y, size, color)
    local entry = cache[name]
    if not entry then
        return
    end

    assert(size ~= nil, "Icon.draw requires size")
    assert(color ~= nil, "Icon.draw requires color")

    local scale = size / 24
    local lw = math.max(1.5, 2 * scale)

    lg.push()
    lg.translate(x, y)
    lg.scale(scale, scale)
    lg.setColor(color)
    lg.setLineWidth(lw / scale)
    lg.setLineStyle("smooth")
    lg.setLineJoin("bevel")
    entry.func(entry.extdata)
    lg.pop()
end

return Icon
