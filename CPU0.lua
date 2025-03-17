-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local spritesheet = gdt.ROM.User.SpriteSheets["assets/vulkan_blue.png"]
local v = require( "assets/vulkan_blue" )

rg3d:push_perspective(
	gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
	1.22, -- FOV (radians)
	0.5,  -- near clip
	50    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

local vertex_data = {
	-- bottom quad
	rmath:vec4(-0.5, 0.0, -0.5, 1),
	rmath:vec4(-0.5, 0.0,  0.5, 1),
	rmath:vec4( 0.5, 0.0, -0.5, 1),

	rmath:vec4(-0.5, 0.0,  0.5, 1),
	rmath:vec4( 0.5, 0.0,  0.5, 1),
	rmath:vec4( 0.5, 0.0, -0.5, 1)
}

local draw_count = 40
local cam_dist = 40
print("drawing " .. tostring(3 * draw_count * draw_count) .. " faces")

-- update function is repeated every time tick
function update()
	gdt.VideoChip0:Clear(color.black)
	
	cam_dist = math.sin(gdt.CPU0.Time * 1.7) * 20 + 30
	local s = math.sin(gdt.CPU0.Time * 0.7)
	local c = math.cos(gdt.CPU0.Time * 0.7)
	rg3d:push_look_at(
		vec3(c * cam_dist, c * cam_dist * 0.75, s * cam_dist), 
		vec3(0,0,0),
		vec3(0,1,0))
	
	-- draw faces
	local p1, p2, p3
	
	local hcount = draw_count/2
	for y=-hcount,hcount do
		for x=-hcount,hcount do
			for tri = 1, #vertex_data, 3 do
				p1 = vertex_data[tri    ] + rmath:vec4(-x,0,y,0)
				p2 = vertex_data[tri + 1] + rmath:vec4(-x,0,y,0)
				p3 = vertex_data[tri + 2] + rmath:vec4(-x,0,y,0)
				rg3d:raster_triangle({p1,p2,p3},screen_width,screen_height)
			end
		end
	end

	gdt.VideoChip0:RasterSprite(vec2(1,4),vec2(64,3),vec2(70,50),vec2(2,40),spritesheet,0,0,color.white,color.clear)
	gdt.VideoChip0:DrawSprite(vec2(0,0), spritesheet, 0, 0, color.white, color.clear)
end