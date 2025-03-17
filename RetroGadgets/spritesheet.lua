local methods = {}
local spritesheet_meta = {__index = methods}

function methods:IsValid()
    return self._Image ~= nil
end

function _G._spritesheet(_name,_image,_w,_h)
    return setmetatable({
        Name = "",
        Type = "",
        Palette = {},
        _Meta = _name and require( _name:match("(.+)%..+") ) or nil,
        _Image = _image,
        _Quad = _image and love.graphics.newQuad(0, 0, math.min(_w, 256), math.min(_h, 64), _image) or nil
    }, spritesheet_meta)
end
