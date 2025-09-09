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


local function standard_rast_top(v1, v2, v3, _color)
	v1 = v1 + vec2(1,1)
	v2 = v2 + vec2(1,1)
	v3 = v3 + vec2(1,1)

	local invslope1 = (v3.X - v1.X) / (v3.Y - v1.Y)
 	local invslope2 = (v3.X - v2.X) / (v3.Y - v2.Y)

  	local curx1 = v3.X
  	local curx2 = v3.X

  	for scanlineY = v3.Y, v1.Y, -1 do
		gdt.VideoChip0:DrawLine(vec2(curx1, scanlineY), vec2(curx2, scanlineY), _color)
		
		curx1 = curx1 - invslope1
		curx2 = curx2 - invslope2
	end
end


local function standard_rast_bottom(v1, v2, v3, _color)
	v1 = v1 + vec2(1,1)
	v2 = v2 + vec2(1,1)
	v3 = v3 + vec2(1,1)
	
	local invslope1 = (v2.X - v1.X) / (v2.Y - v1.Y)
	local invslope2 = (v3.X - v1.X) / (v3.Y - v1.Y)

	local curx1 = v1.X
	local curx2 = v1.X

	for scanlineY = v1.Y, v2.Y do
		gdt.VideoChip0:DrawLine(vec2(curx1, scanlineY), vec2(curx2, scanlineY), _color)
		curx1 = curx1 + invslope1
		curx2 = curx2 + invslope2
	end
end

local function vec3_floor(_vec)
	return vec3(
		math.floor(_vec.X),
		math.floor(_vec.Y),
		math.floor(_vec.Z)
	)
end

local function vec2_floor(_vec)
	return vec2(
		math.floor(_vec.X),
		math.floor(_vec.Y)
	)
end

local function standard_rast(a, b, c, _color)
	local vecs = { a, b, c }
	table.sort(vecs, function(k1,k2) return k1.Y < k2.Y end)
	local v1 = vec2_floor(vecs[1])
	local v2 = vec2_floor(vecs[2])
	local v3 = vec2_floor(vecs[3])

	if v2.Y == v3.Y then
		standard_rast_bottom(vec2_floor(v1), vec2_floor(v2), vec2_floor(v3), _color)
	elseif v1.Y == v2.Y then
		standard_rast_top(vec2_floor(v1), vec2_floor(v2), vec2_floor(v3), _color)
	else
		local v4 = vec2(v1.X + ((v2.Y - v1.Y) / (v3.Y - v1.Y)) * (v3.X - v1.X), v2.Y)

		standard_rast_bottom(vec2_floor(v1), vec2_floor(v2), vec2_floor(v4), _color)
		standard_rast_top   (vec2_floor(v2), vec2_floor(v4), vec2_floor(v3), _color)
	end
end


function lib.draw_id_raster_tri(_p1,_p2,_p3,_shader_input)	
	local draw_id = _shader_input.draw_id
	standard_rast(_p1,_p2,_p3,Color(
		bit32.extract(draw_id,0,8),
		bit32.extract(draw_id,8,8),
		bit32.extract(draw_id,16,8)
	))
end

return lib