local state_menu = {}

function state_menu:on_enter(_delta_time)
	print("entered menu")
end

function state_menu:on_exit(_delta_time)
	print("exited menu")
end

function state_menu:update(_delta_time)

end

return state_menu