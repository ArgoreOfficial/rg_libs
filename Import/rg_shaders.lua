local lib = {}

local rmath = require "rg_math"
local rg3d  = require "rg_3d"

local function _fill_quad(p1,p2,p3,p4,color)
	gdt.VideoChip0:FillTriangle(p1,p2,p3,color)
	gdt.VideoChip0:FillTriangle(p1,p3,p4,color)
end

function lib.diffuse_lambert_quad(_p1,_p2,_p3,_p4,_shader_input)		
	local c = math.max(0.1, _shader_input.light_intensity or 1)

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	_fill_quad(_p1,_p2,_p3,_p4,color)
end

function lib.diffuse_lambert_tri(_p1,_p2,_p3,_shader_input)		
	local c = math.max(0.1, _shader_input.light_intensity or 1)

	local color = Color(
		_shader_input.color.R * c,
		_shader_input.color.G * c,
		_shader_input.color.B * c
	)
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,color)
end

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

return lib