local engine = {}

local rmath = require "rg_math"
local rg3d = require "rg_3d"
--local rinput = require "rg_input"

engine.IS_RG = _VERSION == "Luau"

engine.rinput = {}
engine.camera_pos = vec3(0,0,0)
engine.camera_pitch = 0
engine.camera_yaw = 0
engine.camera_dir   = vec3(0,0,-1)

engine.sun_dir = rmath:vec3_normalize(vec3(0,-1,-1))
engine.average_frametime = 0.0
engine.push_look_at = true

local font = gdt.ROM.System.SpriteSheets["StandardFont"]

local time_since_frametime_update = 0.0
local frametimes = {}

function engine:update(_delta_time)
	time_since_frametime_update = time_since_frametime_update + _delta_time

	if time_since_frametime_update > 0.2 then
		if #frametimes == 64 then
			table.remove(frametimes, 1)
		end
		frametimes[#frametimes+1] = _delta_time

		engine.average_frametime = 0
		for i = 1, #frametimes do
			engine.average_frametime = engine.average_frametime + frametimes[i]
		end
		engine.average_frametime = engine.average_frametime / #frametimes
	end
end

-- called after update and state:update
function engine:post_update(_delta_time)
	engine.camera_pitch = math.min(engine.camera_pitch,  rmath:radians(85))
	engine.camera_pitch = math.max(engine.camera_pitch, -rmath:radians(85))
	engine.camera_dir   = rmath:rot_to_dir(engine.camera_pitch, engine.camera_yaw)

	if engine.push_look_at then
		rg3d:push_look_at(engine.camera_pos, engine.camera_pos + engine.camera_dir, vec3(0,1,0))
	end
end

-- called after state:draw
function engine:draw()
	local ms_text = string.format("%02.2f", engine.average_frametime * 1000)
	gdt.VideoChip0:DrawText(vec2(0,0), font, tostring( math.floor( 1 / engine.average_frametime ) ) .. "FPS", color.white, color.clear )
	gdt.VideoChip0:DrawText(vec2(0,8), font, ms_text .. "ms", color.white, color.clear )
end

return engine