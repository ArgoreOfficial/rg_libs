-- Retro Gadgets
local IS_RG = _VERSION == "Luau"
local function safe_get_asset(name, assetType) -- "SpriteSheet" | "Code" | "AudioSample"
	for _, asset in pairs(gdt.ROM.User.Assets) do
		if asset.Name == name and asset.Type == assetType then
			return asset
		end
	end
	
	return nil
end

-- compat
local unsafe_require = require
require = function(_name)
	local ext = IS_RG and ".lua" or ""
	if safe_get_asset(_name,           "Code") then return unsafe_require(_name) end
	if safe_get_asset(_name .. ".lua", "Code") then return unsafe_require(_name .. ext) end
	return nil
end

local rmath = require("rg_math")
local chip8 = require("chip8")
local chip8_static = require("chip8_static")

-- update function is repeated every time tick
gdt.VideoChip0:SetRenderBufferSize(1, 64, 32)

function update()

	chip8_static.timers_tick()
	for i = 1, 3200 do
		chip8_static.tick()
	end
	--print(chip8_static.PC)

	gdt.VideoChip0:BlitPixelData(vec2(0,0), chip8_static.display)
end