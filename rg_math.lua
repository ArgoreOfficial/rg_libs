local lib = {}

--------------------------------------------------------
--[[  Vector 3                                        ]]
--------------------------------------------------------

function lib:vec3_normalize( _vec )
    local len = math.sqrt( _vec.X * _vec.X + _vec.Y * _vec.Y + _vec.Z * _vec.Z )
    if len == 0 then
        return vec3(0,0,0)
    end
    return _vec / len
end

function lib:vec3_cross( _lhs, _rhs )
    return vec3(
        _lhs.Y * _rhs.Z - _lhs.Z * _rhs.Y,
        _lhs.Z * _rhs.X - _lhs.X * _rhs.Z,
        _lhs.X * _rhs.Y - _lhs.Y * _rhs.X
    )
end

--------------------------------------------------------
--[[  Vector 4                                        ]]
--------------------------------------------------------

local vec4_meta = {}

function lib:vec4(_x,_y,_z,_w)
    local vec = setmetatable({ X=_x, Y=_y, Z=_z, W=_w }, vec4_meta)
    return vec
end

function vec4_meta.__tostring(_vec) 
    return string.format("%.1f", _vec.X) .. ", " 
        .. string.format("%.1f", _vec.Y) .. ", " 
        .. string.format("%.1f", _vec.Z) .. ", " 
        .. string.format("%.1f", _vec.W)
end

function vec4_meta.__mul(_vec,_scalar)
    return lib:vec4(
        _vec.X * _scalar, 
        _vec.Y * _scalar, 
        _vec.Z * _scalar, 
        _vec.W * _scalar
    )
end

function vec4_meta.__div(_vec,_scalar)
    return lib:vec4(
        _vec.X / _scalar, 
        _vec.Y / _scalar, 
        _vec.Z / _scalar, 
        _vec.W / _scalar
    )
end

function vec4_meta.__add(_lhs,_rhs)
    return lib:vec4(
        _lhs.X + _rhs.X, 
        _lhs.Y + _rhs.Y, 
        _lhs.Z + _rhs.Z, 
        _lhs.W + _rhs.W
    )
end

function vec4_meta.__sub(_lhs,_rhs)
    return lib:vec4(
        _lhs.X - _rhs.X, 
        _lhs.Y - _rhs.Y, 
        _lhs.Z - _rhs.Z, 
        _lhs.W - _rhs.W
    )
end

function vec4_meta.__unm(_vec)
    return lib:vec4(
        -_vec.X, 
        -_vec.Y, 
        -_vec.Z, 
        -_vec.W
    )
end

function vec4_meta.__eq(_lhs,_rhs)
    return 
        _lhs.X == _rhs.X and
        _lhs.Y == _rhs.Y and
        _lhs.Z == _rhs.Z and
        _lhs.W == _rhs.W
end

function lib:vec4_normalize( _vec )
    local len = math.pow(_vec.X, 2) + 
                math.pow(_vec.Y, 2) + 
                math.pow(_vec.Z, 2) + 
                math.pow(_vec.W, 2)
    if len == 0 then
        return lib:vec4(0,0,0,0)
    end
    return _vec / len
end

function lib:vec4_to_screen(_vec,_width,_height)
    local n = _vec / _vec.W
    return vec2(
        ( n.X/2 + 0.5) * _width,
        (-n.Y/2 + 0.5) * _height
    )
end
--------------------------------------------------------
--[[  Matrix 3x3                                      ]]
--------------------------------------------------------

function lib:mat3x3(_00, _01, _02, _10, _11, _12, _20, _21, _22 ) 
    return {
        m00 = _00, m01 = _01, m02 = _02,
        m10 = _10, m11 = _11, m12 = _12,
        m20 = _20, m21 = _21, m22 = _22
    }
end

function lib:mat3x3_identity() 
    return lib:mat3x3(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    )
end

function lib:mat3x3_transform( _mat, _vec )
	local x = _vec.X
	local y = _vec.Y
	return vec2(
		( _mat.m00 * x + _mat.m01 * y + _mat.m02 ) / ( _mat.m20 * x + _mat.m21 * y + _mat.m22 ), 
		( _mat.m10 * x + _mat.m11 * y + _mat.m12 ) / ( _mat.m20 * x + _mat.m21 * y + _mat.m22 ) 
    )
end

function lib:mat3x3_mult_mat3x3( _a, _b )
    local res = lib:mat3x3(0,0,0,0,0,0,0,0,0)

    res.m00 = res.m00 + (_a.m00 * _b.m00)
    res.m00 = res.m00 + (_a.m01 * _b.m10)
    res.m00 = res.m00 + (_a.m02 * _b.m20)
    res.m01 = res.m01 + (_a.m00 * _b.m01)
    res.m01 = res.m01 + (_a.m01 * _b.m11)
    res.m01 = res.m01 + (_a.m02 * _b.m21)
    res.m02 = res.m02 + (_a.m00 * _b.m02)
    res.m02 = res.m02 + (_a.m01 * _b.m12)
    res.m02 = res.m02 + (_a.m02 * _b.m22)
    res.m10 = res.m10 + (_a.m10 * _b.m00)
    res.m10 = res.m10 + (_a.m11 * _b.m10)
    res.m10 = res.m10 + (_a.m12 * _b.m20)
    res.m11 = res.m11 + (_a.m10 * _b.m01)
    res.m11 = res.m11 + (_a.m11 * _b.m11)
    res.m11 = res.m11 + (_a.m12 * _b.m21)
    res.m12 = res.m12 + (_a.m10 * _b.m02)
    res.m12 = res.m12 + (_a.m11 * _b.m12)
    res.m12 = res.m12 + (_a.m12 * _b.m22)
    res.m20 = res.m20 + (_a.m20 * _b.m00)
    res.m20 = res.m20 + (_a.m21 * _b.m10)
    res.m20 = res.m20 + (_a.m22 * _b.m20)
    res.m21 = res.m21 + (_a.m20 * _b.m01)
    res.m21 = res.m21 + (_a.m21 * _b.m11)
    res.m21 = res.m21 + (_a.m22 * _b.m21)
    res.m22 = res.m22 + (_a.m20 * _b.m02)
    res.m22 = res.m22 + (_a.m21 * _b.m12)
    res.m22 = res.m22 + (_a.m22 * _b.m22)

    return res
end

function lib:mat3x3_inverse(_mat)
    local ret = lib:mat3x3_identity()
    -- computes the inverse of a matrix m
    local det = _mat.m00 * (_mat.m11 * _mat.m22 - _mat.m21 * _mat.m12) -
                _mat.m01 * (_mat.m10 * _mat.m22 - _mat.m12 * _mat.m20) +
                _mat.m02 * (_mat.m10 * _mat.m21 - _mat.m11 * _mat.m20)
    
    local invdet = 1.0 / det
    
    ret.m00 = (_mat.m11 * _mat.m22 - _mat.m21 * _mat.m12) * invdet
    ret.m01 = (_mat.m02 * _mat.m21 - _mat.m01 * _mat.m22) * invdet
    ret.m02 = (_mat.m01 * _mat.m12 - _mat.m02 * _mat.m11) * invdet
    ret.m10 = (_mat.m12 * _mat.m20 - _mat.m10 * _mat.m22) * invdet
    ret.m11 = (_mat.m00 * _mat.m22 - _mat.m02 * _mat.m20) * invdet
    ret.m12 = (_mat.m10 * _mat.m02 - _mat.m00 * _mat.m12) * invdet
    ret.m20 = (_mat.m10 * _mat.m21 - _mat.m20 * _mat.m11) * invdet
    ret.m21 = (_mat.m20 * _mat.m01 - _mat.m00 * _mat.m21) * invdet
    ret.m22 = (_mat.m00 * _mat.m11 - _mat.m10 * _mat.m01) * invdet
    
    return ret
end

--------------------------------------------------------
--[[  Matrix 4x4                                      ]]
--------------------------------------------------------

function lib:mat4( 
    _00, _01, _02, _03, 
    _10, _11, _12, _13, 
    _20, _21, _22, _23, 
    _30, _31, _32, _33 )

    return {
        m00 = _00 or 1, m01 = _01 or 0, m02 = _02 or 0, m03 = _03 or 0,
        m10 = _10 or 0, m11 = _11 or 1, m12 = _12 or 0, m13 = _13 or 0,
        m20 = _20 or 0, m21 = _21 or 0, m22 = _22 or 1, m23 = _23 or 0,
        m30 = _30 or 0, m31 = _31 or 0, m32 = _32 or 0, m33 = _33 or 1
    }
end

function lib:mat4_identity() 
    return lib:mat4()
end

function lib:mat4_mult_vec4( _mat, _vec )
	return lib:vec4(
		_vec.X*_mat.m00 + _vec.Y*_mat.m01 + _vec.Z*_mat.m02 + _vec.W*_mat.m03,
		_vec.X*_mat.m10 + _vec.Y*_mat.m11 + _vec.Z*_mat.m12 + _vec.W*_mat.m13,
		_vec.X*_mat.m20 + _vec.Y*_mat.m21 + _vec.Z*_mat.m22 + _vec.W*_mat.m23,
		_vec.X*_mat.m30 + _vec.Y*_mat.m31 + _vec.Z*_mat.m32 + _vec.W*_mat.m33
	)
end

function lib:vec4_mult_mat4( _mat, _vec )
	return lib:vec4(
		_vec.X*_mat.m00 + _vec.Y*_mat.m10 + _vec.Z*_mat.m20 + _vec.W*_mat.m30,
		_vec.X*_mat.m01 + _vec.Y*_mat.m11 + _vec.Z*_mat.m21 + _vec.W*_mat.m31,
		_vec.X*_mat.m02 + _vec.Y*_mat.m12 + _vec.Z*_mat.m22 + _vec.W*_mat.m32,
		_vec.X*_mat.m03 + _vec.Y*_mat.m13 + _vec.Z*_mat.m23 + _vec.W*_mat.m33
	)
end

function lib:mat4_transform( _mat, _vec ) 
    return lib:vec4_mult_mat4( 
        _mat, 
        lib:vec4( _vec.X, _vec.Y, _vec.Z, 1 ) 
    )
end

function lib:mat4_inverse( _m )
	local A2323 = _m.m22 * _m.m33 - _m.m23 * _m.m32
	local A1323 = _m.m21 * _m.m33 - _m.m23 * _m.m31
	local A1223 = _m.m21 * _m.m32 - _m.m22 * _m.m31
	local A0323 = _m.m20 * _m.m33 - _m.m23 * _m.m30
	local A0223 = _m.m20 * _m.m32 - _m.m22 * _m.m30
	local A0123 = _m.m20 * _m.m31 - _m.m21 * _m.m30
	local A2313 = _m.m12 * _m.m33 - _m.m13 * _m.m32
	local A1313 = _m.m11 * _m.m33 - _m.m13 * _m.m31
	local A1213 = _m.m11 * _m.m32 - _m.m12 * _m.m31
	local A2312 = _m.m12 * _m.m23 - _m.m13 * _m.m22
	local A1312 = _m.m11 * _m.m23 - _m.m13 * _m.m21
	local A1212 = _m.m11 * _m.m22 - _m.m12 * _m.m21
	local A0313 = _m.m10 * _m.m33 - _m.m13 * _m.m30
	local A0213 = _m.m10 * _m.m32 - _m.m12 * _m.m30
	local A0312 = _m.m10 * _m.m23 - _m.m13 * _m.m20
	local A0212 = _m.m10 * _m.m22 - _m.m12 * _m.m20
	local A0113 = _m.m10 * _m.m31 - _m.m11 * _m.m30
	local A0112 = _m.m10 * _m.m21 - _m.m11 * _m.m20

	local det = _m.m00 * ( _m.m11 * A2323 - _m.m12 * A1323 + _m.m13 * A1223 )
		      - _m.m01 * ( _m.m10 * A2323 - _m.m12 * A0323 + _m.m13 * A0223 )
		      + _m.m02 * ( _m.m10 * A1323 - _m.m11 * A0323 + _m.m13 * A0123 )
		      - _m.m03 * ( _m.m10 * A1223 - _m.m11 * A0223 + _m.m12 * A0123 )

	if det == 0.0 then -- determinant is zero, inverse matrix does not exist
		return lib:mat4()
    end
	det = 1 / det

	local im = lib:mat4()

	im.m00 = det *  ( _m.m11 * A2323 - _m.m12 * A1323 + _m.m13 * A1223 )
	im.m01 = det * -( _m.m01 * A2323 - _m.m02 * A1323 + _m.m03 * A1223 )
	im.m02 = det *  ( _m.m01 * A2313 - _m.m02 * A1313 + _m.m03 * A1213 )
	im.m03 = det * -( _m.m01 * A2312 - _m.m02 * A1312 + _m.m03 * A1212 )
	im.m10 = det * -( _m.m10 * A2323 - _m.m12 * A0323 + _m.m13 * A0223 )
	im.m11 = det *  ( _m.m00 * A2323 - _m.m02 * A0323 + _m.m03 * A0223 )
	im.m12 = det * -( _m.m00 * A2313 - _m.m02 * A0313 + _m.m03 * A0213 )
	im.m13 = det *  ( _m.m00 * A2312 - _m.m02 * A0312 + _m.m03 * A0212 )
	im.m20 = det *  ( _m.m10 * A1323 - _m.m11 * A0323 + _m.m13 * A0123 )
	im.m21 = det * -( _m.m00 * A1323 - _m.m01 * A0323 + _m.m03 * A0123 )
	im.m22 = det *  ( _m.m00 * A1313 - _m.m01 * A0313 + _m.m03 * A0113 )
	im.m23 = det * -( _m.m00 * A1312 - _m.m01 * A0312 + _m.m03 * A0112 )
	im.m30 = det * -( _m.m10 * A1223 - _m.m11 * A0223 + _m.m12 * A0123 )
	im.m31 = det *  ( _m.m00 * A1223 - _m.m01 * A0223 + _m.m02 * A0123 )
	im.m32 = det * -( _m.m00 * A1213 - _m.m01 * A0213 + _m.m02 * A0113 )
	im.m33 = det *  ( _m.m00 * A1212 - _m.m01 * A0212 + _m.m02 * A0112 )

	return im
end

-- https://github.com/ArgoreOfficial/Wyvern/blob/dev/src/engine/wv/math/matrix_core.h#L272
function lib:mat4_perspective( _aspect, _fov, _near, _far )
	local e = 1.0 / math.tan( _fov / 2.0 )
	local m00 = e / _aspect
	local m22 = ( _far + _near ) / ( _near - _far )
	local m32 = ( 2.0 * _far * _near ) / ( _near - _far )

	local res = lib:mat4(
		m00, 0,   0,  0,
		0,   e,   0,  0,
		0,   0, m22, -1,
		0,   0, m32,  0
	)

	return res
end

-- Camera to World Matrix 
function lib:mat4_look_at_c2w(_from, _to, _up) 
    local forward = lib:vec3_normalize(_from - _to)
    local right = lib:vec3_normalize(lib:vec3_cross(_up, forward))
    local up = lib:vec3_cross(forward, right)
    
    return lib:mat4(
          right.X,    right.Y,    right.Z, 0,
             up.X,       up.Y,       up.Z, 0,
        forward.X,  forward.Y,  forward.Z, 0,
          _from.X,    _from.Y,    _from.Z, 1
    )
end

-- View (World to Camera) Matrix == inverse(mat4_look_at_c2w)
function lib:mat4_look_at(_eye, _center, _up)
    local f = lib:vec3_normalize(_center - _eye)
    local s = lib:vec3_normalize(lib:vec3_cross(f, _up))
    local t = lib:vec3_cross(s, f)

    local mat = lib:mat4(
        s.X, t.X, -f.X, 0.0,
        s.Y, t.Y, -f.Y, 0.0,
        s.Z, t.Z, -f.Z, 0.0,
        0.0, 0.0,  0.0, 1.0
    )

    local e = lib:vec4_mult_mat4(mat, lib:vec4(-_eye.X, -_eye.Y, -_eye.Z, 0.0))
    mat.m30 = e.X
    mat.m31 = e.Y
    mat.m32 = e.Z
    mat.m33 = e.W

    return mat
end

return lib