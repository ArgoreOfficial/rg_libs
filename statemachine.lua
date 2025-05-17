local sm = {}

local states = {}
local current_state = -1
local next_state = -1

function sm:add_state(_state)
	states[#states+1] = _state
	return #states
end

function sm:set_state(_index)
	if _index < 1 or _index > #states then return end -- out of bounds
	if current_state == _index        then return end -- already in this state
	
	print("switching to state", _index)
	next_state = _index
end

local function get_current_state() return states[current_state] end

function sm:update(_delta_time)
	if current_state > 0 then 
		get_current_state():update(_delta_time)
	end

	if next_state ~= -1 then -- changing state
		if current_state > 0 then 
			get_current_state():on_exit() 
		end

		current_state = next_state
		next_state = -1

		get_current_state():on_enter()
	end

end

return sm