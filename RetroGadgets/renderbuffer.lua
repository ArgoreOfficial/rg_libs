local methods = {}
local meta = {__index = methods}

function _G._renderbuffer(_w,_h)
    local rb = setmetatable({
        Name = "",
        Type = "RenderBuffer",
        Width  = _w,
        Height = _h,
        _Canvas = love.graphics.newCanvas(_w, _h)
    }, meta)
    rb._Canvas:setFilter("nearest","nearest")
    return rb
end

function methods:IsValid()
    return self._Canvas ~= nil
end

function methods:GetPixelData()
    rg_unimplemented()
end