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

local g_eye     = vec3(0,0,0)
local g_eye_dir = vec3(0,0,1)
local g_view_mat = nil
local g_view_mat_trans_inv = nil
local g_model_view_mat = nil
local g_model_mat_trans_inv = nil
local g_debug_texture = gdt.ROM.User.SpriteSheets["debug.png"]

local g_light_dir             = vec3(0,1,0)
local g_view_space_light_dir  = vec3(0,1,0)
local g_model_space_light_dir = vec3(0,1,0)

local g_raster_tri_func  = nil
local g_raster_quad_func = nil

local g_clip_far = true

local g_current_renderpass = nil
local g_draws = {}
local g_draw_id = 1
local g_spans = {}
local g_top_span    = 100000
local g_bottom_span = 0

--------------------------------------------------------
--[[  Pipeline State Functions                        ]]
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

function lib:set_clip_far( _bool )
	g_clip_far = _bool
end

function lib:set_light_dir(_dir)
	g_light_dir = rmath:vec3_normalize(-_dir)
	
	if g_view_mat_trans_inv then
		g_view_space_light_dir = rmath:vec3_normalize(rmath:mat3_mult_vec3(g_view_mat_trans_inv, g_light_dir))
	end
end

--------------------------------------------------------
--[[  RenderPasses                                    ]]
--------------------------------------------------------

function lib:begin_render()
	if g_current_renderpass then
		print("begin_render cannot be called twice")
		return
	end

	g_current_renderpass = {}
	g_draw_id = 1
	g_spans = {}
	g_top_span = 0
	g_bottom_span = 1000
end

function lib:end_render()
	if not g_current_renderpass then
		print("end_render cannot be called twice")
		return
	end

	local tkeys = {}

	for k in pairs(g_current_renderpass) do table.insert(tkeys, k) end
	
	table.sort(tkeys)
	local num_drawcalls = 0

	for _, k in ipairs(tkeys) do 
		g_current_renderpass[k].func(unpack(g_current_renderpass[k].args))
		num_drawcalls = num_drawcalls + 1
	end
	
	g_current_renderpass = nil
	return { spans=g_spans, top=g_top_span, bottom=g_bottom_span }
end

local function _push_span(_y, _min, _max)
	if( _y < 1 ) then return end

	g_top_span    = math.min(g_top_span, _y)
	g_bottom_span = math.max(g_bottom_span, _y)

	if g_spans[_y] then
		g_spans[_y][1] = math.min(g_spans[_y][1], math.floor(_min)) 
		g_spans[_y][2] = math.max(g_spans[_y][2], math.floor(_max))
	else
		g_spans[_y] = { math.floor(_min), math.floor(_max) }
	end
end

local function _push_span_tri(_p1, _p2, _p3)
	local min = vec2(math.min(_p1.X, _p2.X, _p3.X), math.min(_p1.Y, _p2.Y, _p3.Y))
	local max = vec2(math.max(_p1.X, _p2.X, _p3.X), math.max(_p1.Y, _p2.Y, _p3.Y))
	
	for y = math.floor(min.Y+1), math.floor(max.Y+1) do
		_push_span(y, min.X+1, max.X+1)
	end
end

local function _push_span_quad(_p1, _p2, _p3, _p4)
	local min = vec2(math.min(_p1.X, _p2.X, _p3.X, _p4.X), math.min(_p1.Y, _p2.Y, _p3.Y, _p4.Y))
	local max = vec2(math.max(_p1.X, _p2.X, _p3.X, _p4.X), math.max(_p1.Y, _p2.Y, _p3.Y, _p4.Y))
	
	for y = math.floor(min.Y+1), math.floor(max.Y) do
		_push_span(y, min.X+1, max.X+1)
	end
end

local function _push_cmd_draw(_func, _depth, ...)
	if not g_current_renderpass then
		error("No renderpass")
	end
	
	_depth = -_depth

	while g_current_renderpass[_depth] ~= nil do
		_depth = _depth - 0.001
	end

	g_current_renderpass[_depth] = {
		func = _func,
		args = {...}
	}

	g_draws[g_draw_id] = g_current_renderpass[_depth]
	g_draw_id = g_draw_id + 1
end

function lib:get_draw_call(_index)
	return g_draws[_index]
end

--------------------------------------------------------
--[[  View Matrices                                   ]]
--------------------------------------------------------

function lib:push_look_at(_eye, _center, _up)
	g_eye_dir  = rmath:vec3_normalize(_center - _eye)
	g_eye = _eye
	g_view_mat = rmath:mat4_look_at(_eye, _center, _up)
	g_model_view_mat = g_view_mat

	g_view_mat_trans_inv = rmath:mat3_transposed_inverse(g_view_mat)
    g_view_space_light_dir = rmath:vec3_normalize(rmath:mat3_mult_vec3(g_view_mat_trans_inv, g_light_dir))
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

function lib:push_model_matrix(_model)
	g_model_view_mat = rmath:mat4_mult_mat4(_model, g_view_mat) 
	
	g_model_mat_trans_inv   = rmath:mat3_transposed_inverse(_model or rmath:mat4())
	g_model_space_light_dir = rmath:vec3_normalize(rmath:mat3_mult_vec3(g_model_mat_trans_inv, g_light_dir))
end

function lib:get_model_space_ligt_dir()
	return g_model_space_light_dir
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
	local po2_next = rmath:round_up_to_po2(n)
	local po2      = rmath:round_down_to_po2(n) -- divident power of two
	local fraction = (po2 ~= po2_next) and (((1/_dval) - po2) / (po2_next - po2)) or 0
	
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
	return rmath:mat4_transform(g_model_view_mat, v4)
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
	return rmath:vec3_to_screen(lib:to_clip(_vec), _screen_width, _screen_height)
end

--------------------------------------------------------
--[[  Transformations                                 ]]
--------------------------------------------------------

function lib:translate_tri(_quad, _vec)
	return {
		_quad[1] + _vec,
		_quad[2] + _vec,
		_quad[3] + _vec
	}
end

function lib:scale_tri(_quad, _vec)
	return {
		rmath:vec3_mult(_quad[1], _vec),
		rmath:vec3_mult(_quad[2], _vec),
		rmath:vec3_mult(_quad[3], _vec)
	}
end

function lib:translate_quad(_quad, _vec)
	return {
		_quad[1] + _vec,
		_quad[2] + _vec,
		_quad[3] + _vec,
		_quad[4] + _vec
	}
end

function lib:scale_quad(_quad, _vec)
	return {
		rmath:vec3_mult(_quad[1], _vec),
		rmath:vec3_mult(_quad[2], _vec),
		rmath:vec3_mult(_quad[3], _vec),
		rmath:vec3_mult(_quad[4], _vec)
	}
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
	_bottom_clip_count, -- 
	_shader_input       -- 
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

	local s1, s2, s3

	for i=1, #draw_list do
		if g_raster_tri_func then 
			if not g_current_renderpass then
				error("No renderpass")
			end
			
			--local depth = (draw_list[i][1].Z + draw_list[i][2].Z + draw_list[i][3].Z) / 3
			local depth = math.min(draw_list[i][1].Z,draw_list[i][2].Z,draw_list[i][3].Z)
		
			_shader_input.draw_id = g_draw_id
			s1 = rmath:vec3_to_screen(draw_list[i][1], _render_width, _render_height, draw_list[i][1].Z)
			s2 = rmath:vec3_to_screen(draw_list[i][2], _render_width, _render_height, draw_list[i][2].Z)
			s3 = rmath:vec3_to_screen(draw_list[i][3], _render_width, _render_height, draw_list[i][3].Z)
			_push_cmd_draw(g_raster_tri_func, depth, s1, s2, s3, _shader_input)
			_push_span_tri(s1, s2, s3)
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
	_bottom_clip_count, -- 
	_shader_input
)
	local p1,p2,p3,p4 = _quad[1], _quad[2], _quad[3], _quad[4]
	
	local left_clip = _left_clip_count or count_over_value(-g_clip_margin, p1.X, p2.X, p3.X, p4.X)
	if left_clip == 0 then return end
	
	local right_clip = _right_clip_count or count_under_value(g_clip_margin, p1.X, p2.X, p3.X, p4.X)
	if right_clip == 0 then return end

	local top_clip = _top_clip_count or count_under_value(g_clip_margin, p1.Y, p2.Y, p3.Y, p4.Y)
	if top_clip == 0 then return end
	
	local bottom_clip = _bottom_clip_count or count_over_value(-g_clip_margin, p1.Y, p2.Y, p3.Y, p4.Y)
	if bottom_clip == 0 then return end
	
	if g_raster_quad_func and left_clip == 4 and right_clip == 4 and top_clip == 4 and bottom_clip == 4 then
		_shader_input.draw_id = g_draw_id
		--local depth = (p1.Z + p2.Z + p3.Z + p4.Z)/2
		local depth = math.min(p1.Z, p2.Z, p3.Z, p4.Z)		
		local s1 = rmath:vec3_to_screen(p1, _render_width, _render_height, p1.Z)
		local s2 = rmath:vec3_to_screen(p2, _render_width, _render_height, p2.Z)
		local s3 = rmath:vec3_to_screen(p3, _render_width, _render_height, p3.Z)
		local s4 = rmath:vec3_to_screen(p4, _render_width, _render_height, p4.Z)

		_push_cmd_draw(g_raster_quad_func, depth, s1, s2, s3, s4, _shader_input)
		_push_span_quad(s1,s2,s3,s4)
	else
		clip_and_raster_triangle({p1,p2,p3}, _render_width, _render_height, nil, nil, nil, nil, _shader_input )
		clip_and_raster_triangle({p1,p4,p3}, _render_width, _render_height, nil, nil, nil, nil, _shader_input )
	end
end

local function get_view_normal(_p1,_p2,_p3)
	local U = _p2 - _p1
	local V = _p3 - _p1
	local rel = _p1 - g_eye
	local view_normal = rmath:vec3_normalize(rmath:vec3_cross(U, V))
	view_normal = vec3(view_normal.X * (rel.X), view_normal.Y * (rel.Y), view_normal.Z * (rel.Z))

	return view_normal
end

local function get_view_normal2(_p1,_p2,_p3)
	local U = _p2 - _p1
	local V = _p3 - _p1
	local view_normal = rmath:vec3_normalize(rmath:vec3_cross(U, V))
	return view_normal
end

function lib:raster_triangle(_tri, _render_width, _render_height, _shader_input)
	local p1 = lib:to_view(_tri[1])
	local p2 = lib:to_view(_tri[2])
	local p3 = lib:to_view(_tri[3])
	local triangle = {p1,p2,p3}
	_shader_input = _shader_input or {}

	local near_count = count_under_value(-g_near, p1.Z, p2.Z, p3.Z)
	if near_count == 0 then return end -- behind near plane
	
	local far_count = count_over_value(-g_far, p1.Z, p2.Z, p3.Z)
	if far_count == 0 then return end -- in front of far plane
	
	local nearclipped = {}
	local farclipped  = {}

	local vs_face_normal = rmath:get_triangle_normal({p1,p2,p3})
	local dot = rmath:vec3_dot(vs_face_normal, p1)
	if dot > 0 then return end
	
	-- clip near plane
	if near_count == 1 or near_count == 2 then 
		clip_triangles_plane({triangle}, nearclipped, vec3(0, 0, -g_near), vec3(0, 0, -1.0))
	elseif near_count == 3 then 
		nearclipped = {triangle}
	end

	-- clip far plane
	if far_count == 1 or far_count == 2 then
		if not g_clip_far then return end
		clip_triangles_plane(nearclipped, farclipped, vec3(0, 0, -g_far), vec3(0, 0, 1.0))
	elseif far_count == 3 then
		farclipped = nearclipped
	end

	for i = 1, #farclipped do
		local t = {}
	
		_shader_input.light_intensity = rmath:vec3_dot(g_view_space_light_dir, rmath:vec3_normalize(vs_face_normal))
		
		t[1] = lib:view_to_clip(farclipped[i][1])
		t[2] = lib:view_to_clip(farclipped[i][2])
		t[3] = lib:view_to_clip(farclipped[i][3])

		clip_and_raster_triangle(t, _render_width, _render_height, nil, nil, nil, nil, _shader_input)
	end
end

function lib:raster_quad(_quad, _render_width, _render_height, _shader_input)
	local p1 = lib:to_view(_quad[1])
	local p2 = lib:to_view(_quad[2])
	local p3 = lib:to_view(_quad[3])
	local p4 = lib:to_view(_quad[4])
	_shader_input = _shader_input or {}

	local near_count = count_under_value(-g_near, p1.Z, p2.Z, p3.Z, p4.Z)
	if near_count == 0 then return end -- behind near plane
	
	local far_count = count_over_value(-g_far, p1.Z, p2.Z, p3.Z, p4.Z)
	if far_count == 0 then return end -- in front of far plane

--   p1   p2
--   +----+
--   |   /| 
--   | /  |
--   +----+
--   p4   p3

	if near_count == 4 and far_count == 4 then -- quad is fully inside
		local vs_face_normal_1 = rmath:get_triangle_normal({p1,p2,p4})
		local vs_face_normal_2 = rmath:get_triangle_normal({p3,p4,p2})

		local dot = math.min( rmath:vec3_dot(vs_face_normal_1, p1), rmath:vec3_dot(vs_face_normal_2, p1) )
		if dot > 0 then return end
		
		local vs_face_normal = (vs_face_normal_1 + vs_face_normal_2) / 2

		local t1 = lib:view_to_clip(p1)
		local t2 = lib:view_to_clip(p2)
		local t3 = lib:view_to_clip(p3)
		local t4 = lib:view_to_clip(p4)

		_shader_input.light_intensity = rmath:vec3_dot(g_view_space_light_dir, rmath:vec3_normalize(vs_face_normal))
		
		clip_and_raster_quad({t1,t2,t3,t4}, _render_width, _render_height, nil, nil, nil, nil, _shader_input)
	else
		if far_count ~= 4 and not g_clip_far then return end 
		
		lib:raster_triangle({_quad[1],_quad[2],_quad[3]}, _render_width, _render_height, _shader_input)
		lib:raster_triangle({_quad[1],_quad[3],_quad[4]}, _render_width, _render_height, _shader_input)
	end
end

lib:set_quad_func()
lib:set_tri_func()

return lib