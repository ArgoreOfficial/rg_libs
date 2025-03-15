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

local v4  = rmath:vec4()
local tv4 = rmath:vec4()
local pv4 = rmath:vec4()
function lib:to_screen(_vec, _screen_width, _screen_height)
	v4  = rmath:vec4(_vec.X, _vec.Y, _vec.Z, 1)
	tv4 = rmath:mat4_transform(g_view_mat, v4)
	pv4 = rmath:vec4_to_screen(lib:project(tv4), _screen_width, _screen_height)

	return vec3(pv4.X, pv4.Y, pv4.Z)
end

return lib