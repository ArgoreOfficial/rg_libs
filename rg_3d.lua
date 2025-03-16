local lib = {}

local rmath = require("rg_math")

-- global rg3d state
-- perspective
local g_perspective_e   = 1
local g_perspective_m00 = 1
local g_perspective_m22 = 1
local g_perspective_m32 = 1
local g_use_perspective = true

-- look at
local g_view_mat = {}

function lib:push_look_at(_eye, _center, _up)
	g_view_mat = rmath:mat4_look_at(_eye, _center, _up)
end

function lib:push_perspective( _aspect, _fov, _near, _far )
    g_perspective_e   = 1.0 / math.tan( _fov / 2.0 )
	g_perspective_m00 = g_perspective_e / _aspect
	g_perspective_m22 = ( _far + _near )       / ( _near - _far )
	g_perspective_m32 = ( 2.0 * _far * _near ) / ( _near - _far )
    g_use_perspective = true
end

function lib:project( _vec )
    if g_use_perspective then
	    return rmath:vec4(
			_vec.X * g_perspective_m00,
			_vec.Y * g_perspective_e,
			_vec.Z * g_perspective_m22 + _vec.W * g_perspective_m32,
		   -_vec.Z )
    else
        return rmath:vec4() -- ortho
    end
end

function lib:to_clip(_vec)
	local v4  = rmath:vec4(_vec.X, _vec.Y, _vec.Z, 1)
	local tv4 = rmath:mat4_transform(g_view_mat, v4)
	local cv4 = lib:project(tv4)
	return rmath:vec4(
		cv4.X / cv4.W,
		cv4.Y / cv4.W,
		cv4.Z )
end

function lib:to_screen(_vec, _screen_width, _screen_height)
	local sv4 = rmath:vec3_to_screen(lib:to_clip(_vec), _screen_width, _screen_height)
	return vec3(sv4.X, sv4.Y, sv4.Z)
end

local function count_inside_value(_v1,_v2,_v3,_min,_max)
	local min = _min or -1
	local max = _max or  1
	
	local p1 = (_v1 >= min and _v1 < max) and 1 or 0
	local p2 = (_v2 >= min and _v2 < max) and 1 or 0
	local p3 = (_v3 >= min and _v3 < max) and 1 or 0

	local v = p1 + p2 + p3
	return v
end

function lib:raster_triangle(_tri, _render_width, _render_height)

	local p1 = lib:to_clip(_tri[1])
	local p2 = lib:to_clip(_tri[2])
	local p3 = lib:to_clip(_tri[3])
	
	local x = count_inside_value(p1.X, p2.X, p3.X)
	local y = count_inside_value(p1.Y, p2.Y, p3.Y)
	local z = count_inside_value(p1.Z, p2.Z, p3.Z, 0, 1)

	local count = math.min(x,y)	
	
	if count == 0 then
		return
	end

	local col = color.green
	if count == 1 then
		col = color.red
	elseif count == 2 then
		col = color.yellow
	end

	gdt.VideoChip0:DrawTriangle(
			rmath:vec3_to_screen(p1, _render_width, _render_height),
			rmath:vec3_to_screen(p2, _render_width, _render_height),
			rmath:vec3_to_screen(p3, _render_width, _render_height),
			col )
end

return lib