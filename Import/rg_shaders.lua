local lib = {}

local rmath = require "rg_math"
local rg3d  = require "rg_3d"

local function _fill_quad(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

function lib:use_funcs(_name)
	rg3d:set_quad_func(lib[_name .. "_quad"])
	rg3d:set_tri_func (lib[_name .. "_tri"])
end

function lib.diffuse_lambert_quad(_p1,_p2,_p3,_p4,_shader_input)		
	local c = _shader_input.light_intensity or 1

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	_fill_quad(_p1,_p2,_p3,_p4,color)
end

function lib.diffuse_lambert_tri(_p1,_p2,_p3,_shader_input)		
	local c = _shader_input.light_intensity or 1

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,color)
end

-- Random Face Index Colour

function lib.random_quad(_p1,_p2,_p3,_p4,_shader_input)		
	math.randomseed( _shader_input.primitive_index )
	local color = Color(math.random(0,255),math.random(0,255),math.random(0,255))
	_fill_quad(_p1, _p2, _p3, _p4, color)
end

function lib.random_tri(_p1,_p2,_p3,_shader_input)		
	math.randomseed( _shader_input.primitive_index )
	local color = Color(math.random(0,255),math.random(0,255),math.random(0,255))
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,color)
end

-- Face Index

function lib.index_quad(_p1,_p2,_p3,_p4,_shader_input)	
	local prim_index = _shader_input.primitive_index
	_fill_quad(_p1, _p2, _p3, _p4, Color(
		bit32.extract(prim_index,0,8),
		bit32.extract(prim_index,8,8),
		bit32.extract(prim_index,16,8)
	))
end

function lib.index_tri(_p1,_p2,_p3,_shader_input)
	local prim_index = _shader_input.primitive_index
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,Color(
		bit32.extract(prim_index,0,8),
		bit32.extract(prim_index,8,8),
		bit32.extract(prim_index,16,8)
	))
end


-- DrawID

function lib.draw_id_quad(_p1,_p2,_p3,_p4,_shader_input)		
	local draw_id = _shader_input.draw_id
	_fill_quad(_p1, _p2, _p3, _p4, Color(
		bit32.extract(draw_id,0,8),
		bit32.extract(draw_id,8,8),
		bit32.extract(draw_id,16,8)
	))
end

function lib.draw_id_tri(_p1,_p2,_p3,_shader_input)	
	local draw_id = _shader_input.draw_id
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,Color(
		bit32.extract(draw_id,0,8),
		bit32.extract(draw_id,8,8),
		bit32.extract(draw_id,16,8)
	))
end

return lib