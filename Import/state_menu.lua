local state = {}

local engine = require "engine"
local rmath = require "rg_math"
local rmesh = require "rg_mesh"
local rg3d  = require("rg_3d")

local menu_mesh = nil

function state:on_enter()
	menu_mesh = rmesh:require_drawlist("logo_mesh", vec3(0,0,0), vec3(90,0,0))

	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)

	engine.camera_pos = vec3(0,0,2)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-100)
end

function state:on_exit()
	menu_mesh = nil
end

function state:update(_delta_time)
	local wish_pitch = 0
	local wish_yaw   = 0

	if engine.rinput["LeftArrow"]  then wish_yaw = wish_yaw - 1 end
	if engine.rinput["RightArrow"] then wish_yaw = wish_yaw + 1 end

	if engine.rinput["UpArrow"]   then wish_pitch = wish_pitch + 1 end
	if engine.rinput["DownArrow"] then wish_pitch = wish_pitch - 1 end

	local speed = 5
	if engine.rinput["LeftShift"] then speed = speed * 4 end
end

local function FillQuad(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

local function color_shader(_p1,_p2,_p3,_p4,_shader_input)		
	local c = 255

	if _shader_input.normal then	
		local n = rmath:vec3_normalize(_shader_input.normal)
		local d = rmath:vec3_dot(n, -engine.sun_dir) * 0.5 + 0.5
		c = d
	elseif _shader_input.normals then
		local n1 = _shader_input.normals[1]
		local n2 = _shader_input.normals[2]
		local n3 = _shader_input.normals[3]
		local n4 = _shader_input.normals[4]
		
		local d1 = rmath:vec3_dot(n1, -engine.sun_dir) * 0.5 + 0.5
		local d2 = rmath:vec3_dot(n2, -engine.sun_dir) * 0.5 + 0.5
		local d3 = rmath:vec3_dot(n3, -engine.sun_dir) * 0.5 + 0.5
		local d4 = rmath:vec3_dot(n4, -engine.sun_dir) * 0.5 + 0.5
		
		c = rmath.min(d1, d2, d3, d4)
	end

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	FillQuad(_p1,_p2,_p3,_p4,color)
end

local function color_shader_tri(_p1,_p2,_p3,_shader_input)		
	local c = 255

	if _shader_input.normal then	
		local n = rmath:vec3_normalize(_shader_input.normal)
		local d = rmath:vec3_dot(n, -engine.sun_dir) * 0.5 + 0.5
		c = d
	elseif _shader_input.normals then
		local n1 = _shader_input.normals[1]
		local n2 = _shader_input.normals[2]
		local n3 = _shader_input.normals[3]
		local n4 = _shader_input.normals[4]
		
		local d1 = rmath:vec3_dot(n1, -engine.sun_dir) * 0.5 + 0.5
		local d2 = rmath:vec3_dot(n2, -engine.sun_dir) * 0.5 + 0.5
		local d3 = rmath:vec3_dot(n3, -engine.sun_dir) * 0.5 + 0.5
		local d4 = rmath:vec3_dot(n4, -engine.sun_dir) * 0.5 + 0.5
		
		c = rmath.min(d1, d2, d3, d4)
	end

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,color)
end

function state:draw()
	gdt.VideoChip0:Clear(color.red)

	rg3d:set_tri_func (color_shader_tri)
	rg3d:set_quad_func(color_shader)

	local rot_matrix = rmath:mat4_rotateY(nil,        math.cos(gdt.CPU0.Time) * rmath:radians(20))
	rot_matrix       = rmath:mat4_rotateX(rot_matrix, math.sin(gdt.CPU0.Time*2) * rmath:radians(20))

	rg3d:push_model_matrix(rot_matrix)
	
	rg3d:begin_render()
		rmesh:drawlist_submit( menu_mesh )
	rg3d:end_render()

	--rg3d:push_model_matrix(rmath:mat4())
end

return state