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
local rg3d  = require("rg_3d")
local engine = require "engine"
local state_machine = require("state_machine")

state_machine:add_state("splash", require("state_splash"))
state_machine:add_state("menu",   require("state_menu"))
state_machine:add_state("game",   require("state_game"))
state_machine:set_state("menu")

local shading = gdt.ROM.User.SpriteSheets["shading_cross.png"]
--local rg_tex  = gdt.ROM.User.SpriteSheets["rg_logo.png"]

function eventChannel1(_sender,_event)
	engine.rinput[_event.InputName] = _event.ButtonDown
end

-- update function is repeated every time tick

rg3d:set_light_dir(vec3(0,1,0))

function update()
	local dt = gdt.CPU0.DeltaTime
	
	engine:update(dt)
	state_machine:update(dt)
	engine:post_update(dt)
	
	rg3d:push_look_at(engine.camera_pos, engine.camera_pos + engine.camera_dir, vec3(0,1,0))
	
	state_machine:draw()
	engine:draw()
end