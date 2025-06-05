local state_game = {}

local engine   = require "engine"
local rmath    = require "rg_math"
local rmesh    = require "rg_mesh"
local rg3d     = require("rg_3d")
local rshaders = require("rg_shaders")

local state_machine = require("state_machine")
local FPS = 0

local vis_renderbuffer = gdt.VideoChip0.RenderBuffers[1]
local target_renderbuffer = gdt.VideoChip0.RenderBuffers[2]
local texture_rb = gdt.VideoChip0.RenderBuffers[3]
local normal_rb = gdt.VideoChip0.RenderBuffers[4]
local shadow_rb = gdt.VideoChip0.RenderBuffers[5]

local demo_mesh = {}
local albedo_data = {}
local normal_data = {}
local shadow_data = {}
local light_dir = vec3(0,1,0)
local ms_light_dir = vec3(0,1,0)
local model_view_mat = {}

local rotate_x = 0
local rotate_y = -0.7
local zoom = 0

local DEBUG = 0

function state_game:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)
	
	demo_mesh = rmesh:require_drawlist("cube")	
	engine.camera_pos = vec3(0,0,3.5)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-90)
	
	engine.push_look_at = false -- look at will be manually pushed

	gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- vis buffer
	gdt.VideoChip0:SetRenderBufferSize(2, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- target buffer
	gdt.VideoChip0:SetRenderBufferSize(3, 256, 256) -- albedo texture buffer
	gdt.VideoChip0:SetRenderBufferSize(4, 256, 256) -- normal texture buffer
	gdt.VideoChip0:SetRenderBufferSize(5, 256, 256) -- shadow buffer
	
	albedo_data = require("TX_penta_albedo"):toPixelData(texture_rb:GetPixelData())
	normal_data = require("TX_penta_normal"):toPixelData(normal_rb:GetPixelData())
end

function state_game:on_exit()
	engine.push_look_at = true
end

local touch_last = nil
local touch_delta = vec2(0,0)

function state_game:update(_delta_time)
	if _delta_time == 0 then FPS = 0 
	else FPS = 1 / _delta_time end

	if engine.IS_RG then
		DEBUG = gdt.Switch0.State and 1 or 0
	end

	if engine.rinput["UpArrow"]    then zoom = zoom + _delta_time * 3 end
	if engine.rinput["DownArrow"]  then zoom = zoom - _delta_time * 3 end
	
	if gdt.VideoChip0.TouchState then
		local touch_now = gdt.VideoChip0.TouchPosition
		if touch_last then
			touch_delta = touch_now - touch_last
			touch_last = touch_now
		else
			touch_delta = vec2(0,0)
			touch_last = touch_now
		end
	else
		touch_last = nil
		touch_delta = touch_delta * 0.9
	end
	
	rotate_x = rotate_x + rmath:radians(touch_delta.Y)
	rotate_y = rotate_y + rmath:radians(touch_delta.X)
end

local font = gdt.ROM.System.SpriteSheets["StandardFont"]

local function barycentric(p, a, b, c)
    local v0 = b - a
	local v1 = c - a
	local v2 = p - a
    local d00 = rmath:vec3_dot(v0, v0)
    local d01 = rmath:vec3_dot(v0, v1)
    local d11 = rmath:vec3_dot(v1, v1)
    local d20 = rmath:vec3_dot(v2, v0)
    local d21 = rmath:vec3_dot(v2, v1)
    local denom = d00 * d11 - d01 * d01
    local v = (d11 * d20 - d01 * d21) / denom
    local w = (d00 * d21 - d01 * d20) / denom
    local u = 1.0 - v - w

	return u,v,w
end

local function barycentric_lerp(_a,_b,_c, _u,_v,_w)
	return _a*_u + _b*_v + _c*_w
end

local function fetch_attrib(_attr,_bary)
	return barycentric_lerp(_attr[1],_attr[2],_attr[3],_bary.X,_bary.Y,_bary.Z) * _bary.W
end

local index = 0
local shader_input = nil
local light = 1
local p1,p2,p3,p4

local STAGE_SHADOW = false

local function uv_to_pixel_coordinate(_uv, _width, _height)
	_uv = vec2((_uv.X % 1) * _width, (_uv.Y % 1) * _height)
	_uv = vec2(math.floor(_uv.X % _width), math.floor(_uv.Y % _width))
	return vec2(_uv.X+1, _uv.Y+1)
end

local function calculate_tb(_pos, _uvs, _normal)
	local uv1 = vec2(_uvs[1].X, -_uvs[1].Y)
	local uv2 = vec2(_uvs[2].X, -_uvs[2].Y)
	local uv3 = vec2(_uvs[3].X, -_uvs[3].Y)

	local edge1 = _pos[2] - _pos[1]
	local edge2 = _pos[3] - _pos[1]
	local deltaUV1 = uv2 - uv1
	local deltaUV2 = uv3 - uv1 

	local f = 1.0 / (deltaUV1.X * deltaUV2.Y - deltaUV2.X * deltaUV1.Y)

	local tangent = rmath:vec3_normalize(vec3(
		f * (deltaUV2.Y * edge1.X - deltaUV1.Y * edge2.X),
		f * (deltaUV2.Y * edge1.Y - deltaUV1.Y * edge2.Y),
		f * (deltaUV2.Y * edge1.Z - deltaUV1.Y * edge2.Z)
	))

	local bitangent = rmath:vec3_normalize(vec3(
		f * (-deltaUV2.X * edge1.X + deltaUV1.X * edge2.X),
		f * (-deltaUV2.X * edge1.Y + deltaUV1.X * edge2.Y),
		f * (-deltaUV2.X * edge1.Z + deltaUV1.X * edge2.Z)
	))

	return tangent, bitangent
end

local function colvec3(_vec)
	return Color(
		_vec.X * 255,
		_vec.Y * 255,
		_vec.Z * 255
	)
end

local function material_func(_x, _y, _pixel) -- : color
	if DEBUG == 1 then
		if _pixel.R + _pixel.G + _pixel.B == 0 then
			return color.white
		else
			return color.black
		end
	elseif DEBUG == 2 then
		return Color(
			rmath:lerp(_pixel.R, 255, 0.5), 
			rmath:lerp(_pixel.G, 255, 0.5), 
			rmath:lerp(_pixel.B, 255, 0.5)
		)
	else
		index = bit32.bor(_pixel.R, bit32.lshift(_pixel.G,8), bit32.lshift(_pixel.B,16))

		if index > 0 then 
			p1 = rg3d:get_draw_call(index).args[1] 
			p2 = rg3d:get_draw_call(index).args[2] 
			p3 = rg3d:get_draw_call(index).args[3] 
			p4 = rg3d:get_draw_call(index).args[4] -- position 4 (quad) OR shader input (triangle)
			shader_input = rg3d:get_draw_call(index).args[5] or p4

			local clip_space_point = rmath:vec3_from_screen(vec2(_x,_y), gdt.VideoChip0.Width, gdt.VideoChip0.Height)
			local cs = shader_input.clip_space_vertices
			local u,v,w = barycentric(
				clip_space_point, 
				vec3(cs[1].X, cs[1].Y, 0), 
				vec3(cs[2].X, cs[2].Y, 0), 
				vec3(cs[3].X, cs[3].Y, 0)
			)

			local a_texcoord  = fetch_attrib(shader_input.texcoords, u,v,w)
			local pixel_coord = uv_to_pixel_coordinate(a_texcoord, 256, 256)

			local a_normal  = rmath:vec3_normalize(fetch_attrib(shader_input.vertex_normals,  u,v,w))
--			local a_tangent = rmath:vec3_normalize(fetch_attrib(shader_input.vertex_tangents, u,v,w))
--			local bitangent = shader_input.bitangent_sign * rmath:vec3_cross(a_normal, a_tangent)

			local tex_albedo = albedo_data:GetPixel(pixel_coord.X, pixel_coord.Y)
			--return Color(u*255, v*255, w*255)
			return colvec3(a_normal)
			--return tex_albedo
--			local tex_normal = normal_data:GetPixel(pixel_coord.X, pixel_coord.Y)
--			tex_normal = vec3(tex_normal.R-127.5, tex_normal.G-127.5, tex_normal.B-127.5)
--
--			local TBN    = rmath:mat3x3_from_vec3(a_tangent, bitangent, a_normal)
--			local normal = rmath:vec3_normalize(rmath:vec3_mult_mat3(tex_normal, TBN))
--			light = rmath:vec3_dot(ms_light_dir, normal)
--
--			return Color(
--				light * tex_albedo.R,
--				light * tex_albedo.G,
--				light * tex_albedo.B
--			)
		end
	end
end

local function screen_to_clip(_vec2, _width, _height)
	return vec2(
		(_vec2.X / _width ) * 2.0 - 1.0,
		(_vec2.Y / _height) * 2.0 - 1.0
	)
end

local function compute_true_barycentric(_cs_point, _cs1, _cs2, _cs3, _invz1, _invz2, _invz3)

	local u,v,w = barycentric(
		_cs_point, 
		vec3(_cs1.X, _cs1.Y, 0), 
		vec3(_cs2.X, _cs2.Y, 0), 
		vec3(_cs3.X, _cs3.Y, 0)
	)

	local z = 1 / (u * _invz1 + v * _invz2 + w * _invz3)

	return rmath:vec4(
		u / _cs1.Z, 
		v / _cs2.Z, 
		w / _cs3.Z, 
		z
	)
end

local function material_func2(_x, _y, _pixel) -- : color
	index = bit32.bor(_pixel.R, bit32.lshift(_pixel.G,8), bit32.lshift(_pixel.B,16))

	if index > 0 then 
		p1 = rg3d:get_draw_call(index).args[1] 
		p2 = rg3d:get_draw_call(index).args[2] 
		p3 = rg3d:get_draw_call(index).args[3] 
		p4 = rg3d:get_draw_call(index).args[4] -- position 4 (quad) OR shader input (triangle)
		shader_input = rg3d:get_draw_call(index).args[5] or p4
		
		local clip_space_point = rmath:vec3_from_screen(vec2(_x,_y), gdt.VideoChip0.Width, gdt.VideoChip0.Height)
		local cs = shader_input.clip_space_vertices
		local bary = compute_true_barycentric(clip_space_point, cs[1], cs[2], cs[3],shader_input.inv_Zs[1],shader_input.inv_Zs[2],shader_input.inv_Zs[3])

		local a_texcoord = fetch_attrib(shader_input.texcoords, bary)
		
		local pixel_coord = uv_to_pixel_coordinate(a_texcoord, 256, 256)
		
		local tex_color = albedo_data:GetPixel(pixel_coord.X, pixel_coord.Y)
		
		return tex_color -- colvec3(vec3(r,g,b)) -- colvec3(vec3(u,v,w))
	end
end

local function material_pass(spans, vis_pd, target_pd)
	for y = math.max(1, spans.top), math.min(target_pd.Height, spans.bottom) do
		if spans.spans[y] then
			for x = math.max(1, spans.spans[y][1]), math.min(target_pd.Width, spans.spans[y][2]) do
				local frag_color = material_func2(x,y,vis_pd:GetPixel(x,y))	
				if frag_color then
					target_pd:SetPixel(x,y, frag_color)
				end
			end
		end
	end
end

function state_game:draw()
	local time = 0 -- gdt.CPU0.Time
	light_dir = vec3(0,0,-1)
	
	-- Model Setup
	local model = nil
	model = rmath:mat4_translate(model, vec3(0,0,zoom))
	model = rmath:mat4_rotateX(model, rotate_x)
	model = rmath:mat4_rotateY(model, rotate_y)
	
	-- Shading pass
	if STAGE_SHADOW then -- kinda broken
		rshaders:use_funcs("index")
		gdt.VideoChip0:RenderOnBuffer(5) -- shading buffer
		gdt.VideoChip0:Clear(color.black)
		rg3d:push_look_at(light_dir * 3.5, -light_dir, vec3(0,1,0))
		rg3d:push_model_matrix(model)

		ms_light_dir = rg3d:get_model_space_ligt_dir()
		model_view_mat = rg3d:get_model_view_mat()
		
		rg3d:begin_render()
			rmesh:drawlist_submit(demo_mesh,shadow_rb.Width,shadow_rb.Height)
		rg3d:end_render()
	end
	
	-- Visbility Pass
	rshaders:use_funcs("draw_id")
	gdt.VideoChip0:RenderOnBuffer(1) -- vis buffer
	shadow_data = shadow_rb:GetPixelData()
	gdt.VideoChip0:Clear(color.black)
	
	rg3d:push_model_matrix(model)
	rg3d:push_look_at(engine.camera_pos, engine.camera_pos + engine.camera_dir, vec3(0,1,0))
	rg3d:set_light_dir(light_dir)
	ms_light_dir = rg3d:get_model_space_ligt_dir()

	rg3d:begin_render()
		rmesh:drawlist_submit(demo_mesh)
	local spans = rg3d:end_render() or {}
	
	gdt.VideoChip0:RenderOnBuffer(2)
	 -- normal rendering here
	if engine.IS_RG then
		gdt.VideoChip0:Clear(color.black)
	else
		gdt.VideoChip0:Clear(Color(29,29,29))
	end
	gdt.VideoChip0:DrawText(vec2(0,gdt.VideoChip0.Height-16),font,"Click and drag to rotate",color.white,color.clear)
	gdt.VideoChip0:DrawText(vec2(0,gdt.VideoChip0.Height-8),font,"Up and down arrow to zoom in and out",color.white,color.clear)
	
	gdt.VideoChip0:RenderOnScreen()
	
	--gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),vis_renderbuffer,vis_renderbuffer.Width,vis_renderbuffer.Height)

	local vis_pd = vis_renderbuffer:GetPixelData()
	local target_pd = target_renderbuffer:GetPixelData()

	material_pass(spans, vis_pd, target_pd)

	gdt.VideoChip0:BlitPixelData(vec2(0,0), target_pd)

	if DEBUG == 1 then
		gdt.VideoChip0:DrawText(vec2(0,8),font,"RENDER DEBUG MODE",color.white,color.black)
	end
end

return state_game