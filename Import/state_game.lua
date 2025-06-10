local state_game = {}

local engine   = require "engine"
local rmath    = require "rg_math"
local rmesh    = require "rg_mesh"
local rg3d     = require("rg_3d")
local rshaders = require("rg_shaders")

local state_machine = require("state_machine")

local vis_renderbuffer = gdt.VideoChip0.RenderBuffers[1]
local target_renderbuffer = gdt.VideoChip0.RenderBuffers[2]
local texture_rb = gdt.VideoChip0.RenderBuffers[3]
local normal_rb = gdt.VideoChip0.RenderBuffers[4]
local shadow_rb = gdt.VideoChip0.RenderBuffers[5]
local test_buffer = {}

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

local touch_last = nil
local touch_delta = vec2(0,0)

local font = gdt.ROM.System.SpriteSheets["StandardFont"]

local shader_input = nil
local light = 1

local STAGE_SHADOW = true

local clear_color = vec3(0,0,0)
if not engine.IS_RG then
	clear_color = vec3(29,29,29)
end

--------------------------------------------------------
--[[  GLSL Compat                                     ]]
--------------------------------------------------------

local function texture(_texture, _texcoord)
	local pixel_x = (_texcoord.X * (_texture.Width )) + 1
	local pixel_y = (_texcoord.Y * (_texture.Height)) + 1
	
	-- wrap X and Y coordinate
	while pixel_x <= 0 do pixel_x = pixel_x + _texture.Width  end
	while pixel_y <= 0 do pixel_y = pixel_y + _texture.Height end

	while pixel_x > _texture.Width  do pixel_x = pixel_x - _texture.Width  end
	while pixel_y > _texture.Height do pixel_y = pixel_y - _texture.Height end

	return _texture:GetPixel(pixel_x, pixel_y)
end

local function packUnorm3x8(v)
	return bit32.bor(v.R, bit32.lshift(v.G, 8), bit32.lshift(v.B, 16))
end

--------------------------------------------------------
--[[  Shaders                                         ]]
--------------------------------------------------------

local function barycentric(_point, _p1, _p2, _p3)
    local v0 = _p2 - _p1
	local v1 = _p3 - _p1
	local v2 = _point - _p1
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

local function barycentric_lerp(_v1, _v2, _v3, _u, _v, _w)
	return _v1*_u + _v2*_v + _v3*_w
end

local function fetch_attrib(_attr,_bary)
	return barycentric_lerp(_attr[1],_attr[2],_attr[3],_bary.X,_bary.Y,_bary.Z) * _bary.W
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

local function material_func(_x, _y, _pixel, _index)
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
		if _index > 0 then 
			shader_input = rg3d:get_draw_call(_index).args[5] or rg3d:get_draw_call(_index).args[4]

			-- triangle fetch
			local clip_space_point = rmath:vec3_from_screen(vec2(_x,_y), gdt.VideoChip0.Width, gdt.VideoChip0.Height)
			local cs = shader_input.clip_space_vertices
			local bary = compute_true_barycentric(clip_space_point, cs[1], cs[2], cs[3],shader_input.inv_Zs[1],shader_input.inv_Zs[2],shader_input.inv_Zs[3])

			local world_space_point = fetch_attrib(demo_mesh[shader_input.primitive_index][2][1], bary)

			local shadow_point = rg3d:to_screen(world_space_point, shadow_rb.Width, shadow_rb.Height)

			local in_shadow = true
			for offset_y = -1, 1 do
				for offset_x = -1, 1 do
					shadow_point = shadow_point + vec2(offset_x, offset_y)
					if in_shadow then
						if shadow_point.X >= 1 and shadow_point.X < shadow_rb.Width and shadow_point.Y >= 1 and shadow_point.Y < shadow_rb.Height then
							
								--shadow_data:SetPixel(math.floor(shadow_point.X+0.5), math.floor(shadow_point.Y+0.5), rmath:vec3_to_color(shadow_point))
								local shadow_pixel = shadow_data:GetPixel(math.floor(shadow_point.X+0.5), math.floor(shadow_point.Y+0.5))
								local shadow_index = packUnorm3x8(shadow_pixel)
								--if shader_input.primitive_index ~= shadow_index then return color.black end
								if shader_input.primitive_index == shadow_index then in_shadow = false end
								
								--return color.white
							
						end
					end
				end
			end

			if in_shadow then return color.black end
			
--			if math.abs(clip_space_point.X) < 1 and math.abs(clip_space_point.Y) < 1 then	
--				local shadow_point = rmath:vec3_to_screen(clip_space_point, shadow_rb.Width, shadow_rb.Height)
--				--local shadow_pixel = shadow_data:GetPixel(shadow_point.X, shadow_point.Y)
--				--local shadow_index = packUnorm3x8(shadow_pixel)
--				shadow_data:SetPixel(shadow_point.X, shadow_point.Y, color.white)
--				
--				-- if shader_input.primitive_index == shadow_index then return shadow_pixel end
--				--return shadow_pixel
--				return color.white
--			end

			-- attribute fetch
			local a_texcoord  = fetch_attrib(shader_input.texcoords, bary)
			local a_normal  = rmath:vec3_normalize(fetch_attrib(shader_input.vertex_normals,  bary))
			local a_tangent = rmath:vec3_normalize(fetch_attrib(shader_input.vertex_tangents, bary))
			local bitangent = shader_input.bitangent_sign * rmath:vec3_cross(a_normal, a_tangent)

			-- texture fetch
			local tex_albedo = texture(albedo_data, a_texcoord)
			local tex_normal = texture(normal_data, a_texcoord)
			tex_normal = vec3(tex_normal.R-127.5, tex_normal.G-127.5, tex_normal.B-127.5)

			-- normal calculation
			local TBN    = rmath:mat3x3_from_vec3(a_tangent, bitangent, a_normal)
			local normal = rmath:vec3_normalize(rmath:vec3_mult_mat3(tex_normal, TBN))
			light = rmath:vec3_dot(ms_light_dir, normal)
			light = math.max(0, math.min(1, light))

			-- light lerp
			local vec3_col = vec3(tex_albedo.R, tex_albedo.G, tex_albedo.B)
			local frag_color = rmath:lerp(clear_color, vec3_col, light)

			return Color(frag_color.X,frag_color.Y,frag_color.Z)
		end
	end
end

local function material_pass(spans, vis_pd, target_pd)
	local pixel = nil
	for y = math.max(1, spans.top), math.min(target_pd.Height, spans.bottom) do
		if spans.spans[y] then
			for x = math.max(1, spans.spans[y][1]), math.min(target_pd.Width, spans.spans[y][2]) do
				pixel = vis_pd:GetPixel(x,y)
				local frag = material_func(x,y, pixel, packUnorm3x8(pixel))
				if frag then target_pd:SetPixel(x,y, frag) end
			end
		end
	end
end

--------------------------------------------------------
--[[  State                                           ]]
--------------------------------------------------------

function state_game:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)
	
	demo_mesh = rmesh:require_drawlist("penta")	
	engine.camera_pos = vec3(0,0,3.5)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-90)
	
	engine.push_look_at = false -- look at will be manually pushed

	gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- vis buffer
	gdt.VideoChip0:SetRenderBufferSize(2, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- target buffer
	gdt.VideoChip0:SetRenderBufferSize(3, 256, 256) -- albedo texture buffer
	gdt.VideoChip0:SetRenderBufferSize(4, 256, 256) -- normal texture buffer
	gdt.VideoChip0:SetRenderBufferSize(5, 4096, 4096) -- shadow buffer
	
	albedo_data = require("TX_penta_albedo"):toPixelData(texture_rb:GetPixelData())
	normal_data = require("TX_penta_normal"):toPixelData(normal_rb:GetPixelData())

	for i = 1, gdt.VideoChip0.Width * gdt.VideoChip0.Height do
		test_buffer[i] = 0
	end
end

function state_game:on_exit()
	engine.push_look_at = true
end

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

function state_game:draw()
	light_dir = vec3(1,0,-1)
	
	-- Model Setup
	local model = nil
	model = rmath:mat4_scale(model, vec3(1-zoom,1-zoom,1-zoom))
	model = rmath:mat4_rotateX(model, rotate_x)
	model = rmath:mat4_rotateY(model, rotate_y)
	
	-- Shading pass
	if STAGE_SHADOW then -- kinda broken
		rshaders:use_funcs("index")
		gdt.VideoChip0:RenderOnBuffer(5) -- shading buffer
		gdt.VideoChip0:Clear(color.black)
		rg3d:push_look_at(-light_dir * 3.5, -light_dir, vec3(0,1,0))
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
	
	local vis_pd = vis_renderbuffer:GetPixelData()
	local target_pd = target_renderbuffer:GetPixelData()

	rg3d:push_look_at(-light_dir * 3.5, -light_dir, vec3(0,1,0))
	rg3d:push_model_matrix(model)

	material_pass(spans, vis_pd, target_pd)

	gdt.VideoChip0:BlitPixelData(vec2(0,0), target_pd)
	
	gdt.VideoChip0:RenderOnBuffer(5)
	gdt.VideoChip0:BlitPixelData(vec2(0,0), shadow_data)
	gdt.VideoChip0:RenderOnScreen()
	
	--gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),shadow_rb,shadow_rb.Width,shadow_rb.Height)

	if DEBUG == 1 then
		gdt.VideoChip0:DrawText(vec2(0,8),font,"RENDER DEBUG MODE",color.white,color.black)
	end
end

return state_game