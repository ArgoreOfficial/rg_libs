local color_meta = {}

function _G.ColorRGBA(r,g,b,a)
    return setmetatable({ R=r, G=g, B=b, A=a }, color_meta)
end

function _G.Color(r,g,b)
    return ColorRGBA(r,g,b,255)
end

_G.color = {
    clear   = ColorRGBA(0, 0, 0, 0),
    black   = Color(  0,   0,   0),
    blue    = Color(  0,   0, 255),
    cyan    = Color(  0, 255, 255),
    gray    = Color(  0,   0,   0), -- TODO
    green   = Color(  0, 255,   0),
    magenta = Color(255,   0, 255),
    red     = Color(255,   0,   0),
    white   = Color(255, 255, 255),
    yellow  = Color(255, 255,   0)
}