local state_game = {}

function state_game:on_enter(_delta_time)
	print("entered game")
end

function state_game:on_exit(_delta_time)
	print("exited game")
end

function state_game:update(_delta_time)

end

return state_game