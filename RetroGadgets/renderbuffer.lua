local rb_methods = {}
local rb_meta = {__index = rb_methods}

local pd_methods = {}
local pd_meta = {__index = pd_methods}

function _G._renderbuffer_new(_w,_h)
    local rb = setmetatable({
        Name = "",
        Type = "RenderBuffer",
        Width  = _w,
        Height = _h,
        _Canvas = love.graphics.newCanvas(_w, _h)
    }, rb_meta)
    rb._Canvas:setFilter("nearest","nearest")
    return rb
end

function _G._renderbuffer_set(_rb, _w,_h)
    _rb.Name = ""
    _rb.Type = "RenderBuffer"
    _rb.Width  = _w
    _rb.Height = _h
    _rb._Canvas = love.graphics.newCanvas(_w, _h)
    _rb._Canvas:setFilter("nearest","nearest")
    return _rb
end

function rb_methods:IsValid()
    return self._Canvas ~= nil
end

function rb_methods:GetPixelData()
    return setmetatable({
        Width  = self.Width,
        Height = self.Height,
        _ImageData = self._Canvas:newImageData()
    }, pd_meta)
end

function pd_methods:GetPixel(_x, _y)
    local r, g, b, a = self._ImageData:getPixel(_x-1, _y-1)
    return ColorRGBA(r*255, g*255, b*255, a*255)
end

function pd_methods:SetPixel(_x, _y, _color)
    self._ImageData:setPixel(
        _x-1, _y-1, 
        _color.R / 255, 
        _color.G / 255, 
        _color.B / 255, 
        _color.A / 255
    )
end