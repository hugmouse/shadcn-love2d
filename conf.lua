local love = require("love")

if love._os == "Windows" then
    local ffi = require "ffi"
    ffi.cdef [[ bool SetProcessDPIAware(); ]]
    ffi.C.SetProcessDPIAware();
end

function love.conf(t)
    t.identity = "shadcn-love2d"
    t.window.title = "shadcn-love2d"
    t.window.width = 1280
    t.window.height = 720
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 480
    t.highdpi = true

    -- Disable unused modules
    t.modules.joystick = false
    t.modules.physics = false
    t.modules.video = false
    t.modules.audio = false
    t.modules.sound = false
end
