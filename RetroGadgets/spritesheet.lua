require "RetroGadgets.pixeldata"

local methods = {}
local meta = {__index = methods}

function methods:IsValid()
    return self._Image ~= nil
end

function methods:GetPixelData()
    return _pixeldata(self._Image:getWidth(), self._Image:getHeight(), love.image.newImageData(self.Name))
end

function _G._spritesheet(_name,_image,_w,_h)
    local r,m = pcall(require, _name:match("(.+)%..+") )
    return setmetatable({
        Name = _name,
        Type = "",
        Palette = {},
        _Meta = _name and (r and m or nil) or nil,
        _Image = _image,
        _Quad = _image and love.graphics.newQuad(0, 0, math.min(_w, 256), math.min(_h, 64), _image) or nil
    }, meta)
end
