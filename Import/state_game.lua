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
	kanohi_hau = rmesh:require_drawlist("kanohi_hau", vec3(0,-0.4,-3), vec3(0,90,0))

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

function state_game:draw()
	if not rb1 then return end
	if not kanohi_hau then return end

	rg3d:set_light_dir(vec3(1,0,0))

	rshaders:use_funcs("draw_id")

	gdt.VideoChip0:RenderOnBuffer(1)
	gdt.VideoChip0:Clear(color.black)
	rg3d:begin_render()
		rg3d:push_model_matrix(nil)
		rmesh:drawlist_submit(kanohi_hau)
	local spans = rg3d:end_render() or {}
	
	gdt.VideoChip0:RenderOnScreen()
	gdt.VideoChip0:DrawRenderBuffer(vec2(0,0),rb1,rb1.Width,rb1.Height)

	local pd = rb1:GetPixelData()
	local index = 0
	local pixel = nil
	local shader_input = nil
	local light_col = 1

	local DEBUG = 1

	local span_min, span_max
	for y = spans.top, spans.bottom do
		if spans.spans[y] then
			span_min = spans.spans[y][1]
			span_max = spans.spans[y][2]
	
			for x = span_min, span_max do
				if DEBUG == 1 then
					pd:SetPixel(x,y, color.white)
				else
					pixel = pd:GetPixel(x,y)
					index = bit32.bor(
						pixel.R,
						bit32.lshift(pixel.G,8),
						bit32.lshift(pixel.B,16))
		
					if index > 0 then 
						shader_input = rg3d:get_draw_call(index).args[4]
						light_col = shader_input.light_intensity or 1
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

	gdt.VideoChip0:BlitPixelData(vec2(0,0), pd)
end

return state_game