
-- https://docs.retrogadgets.game/modules/VideoChip.html

local methods = {}
local meta = {__index = methods}

local function _set_color(_color)
    love.graphics.setColor(_color.R/255, _color.G/255, _color.B/255, _color.A/255)
end

local function _reset_color()
    love.graphics.setColor(1, 1, 1, 1)
end

function _G._videochip()
    return setmetatable({
        Width  = GADGET.ScreenWidth,
        Height = GADGET.ScreenHeight
    }, meta)
end

function methods:Clear(_color)
    local r = _color.R / 255.0
    local g = _color.G / 255.0
    local b = _color.B / 255.0
    love.graphics.clear(r,g,b)
end

function methods:RenderOnScreen() error("unimplemented") end
function methods:RenderOnBuffer(index) error("unimplemented") end
function methods:SetRenderBufferSize(index, width, height) error("unimplemented") end
function methods:SetPixel(position, color) error("unimplemented") end
function methods:DrawPointGrid(gridOffset, dotsDistance, color) error("unimplemented") end

function methods:DrawLine(_start,_end,_color)
    _set_color(_color)
    love.graphics.line(_start.X, _start.Y, _end.X, _end.Y)
    _reset_color()
end

function methods:DrawCircle(_position, _radius, _color)
    _set_color(_color)
    love.graphics.circle("line",_position.X,_position.Y,_radius)
    _reset_color()
end

function methods:FillCircle(_position, _radius, _color)
    _set_color(_color)
    love.graphics.circle("fill",_position.X,_position.Y,_radius)
    _reset_color()
end

function methods:DrawRect(_position1, _position2, _color) error("unimplemented") end
function methods:FillRect(_position1, _position2, _color) error("unimplemented") end

function methods:DrawTriangle(_position1, _position2, _position3, _color)
    methods:DrawLine(_position1, _position2, _color)
    methods:DrawLine(_position2, _position3, _color)
    methods:DrawLine(_position3, _position1, _color)
end

function methods:FillTriangle(_position1, _position2, _position3, _color)
    _set_color(_color)
    love.graphics.polygon("fill", 
        _position1.X,_position1.Y,
        _position2.X,_position2.Y,
        _position3.X,_position3.Y
   )
    _reset_color()
end

function methods:DrawSprite(position, spriteSheet, spriteX, spriteY, tintColor, backgroundColor) error("unimplemented") end
function methods:DrawCustomSprite(position, spriteSheet, spriteOffset, spriteSize, tintColor, backgroundColor) error("unimplemented") end
function methods:DrawText(position, fontSprite, text, textColor, backgroundColor) error("unimplemented") end
function methods:RasterSprite(position1, position2, position3, position4, spriteSheet, spriteX, spriteY, tintColor, backgroundColor) error("unimplemented") end
function methods:RasterCustomSprite(position1, position2, position3, position4, spriteSheet, spriteOffset, spriteSize, tintColor, backgroundColor) error("unimplemented") end
function methods:DrawRenderBuffer(position, renderBuffer, width, height) error("unimplemented") end
function methods:RasterRenderBuffer(position1, position2 , position3, position4, renderBuffer) error("unimplemented") end
function methods:SetPixelData(pixelData) error("unimplemented") end
function methods:BlitPixelData(position, pixelData) error("unimplemented") end
