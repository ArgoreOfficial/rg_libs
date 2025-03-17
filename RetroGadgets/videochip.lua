
-- https://docs.retrogadgets.game/modules/VideoChip.html

local methods = {}
local meta = {__index = methods}


local draw_quad_data = {
	{0,0, 0,0, 1,1,1,1},
	{1,0, 1,0, 1,1,1,1},
	{1,1, 1,1, 1,1,1,1},
	{0,1, 0,1, 1,1,1,1},
}
local draw_quad = love.graphics.newMesh(draw_quad_data,"fan","dynamic")

local function _color_to_rgba(_color)
    return _color.R/255, _color.G/255, _color.B/255, _color.A/255
end

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
    local r,g,b = _color_to_rgba(_color)
    love.graphics.clear(r,g,b)
end

function methods:RenderOnScreen()
    error("unimplemented") 
end

function methods:RenderOnBuffer(_index) 
    error("unimplemented")
end

function methods:SetRenderBufferSize(_index, _width, _height) 
    error("unimplemented") 
end

function methods:SetPixel(_position, _color)
    _set_color(_color)
    love.graphics.rectangle("fill", _position.X, _position.Y, 1, 1)
    _reset_color()
end

function methods:DrawPointGrid(_gridOffset, _dotsDistance, _color)
    error("unimplemented") 
end

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

function methods:DrawRect(_position1, _position2, _color)
    _set_color(_color)
    love.graphics.rectangle(
        "line",
        _position1.X + 1,
        _position1.Y + 1,
        _position2.X - (_position1.X+1),
        _position2.Y - (_position1.Y+1))
    _reset_color()
end

function methods:FillRect(_position1, _position2, _color)
    _set_color(_color)
    love.graphics.rectangle(
        "fill",
        _position1.X,
        _position1.Y,
        _position2.X - _position1.X,
        _position2.Y - _position1.Y)
    _reset_color()
end

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

function methods:DrawSprite(_position, _spriteSheet, _spriteX, _spriteY, _tintColor, _backgroundColor) 
    _set_color(_tintColor)
    
    _spriteSheet._Quad:setViewport(
        _spriteX * _spriteSheet._Meta.sprite_width, 
        _spriteY * _spriteSheet._Meta.sprite_height,
        _spriteSheet._Meta.sprite_width,
        _spriteSheet._Meta.sprite_height)

	love.graphics.draw(
        _spriteSheet._Image, _spriteSheet._Quad,
        _position.X, _position.Y )
    _reset_color()
end

function methods:DrawCustomSprite(_position, _spriteSheet, _spriteOffset, _spriteSize, _tintColor, _backgroundColor) 
    _set_color(_tintColor)    
    
    _spriteSheet._Quad:setViewport(_spriteOffset.X, _spriteOffset.Y, _spriteSize.X, _spriteSize.Y)
	love.graphics.draw(_spriteSheet._Image, _spriteSheet._Quad, _position.X, _position.Y )
    
    _reset_color()    
end

function methods:DrawText(position, fontSprite, text, textColor, backgroundColor) error("unimplemented") end

function methods:RasterSprite(_position1, _position2, _position3, _position4, _spriteSheet, _spriteX, _spriteY, _tintColor, _backgroundColor)
    local r,g,b,a = _color_to_rgba(_tintColor)
    draw_quad:setVertex(1, _position1.X, _position1.Y, 0.0, 0.0, r, g, b, a)
    draw_quad:setVertex(2, _position2.X, _position2.Y, 1.0, 0.0, r, g, b, a)
    draw_quad:setVertex(3, _position3.X, _position3.Y, 1.0, 1.0, r, g, b, a)
    draw_quad:setVertex(4, _position4.X, _position4.Y, 0.0, 1.0, r, g, b, a)
    draw_quad:setTexture(_spriteSheet._Image)

    love.graphics.draw(draw_quad,0,0)
end

function methods:RasterCustomSprite(position1, position2, position3, position4, spriteSheet, spriteOffset, spriteSize, tintColor, backgroundColor) error("unimplemented") end
function methods:DrawRenderBuffer(position, renderBuffer, width, height) error("unimplemented") end
function methods:RasterRenderBuffer(position1, position2 , position3, position4, renderBuffer) error("unimplemented") end
function methods:SetPixelData(pixelData) error("unimplemented") end
function methods:BlitPixelData(position, pixelData) error("unimplemented") end
