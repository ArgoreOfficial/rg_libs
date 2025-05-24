local state = {}

local engine = require "engine"
local rmath = require "rg_math"
local rmesh = require "rg_mesh"
local rg3d  = require("rg_3d")
local state_machine = require("state_machine")

local menu_mesh = nil

local selected_cursor = 1
local moved_selected_cursor = false

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
	engine.camera_yaw   = rmath:radians(-90)
end

function state:on_exit()
	menu_mesh = nil
end

function state:update(_delta_time)
	local wish_pitch = 0
	local wish_yaw   = 0

	local selected_delta = 0

	selected_delta = selected_delta + (engine.rinput["UpArrow"]   and -1 or 0)
	selected_delta = selected_delta + (engine.rinput["DownArrow"] and  1 or 0)

	if engine.rinput["Return"] then
		state_machine:set_state("game")
	end

	if selected_delta ~= 0 then
		if not moved_selected_cursor then
			selected_cursor = selected_cursor + selected_delta
		end
		moved_selected_cursor = true
	else
		moved_selected_cursor = false
	end
end

local function FillQuad(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

local function color_shader(_p1,_p2,_p3,_p4,_shader_input)		
	local c = 1

	if _shader_input.light_intensity then
		c = math.max(0.1, _shader_input.light_intensity)
	elseif _shader_input.normal then	
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

	if _shader_input.light_dot then
		c = math.max(0.2, _shader_input.light_dot)
	elseif _shader_input.normal then	
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
		{color=color.blue})
end

function state:draw()
	gdt.VideoChip0:Clear(color.red)

	rg3d:set_tri_func (color_shader_tri)
	rg3d:set_quad_func(color_shader)

	local t = gdt.CPU0.Time
	local model_matrix = rmath:mat4_translate(nil, vec3(0.4,0,0))
	model_matrix       = rmath:mat4_rotateY(model_matrix, math.cos(t) * rmath:radians(20) - rmath:radians(20))
	model_matrix       = rmath:mat4_rotateX(model_matrix, math.sin(t) * rmath:radians(45))
	rg3d:push_model_matrix(model_matrix)
	
	rg3d:begin_render()
		rmesh:drawlist_submit( menu_mesh )

		local button_mesh_matrix = rmath:mat4_scale(nil, vec3(0.7, 0.2, 1))
		local button_mesh_matrix = rmath:mat4_translate(button_mesh_matrix, vec3(0,-0.5,0))

		for i = 1, 3 do
			local button1_model = nil
			local pos_index = i - 2
			local y_pos = pos_index * 0.3
			local rot = 40 - (selected_cursor == i and 10 or 0)

			button1_model = rmath:mat4_translate(button1_model, vec3(-1, -y_pos,0))
			button1_model = rmath:mat4_rotateY(button1_model, rmath:radians(rot))
			button1_model = rmath:mat4_rotateX(button1_model, rmath:radians(selected_cursor == i and -10 or 0))
			button1_model = rmath:mat4_mult_mat4(button_mesh_matrix, button1_model)
			
			rg3d:push_model_matrix(button1_model)
			draw_simple_quad()
		end

		
	rg3d:end_render()

	--rg3d:push_model_matrix(rmath:mat4())
end

return state