local ROM = {}

require("RetroGadgets.spritesheet")

function SplitFilename(strFilename)
    -- Returns the Path, Filename, and Extension as 3 values
    return string.match(strFilename, "(.-)([^\\]-([^\\%.]+))$")
end

local rom_spritesheet_meta = {}
function rom_spritesheet_meta:__index(_k)
    local ret,img = pcall(love.graphics.newImage, "Import/" .. _k)
    if not ret then
        return nil
    end
    img:setFilter("linear", "nearest")
    return _spritesheet("Import/" .. _k, img, img:getWidth(), img:getHeight() )
end

-- "SpriteSheet" | "Code" | "AudioSample"
local asset_types = {
    ["lua"] = "Code",
    
    ["png"] = "SpriteSheet",

    ["wav"] = "AudioSample",
    ["mp3"] = "AudioSample"
}

local function _create_rom_system()
    local SpriteSheets = {}

    -- load standard font texture
    local ret,standard_font = pcall(love.graphics.newImage, "RetroGadgets/ROM/System/StandardFont.png")
    if ret then
        standard_font:setFilter("linear", "nearest")
        SpriteSheets[ "StandardFont" ] = _spritesheet("StandardFont", standard_font, standard_font:getWidth(), standard_font:getHeight() )
    end
    return { 
        Assets       = {},
        SpriteSheets = SpriteSheets,
        Codes        = {},
        AudioSamples = {}
    }
end

local function _create_rom_user()
    local SpriteSheets = setmetatable({}, rom_spritesheet_meta)
    local Assets = {}
    
    for _, file in ipairs(love.filesystem.getDirectoryItems("Import")) do
        local path,name,extension = SplitFilename(file)
        table.insert(Assets, {
            Name = name,
            Type = asset_types[extension] or "Unknown"
        })
    end

    return { 
        Assets       = Assets,
        SpriteSheets = SpriteSheets,
        Codes        = {},
        AudioSamples = {}
    }
end

ROM.System = _create_rom_system() 
ROM.User = _create_rom_user()

return ROM
