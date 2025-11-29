local color_meta = {}

function _G.ColorRGBA(r,g,b,a)
    return setmetatable({ R=r, G=g, B=b, A=a }, color_meta)
end

function _G.Color(r,g,b)
    return ColorRGBA(r,g,b,255)
end

-- https://github.com/iskolbin/lhsx/blob/master/hsx.lua#L40
function _G.ColorHSV(h, s, v)
    local C = v * s
	local m = v - C
	local r, g, b = m, m, m
	
    local h2 = ((h / 360) % 1.0) * 6
    local X = C * (1 - math.abs(h2 % 2 - 1))
    C, X = C + m, X + m
    if     h2 < 1 then r, g, b = C, X, m
    elseif h2 < 2 then r, g, b = X, C, m
    elseif h2 < 3 then r, g, b = m, C, X
    elseif h2 < 4 then r, g, b = m, X, C
    elseif h2 < 5 then r, g, b = X, m, C
    else               r, g, b = C, m, X
    end
	
	return Color(r * 255, g * 255, b * 255)
end

function color_meta.__eq(_lhs,_rhs)
    return 
        _lhs.R == _rhs.R and
        _lhs.G == _rhs.G and
        _lhs.B == _rhs.B
end

_G.color = {
    clear   = ColorRGBA(0, 0, 0, 0),
    black   = Color(  0,   0,   0),
    blue    = Color(  0,   0, 255),
    cyan    = Color(  0, 255, 255),
    gray    = Color(127.5,127.5,127.5),
    green   = Color(  0, 255,   0),
    magenta = Color(255,   0, 255),
    red     = Color(255,   0,   0),
    white   = Color(255, 255, 255),
    yellow  = Color(255, 255,   0)
}