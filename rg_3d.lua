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

local function dist_to_plane(_point,_plane_pos,_plane_normal)
	local n = rmath:vec3_normalize(_point)
	return _plane_normal.X * _point.X
	     + _plane_normal.Y * _point.Y
		 + _plane_normal.Z * _point.Z
		 - rmath:vec3_dot(_plane_normal, _plane_pos)
end

local function line_intersect_plane(_start, _end, _plane_pos, _plane_normal )
	_plane_normal = rmath:vec3_normalize(_plane_normal)
	local plane_d = -rmath:vec3_dot(_plane_normal,_plane_pos)
	local ad = rmath:vec3_dot(_start, _plane_normal)
	local bd = rmath:vec3_dot(_end, _plane_normal)
	local t = (-plane_d - ad) / (bd - ad)
	
	if t < 0 or t > 1 then return nil end
	
	local start_to_end = _end - _start
	local line_to_intersect = start_to_end * t
	
	return _start + line_to_intersect
end

local function triangle_clip_plane(_tri, _plane_pos, _plane_normal)
	_plane_normal = rmath:vec3_normalize(_plane_normal)
	local inside_points = {}
	local outside_points = {}

	local d1 = dist_to_plane(_tri[1], _plane_pos, _plane_normal)
	local d2 = dist_to_plane(_tri[2], _plane_pos, _plane_normal)
	local d3 = dist_to_plane(_tri[3], _plane_pos, _plane_normal)

	if d1 >= 0 then inside_points [#inside_points +1] = _tri[1]
	else            outside_points[#outside_points+1] = _tri[1] end

	if d2 >= 0 then inside_points [#inside_points +1] = _tri[2]
	else            outside_points[#outside_points+1] = _tri[2] end

	if d3 >= 0 then inside_points [#inside_points +1] = _tri[3]
	else            outside_points[#outside_points+1] = _tri[3] end

	if #inside_points == 0 then return nil, nil, nil end
	if #inside_points == 3 then return _tri, nil, nil end

	if #inside_points == 1 and #outside_points == 2 then
		local t = {
			inside_points[1],
			line_intersect_plane(inside_points[1], outside_points[1], _plane_pos, _plane_normal),
			line_intersect_plane(inside_points[1], outside_points[2], _plane_pos, _plane_normal)
		}
		
		return t, nil, nil
	end

	
	if #inside_points == 2 and #outside_points == 1 then
		local t1 = {
			inside_points[1],
			inside_points[2],
			line_intersect_plane(inside_points[1], outside_points[1], _plane_pos, _plane_normal)
		}
		
		local t2 = {
			inside_points[2],
			t1[3],
			line_intersect_plane(inside_points[2], outside_points[1], _plane_pos, _plane_normal)
		}
		
		return t1, t2, nil
	end
end

local function clip_triangles_plane(_in, _out,_plane_pos,_plane_normal)
	for i=1,#_in do
		local a,b,c = triangle_clip_plane(_in[i],_plane_pos,_plane_normal)
		if a then _out[#_out+1] = a end
		if b then _out[#_out+1] = b end
		if c then _out[#_out+1] = c end
	end
end

local function clip_triangles(_in, _out)
	local temp, temp2 = {}, {}
	local d = 0.9

	clip_triangles_plane(_in, temp,   vec3(-d, 0, 0), vec3( 1, 0, 0)) -- left
	clip_triangles_plane(temp, temp2, vec3( 0,-d, 0), vec3( 0, 1, 0)) -- top
	temp = {}
	clip_triangles_plane(temp2, temp, vec3( d, 0, 0), vec3(-1, 0, 0)) -- right
	clip_triangles_plane(temp, _out,  vec3( 0, d, 0), vec3( 0,-1, 0)) -- bottom
end

function lib:raster_triangle(_tri, _render_width, _render_height)
	local p1 = lib:to_clip(_tri[1])
	local p2 = lib:to_clip(_tri[2])
	local p3 = lib:to_clip(_tri[3])
	
	do return end

	local triangle = {p1,p2,p3}
	local tri_list = {triangle}
	local clipped_tri_list = {}
	clip_triangles(tri_list, clipped_tri_list)

	local col = color.green
	
	for i=1, #clipped_tri_list do
		gdt.VideoChip0:DrawTriangle(
			rmath:vec3_to_screen(clipped_tri_list[i][1], _render_width, _render_height),
			rmath:vec3_to_screen(clipped_tri_list[i][2], _render_width, _render_height),
			rmath:vec3_to_screen(clipped_tri_list[i][3], _render_width, _render_height),
			col )
	end
end

return lib