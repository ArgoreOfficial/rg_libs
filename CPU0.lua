-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local function debug_triangle(_p1,_p2,_p3)
    gdt.VideoChip0:DrawLine(_p1,_p2,color.red)
    gdt.VideoChip0:DrawLine(_p2,_p3,color.red)
    gdt.VideoChip0:DrawLine(_p3,_p1,color.red)
end

local function draw_triangle(_p1,_p2,_p3)
    debug_triangle(_p1,_p2,_p3)
end

rg3d:push_perspective(
    gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
    1.23, -- FOV (radians)
    0.1,  -- near clip
    10    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

-- update function is repeated every time tick
function Update()
    gdt.VideoChip0:Clear(color.black)
    
    -- triangle in world space
    local vertex_data = {
        vec4(-0.5, -0.5, 0.0, 1),
        vec4(-0.5,  0.5, 0.0, 1),
        vec4( 0.5, -0.5, 0.0, 1),

        vec4(-0.5,  0.5, 0.0, 1),
        vec4( 0.5,  0.5, 0.0, 1),
        vec4( 0.5, -0.5, 0.0, 1)
    }

    -- push_view_transform(pos,rot)
    local view_mat = rmath:mat4_look_at(vec3(0.5,0.6,1), vec3(0,0,0), vec3(0,1,0))

    -- triangles in screen space
    local transformed_data = {}
    for i = 1, #vertex_data do
        local transformed = rmath:mat4_transform(view_mat, vertex_data[i])
        transformed_data[i] = rmath:vec4_to_screen(rg3d:project(transformed),screen_width,screen_height)
    end
    
    -- draw triangles
    for i = 1, #transformed_data, 3 do
        draw_triangle(
            transformed_data[i],
            transformed_data[i + 1],
            transformed_data[i + 2]
        )
    end
end