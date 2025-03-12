local vec4_meta = {}

function _G.vec4(_x,_y,_z,_w)
    local vec = setmetatable({ X=_x, Y=_y, Z=_z, W=_w }, vec4_meta)
    return vec
end

function _G.vec3(_x,_y,_z)
    return vec4(_x,_y,_z,0)
end

function _G.vec2(_x,_y)
    return vec4(_x,_y,0,0)
end

vec4_meta.__tostring = function(_vec) 
    return string.format("%.1f", _vec.X) .. ", " 
        .. string.format("%.1f", _vec.Y) .. ", " 
        .. string.format("%.1f", _vec.Z) .. ", " 
        .. string.format("%.1f", _vec.W)
end

vec4_meta.__mul = function(_vec,_scalar)
    return vec4(
        _vec.X * _scalar, 
        _vec.Y * _scalar, 
        _vec.Z * _scalar, 
        _vec.W * _scalar
    )
end

vec4_meta.__div = function(_vec,_scalar)
    return vec4(
        _vec.X / _scalar, 
        _vec.Y / _scalar, 
        _vec.Z / _scalar, 
        _vec.W / _scalar
    )
end

vec4_meta.__add = function(_lhs,_rhs)
    return vec4(
        _lhs.X + _rhs.X, 
        _lhs.Y + _rhs.Y, 
        _lhs.Z + _rhs.Z, 
        _lhs.W + _rhs.W
    )
end

vec4_meta.__sub = function(_lhs,_rhs)
    return vec4(
        _lhs.X - _rhs.X, 
        _lhs.Y - _rhs.Y, 
        _lhs.Z - _rhs.Z, 
        _lhs.W - _rhs.W
    )
end

vec4_meta.__unm = function(_vec)
    return vec4(
        -_vec.X, 
        -_vec.Y, 
        -_vec.Z, 
        -_vec.W
    )
end

vec4_meta.__eq = function(_lhs,_rhs)
    return 
        _lhs.X == _rhs.X and
        _lhs.Y == _rhs.Y and
        _lhs.Z == _rhs.Z and
        _lhs.W == _rhs.W
end

return nil