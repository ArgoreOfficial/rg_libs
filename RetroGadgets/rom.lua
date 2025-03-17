local ROM = {}

require("RetroGadgets.spritesheet")

local rom_spritesheet_meta = {}
function rom_spritesheet_meta:__index(_k)
    local ret,img = pcall(love.graphics.newImage, _k)
    if not ret then
        return _spritesheet(nil, nil, 0, 0)
    end
    return _spritesheet(_k, img, img:getWidth(), img:getHeight() )
end

local function _create_romsystem()
    local spritesheets = setmetatable({}, rom_spritesheet_meta)
    
    return { 
        Assets       = {},
        SpriteSheets = spritesheets,
        Codes        = {},
        AudioSamples = {}
    }
end

--ROM.System = _create_romsystem({}) -- TODO
ROM.User = _create_romsystem({})

return ROM
