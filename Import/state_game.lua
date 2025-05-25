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

local demo_mesh = {}
local albedo_data = {}
local normal_data = nil
local ms_light_dir = vec3(0,1,0)

local DEBUG = 0

function state_game:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)
	--demo_mesh = rmesh:require_drawlist("kanohi_hau", vec3(0,-0.25,0.2), vec3(0,0,0))
	demo_mesh = rmesh:require_drawlist("penta", vec3(0,-0.3,0), vec3(0,-35,0))	
	engine.camera_pos = vec3(0,0,3.1)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-90)
	
	gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- vis buffer
	gdt.VideoChip0:SetRenderBufferSize(2, gdt.VideoChip0.Width, gdt.VideoChip0.Height) -- target buffer
	gdt.VideoChip0:SetRenderBufferSize(3, 256, 256) -- albedo texture buffer
	gdt.VideoChip0:SetRenderBufferSize(4, 256, 256) -- normal texture buffer
	
	albedo_data = require("TX_penta_albedo"):toPixelData(texture_rb:GetPixelData())
	normal_data = require("TX_penta_normal"):toPixelData(normal_rb:GetPixelData())
end

function state_game:on_exit()
	-- on exit
end

function state_game:update(_delta_time)
	if _delta_time == 0 then FPS = 0 
	else FPS = 1 / _delta_time end

	if engine.IS_RG then
		DEBUG = gdt.Switch0.State and 1 or 0
	end

	NORMAL_MODE = (gdt.CPU0.Time % 4 < 2) and 1 or 0
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

local index = 0
local shader_input = nil
local light = 1
local p1,p2,p3,p4

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
			
			-- TODO: shader input model space positions
			local ms_p1 = demo_mesh[shader_input.primitive_index][2][1][1]
			local ms_p2 = demo_mesh[shader_input.primitive_index][2][1][2]
			local ms_p3 = demo_mesh[shader_input.primitive_index][2][1][3]
			
			local u,v,w = barycentric(vec2(_x,_y), p1, p2, p3)
			local ws_normal = barycentric_lerp(
				shader_input.vertex_normals[1],
				shader_input.vertex_normals[2],
				shader_input.vertex_normals[3],
				u,v,w 
			)
			
			local tex_uv = barycentric_lerp(
				shader_input.texcoords[1], 
				shader_input.texcoords[2], 
				shader_input.texcoords[3],  
				u,v,w )

			tex_uv = vec2((tex_uv.X % 1) * albedo_data.Width, (tex_uv.Y % 1) * albedo_data.Height)
			tex_uv = vec2(math.floor(tex_uv.X % albedo_data.Width), math.floor(tex_uv.Y % albedo_data.Width))
			
			local T = barycentric_lerp(
				shader_input.vertex_tangents[1],
				shader_input.vertex_tangents[2],
				shader_input.vertex_tangents[3],
				u,v,w 
			)

			local B = barycentric_lerp(
				shader_input.vertex_bitangents[1],
				shader_input.vertex_bitangents[2],
				shader_input.vertex_bitangents[3],
				u,v,w 
			)

			local N = ws_normal
			
			local TBN = rmath:mat3x3(
				T.X, T.Y, T.Z, 
				B.X, B.Y, B.Z, 
				N.X, N.Y, N.Z
			)
			--TBN = rmath:mat3_transpose(TBN)
			
			local tex_normal = normal_data:GetPixel(tex_uv.X+1, tex_uv.Y+1)
			local ts_normal = rmath:vec3_normalize(vec3(
				(tex_normal.R / 255) * 2.0 - 1.0,
				(tex_normal.G / 255) * 2.0 - 1.0,
				(tex_normal.B / 255) * 2.0 - 1.0
			))

			function vec3_to_col(_vec) 
				return Color(
					(_vec.X) * 255,
					(_vec.Y) * 255,
					(_vec.Z) * 255
				)
			end

			local ws_tex_normal = rmath:mat3_mult_vec3(TBN, ts_normal)

			local tex_col = albedo_data:GetPixel(tex_uv.X+1, tex_uv.Y+1)

			light = math.min(math.max(0.1, rmath:vec3_dot(ms_light_dir, ws_tex_normal)),1)
			local frag_color =  Color(
				light * tex_col.R,
				light * tex_col.G,
				light * tex_col.B
			)

			return frag_color
		end
	end
end

local function material_pass(spans, vis_pd, target_pd)
	for y = spans.top, spans.bottom do
		if y > 0 and y <= target_pd.Height then
			if spans.spans[y] then
				for x = spans.spans[y][1], spans.spans[y][2] do
					if x > 0 and x <= target_pd.Width then
						local frag_color = material_func(x,y,vis_pd:GetPixel(x,y))
						if frag_color then
							target_pd:SetPixel(x,y, frag_color)
						end
					end
				end
			end
		end
	end
end

function state_game:draw()
	local light_dir = vec3(
		math.sin(gdt.CPU0.Time),
		1,
		math.cos(gdt.CPU0.Time)
	)
	rg3d:set_light_dir(light_dir)

	rshaders:use_funcs("draw_id")

	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.black)

	-- Visbility pass

	local model = nil
	--model = rmath:mat4_rotateY(model, gdt.CPU0.Time)
	
	rg3d:push_model_matrix(model)
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
	gdt.VideoChip0:RenderOnScreen()

	--gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),vis_renderbuffer,vis_renderbuffer.Width,vis_renderbuffer.Height)

	local vis_pd = vis_renderbuffer:GetPixelData()
	local target_pd = target_renderbuffer:GetPixelData()
	
	material_pass(spans, vis_pd, target_pd)

	gdt.VideoChip0:BlitPixelData(vec2(0,0), target_pd)
end

return state_game