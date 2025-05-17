local sm = {}

local states = {}
local state_indices = {}

local current_state = -1
local next_state = -1

function sm:add_state(_name, _state)
	states[#states+1] = _state
	state_indices[_name] = #states
end

function sm:set_state(_name)
	local index = state_indices[_name]

	if not index then return end 
	if index < 1 or index > #states then return end -- out of bounds
	if current_state == index       then return end -- already in this state
	
	next_state = index
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

function sm:draw()
	if current_state > 0 then 
		get_current_state():draw()
	end
end

return sm