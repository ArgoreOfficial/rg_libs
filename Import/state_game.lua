local state_game = {}

local engine   = require "engine"
local rmath    = require "rg_math"
local rmesh    = require "rg_mesh"
local rg3d     = require("rg_3d")
local rshaders = require("rg_shaders")

local state_machine = require("state_machine")
local FPS = 0

local rb1 = gdt.VideoChip0.RenderBuffers[1]
local kanohi_hau = nil

function state_game:on_enter()
	rg3d:push_perspective(
		gdt.VideoChip0.Width / gdt.VideoChip0.Height,    -- screen aspect ratio
		rmath:radians(30), -- half FOV (radians)
		0.5,  -- near clip
		50    -- far clip
	)
	kanohi_hau = rmesh:require_drawlist("kanohi_hau", vec3(0,-0.25,0), vec3(0,0,0))

	engine.camera_pos = vec3(0,0,2)
	engine.camera_pitch = 0
	engine.camera_yaw   = rmath:radians(-90)
	
	gdt.VideoChip0:SetRenderBufferSize(1, gdt.VideoChip0.Width, gdt.VideoChip0.Height)
end

function state_game:on_exit()
	-- on exit
end

function state_game:update(_delta_time)
	if _delta_time == 0 then FPS = 0 
	else FPS = 1 / _delta_time end
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

function state_game:draw()
	if not rb1 then return end
	if not kanohi_hau then return end

	local light_dir = -vec3(
		math.cos(gdt.CPU0.Time),
		0,
		math.sin(gdt.CPU0.Time)
	)
	rg3d:set_light_dir(-light_dir)

	rshaders:use_funcs("draw_id")

	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.black)
	rg3d:push_model_matrix(nil)
	
	rg3d:begin_render()
		rmesh:drawlist_submit(kanohi_hau)
	local spans = rg3d:end_render() or {}
	
	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:Clear(color.blue)
	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)

	local pd = rb1:GetPixelData()
	local index = 0
	local pixel = nil
	local shader_input = nil
	local light_col = 1
	local p1,p2,p3,p4

	local DEBUG = 0
	if engine.IS_RG then
		DEBUG = gdt.Switch0.State and 1 or 0
	end

	for y = spans.top, spans.bottom do
		if y > 0 and y <= pd.Height then
			if spans.spans[y] then
				for x = spans.spans[y][1], spans.spans[y][2] do
					if x > 0 and x <= pd.Width then
						pixel = pd:GetPixel(x,y)
						if DEBUG == 1 then
							if pixel.R + pixel.G + pixel.B == 0 then
								pd:SetPixel(x,y,color.white)		
							end
						elseif DEBUG == 2 then
							pd:SetPixel(x,y, Color(
								rmath:lerp(pixel.R, 255, 0.5), 
								rmath:lerp(pixel.G, 255, 0.5), 
								rmath:lerp(pixel.B, 255, 0.5)
							))		
						else
							index = bit32.bor(
								pixel.R,
								bit32.lshift(pixel.G,8),
								bit32.lshift(pixel.B,16))
				
							if index > 0 then 
								p1 = rg3d:get_draw_call(index).args[1] 
								p2 = rg3d:get_draw_call(index).args[2] 
								p3 = rg3d:get_draw_call(index).args[3] 
								p4 = rg3d:get_draw_call(index).args[4] -- position 4 (quad) OR shader input (triangle)
								shader_input = rg3d:get_draw_call(index).args[5] or p4

								local u,v,w = barycentric(vec2(x,y), p1, p2, p3)
								local ws_normal = barycentric_lerp(
									shader_input.vertex_normals[1],
									shader_input.vertex_normals[2],
									shader_input.vertex_normals[3],
									u,v,w 
								)
								-- light_col =  shader_input.light_intensity or 1
								light_col = rmath:vec3_dot(light_dir, ws_normal)

								pd:SetPixel(x,y, Color(
									shader_input.color.R * light_col,
									shader_input.color.G * light_col,
									shader_input.color.B * light_col
								))
							end
						end
					end
				end
			end
		end
	end

	gdt.VideoChip0:BlitPixelData(vec2(0,0), pd)
end

return state_game