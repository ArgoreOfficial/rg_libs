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
	1.3, -- FOV (radians)
	0.1,  -- near clip
	10    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

local vertex_data = {
	-- bottom quad
	rmath:vec4(-0.5, -0.5, 0.0, 1),
	rmath:vec4(-0.5,  0.5, 0.0, 1),
	rmath:vec4( 0.5, -0.5, 0.0, 1),

	rmath:vec4(-0.5,  0.5, 0.0, 1),
	rmath:vec4( 0.5,  0.5, 0.0, 1),
	rmath:vec4( 0.5, -0.5, 0.0, 1)
}

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:Clear(color.black)
	
	local s = math.sin(gdt.CPU0.Time * 0.7)
	rg3d:push_look_at(vec3(1.5,0,3.5), vec3(0,s*5,0), vec3(0,1,0))
	
	-- draw faces
	local p1, p2, p3
	local count = 50
	local hcount = count/2
	for y=-hcount,hcount do
		for x=-hcount,hcount do
			for tri = 1, #vertex_data, 3 do
				p1 = vertex_data[tri    ] + rmath:vec4(-x,y,0,0)
				p2 = vertex_data[tri + 1] + rmath:vec4(-x,y,0,0)
				p3 = vertex_data[tri + 2] + rmath:vec4(-x,y,0,0)
				rg3d:raster_triangle({p1,p2,p3},screen_width,screen_height)
			end
		end
	end
end