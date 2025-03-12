local lib = {}

-- global lib state
local g_perspective_e   = 1
local g_perspective_m00 = 1
local g_perspective_m22 = 1
local g_perspective_m32 = 1
local g_use_perspective = true

function lib:push_perspective( _aspect, _fov, _near, _far )
    g_perspective_e   = 1.0 / math.tan( _fov / 2.0 )
	g_perspective_m00 = g_perspective_e / _aspect
	g_perspective_m22 = ( _far + _near )       / ( _near - _far )
	g_perspective_m32 = ( 2.0 * _far * _near ) / ( _near - _far )

    g_use_perspective = true
end

function lib:project( _vec )
    if g_use_perspective then
	    return vec4(
	    	 _vec.X * g_perspective_m00,
	    	 _vec.Y * g_perspective_e,
	    	 _vec.Z * g_perspective_m22 + _vec.W * g_perspective_m32,
	    	-_vec.Z )
    else
        return vec4(0,0,0,0) -- ortho
    end
end

return lib