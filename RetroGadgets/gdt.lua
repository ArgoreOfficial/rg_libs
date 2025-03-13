local _cpu_time_start = love.timer.getTime()

_G.gdt = {
    CPU0 = {
        Time = 0
    },
    VideoChip0 = {
        Width  = GADGET.ScreenWidth,
        Height = GADGET.ScreenHeight
    }
}

function gdt.VideoChip0:Clear( color )
    love.graphics.clear(color.R/255, color.G/255, color.B/255, color.A/255)
end

function gdt.VideoChip0:DrawLine(_start,_end,_color)
    love.graphics.setColor(_color.R/255, _color.G/255, _color.B/255, _color.A/255)
    love.graphics.line(_start.X, _start.Y, _end.X, _end.Y)
end

function _G._update_gdt()
    gdt.CPU0.Time = love.timer.getTime() - _cpu_time_start
end