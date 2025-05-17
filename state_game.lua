local state_game = {}

local engine = require "engine"
local rmath = require "rg_math"

function state_game:on_enter()
	-- on enter
end

function state_game:on_exit()
	-- on exit
end

local function get_move_wish()
	local move_input = vec3(0,0,0)
	
	if engine.rinput["W"] then move_input = move_input + vec3(0,0, 1) end
	if engine.rinput["S"] then move_input = move_input + vec3(0,0,-1) end

	if engine.rinput["A"] then move_input = move_input + vec3(-1,0,0) end
	if engine.rinput["D"] then move_input = move_input + vec3( 1,0,0) end

	if engine.rinput["E"] then move_input = move_input + vec3(0, 1,0) end
	if engine.rinput["Q"] then move_input = move_input + vec3(0,-1,0) end

	local up      = vec3(0,1,0)
	local right   = rmath:rot_to_dir(0, engine.camera_yaw + rmath:radians(90))
	local forward = rmath:rot_to_dir(engine.camera_pitch, engine.camera_yaw)

	local move_wish = right   * move_input.X + 
					  up      * move_input.Y + 
					  forward * move_input.Z

	return rmath:vec3_normalize(move_wish)
end


function state_game:update(_delta_time)
	local wish_pitch = 0
	local wish_yaw   = 0

	if engine.rinput["LeftArrow"]  then wish_yaw = wish_yaw - 1 end
	if engine.rinput["RightArrow"] then wish_yaw = wish_yaw + 1 end

	if engine.rinput["UpArrow"]   then wish_pitch = wish_pitch + 1 end
	if engine.rinput["DownArrow"] then wish_pitch = wish_pitch - 1 end

	engine.camera_pitch = engine.camera_pitch + wish_pitch * _delta_time * 1.2
	engine.camera_yaw   = engine.camera_yaw   + wish_yaw   * _delta_time * 1.2

	
	local speed = 5
	if engine.rinput["LeftShift"] then speed = speed * 4 end
	engine.camera_pos = engine.camera_pos + get_move_wish() * _delta_time * speed
end

function state_game:draw()
	gdt.VideoChip0:Clear(color.black)
end

return state_game