require "RetroGadgets.pixeldata"

local methods = {}
local meta = {__index = methods}

function _G._renderbuffer_new(_w, _h)
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

function _G._renderbuffer_set(_rb, _w, _h)
    _rb.Name = ""
    _rb.Type = "RenderBuffer"
    _rb.Width  = _w
    _rb.Height = _h
    _rb._Canvas = love.graphics.newCanvas(_w, _h)
    _rb._Canvas:setFilter("nearest","nearest")
    return _rb
end

function methods:IsValid()
    return self._Canvas ~= nil
end

function methods:GetPixelData()
    return _pixeldata(self.Width, self.Height, self._Canvas:newImageData())
end
