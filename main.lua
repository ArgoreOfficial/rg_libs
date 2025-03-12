if gdt == nil then
    require( "RetroGadgets" ) -- RG compatibility layer
end

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

function debug_triangle(_p1,_p2,_p3)
    love.graphics.line(
        _p1.X, _p1.Y,
        _p2.X, _p2.Y,
        _p3.X, _p3.Y,
        _p1.X, _p1.Y
    )
end

function debug_quad(_p1,_p2,_p3,_p4)
    love.graphics.line(
        _p1.X, _p1.Y,
        _p2.X, _p2.Y,
        _p3.X, _p3.Y,
        _p4.X, _p4.Y,
        _p1.X, _p1.Y
    )
end

function debug_quad_tri(_p1,_p2,_p3,_p4)
    love.graphics.line(
        _p1.X, _p1.Y,
        _p2.X, _p2.Y,
        _p4.X, _p4.Y,
        _p1.X, _p1.Y
    )

    love.graphics.line(
        _p2.X, _p2.Y,
        _p3.X, _p3.Y,
        _p4.X, _p4.Y,
        _p2.X, _p2.Y
    )
end

function vec4_to_screen(_vec)
    local n = _vec / _vec.W
    return vec4(
        ( n.X/2 + 0.5) * gdt.VideoChip0.Width,
        (-n.Y/2 + 0.5) * gdt.VideoChip0.Height,
        n.Z,
        n.W
    )
end

function draw_triangle(_p1,_p2,_p3)
    debug_triangle(_p1,_p2,_p3)
end

rg3d:push_perspective(
    1,    -- screen aspect ratio
    1.23, -- FOV (radians)
    0.1,  -- near clip
    10    -- far clip
)

function Update()
    gdt.VideoChip0:Clear(color.clear)
    local s = math.sin(gdt.CPU0:Time())
    print(s)
    -- triangle in world space
    local p1 = vec4(-0.5, 0.0, -1.3 + s*0.2, 1)
    local p2 = vec4( 0.0, 1.0, -1.3 + s*0.2, 1)
    local p3 = vec4( 0.5, 0.0, -1.3 + s*0.2, 1)
    
    -- push_view_transform(pos,rot)
    
    -- triangle in screen space
    local t1 = vec4_to_screen(rg3d:project(p1))
    local t2 = vec4_to_screen(rg3d:project(p2))
    local t3 = vec4_to_screen(rg3d:project(p3))

    draw_triangle(t1,t2,t3)
end

function love.draw()
    Update()
    _display_print()
end