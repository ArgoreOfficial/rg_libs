local _cpu_time_start = love.timer.getTime()
local _cpu_time_last = love.timer.getTime()

require("RetroGadgets.videochip")

_G.gdt = {
    CPU0 = {
        Time = 0.0,
        DeltaTime = 0.0,
        Source = {},
        EventChannels = {}
    },
    VideoChip0 = _videochip(),
}

function _G._update_gdt()
    local now = love.timer.getTime()
    gdt.CPU0.Time      = now - _cpu_time_start
    gdt.CPU0.DeltaTime = now - _cpu_time_last
    
    _cpu_time_last = now
end