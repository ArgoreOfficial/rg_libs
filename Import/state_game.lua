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
	--demo_mesh = rmesh:require_drawlist("kanohi_hau", vec3(0,-0.25,0.2), vec3(0,0,0))
	demo_mesh = rmesh:require_drawlist("penta")	
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

local index = 0
local shader_input = nil
local light = 1
local p1,p2,p3,p4

local STAGE_SHADOW = false

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
			
			local u,v,w = barycentric(vec2(_x,_y), p1, p2, p3)
			
			local tex_uv = barycentric_lerp(
				shader_input.texcoords[1], 
				shader_input.texcoords[2], 
				shader_input.texcoords[3],  
				u,v,w )

			tex_uv = vec2((tex_uv.X % 1) * albedo_data.Width, (tex_uv.Y % 1) * albedo_data.Height)
			tex_uv = vec2(math.floor(tex_uv.X % albedo_data.Width), math.floor(tex_uv.Y % albedo_data.Width))
			
			local N = barycentric_lerp(
				shader_input.vertex_normals[1],
				shader_input.vertex_normals[2],
				shader_input.vertex_normals[3],
				u,v,w 
			)

			local tex_albedo = albedo_data:GetPixel(tex_uv.X+1, tex_uv.Y+1)
			light = math.min(math.max(0.1, rmath:vec3_dot(ms_light_dir, N)),1)

			-- Do shadow pass
			if STAGE_SHADOW then
				-- TODO: shader input model space positions
				local ws_fragpos = barycentric_lerp(
					demo_mesh[shader_input.primitive_index][2][1][1],
					demo_mesh[shader_input.primitive_index][2][1][2],
					demo_mesh[shader_input.primitive_index][2][1][3],
					u,v,w 
				)

				local function to_view(_vec)
					local v4  = rmath:vec4(_vec.X, _vec.Y, _vec.Z, 1)
					return rmath:mat4_transform(model_view_mat, v4)
				end

				local function view_to_clip(_vec)
					local cv4 = rg3d:project(_vec)
					return rmath:vec4(
						cv4.X / cv4.W,
						cv4.Y / cv4.W,
						cv4.Z )
				end

				local function to_screen(_vec, _screen_width, _screen_height)
					return rmath:vec3_to_screen(view_to_clip(to_view(_vec)), _screen_width, _screen_height)
				end

				local shadow_pixel_pos = to_screen(ws_fragpos, shadow_rb.Width, shadow_rb.Height)
				

				local this_prim = shader_input.primitive_index
				local is_prim = false
				for s_y = -2, 2 do
					for s_x = -2, 2 do
						local shadow_pixel = shadow_data:GetPixel(
							math.min(math.max(1, shadow_pixel_pos.X + s_x + 0.5), shadow_rb.Width),
							math.min(math.max(1, shadow_pixel_pos.Y + s_y + 0.5), shadow_rb.Height)
						)
						
						local shadow_prim = bit32.bor(shadow_pixel.R, bit32.lshift(shadow_pixel.G,8), bit32.lshift(shadow_pixel.B,16))
						
						if shadow_prim == this_prim then is_prim = true end
					end
				end
				
				light = is_prim and light or 0.1
			end

			local frag = Color(
				light * tex_albedo.R,
				light * tex_albedo.G,
				light * tex_albedo.B
			)

			return frag
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
	local time = 0 -- gdt.CPU0.Time
	light_dir = vec3(0,0,-1)
	
	-- Model Setup
	local model = nil
	model = rmath:mat4_translate(model, vec3(0,-0.2,zoom))
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