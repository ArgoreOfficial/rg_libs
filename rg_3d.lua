local lib = {}

local rmath = require("rg_math")

-- global rg3d state
-- perspective
local g_perspective_e   = 1
local g_perspective_m00 = 1
local g_perspective_m22 = 1
local g_perspective_m32 = 1
local g_use_perspective = true
local g_near = 0.1
local g_far = 100

-- look at
local g_view_mat = {}

function lib:push_look_at(_eye, _center, _up)
	g_view_mat = rmath:mat4_look_at(_eye, _center, _up)
end

function lib:push_perspective( _aspect, _fov, _near, _far )
	g_near = _near
	g_far  = _far

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

function lib:to_view(_vec)
	local v4  = rmath:vec4(_vec.X, _vec.Y, _vec.Z, 1)
	return rmath:mat4_transform(g_view_mat, v4)
end

function lib:view_to_clip(_vec)
	local cv4 = lib:project(_vec)
	return rmath:vec4(
		cv4.X / cv4.W,
		cv4.Y / cv4.W,
		cv4.Z )
end

function lib:to_clip(_vec)
	return lib:view_to_clip(lib:to_view(_vec))
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
	local d = 1.0
	clip_triangles_plane(_in, temp,   vec3(-d, 0, 0), vec3( 1, 0, 0)) -- left
	clip_triangles_plane(temp, temp2, vec3( 0,-d, 0), vec3( 0, 1, 0)) -- top
	temp = {}
	clip_triangles_plane(temp2, temp, vec3( d, 0, 0), vec3(-1, 0, 0)) -- right
	temp2 = {}
	clip_triangles_plane(temp, _out,  vec3( 0, d, 0), vec3( 0,-1, 0)) -- bottom
end

local function count_over_value(_v1,_v2,_v3,_value)
	local p1 = (_v1 > _value) and 1 or 0
	local p2 = (_v2 > _value) and 1 or 0
	local p3 = (_v3 > _value) and 1 or 0
	return p1 + p2 + p3
end

local function count_under_value(_v1,_v2,_v3,_value)
	local p1 = (_v1 < _value) and 1 or 0
	local p2 = (_v2 < _value) and 1 or 0
	local p3 = (_v3 < _value) and 1 or 0
	return p1 + p2 + p3
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

local function clip_and_raster(_tri, _render_width, _render_height)
	local p1 = _tri[1]
	local p2 = _tri[2]
	local p3 = _tri[3]
	local triangle = {p1,p2,p3}

	local x = count_inside_value(p1.X, p2.X, p3.X)
	local y = count_inside_value(p1.Y, p2.Y, p3.Y)
	local count = math.min(x,y)
	if count == 0 then return end
	
	local draw_list = {}
	if count == 1 or count == 2 then
		clip_triangles({triangle}, draw_list)
	elseif count == 3 then
		draw_list = {triangle}
	end
	
	local col = color.green
	if count == 1 then
		col = color.red
	elseif count == 2 then
		col = color.yellow
	end
	for i=1, #draw_list do
		local z = math.max(draw_list[i][1].Z, draw_list[i][2].Z, draw_list[i][3].Z)
		local c = 1 - (z / g_far)
		
		local col2 = Color(col.R * c, col.G * c, col.B * c)
		gdt.VideoChip0:FillTriangle(
			rmath:vec3_to_screen(draw_list[i][1], _render_width, _render_height),
			rmath:vec3_to_screen(draw_list[i][2], _render_width, _render_height),
			rmath:vec3_to_screen(draw_list[i][3], _render_width, _render_height),
			col2 )
	end
end

function lib:raster_triangle(_tri, _render_width, _render_height)
	local p1 = lib:to_view(_tri[1])
	local p2 = lib:to_view(_tri[2])
	local p3 = lib:to_view(_tri[3])
	local triangle = {p1,p2,p3}

	local near_count = count_under_value(p1.Z,p2.Z,p3.Z,-g_near)
	if near_count == 0 then return end -- behind near plane
	
	local far_count = count_over_value(p1.Z,p2.Z,p3.Z,-g_far)
	if far_count == 0 then return end -- in front of far plane

	local nearclipped = {}
	local farclipped  = {}

	-- clip near plane
	if near_count == 1 or near_count == 2 then 
		clip_triangles_plane({triangle}, nearclipped, vec3(0, 0, -g_near), vec3(0, 0, -1.0))
	elseif near_count == 3 then 
		nearclipped = {triangle}
	end

	-- clip far plane
	if far_count == 1 or far_count == 2 then
		clip_triangles_plane(nearclipped, farclipped, vec3(0, 0, -g_far), vec3(0, 0, 1.0))
	elseif far_count == 3 then
		farclipped = nearclipped
	end

	for i = 1, #farclipped do
		local t = {}
		t[1] = lib:view_to_clip(farclipped[i][1])
		t[2] = lib:view_to_clip(farclipped[i][2])
		t[3] = lib:view_to_clip(farclipped[i][3])
		clip_and_raster(t, _render_width, _render_height)
	end
end

return lib