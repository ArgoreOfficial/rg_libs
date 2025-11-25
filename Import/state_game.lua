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
local zoom = 1

local DEBUG = 0

local touch_last = nil
local touch_delta = vec2(0,0)

local font = gdt.ROM.System.SpriteSheets["StandardFont"]

local shader_input = nil
local light = 1

local STAGE_SHADOW = true

local clear_color = vec3(0,0,0)
if not engine.IS_RG then
	--clear_color = vec3(29,29,29)
end

--------------------------------------------------------
--[[  GLSL Compat                                     ]]
--------------------------------------------------------

local function texture(_texture, _texcoord)
	local pixel_x = math.floor((_texcoord.X * (_texture.Width )) + 1)
	local pixel_y = math.floor((_texcoord.Y * (_texture.Height)) + 1)
	
	-- wrap X and Y coordinate
	while pixel_x < 1 do pixel_x = pixel_x + _texture.Width  end
	while pixel_y < 1 do pixel_y = pixel_y + _texture.Height end

	while pixel_x > _texture.Width  do pixel_x = pixel_x - _texture.Width  end
	while pixel_y > _texture.Height do pixel_y = pixel_y - _texture.Height end

	return _texture:GetPixel(pixel_x, pixel_y)
end

local function packUnorm3x8(v)
	return bit32.bor(v.R, bit32.lshift(v.G, 8), bit32.lshift(v.B, 16))
end

--------------------------------------------------------
--[[  Maths                                           ]]
--------------------------------------------------------

-- triangle = {a:vec3, b:vec3, c:vec3}
function ray_intersects_triangle(ray_origin, ray_vector, triangle)
    local epsilon = 0.0000001

    local edge1 = triangle[2] - triangle[1]
    local edge2 = triangle[3] - triangle[1]
    local ray_cross_e2 = rmath:vec3_cross(ray_vector, edge2)
    local det = rmath:vec3_dot(edge1, ray_cross_e2)

    if det > -epsilon and det < epsilon then
        return nil -- This ray is parallel to this triangle.
    end

    local inv_det = 1.0 / det
    local s = ray_origin - triangle[1]
    local u = inv_det * rmath:vec3_dot(s, ray_cross_e2)

    if ((u < 0 and math.abs(u) > epsilon) or (u > 1 and math.abs(u-1) > epsilon)) then
        return nil
    end

    local s_cross_e1 = rmath:vec3_cross(s, edge1)
    local v = inv_det * rmath:vec3_dot(ray_vector, s_cross_e1)

    if ((v < 0 and math.abs(v) > epsilon) or (u + v > 1 and math.abs(u + v - 1) > epsilon)) then
        return nil 
    end

    -- At this stage we can compute t to find out where the intersection point is on the line.
    local t = inv_det * rmath:vec3_dot(edge2, s_cross_e1)

    if t > epsilon then -- ray intersection
        return  vec3(ray_origin + ray_vector * t)
    else -- This means that there is a line intersection but not a ray intersection.
        return nil
    end
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

local function material_func(_x, _y, _pixel, _index, _vis_pd)
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
			DO_SHADING = true
			local gl_FragColor = vec3(255,255,255)

			light = 1.0

			-- triangle fetch
			local clip_space_point = rmath:vec3_from_screen(vec2(_x,_y), gdt.VideoChip0.Width, gdt.VideoChip0.Height)
			local cs = shader_input.clip_space_vertices
			local bary = compute_true_barycentric(clip_space_point, cs[1], cs[2], cs[3],shader_input.inv_Zs[1],shader_input.inv_Zs[2],shader_input.inv_Zs[3])

			local world_space_point = fetch_attrib(demo_mesh[shader_input.primitive_index][2][1], bary)
			local a_normal  = rmath:vec3_normalize(fetch_attrib(shader_input.vertex_normals,  bary))

			if rmath:vec3_dot(a_normal, ms_light_dir) > 0.0 then
				for i = 1, #demo_mesh do
					if i ~= shader_input.primitive_index then
						-- [i] command -> [2] data -> [4] extra -> .normal
						if rmath:vec3_dot(demo_mesh[i][2][4].normal, ms_light_dir) > 0.0 then
							-- [i] command -> [2] data -> [1] face
							if ray_intersects_triangle(world_space_point, ms_light_dir, demo_mesh[i][2][1]) then
								light = 0.0
								i = #demo_mesh
							end
						end
					end
				end
			else
				light = 0.0
			end

			if false then
				-- attribute fetch
				local a_texcoord  = fetch_attrib(shader_input.texcoords, bary)
				
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

				gl_FragColor = vec3(tex_albedo.R, tex_albedo.G, tex_albedo.B)
			else
				-- attribute fetch
				local a_texcoord  = fetch_attrib(shader_input.texcoords, bary)
				
				-- texture fetch
				local tex_albedo = texture(albedo_data, a_texcoord)
				gl_FragColor = vec3(tex_albedo.R, tex_albedo.G, tex_albedo.B)
			end
		
			-- light lerp
			light = rmath:map_range(light, 0, 1, 0.2, 1.0)
			local frag_color = rmath:lerp(clear_color, gl_FragColor, light)

			return Color(frag_color.X,frag_color.Y,frag_color.Z)
			--return Color(
			--	world_space_point.X * 255,
			--	world_space_point.Y * 255,
			--	world_space_point.Z * 255
			--)
		end
	end
end

local function material_pass(spans, _vis_pd, target_pd)
	local pixel = nil
	for y = math.max(1, spans.top), math.min(target_pd.Height, spans.bottom) do
		if spans.spans[y] then
			for x = math.max(1, spans.spans[y][1]), math.min(target_pd.Width, spans.spans[y][2]) do
				pixel = _vis_pd:GetPixel(x,y)
				local frag = material_func(x,y, pixel, packUnorm3x8(pixel), _vis_pd)
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
	gdt.VideoChip0:SetRenderBufferSize(5, 512, 512) -- shadow buffer
	
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

	if engine.rinput["UpArrow"]    then zoom = zoom / (1 + _delta_time) end
	if engine.rinput["DownArrow"]  then zoom = zoom * (1 + _delta_time) end
	
	zoom = math.min(3, math.max(0.7, zoom))

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
	light_dir = vec3(1,-0,-1)
	light_dir = rmath:vec3_normalize(light_dir)
	
	-- Model Setup
	local model = nil
	local zoom_scale = 1 / (zoom*zoom)
	model = rmath:mat4_scale(model, vec3(zoom_scale,zoom_scale,zoom_scale))
	model = rmath:mat4_rotateX(model, rotate_x)
	model = rmath:mat4_rotateY(model, rotate_y)
	
	-- Shading pass
	if DEBUG == 0 and STAGE_SHADOW then -- kinda broken
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