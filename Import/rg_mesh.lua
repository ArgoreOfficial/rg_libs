local lib = {}

local rg3d = require "rg_3d"
local rmath = require "rg_math"

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

function lib:drawlist_build(_mesh)
	local command_list = {}
	local COL = 1
	local POS = 4
	
	for i = 1, #_mesh do
		local m = _mesh[i]
		local col = Color(m[COL+0], m[COL+1], m[COL+2])
		
		local command = nil
		local face = {
			vec3(m[POS+0],m[POS+1],m[POS+2]),
			vec3(m[POS+3],m[POS+4],m[POS+5]),
			vec3(m[POS+6],m[POS+7],m[POS+8])
		}
		
		local func = rg3d.raster_triangle
		
		if m[POS+9] then -- if not nil, face is a quad
			func = rg3d.raster_quad
			table.insert(face, vec3(m[POS+9],m[POS+10],m[POS+11]))
		end
		
		command = {func, {face, screen_width, screen_height, {
			primitive_index = i,
			color = col,
			normal = rmath:get_triangle_normal(face)
		}}}
		table.insert(command_list, command)
	end
	return command_list
end

function lib:drawlist_submit(_list)
	for i = 1, #_list do
		_list[i][1](rg3d, table.unpack(_list[i][2]))
	end
end

function lib:require_drawlist(_name)
	local mesh = require(_name .. (IS_RG and ".lua" or ""))
	return lib:drawlist_build(mesh)
end

return lib