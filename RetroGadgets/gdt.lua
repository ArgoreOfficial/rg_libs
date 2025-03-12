local gdt = {
    CPU0 = {},
    VideoChip0 = {
        Width = love.graphics.getWidth(),
        Height = love.graphics.getHeight()
    }
}

local _cpu_time_start = love.timer.getTime()
function gdt.CPU0:Time()
    return love.timer.getTime() - _cpu_time_start
end

function gdt.VideoChip0:Clear( color )
    love.graphics.setBackgroundColor(color.R/255,color.G/255,color.B/255,color.A/255)
end

return gdt