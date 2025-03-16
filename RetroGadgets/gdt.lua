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

local function set_color(_color)
    love.graphics.setColor(_color.R/255, _color.G/255, _color.B/255, _color.A/255)
end

local function reset_color()
    love.graphics.setColor(1, 1, 1, 1)
end

function gdt.VideoChip0:Clear( _color )
    local r = _color.R / 255.0
    local g = _color.G / 255.0
    local b = _color.B / 255.0
    love.graphics.clear(r,g,b)
end

function gdt.VideoChip0:DrawLine(_start,_end,_color)
    set_color( _color )
    love.graphics.line(_start.X, _start.Y, _end.X, _end.Y)
    reset_color()
end

function gdt.VideoChip0:DrawTriangle(_position1, _position2, _position3, _color)
    gdt.VideoChip0:DrawLine(_position1, _position2, _color)
    gdt.VideoChip0:DrawLine(_position2, _position3, _color)
    gdt.VideoChip0:DrawLine(_position3, _position1, _color)
end

function gdt.VideoChip0:FillTriangle(_position1, _position2, _position3, _color)
    set_color( _color )
    love.graphics.polygon( "fill", 
        _position1.X,_position1.Y,
        _position2.X,_position2.Y,
        _position3.X,_position3.Y
    )
    reset_color()
end

function gdt.VideoChip0:DrawCircle( _position, _radius, _color )
    set_color(_color)
    love.graphics.circle("line",_position.X,_position.Y,_radius)
    reset_color()
end

function gdt.VideoChip0:FillCircle( _position, _radius, _color )
    set_color(_color)
    love.graphics.circle("fill",_position.X,_position.Y,_radius)
    reset_color()
end

function _G._update_gdt()
    gdt.CPU0.Time = love.timer.getTime() - _cpu_time_start
end