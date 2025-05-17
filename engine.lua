local engine = {}

local rmath = require "rg_math"
local rg3d = require "rg_3d"
--local rinput = require "rg_input"

engine.rinput = {}
engine.camera_pos = vec3(0,0,0)
engine.camera_pitch = 0
engine.camera_yaw = 0
engine.camera_dir   = vec3(0,0,-1)

engine.sun_dir = rmath:vec3_normalize(vec3(0,-1,-1))

function engine:update(_delta_time)
	-- update
end

-- called after update and state:update
function engine:post_update(_delta_time)
	engine.camera_pitch = math.min(engine.camera_pitch,  rmath:radians(85))
	engine.camera_pitch = math.max(engine.camera_pitch, -rmath:radians(85))
	engine.camera_dir   = rmath:rot_to_dir(engine.camera_pitch, engine.camera_yaw)

	--engine.sun_dir = vec3(math.cos(gdt.CPU0.Time), 0, math.sin(gdt.CPU0.Time))
	--engine.sun_dir = rmath:vec3_normalize(engine.sun_dir)
end

return engine