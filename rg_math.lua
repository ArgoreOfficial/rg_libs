local lib = {}

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

function lib:mat4( 
    _00, _01, _02, _03, 
    _10, _11, _12, _13, 
    _20, _21, _22, _23, 
    _30, _31, _32, _33 )

    return {
        m00 = _00, m01 = _01, m02 = _02, m03 = _03,
        m10 = _10, m11 = _11, m12 = _12, m13 = _13,
        m20 = _20, m21 = _21, m22 = _22, m23 = _23,
        m30 = _30, m31 = _31, m32 = _32, m33 = _33
    }
end

function lib:mat4_identity() 
    return lib:mat4(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
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

function lib:mat4_mult_vec4( _mat, _vec )
	return vec4(
		_vec.X*_mat.m00 + _vec.Y*_mat.m01 + _vec.Z*_mat.m02 + _vec.W*_mat.m03,
		_vec.X*_mat.m10 + _vec.Y*_mat.m11 + _vec.Z*_mat.m12 + _vec.W*_mat.m13,
		_vec.X*_mat.m20 + _vec.Y*_mat.m21 + _vec.Z*_mat.m22 + _vec.W*_mat.m23,
		_vec.X*_mat.m30 + _vec.Y*_mat.m31 + _vec.Z*_mat.m32 + _vec.W*_mat.m33
	)
end

function lib:vec4_mult_mat4( _mat, _vec )
	return vec4(
		_vec.X*_mat.m00 + _vec.Y*_mat.m10 + _vec.Z*_mat.m20 + _vec.W*_mat.m30,
		_vec.X*_mat.m01 + _vec.Y*_mat.m11 + _vec.Z*_mat.m21 + _vec.W*_mat.m31,
		_vec.X*_mat.m02 + _vec.Y*_mat.m12 + _vec.Z*_mat.m22 + _vec.W*_mat.m32,
		_vec.X*_mat.m03 + _vec.Y*_mat.m13 + _vec.Z*_mat.m23 + _vec.W*_mat.m33
	)
end

function lib:mat4_transform( mat, _vec ) 
    local v = lib:vec4_mult_mat4( 
        _mat, 
        vec4( _vec.X, _vec.Y, _vec.Z, 1 ) 
    )
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

return lib