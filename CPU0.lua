-- Retro Gadgets

local rmath = require("rg_math")
local rg3d  = require("rg_3d")

local palette    = gdt.ROM.User.SpriteSheets["stripes.png"]
local miptexture = gdt.ROM.User.SpriteSheets["mipmap64.png"]
local shading    = gdt.ROM.User.SpriteSheets["shading_cross.png"]
local steve      = gdt.ROM.User.SpriteSheets["steve_beetle.png"]

gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height)
-- this has to be grabbed after because of love2d stuff
local rb1 = gdt.VideoChip0.RenderBuffers[1]

rg3d:push_perspective(
	gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
	1.22, -- FOV (radians)
	0.5,  -- near clip
	50    -- far clip
)

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

local quad_vbo = {
	-- bottom quad
	vec3(-0.5, 0.0, -0.5),
	vec3(-0.5, 0.0,  0.5),
	vec3( 0.5, 0.0,  0.5),
	vec3( 0.5, 0.0, -0.5)
}

local draw_count = 40

local cam_pos   = vec3(3,3,0)
local cam_pitch = 0
local cam_yaw   = rmath.const.PI
local cam_dir   = vec3(0,0,-1)

local function rot_to_dir(_pitch, _yaw)
	return vec3(
		math.cos(_yaw)*math.cos(_pitch),
		math.sin(_pitch),
		math.sin(_yaw)*math.cos(_pitch)
	)
end

local rinput = {}
function eventChannel1(_sender,_event)
	rinput[_event.InputName] = _event.ButtonDown
end

local function update_dir(_v)
	local wish_pitch = 0
	local wish_yaw   = 0

	if rinput["LeftArrow"]  then wish_yaw = wish_yaw - 1 end
	if rinput["RightArrow"] then wish_yaw = wish_yaw + 1 end

	if rinput["UpArrow"]   then wish_pitch = wish_pitch + 1 end
	if rinput["DownArrow"] then wish_pitch = wish_pitch - 1 end

	cam_pitch = cam_pitch + wish_pitch * _v
	cam_yaw   = cam_yaw   + wish_yaw   * _v
	cam_pitch = math.min(cam_pitch,  rmath:radians(85))
	cam_pitch = math.max(cam_pitch, -rmath:radians(85))
	cam_dir   = rot_to_dir(cam_pitch, cam_yaw)
end

local function get_move_wish()
	local move_input = vec3(0,0,0)
	
	if rinput["W"] then move_input = move_input + vec3(0,0, 1) end
	if rinput["S"] then move_input = move_input + vec3(0,0,-1) end

	if rinput["A"] then move_input = move_input + vec3(-1,0,0) end
	if rinput["D"] then move_input = move_input + vec3( 1,0,0) end

	if rinput["E"] then move_input = move_input + vec3(0, 1,0) end
	if rinput["Q"] then move_input = move_input + vec3(0,-1,0) end

	local up      = vec3(0,1,0)
	local right   = rot_to_dir(0, cam_yaw + rmath:radians(90))
	local forward = rot_to_dir(cam_pitch, cam_yaw)

	local move_wish = right   * move_input.X + 
	                  up      * move_input.Y + 
	                  forward * move_input.Z

	return rmath:vec3_normalize(move_wish)
end

local function raster_rect(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

local function raster_quad(_p1,_p2,_p3,_p4)
	raster_rect(_p1,_p2,_p3,_p4,color.blue)
end

local function quad_shading(_p1,_p2,_p3,_p4,_color,_val1,_val2,_val3,_val4)
	
	local alpha = math.min(_val1,_val2,_val3,_val4)
	--local alpha = ((_val1+_val2+_val3+_val4) / 4)
	
	--raster_rect(
	--	_p1,_p2,_p3,_p4,
	--	ColorRGBA(_color.R,_color.G,_color.B, 255 * alpha)
	--)

	--alpha = 0

	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(0,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val1-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(64,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val2-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(128,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val3-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(128+64,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val4-alpha) ),
		color.clear
	)
end

local function create_shader_scrolling_quad(_texture, _width, _height, _scroll_x, _scroll_y)
	return function(_p1,_p2,_p3,_p4,_view_normal,_shader_input)		
		local t = (gdt.CPU0.Time * 16) % 32
		local light_dir = vec3(math.cos(gdt.CPU0.Time), 0, math.sin(gdt.CPU0.Time))
		light_dir = rmath:vec3_normalize(light_dir)
		
		local n1 = (_shader_input and _shader_input.normals) and _shader_input.normals[1] or -light_dir
		local n2 = (_shader_input and _shader_input.normals) and _shader_input.normals[2] or -light_dir
		local n3 = (_shader_input and _shader_input.normals) and _shader_input.normals[3] or -light_dir
		local n4 = (_shader_input and _shader_input.normals) and _shader_input.normals[4] or -light_dir
		
		local d1 = rmath:vec3_dot(n2, light_dir) * 0.5 + 0.5
		local d2 = rmath:vec3_dot(n1, light_dir) * 0.5 + 0.5
		local d3 = rmath:vec3_dot(n4, light_dir) * 0.5 + 0.5
		local d4 = rmath:vec3_dot(n3, light_dir) * 0.5 + 0.5
		
		local c = math.min(d1,d2,d3,d4)*255
		--local c = (d1+d2+d3+d4)/4*255
		--local c = 255

		gdt.VideoChip0:RasterCustomSprite(
			_p1,_p2,_p3,_p4,
			_texture,
			vec2(t*_scroll_x,t*_scroll_y),vec2(_width, _height),
			Color(c,c,c),
			color.clear
		)
		
		quad_shading(_p2,_p1,_p4,_p3,color.black,d1,d2,d3,d4) -- TODO: fix order
	end
end

local function raster_quad_sprite_mipped(_p1,_p2,_p3,_p4,_view_normal,_shader_input)
	local u, v, fraction = rg3d:get_mip_UVs(_p1, _p2, _p3, _p4, 64, 64)
	local mip = rg3d:get_mip_level(_p1, _p2, _p3, _p4, 64, 64)

	local z = math.max(_p1.Z, _p2.Z, _p3.Z, _p4.Z)
	local c = 1 - (z / 50) -- z / g_far
	local fog = Color(c*255, c*255, c*255)
	local mip0col = ColorRGBA(fog.R, fog.G, fog.B, (1-fraction) * 255)
	
	local u2, v2 = rg3d:get_mip_level_UVs(mip-1, 64, 64)
	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4, miptexture, u, v, fog, color.clear)
	if mip > 1 then
		gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4, miptexture, u2, v2, mip0col, color.clear)
	end
end

local function raster_tri_sprite(_p1,_p2,_p3)
	gdt.VideoChip0:DrawTriangle(_p1,_p2,_p3,color.green)
end

local function vec3_mult(_lhs,_rhs)
	return vec3(
		_lhs.X * _rhs.X,
		_lhs.Y * _rhs.Y,
		_lhs.Z * _rhs.Z
	)
end

local palette_quad_shader = create_shader_scrolling_quad(palette,64,32,0,1)
local smooth_quad_shader  = create_shader_scrolling_quad(steve,64,64,0,0)

--local rmesh = require "rg_mesh"
--local torus_drawlist = rmesh:parse_obj("torus.obj")
--rmesh:export_mesh( torus_drawlist )

local torus_drawlist = require "torus_obj" -- rmesh:parse_obj("torus.obj")

-- update function is repeated every time tick
function update()
	local dt = gdt.CPU0.DeltaTime
	
	update_dir(dt * 1.2)
	local speed = 5
	if rinput["LeftShift"] then speed = speed * 4 end
	cam_pos = cam_pos + get_move_wish() * dt * speed
	
	-- draw

	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.black)
	
	rg3d:push_look_at(cam_pos, cam_pos + cam_dir, vec3(0,1,0))
	rg3d:begin_render() -- begin renderpass
	rg3d:set_clip_far( true )
	rg3d:set_tri_func(nil) -- set to custom
	rg3d:set_quad_func(palette_quad_shader) -- set to custom
	
	local function translate_quad(_quad, _vec)
		return {
			_quad[1] + _vec,
			_quad[2] + _vec,
			_quad[3] + _vec,
			_quad[4] + _vec
		}
	end

	local function scale_quad(_quad, _vec)
		return {
			vec3_mult(_quad[1], _vec),
			vec3_mult(_quad[2], _vec),
			vec3_mult(_quad[3], _vec),
			vec3_mult(_quad[4], _vec)
		}
	end

	local scale_x = 0--rmath.nsin(gdt.CPU0.Time * 4)
	local scale_z = 0--rmath.ncos(gdt.CPU0.Time * 4)

	for i = 1, #torus_drawlist do
		local ws = scale_quad(torus_drawlist[i].verts, vec3( 1.3+scale_x, 1.3+scale_z, 1.3+scale_x ) )
		ws = translate_quad(ws, vec3(-3,2,0))
		local shader_input = {
			normals = torus_drawlist[i].normals
		}
		rg3d:raster_quad(ws, screen_width, screen_height, shader_input)
	end
	
	rg3d:set_quad_func(smooth_quad_shader)
	rg3d:raster_quad(translate_quad(scale_quad(quad_vbo, vec3(2,0,2)), vec3(4,1,0)),screen_width,screen_height)
	rg3d:end_render()
	
	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.black)

	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)
	
	--gdt.VideoChip0:DrawSprite(vec2(0,0), palette, 0, 0, color.white, color.white )
	--gdt.VideoChip0:DrawSprite(vec2(64,0), palette, 0, 0, color.red, color.white )
	--gdt.VideoChip0:DrawSprite(vec2(128,0), palette, 0, 0, color.blue, color.white )
end