local vec3_meta = {}

function _G.vec3(_x,_y,_z)
    local vec = setmetatable({ X=_x, Y=_y, Z=_z }, vec3_meta)
    return vec
end

function _G.vec2(_x,_y)
    return vec3(_x,_y,0)
end

function vec3_meta.__newindex(t, key, value)
    if key == "x" then error("lowercase .x used on vector, did you mean .X ?") end
    if key == "y" then error("lowercase .y used on vector, did you mean .Y ?") end
    if key == "z" then error("lowercase .z used on vector, did you mean .Z ?") end

    error("unknown vector member: " .. key)
end

function vec3_meta.__tostring(_vec) 
    return string.format("%.1f", _vec.X) .. ", " 
        .. string.format("%.1f", _vec.Y) .. ", " 
        .. string.format("%.1f", _vec.Z)
end

function vec3_meta.__mul(_lhs,_rhs)
    if type(_lhs) == "number" then
        return vec3(
            _lhs * _rhs.X, 
            _lhs * _rhs.Y, 
            _lhs * _rhs.Z
        )
    else
        return vec3(
            _lhs.X * _rhs, 
            _lhs.Y * _rhs, 
            _lhs.Z * _rhs
        )
    end
end

function vec3_meta.__div(_vec,_scalar)
    return vec3(
        _vec.X / _scalar, 
        _vec.Y / _scalar, 
        _vec.Z / _scalar
    )
end

function vec3_meta.__add(_lhs,_rhs)
    return vec3(
        _lhs.X + _rhs.X, 
        _lhs.Y + _rhs.Y, 
        _lhs.Z + _rhs.Z
    )
end

function vec3_meta.__sub(_lhs,_rhs)
    return vec3(
        _lhs.X - _rhs.X, 
        _lhs.Y - _rhs.Y, 
        _lhs.Z - _rhs.Z
    )
end

function vec3_meta.__unm(_vec)
    return vec3(
        -_vec.X, 
        -_vec.Y, 
        -_vec.Z
    )
end

function vec3_meta.__eq(_lhs,_rhs)
    return 
        _lhs.X == _rhs.X and
        _lhs.Y == _rhs.Y and
        _lhs.Z == _rhs.Z
end

return nil