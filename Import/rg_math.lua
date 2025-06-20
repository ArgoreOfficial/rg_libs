local lib = {
    const = {}
}

local function setup_const(t)
    local proxy = {}
    local mt = {       -- create metatable
      __index = t,
      __newindex = function (t,k,v)
        error("attempt to update a read-only table", 2)
      end
    }
    setmetatable(proxy, mt)
    return proxy
end

lib.const.PI = 3.141592
lib.const.EPSILON = 0.000001
lib.const = setup_const(lib.const)


function lib.nsin(_v)
	return math.sin(_v) * 0.5 + 0.5
end

function lib.ncos(_v)
	return math.cos(_v) * 0.5 + 0.5
end


--------------------------------------------------------
--[[  Math                                            ]]
--------------------------------------------------------

function lib:radians(_degrees)
    return _degrees * ( lib.const.PI / 180.0 )
end

function lib:degrees( _radians ) 
	return _radians * ( 180.0 / lib.const.PI )
end

function lib:round_down_to_po2(_x)
    _x = bit32.bor( _x, bit32.rshift(_x,  1) )
    _x = bit32.bor( _x, bit32.rshift(_x,  2) )
    _x = bit32.bor( _x, bit32.rshift(_x,  4) )
    _x = bit32.bor( _x, bit32.rshift(_x,  8) )
    _x = bit32.bor( _x, bit32.rshift(_x, 16) )
    return _x - bit32.rshift(_x, 1)
end

function lib:round_up_to_po2(_x)
	_x = _x - 1
	_x = bit32.bor(_x, bit32.rshift(_x, 1 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 2 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 4 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 8 ))
	_x = bit32.bor(_x, bit32.rshift(_x, 16 ))
	return _x + 1
end

function lib:round_to_po2(_n)
	local v = _n - 1
	v = bit32.bor(v, bit32.rshift(v, 1))
	v = bit32.bor(v, bit32.rshift(v, 2))
	v = bit32.bor(v, bit32.rshift(v, 4))
	v = bit32.bor(v, bit32.rshift(v, 8))
	v = bit32.bor(v, bit32.rshift(v, 16))
	v = v + 1 -- next power of 2

	local x = bit32.rshift(v, 1 ) -- previous power of 2

	return (math.abs(v - _n) > math.abs(_n - x)) and x or v
end

function lib:lerp(_a, _b, _t)
	return _a + (_b - _a) * _t
end

function lib:map_range(_input, _input_start, _input_end, _output_start, _output_end)
    return _output_start + ((_output_end - _output_start) / (_input_end - _input_start)) * (_input - _input_start)
end

--------------------------------------------------------
--[[  Vector 3                                        ]]
--------------------------------------------------------

function lib:vec3_len(_vec)
    return math.sqrt( _vec.X * _vec.X + _vec.Y * _vec.Y + _vec.Z * _vec.Z )
end

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

function lib:vec3_dot( _lhs, _rhs )
    return (_lhs.X * _rhs.X) 
         + (_lhs.Y * _rhs.Y) 
         + (_lhs.Z * _rhs.Z)
end

function lib:vec3_to_screen(_vec,_width,_height,_depth)
    return vec3(
        ( _vec.X/2 + 0.5) * _width,
        (-_vec.Y/2 + 0.5) * _height,
        _depth or 0
    )
end

function lib:vec3_from_screen(_vec,_width,_height)
    local x = _vec.X / _width
    local y = _vec.Y / _height

    x = x - 0.5
    y = y - 0.5

    x = x * 2
    y = y * 2

    return vec3(x, -y, _vec.Z or 0)
end

function lib:vec3_mult(_lhs,_rhs)
	return vec3(
		_lhs.X * _rhs.X,
		_lhs.Y * _rhs.Y,
		_lhs.Z * _rhs.Z
	)
end

function lib:vec3_to_color(_vec)
	return Color(_vec.X, _vec.Y, _vec.Z)
end

function lib:rot_to_dir(_pitch, _yaw)
	return vec3(
		math.cos(_yaw)*math.cos(_pitch),
		math.sin(_pitch),
		math.sin(_yaw)*math.cos(_pitch)
	)
end

--------------------------------------------------------
--[[  Vector 4                                        ]]
--------------------------------------------------------

local vec4_meta = {}

function lib:vec4(_x,_y,_z,_w)
    local vec = setmetatable({ X=_x or 0, Y=_y or 0, Z=_z or 0, W=_w or 0 }, vec4_meta)
    return vec
end

function vec4_meta.__tostring(_vec) 
    return tostring(_vec.X) .. ", " 
        .. tostring(_vec.Y) .. ", " 
        .. tostring(_vec.Z) .. ", " 
        .. tostring(_vec.W)
end

function vec4_meta.__mul(_vec,_scalar)
    return lib:vec4(
        _vec.X * _scalar, 
        _vec.Y * _scalar, 
        _vec.Z * _scalar, 
        (_vec.W or 0 ) * _scalar
    )
end

function vec4_meta.__div(_vec,_scalar)
    return lib:vec4(
        _vec.X / _scalar, 
        _vec.Y / _scalar, 
        _vec.Z / _scalar, 
        (_vec.W or 0) / _scalar
    )
end

function vec4_meta.__add(_lhs,_rhs)
    return lib:vec4(
        _lhs.X + _rhs.X, 
        _lhs.Y + _rhs.Y, 
        _lhs.Z + _rhs.Z, 
        (_lhs.W or 0) + (_rhs.W or 0)
    )
end

function vec4_meta.__sub(_lhs,_rhs)
    return lib:vec4(
        _lhs.X - _rhs.X, 
        _lhs.Y - _rhs.Y, 
        _lhs.Z - _rhs.Z, 
        (_lhs.W or 0) - (_rhs.W or 0)
    )
end

function vec4_meta.__unm(_vec)
    return lib:vec4(
        -_vec.X, 
        -_vec.Y, 
        -_vec.Z, 
        -(_vec.W or 0)
    )
end

function vec4_meta.__eq(_lhs,_rhs)
    return 
        _lhs.X == _rhs.X and
        _lhs.Y == _rhs.Y and
        _lhs.Z == _rhs.Z and
        (_lhs.W or 0) == (_rhs.W or 0)
end

function lib:vec4_normalize( _vec )
    local len = math.pow(_vec.X, 2) + 
                math.pow(_vec.Y, 2) + 
                math.pow(_vec.Z, 2) + 
                math.pow(_vec.W or 0, 2)
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
--[[  Matrix                                          ]]
--------------------------------------------------------

local function _matrix_at(_row,_col)
    return "m" .. tostring(_row) .. tostring(_col)
end

local function _matrix_generic_mult(_a, _b)
    local res = lib:mat4()
    for row = 1, 4 do
        for col = 1, 4 do
            local v = 0
            for inner = 1, 4 do
                v = v + _a[_matrix_at(row, inner)] * _b[_matrix_at(inner, col)]
            end
            res[_matrix_at(row, col)] = v
        end
    end
    return res
end


--------------------------------------------------------
--[[  Matrix 2x2                                      ]]
--------------------------------------------------------

function lib:mat2(_00, _01, _10, _11)
    return {
        m00 = _00 or 1, m01 = _01 or 0,
        m10 = _10 or 0, m11 = _11 or 1
    }
end

function lib:mat2_vec2(_0,_1)
    return lib:mat2(
        _0.X, _0.Y,
        _1.X, _1.Y
    )
end

function lib:mat2_determinant(_mat)
    return (_mat.m00 * _mat.m11) - (_mat.m01 * _mat.m10)
end

--------------------------------------------------------
--[[  Matrix 3x3                                      ]]
--------------------------------------------------------

function lib:mat3x3(_00, _01, _02, _10, _11, _12, _20, _21, _22 ) 
    return {
        m00 = _00 or 1, m01 = _01 or 0, m02 = _02 or 0,
        m10 = _10 or 0, m11 = _11 or 1, m12 = _12 or 0,
        m20 = _20 or 0, m21 = _21 or 0, m22 = _22 or 1
    }
end

function lib:mat3x3_from_vec3(_0, _1, _2) 
    return lib:mat3x3(
        _0.X or 1, _0.Y or 0, _0.Z or 0,
        _1.X or 0, _1.Y or 1, _1.Z or 0,
        _2.X or 0, _2.Y or 0, _2.Z or 1 
    )
end

function lib:mat3_print(_mat)
    print(_mat.m00, _mat.m01, _mat.m02, _mat.m03)
    print(_mat.m10, _mat.m11, _mat.m12, _mat.m13)
    print(_mat.m20, _mat.m21, _mat.m22, _mat.m23)
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
    local res = lib:mat3x3()

    res.m00 = (_a.m00 * _b.m00) + (_a.m01 * _b.m10) + (_a.m02 * _b.m20)
    res.m01 = (_a.m00 * _b.m01) + (_a.m01 * _b.m11) + (_a.m02 * _b.m21)
    res.m02 = (_a.m00 * _b.m02) + (_a.m01 * _b.m12) + (_a.m02 * _b.m22)
    res.m10 = (_a.m10 * _b.m00) + (_a.m11 * _b.m10) + (_a.m12 * _b.m20)
    res.m11 = (_a.m10 * _b.m01) + (_a.m11 * _b.m11) + (_a.m12 * _b.m21)
    res.m12 = (_a.m10 * _b.m02) + (_a.m11 * _b.m12) + (_a.m12 * _b.m22)
    res.m20 = (_a.m20 * _b.m00) + (_a.m21 * _b.m10) + (_a.m22 * _b.m20)
    res.m21 = (_a.m20 * _b.m01) + (_a.m21 * _b.m11) + (_a.m22 * _b.m21)
    res.m22 = (_a.m20 * _b.m02) + (_a.m21 * _b.m12) + (_a.m22 * _b.m22)

    return res
end

function lib:mat3_mult_vec3(_mat, _vec)
    return vec3(
		_vec.X*_mat.m00 + _vec.Y*_mat.m01 + _vec.Z*_mat.m02,
		_vec.X*_mat.m10 + _vec.Y*_mat.m11 + _vec.Z*_mat.m12,
		_vec.X*_mat.m20 + _vec.Y*_mat.m21 + _vec.Z*_mat.m22
	)
end

function lib:vec3_mult_mat3(_vec, _mat)
	return vec3(
		_vec.X*_mat.m00 + _vec.Y*_mat.m10 + _vec.Z*_mat.m20,
		_vec.X*_mat.m01 + _vec.Y*_mat.m11 + _vec.Z*_mat.m21,
		_vec.X*_mat.m02 + _vec.Y*_mat.m12 + _vec.Z*_mat.m22
	)
end


function lib:mat3_inverse(_mat)
    local ret = lib:mat3x3()
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

function lib:mat3_transpose( _mat )
	return lib:mat3x3(
        _mat.m00, _mat.m10, _mat.m20,
        _mat.m01, _mat.m11, _mat.m21,
        _mat.m02, _mat.m12, _mat.m22
    )
end

function lib:mat3_transposed_inverse(_mat)
    local ret = lib:mat3x3()
    local det = _mat.m00 * (_mat.m11 * _mat.m22 - _mat.m21 * _mat.m12) - 
                _mat.m01 * (_mat.m10 * _mat.m22 - _mat.m12 * _mat.m20) + 
                _mat.m02 * (_mat.m10 * _mat.m21 - _mat.m11 * _mat.m20)

    local invdet = 1.0 / det
    
    ret.m00 =  (_mat.m11*_mat.m22-_mat.m21*_mat.m12) * invdet
    ret.m10 = -(_mat.m01*_mat.m22-_mat.m02*_mat.m21) * invdet
    ret.m20 =  (_mat.m01*_mat.m12-_mat.m02*_mat.m11) * invdet
    ret.m01 = -(_mat.m10*_mat.m22-_mat.m12*_mat.m20) * invdet
    ret.m11 =  (_mat.m00*_mat.m22-_mat.m02*_mat.m20) * invdet
    ret.m21 = -(_mat.m00*_mat.m12-_mat.m10*_mat.m02) * invdet
    ret.m02 =  (_mat.m10*_mat.m21-_mat.m20*_mat.m11) * invdet
    ret.m12 = -(_mat.m00*_mat.m21-_mat.m20*_mat.m01) * invdet
    ret.m22 =  (_mat.m00*_mat.m11-_mat.m10*_mat.m01) * invdet

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

function lib:mat4_print(_mat)
    print(_mat.m00, _mat.m01, _mat.m02, _mat.m03)
    print(_mat.m10, _mat.m11, _mat.m12, _mat.m13)
    print(_mat.m20, _mat.m21, _mat.m22, _mat.m23)
    print(_mat.m30, _mat.m31, _mat.m32, _mat.m33)
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

function lib:mat4_transpose( _mat )
    if not _mat then error("cannot transpose nil") end
    
    local res = lib:mat4()

	res.m00 = _mat.m00
	res.m10 = _mat.m01
	res.m20 = _mat.m02
	res.m30 = _mat.m03
	res.m01 = _mat.m10
	res.m11 = _mat.m11
	res.m21 = _mat.m12
	res.m31 = _mat.m13
	res.m02 = _mat.m20
	res.m12 = _mat.m21
	res.m22 = _mat.m22
	res.m32 = _mat.m23
	res.m03 = _mat.m30
	res.m13 = _mat.m31
	res.m23 = _mat.m32
	res.m33 = _mat.m33

	return res
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

function lib:mat4_mult_mat4(_lhs, _rhs)
    if not _lhs then return _rhs end
    if not _rhs then return _lhs end

	local res = lib:mat4()

	res.m00 = (_lhs.m00 * _rhs.m00) + (_lhs.m01 * _rhs.m10) + (_lhs.m02 * _rhs.m20) + (_lhs.m03 * _rhs.m30)
	res.m01 = (_lhs.m00 * _rhs.m01) + (_lhs.m01 * _rhs.m11) + (_lhs.m02 * _rhs.m21) + (_lhs.m03 * _rhs.m31) 
	res.m02 = (_lhs.m00 * _rhs.m02) + (_lhs.m01 * _rhs.m12) + (_lhs.m02 * _rhs.m22) + (_lhs.m03 * _rhs.m32)
	res.m03 = (_lhs.m00 * _rhs.m03) + (_lhs.m01 * _rhs.m13) + (_lhs.m02 * _rhs.m23) + (_lhs.m03 * _rhs.m33)
	res.m10 = (_lhs.m10 * _rhs.m00) + (_lhs.m11 * _rhs.m10) + (_lhs.m12 * _rhs.m20) + (_lhs.m13 * _rhs.m30)
	res.m11 = (_lhs.m10 * _rhs.m01) + (_lhs.m11 * _rhs.m11) + (_lhs.m12 * _rhs.m21) + (_lhs.m13 * _rhs.m31)
	res.m12 = (_lhs.m10 * _rhs.m02) + (_lhs.m11 * _rhs.m12) + (_lhs.m12 * _rhs.m22) + (_lhs.m13 * _rhs.m32)
	res.m13 = (_lhs.m10 * _rhs.m03) + (_lhs.m11 * _rhs.m13) + (_lhs.m12 * _rhs.m23) + (_lhs.m13 * _rhs.m33)
	res.m20 = (_lhs.m20 * _rhs.m00) + (_lhs.m21 * _rhs.m10) + (_lhs.m22 * _rhs.m20) + (_lhs.m23 * _rhs.m30)
	res.m21 = (_lhs.m20 * _rhs.m01) + (_lhs.m21 * _rhs.m11) + (_lhs.m22 * _rhs.m21) + (_lhs.m23 * _rhs.m31)
	res.m22 = (_lhs.m20 * _rhs.m02) + (_lhs.m21 * _rhs.m12) + (_lhs.m22 * _rhs.m22) + (_lhs.m23 * _rhs.m32)
	res.m23 = (_lhs.m20 * _rhs.m03) + (_lhs.m21 * _rhs.m13) + (_lhs.m22 * _rhs.m23) + (_lhs.m23 * _rhs.m33)
	res.m30 = (_lhs.m30 * _rhs.m00) + (_lhs.m31 * _rhs.m10) + (_lhs.m32 * _rhs.m20) + (_lhs.m33 * _rhs.m30)
	res.m31 = (_lhs.m30 * _rhs.m01) + (_lhs.m31 * _rhs.m11) + (_lhs.m32 * _rhs.m21) + (_lhs.m33 * _rhs.m31)
	res.m32 = (_lhs.m30 * _rhs.m02) + (_lhs.m31 * _rhs.m12) + (_lhs.m32 * _rhs.m22) + (_lhs.m33 * _rhs.m32)
	res.m33 = (_lhs.m30 * _rhs.m03) + (_lhs.m31 * _rhs.m13) + (_lhs.m32 * _rhs.m23) + (_lhs.m33 * _rhs.m33)

    return res
end
-- wv::Matrix4x4::scale
function lib:mat4_scale(_m, _scale)
	return lib:mat4_mult_mat4( lib:mat4(
        _scale.X, 0.0,      0.0, 0.0,
        0.0, _scale.Y,      0.0, 0.0,
        0.0,      0.0, _scale.Z, 0.0
    ), _m )
end

-- wv::Matrix4x4::rotateX
function lib:mat4_rotateX(_m, _angle)
	local mat = lib:mat4(
        1.0,               0.0,              0.0, 0.0,
        0.0,  math.cos(_angle), math.sin(_angle), 0.0,
        0.0, -math.sin(_angle), math.cos(_angle), 0.0
    )

	return lib:mat4_mult_mat4(mat, _m)
end

-- wv::Matrix4x4::rotateY
function lib:mat4_rotateY(_m, _angle)
	local mat = lib:mat4(
        math.cos( _angle ), 0.0, -math.sin( _angle ), 0.0,
        0.0, 1.0,                 0.0,                0.0,
        math.sin( _angle ), 0.0,  math.cos( _angle ), 0.0
    )

	return lib:mat4_mult_mat4(mat, _m)
end

-- wv::Matrix4x4::rotateZ
function lib:mat4_rotateZ(_m, _angle)
	local mat = lib:mat4(
         math.cos( _angle ), math.sin( _angle ), 0.0, 0.0,
        -math.sin( _angle ), math.cos( _angle ), 0.0, 0.0,
        0.0,                0.0,                 1.0, 0.0
    )
    
	return lib:mat4_mult_mat4(mat, _m)
end

-- wv::Matrix4x4
function lib:mat4_translate(_m, _t)
    return lib:mat4_mult_mat4( lib:mat4(
          1.0,  0.0,  0.0, 0.0,
          0.0,  1.0,  0.0, 0.0,
          0.0,  0.0,  1.0, 0.0,
         _t.X, _t.Y, _t.Z, 1.0
    ), _m )
end

function lib:mat4_model_matrix(_pos,_rot,_scale)
    local model = lib:mat4()

	model = lib:mat4_translate(model, _pos)
    
	model = lib:mat4_rotateZ(model, lib:radians(_rot.Z))
	model = lib:mat4_rotateY(model, lib:radians(_rot.Y))
	model = lib:mat4_rotateX(model, lib:radians(_rot.X))
    
	model = lib:mat4_scale(model, _scale)

    return model
end

--------------------------------------------------------
--[[  Geometry                                        ]]
--------------------------------------------------------

function lib:area_of_four_points(_a,_b,_c,_d)
    local v = (_a.X*_b.Y - _a.Y*_b.X) + 
              (_b.X*_c.Y - _b.Y*_c.X) + 
              (_c.X*_d.Y - _c.Y*_d.X) +
              (_d.X*_a.Y - _d.Y*_a.X)
    return v / 2
end

function lib:get_triangle_normal(_triangle)
	local U = _triangle[2] - _triangle[1]
	local V = _triangle[3] - _triangle[1]

	local nx = (U.Y * V.Z) - (U.Z * V.Y)
	local ny = (U.Z * V.X) - (U.X * V.Z)
	local nz = (U.X * V.Y) - (U.Y * V.X)
	
	return vec3(nx, ny, nz)
end

return lib