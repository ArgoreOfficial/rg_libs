local methods = {}
local meta = {__index = methods}

function methods:GetPixel(_x,_y)
	local r, g, b, a = self._ImageData:getPixel(_x-1, _y-1)
    return ColorRGBA(r*255, g*255, b*255, a*255)
end

function methods:SetPixel(_x, _y, _color)
    self._ImageData:setPixel(
        _x-1, _y-1, 
        _color.R / 255, 
        _color.G / 255, 
        _color.B / 255, 
        _color.A / 255
    )
end

function _G._pixeldata(_w, _h, _imagedata)
	return setmetatable({
        Width  = _w,
        Height = _h,
        _ImageData = _imagedata
    }, meta)
end