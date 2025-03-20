local lib = {}

local rmath = require("rg_math")

local g_clip_margin = 2


--------------------------------------------------------
--[[  Globals                                         ]]
--------------------------------------------------------

local g_perspective_e   = 1
local g_perspective_m00 = 1
local g_perspective_m22 = 1
local g_perspective_m32 = 1
local g_use_perspective = true
local g_near = 0.5
local g_far = 50

local g_view_mat = {}
local g_debug_texture = gdt.ROM.User.SpriteSheets["debug.png"]

local g_raster_tri_func  = nil
local g_raster_quad_func = nil

--------------------------------------------------------
--[[  Default Raster Functions                        ]]
--------------------------------------------------------

local function default_raster_tri(_p1,_p2,_p3)
	gdt.VideoChip0:FillTriangle( _p1, _p2, _p3, Color(0,0,153) )
end

local function default_raster_quad(_p1,_p2,_p3,_p4)
	gdt.VideoChip0:RasterCustomSprite(_p1,_p2,_p3,_p4,g_debug_texture,vec2(0,0),vec2(64,64),color.white,color.clear)
end

function lib:set_quad_func( _func )
	g_raster_quad_func = _func or default_raster_quad
end

function lib:set_tri_func( _func )
	g_raster_tri_func = _func or default_raster_tri
end

--------------------------------------------------------
--[[  View Matrices                                   ]]
--------------------------------------------------------

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

--------------------------------------------------------
--[[  MipMap                                          ]]
--------------------------------------------------------

function lib.mip_func_round(_v) return math.floor(_v + 0.5) end
function lib.mip_func_floor(_v) return math.floor(_v)     end
function lib.mip_func_ceil (_v) return math.ceil (_v)     end
local g_default_mip_function = lib.mip_func_floor

function lib:select_mip(_dval, _max, _mip_function)
	local n = _mip_function(1/_dval)
	local po2      = rmath:round_down_to_po2(n) -- divident power of two
	local po2_next = po2 * 2
	local fraction = (po2_next > po2) and ((1/_dval) - po2) / (po2_next - po2) or 0
	
	local mip = math.log(po2)/math.log(2.0) + 1 -- po2 exponent
	if mip > _max then
		mip = _max
		po2 = math.pow(2, mip-1)
	elseif mip <= 0 then
		mip = 1
		po2 = 1
	end

	return mip, po2, fraction
end

function lib:get_mip_height(_mip,_base_height)
	local y = 0
	local mip = 2
	while mip < _mip do
		local mp = math.pow(2,mip-1)
		local mv = 1 / mp
		y = y + _base_height * mv
		mip = mip + 1
	end
	return y
end

function lib:get_mip_level_UVs(_mip, _base_width, _base_height)
	local po2 = math.pow(2, _mip-1)
	local mval = 1 / po2 -- mip width

	local w = _base_width  * mval
	local h = _base_height * mval
	
	local x = _mip == 1 and 0 or _base_width
	local y = lib:get_mip_height(_mip, _base_height)
	local u = vec2(x, y)
	local v = vec2(w, h)

	return u, v
end

function lib:get_mip_level(_p1,_p2,_p3,_p4, _base_width, _base_height, _mip_function)
	local dvalx = (math.max(_p1.X, _p2.X, _p3.X, _p4.X) - math.min(_p1.X, _p2.X, _p3.X, _p4.X)) / _base_width
	local dvaly = (math.max(_p1.Y, _p2.Y, _p3.Y, _p4.Y) - math.min(_p1.Y, _p2.Y, _p3.Y, _p4.Y)) / _base_height
	local dval = (dvalx > dvaly) and dvalx or dvaly
	
	local mip = lib:select_mip(dval, 35, _mip_function and _mip_function or g_default_mip_function)
	return mip
end

function lib:get_mip_UVs(_p1,_p2,_p3,_p4, _base_width, _base_height, _mip_function)
	local dvalx = (math.max(_p1.X, _p2.X, _p3.X, _p4.X) - math.min(_p1.X, _p2.X, _p3.X, _p4.X)) / _base_width
	local dvaly = (math.max(_p1.Y, _p2.Y, _p3.Y, _p4.Y) - math.min(_p1.Y, _p2.Y, _p3.Y, _p4.Y)) / _base_height
	local dval = (dvalx > dvaly) and dvalx or dvaly
	
	local mip, po2, fraction = lib:select_mip(dval, 35, _mip_function and _mip_function or g_default_mip_function)
	local mval = 1 / po2 -- mip width

	local w = _base_width  * mval
	local h = _base_height * mval
	
	local x = mip == 1 and 0 or _base_width
	local y = lib:get_mip_height(mip, _base_height)
	local u = vec2(x, y)
	local v = vec2(w, h)

	return u, v, fraction
end

--------------------------------------------------------
--[[  Projection                                      ]]
--------------------------------------------------------

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

--------------------------------------------------------
--[[  Math Util                                       ]]
--------------------------------------------------------

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

local function count_over_value(_value,_v1,_v2,_v3,_v4)
	local p1 = (_v1 > _value) and 1 or 0
	local p2 = (_v2 > _value) and 1 or 0
	local p3 = _v3 and ((_v3 > _value) and 1 or 0) or 0
	local p4 = _v4 and ((_v4 > _value) and 1 or 0) or 0
	return p1 + p2 + p3 + p4
end

local function count_under_value(_value,_v1,_v2,_v3,_v4)
	local p1 = (_v1 < _value) and 1 or 0
	local p2 = (_v2 < _value) and 1 or 0
	local p3 = _v3 and ((_v3 < _value) and 1 or 0) or 0
	local p4 = _v4 and ((_v4 < _value) and 1 or 0) or 0
	return p1 + p2 + p3 + p4
end

--------------------------------------------------------
--[[  Clipping & Raster                               ]]
--------------------------------------------------------

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

local function clip_and_raster_triangle(
	_tri,               -- {p1, p2, p3}
	_render_width, 
	_render_height, 

	_left_clip_count,   -- optional: use these if you've precomputed 
	_right_clip_count,  -- which points are inside the view frustum
	_top_clip_count,    -- 
	_bottom_clip_count  -- 
)
	local p1 = _tri[1]
	local p2 = _tri[2]
	local p3 = _tri[3]
	local triangle = {p1,p2,p3}
	
	local left_clip = _left_clip_count or count_over_value(-g_clip_margin, p1.X, p2.X, p3.X)
	if left_clip == 0 then return end
	
	local right_clip = _right_clip_count or count_under_value(g_clip_margin, p1.X, p2.X, p3.X)
	if right_clip == 0 then return end

	local top_clip = _top_clip_count or count_under_value(g_clip_margin, p1.Y, p2.Y, p3.Y)
	if top_clip == 0 then return end
	
	local bottom_clip = _bottom_clip_count or count_over_value(-g_clip_margin, p1.Y, p2.Y, p3.Y)
	if bottom_clip == 0 then return end
	
	local draw_list = {}
	if left_clip == 3 and right_clip == 3 and top_clip == 3 and bottom_clip == 3 then
		draw_list = {triangle}
	else
		clip_triangles({triangle}, draw_list)
	end

	for i=1, #draw_list do
		if g_raster_tri_func then 
			g_raster_tri_func(
				rmath:vec3_to_screen(draw_list[i][1], _render_width, _render_height, draw_list[i][1].Z),
				rmath:vec3_to_screen(draw_list[i][2], _render_width, _render_height, draw_list[i][2].Z),
				rmath:vec3_to_screen(draw_list[i][3], _render_width, _render_height, draw_list[i][3].Z))
		end
	end
end

local function clip_and_raster_quad(
	_quad,               -- {p1, p2, p3, p3}
	_render_width, 
	_render_height, 

	_left_clip_count,   -- optional: use these if you've precomputed 
	_right_clip_count,  -- which points are inside the view frustum
	_top_clip_count,    -- 
	_bottom_clip_count  -- 
)
	local p1 = _quad[1]
	local p2 = _quad[2]
	local p3 = _quad[3]
	local p4 = _quad[4]
	
	local left_clip = _left_clip_count or count_over_value(-g_clip_margin, p1.X, p2.X, p3.X, p4.X)
	if left_clip == 0 then return end
	
	local right_clip = _right_clip_count or count_under_value(g_clip_margin, p1.X, p2.X, p3.X, p4.X)
	if right_clip == 0 then return end

	local top_clip = _top_clip_count or count_under_value(g_clip_margin, p1.Y, p2.Y, p3.Y, p4.Y)
	if top_clip == 0 then return end
	
	local bottom_clip = _bottom_clip_count or count_over_value(-g_clip_margin, p1.Y, p2.Y, p3.Y, p4.Y)
	if bottom_clip == 0 then return end
	
	if g_raster_quad_func and left_clip == 4 and right_clip == 4 and top_clip == 4 and bottom_clip == 4 then
		g_raster_quad_func(
			rmath:vec3_to_screen(p1, _render_width, _render_height, p1.Z),
			rmath:vec3_to_screen(p2, _render_width, _render_height, p2.Z),
			rmath:vec3_to_screen(p3, _render_width, _render_height, p3.Z),
			rmath:vec3_to_screen(p4, _render_width, _render_height, p4.Z))
	else
		clip_and_raster_triangle({p1,p2,p3}, _render_width, _render_height )
		clip_and_raster_triangle({p1,p3,p4}, _render_width, _render_height )
	end
end

function lib:raster_triangle(_tri, _render_width, _render_height)
	local p1 = lib:to_view(_tri[1])
	local p2 = lib:to_view(_tri[2])
	local p3 = lib:to_view(_tri[3])
	local triangle = {p1,p2,p3}

	local near_count = count_under_value(-g_near, p1.Z, p2.Z, p3.Z)
	if near_count == 0 then return end -- behind near plane
	
	local far_count = count_over_value(-g_far, p1.Z, p2.Z, p3.Z)
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
		clip_and_raster_triangle(t, _render_width, _render_height)
	end
end

function lib:raster_quad(_quad, _render_width, _render_height)
	local p1 = lib:to_view(_quad[1])
	local p2 = lib:to_view(_quad[2])
	local p3 = lib:to_view(_quad[3])
	local p4 = lib:to_view(_quad[4])
	
	local near_count = count_under_value(-g_near, p1.Z, p2.Z, p3.Z, p4.Z)
	if near_count == 0 then return end -- behind near plane
	
	local far_count = count_over_value(-g_far, p1.Z, p2.Z, p3.Z, p4.Z)
	if far_count == 0 then return end -- in front of far plane

	if near_count == 4 and far_count == 4 then -- quad is fully inside
		local t1 = lib:view_to_clip(p1)
		local t2 = lib:view_to_clip(p2)
		local t3 = lib:view_to_clip(p3)
		local t4 = lib:view_to_clip(p4)
		
		clip_and_raster_quad({t1,t2,t3,t4}, _render_width, _render_height)
	else
		lib:raster_triangle({_quad[1],_quad[2],_quad[3]},_render_width,_render_height)
		lib:raster_triangle({_quad[1],_quad[3],_quad[4]},_render_width,_render_height)
	end
end

lib:set_quad_func()
lib:set_tri_func()

return lib