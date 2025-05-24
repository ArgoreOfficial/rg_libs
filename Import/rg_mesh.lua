local lib = {}

local rg3d = require "rg_3d"
local rmath = require "rg_math"

local screen_width  = gdt.VideoChip0.Width
local screen_height = gdt.VideoChip0.Height

local function _extract_vec3(_t, _offset)
	return vec3(_t[_offset+1],_t[_offset+2],_t[_offset+3])
end

function lib:drawlist_build(_mesh,_pos,_rot,_scale)
	local command_list = {}
	local COL = 1
	local POS = 4
	local NORM = 5
	
	for i = 1, #_mesh do
		local m = _mesh[i]
		local col = Color(m[COL+0], m[COL+1], m[COL+2])
		
		local command = nil
		local face = {
			_extract_vec3(m[POS], 0),
			_extract_vec3(m[POS], 3),
			_extract_vec3(m[POS], 6)
		}
		
		local model_space_verts = {
			_extract_vec3(m[POS], 0),
			_extract_vec3(m[POS], 3),
			_extract_vec3(m[POS], 6)
		}

		local vertex_normals = {
			_extract_vec3(m[NORM], 0),
			_extract_vec3(m[NORM], 3),
			_extract_vec3(m[NORM], 6)
		}
		
		local func = rg3d.raster_triangle
		
		if m[POS+9] then -- if not nil, face is a quad
			func = rg3d.raster_quad
			table.insert(face, _extract_vec3(m[POS], 9))
			table.insert(model_space_verts, _extract_vec3(m[POS], 9))
			table.insert(vertex_normals, _extract_vec3(m[NORM], 9))
		end
		
		if _pos or _rot or _scale then
			local transform = rmath:mat4_model_matrix(_pos or vec3(0,0,0), _rot or vec3(0,45,0), _scale or vec3(1,1,1))
			for i = 1, #face do
				face[i] = rmath:mat4_transform(transform, face[i])
			end
		end

		command = {func, {face, screen_width, screen_height, {
			primitive_index = i,
			color = col,
			normal = rmath:get_triangle_normal(face),
			vertex_normals = vertex_normals
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

function lib:require_drawlist(_name,_pos,_rot,_scale)
	local mesh = require(_name)
	return lib:drawlist_build(mesh,_pos,_rot,_scale)
end

return lib