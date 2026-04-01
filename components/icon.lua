local love = require("love")
local svglover = require("lib.svglover")

local lg = love.graphics
local loadstring = loadstring

local Icon = {}

-- Map app icon names → SVG filenames (handles legacy name differences)
local iconFiles = {
    ["circle"]          = "circle",
    ["timer"]           = "timer",
    ["check-circle"]    = "circle-check",
    ["circle-slash"]    = "ban",
    ["question-circle"] = "circle-help",
    ["arrow-up"]        = "arrow-up",
    ["arrow-right"]     = "arrow-right",
    ["arrow-down"]      = "arrow-down",
    ["ellipsis"]        = "ellipsis",
    ["plus-circle"]     = "circle-plus",
    ["search"]          = "search",
    ["chevrons-up-down"] = "chevrons-up-down",
    ["chevron-up"]      = "chevron-up",
    ["chevron-down"]    = "chevron-down",
    ["chevron-right"]   = "chevron-right",
    ["chevron-left"]    = "chevron-left",
    ["check"]           = "check",
    ["chevrons-left"]   = "chevrons-left",
    ["chevrons-right"]  = "chevrons-right",
    ["eye-off"]         = "eye-off",
}

-- Cached draw data per icon: { func = compiled_fn, extdata = {...} }
local cache = {}

function Icon.load()
    for name, file in pairs(iconFiles) do
        local svg = svglover.load("assets/icons/" .. file .. ".svg")

        -- Strip setColor and setLineWidth from generated draw commands
        -- so we can apply dynamic color and proportional line width at draw time
        local cmds = svg.drawcommands
        cmds = cmds:gsub("love%.graphics%.setColor%([^%)]+%)\n?", "")
        cmds = cmds:gsub("love%.graphics%.setLineWidth%([^%)]+%)\n?", "")

        cache[name] = {
            func = assert(loadstring(cmds)),
            extdata = svg.extdata,
        }
    end
end

function Icon.draw(name, x, y, size, color)
    local entry = cache[name]
    if not entry then return end

    size = size or 16
    color = color or { 0.631, 0.631, 0.659 }

    local scale = size / 24
    local lw = math.max(1.5, 2 * scale)

    lg.push()
    lg.translate(x, y)
    lg.scale(scale, scale)
    lg.setColor(color)
    lg.setLineWidth(lw / scale) -- compensate for transform so stroke is consistent
    lg.setLineStyle("smooth")
    lg.setLineJoin("bevel")
    entry.func(entry.extdata)
    lg.pop()
end

return Icon
