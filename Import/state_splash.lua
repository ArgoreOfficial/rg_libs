local state = {}

local rmesh = require "rg_mesh"
local rmath = require "rg_math"
local rg3d  = require "rg_3d"
local engine = require "engine"
local state_machine = require("state_machine")

local logo_drawlist      = nil
local logo_face_drawlist = nil
local bg_drawlist        = nil

local camera_path = require "camera_path"

local palette = gdt.ROM.User.SpriteSheets["stripes.png"]

function state:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(40), -- FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)

	logo_drawlist      = rmesh:require_drawlist "argore_logo"
	logo_face_drawlist = rmesh:require_drawlist "argore_logo_face"
	bg_drawlist        = rmesh:require_drawlist "argore_bg"
end

function state:on_exit()
	-- on exit
end

local path_frame = 1
local path_frame_timer = 0
local path_framerate = 1/60


local function FillQuad(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

local function raster_quad(_p1,_p2,_p3,_p4)
	FillQuad(_p1,_p2,_p3,_p4,color.blue)
end

local function logo_shader(_p1,_p2,_p3,_p4,_shader_input)		
	local c = 255

	if _shader_input.normal then	
		local n = rmath:vec3_normalize(_shader_input.normal)
		local d = rmath:vec3_dot(n, -engine.sun_dir) * 0.5 + 0.5
		c = d * 255
	elseif _shader_input.normals then
		local n1 = _shader_input.normals[1]
		local n2 = _shader_input.normals[2]
		local n3 = _shader_input.normals[3]
		local n4 = _shader_input.normals[4]
		
		local d1 = rmath:vec3_dot(n1, -engine.sun_dir) * 0.5 + 0.5
		local d2 = rmath:vec3_dot(n2, -engine.sun_dir) * 0.5 + 0.5
		local d3 = rmath:vec3_dot(n3, -engine.sun_dir) * 0.5 + 0.5
		local d4 = rmath:vec3_dot(n4, -engine.sun_dir) * 0.5 + 0.5
		
		c = rmath.min(d1, d2, d3, d4) * 255
	end

	FillQuad(_p1,_p2,_p3,_p4,Color(c,c,c))
end

local function logo_shader_tri(_p1,_p2,_p3,_shader_input)		
	local c = 255

	if _shader_input.normal then	
		local n = rmath:vec3_normalize(_shader_input.normal)
		local d = rmath:vec3_dot(n, -engine.sun_dir) * 0.5 + 0.5
		c = d * 255
	elseif _shader_input.normals then
		local n1 = _shader_input.normals[1]
		local n2 = _shader_input.normals[2]
		local n3 = _shader_input.normals[3]
		local n4 = _shader_input.normals[4]
		
		local d1 = rmath:vec3_dot(n1, -engine.sun_dir) * 0.5 + 0.5
		local d2 = rmath:vec3_dot(n2, -engine.sun_dir) * 0.5 + 0.5
		local d3 = rmath:vec3_dot(n3, -engine.sun_dir) * 0.5 + 0.5
		local d4 = rmath:vec3_dot(n4, -engine.sun_dir) * 0.5 + 0.5
		
		c = rmath.min(d1, d2, d3, d4) * 255
	end

	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,Color(c,c,c))
end

local function shader_quad_random(_p1,_p2,_p3,_p4,_shader_input)		
	math.randomseed( _shader_input.primitive_index )
	local color = Color(math.random(0,255),math.random(0,255),math.random(0,255))
	FillQuad(_p1, _p2, _p3, _p4, color)
end

local function shader_tri_random(_p1,_p2,_p3,_shader_input)		
	math.randomseed( _shader_input.primitive_index )
	local color = Color(math.random(0,255),math.random(0,255),math.random(0,255))
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,color)
end


local function background_scroll_shader(_p1,_p2,_p3,_p4,_shader_input)		
	local t = (gdt.CPU0.Time * 16) % 32
	gdt.VideoChip0:RasterCustomSprite(
			_p1,_p2,_p3,_p4,
			palette,
			vec2(0,0),vec2(64,32),
			color.white,
			color.clear
		)
end

function state:update(_delta_time)

	path_frame_timer = path_frame_timer + _delta_time
	if path_frame_timer > path_framerate then
		path_frame = path_frame + 1
		path_frame_timer = path_frame_timer - path_framerate

		if path_frame > 230 then
			path_frame = 1

			state_machine:set_state("game")
		end
	end

	engine.camera_pos   = camera_path[ path_frame ].pos
	engine.camera_pitch = rmath:radians(camera_path[ path_frame ].pitch)
	engine.camera_yaw   = rmath:radians(camera_path[ path_frame ].yaw)
end

function state:draw()
	-- draw scrolling background
	gdt.VideoChip0:Clear(color.black)
	
	rg3d:set_tri_func(shader_tri_random)
	
	rg3d:set_quad_func(background_scroll_shader)
	rg3d:begin_render()
	rmesh:drawlist_submit(bg_drawlist)
	rg3d:end_render()
	
	-- draw logo
	
	rg3d:set_tri_func(logo_shader_tri)
	rg3d:set_quad_func(logo_shader)

	rg3d:begin_render()
		rmesh:drawlist_submit(logo_drawlist)
	rg3d:end_render()
	
	rg3d:begin_render()
		rmesh:drawlist_submit(logo_face_drawlist)
	rg3d:end_render()
end

return state