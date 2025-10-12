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
    if _x <= 0 or _y <= 0 or _x > self.Width or _y > self.Height then
        error("out of range: " .. _x .. "," .. _y)
    end

    local x = math.max(0, math.min(_x-1, self.Width-1))
    local y = math.max(0, math.min(_y-1, self.Height-1))

    self._ImageData:setPixel(
        x, y, 
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

_G.PixelData = {}
function _G.PixelData.new(width, height, color)
    width  = math.min(width,  4096)
    height = math.min(height, 4096)
    local pd = _pixeldata(width, height, love.image.newImageData(width, height))
    local width, height = pd._ImageData:getDimensions()

    for y = 1, height do
        for x = 1, width do
            pd._ImageData:setPixel(x-1, y-1, color.R/255, color.G/255, color.B/255, color.A/255)
        end
    end

    return pd
end