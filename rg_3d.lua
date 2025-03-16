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

local project_return_vec = rmath:vec4()
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

local to_clip_v4  = rmath:vec4() -- world space vec4
local to_clip_tv4 = rmath:vec4() -- view space vec3
local to_clip_cv4 = rmath:vec4() -- clip space vec3
function lib:to_clip(_vec)
	to_clip_v4  = rmath:vec4(_vec.X, _vec.Y, _vec.Z, 1)
	to_clip_tv4 = rmath:mat4_transform(g_view_mat, to_clip_v4)
	to_clip_cv4 = lib:project(to_clip_tv4)
	return rmath:vec4(
		to_clip_cv4.X / to_clip_cv4.W,
		to_clip_cv4.Y / to_clip_cv4.W,
		to_clip_cv4.Z )
end

local to_screen_sv4 = rmath:vec4() -- screen space vec4
function lib:to_screen(_vec, _screen_width, _screen_height)
	to_screen_sv4 = rmath:vec3_to_screen(lib:to_clip(_vec), _screen_width, _screen_height)
	return vec3(to_screen_sv4.X, to_screen_sv4.Y, to_screen_sv4.Z)
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

local function debug_triangle(_p1,_p2,_p3,_color)
	gdt.VideoChip0:DrawLine(_p1,_p2,_color)
	gdt.VideoChip0:DrawLine(_p2,_p3,_color)
	gdt.VideoChip0:DrawLine(_p3,_p1,_color)
end

local function draw_triangle(_p1,_p2,_p3,_color)
	debug_triangle(_p1,_p2,_p3,_color)
end


function lib:raster_triangle(_tri, _render_width, _render_height)

	local p1 = lib:to_clip( _tri[1] )
	local p2 = lib:to_clip( _tri[2] )
	local p3 = lib:to_clip( _tri[3] )
	
	local x = count_inside_value(p1.X, p2.X, p3.X)
	local y = count_inside_value(p1.Y, p2.Y, p3.Y)
	local z = count_inside_value(p1.Z, p2.Z, p3.Z, 0, 1)

	-- draw triangles
	
	local one   = math.min(x,y) == 1
	local two   = math.min(x,y) == 2
	local three = math.min(x,y) == 3

	print(math.min(x,y))
	if math.min(x,y) == 0 then return end

	draw_triangle(
			rmath:vec3_to_screen(p1, _render_width, _render_height),
			rmath:vec3_to_screen(p2, _render_width, _render_height),
			rmath:vec3_to_screen(p3, _render_width, _render_height),
			(one and color.red) or (two and color.yellow) or (three and color.green) or color.cyan )
end

return lib