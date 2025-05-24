local methods = {}
local meta = {__index = methods}

function methods:GetPixel(_x,_y)
    if _x <= 0 or _y <= 0 or _x > self.Width or _y > self.Height then
        error("out of range: " .. _x .. "," .. _y)
    end

    local x = math.max(0, math.min(_x-1, self.Width-1))
    local y = math.max(0, math.min(_y-1, self.Height-1))

	local r, g, b, a = self._ImageData:getPixel(x,y)
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