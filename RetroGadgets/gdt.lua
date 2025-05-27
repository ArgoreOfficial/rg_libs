local _cpu_time_start = love.timer.getTime()

require("RetroGadgets.videochip")

_G.gdt = {
    CPU0 = {
        Time = 0.0,
        DeltaTime = 0.0,
        Source = {},
        EventChannels = {}
    },
    VideoChip0 = _videochip(GADGET.ScreenWidth, GADGET.ScreenHeight, 16),
    ROM = require("RetroGadgets.rom")
}

function _G._update_gdt(_dt)
    local now = love.timer.getTime()
    gdt.CPU0.Time      = now - _cpu_time_start
    gdt.CPU0.DeltaTime = _dt
end