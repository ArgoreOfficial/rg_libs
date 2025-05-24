local state_game = {}

local engine   = require "engine"
local rmath    = require "rg_math"
local rmesh    = require "rg_mesh"
local rg3d     = require("rg_3d")
local rshaders = require("rg_shaders")

local state_machine = require("state_machine")

local rb1 = nil
local kanohi_hau = nil

function state_game:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)
kanohi_hau = rmesh:require_drawlist("kanohi_hau", vec3(0,-0.4,-3), vec3(0,90,0))
	
	engine.camera_pos = vec3(0,0,2)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-90)
	
	gdt.VideoChip0:SetRenderBufferSize(1, 200, 150)
	rb1 = gdt.VideoChip0.RenderBuffers[1]
end

function state_game:on_exit()
	-- on exit
end

function state_game:update(_delta_time)
	
end

local function renderbuffer_shader(_p1,_p2,_p3,_p4,_shader_input)
	gdt.VideoChip0:RasterRenderBuffer(_p4,_p3,_p2,_p1,rb1)
end

local function draw_simple_quad()
	rg3d:raster_quad(
		{
			vec3(0,0,0),
			vec3(1,0,0),
			vec3(1,1,0),
			vec3(0,1,0)
		},
		gdt.VideoChip0.Width, 
		gdt.VideoChip0.Height,
		{color=color.blue}
	)
end

local font = gdt.ROM.System.SpriteSheets["StandardFont"]

function state_game:draw()
	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.red)
	gdt.VideoChip0:DrawText(vec2(0,0), font, "Some Gaming Thing", color.white, color.black)
	
	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.black)
	--gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,400,300)

	--rg3d:set_light_dir(vec3(1,0,0))

	rg3d:set_quad_func(rshaders.diffuse_lambert_quad)
	rg3d:set_tri_func(rshaders.diffuse_lambert_tri)
	
	rg3d:begin_render()
		rg3d:push_model_matrix(nil)
		rmesh:drawlist_submit(kanohi_hau)
	rg3d:end_render()
end

return state_game