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

local function quad_shading(_p1,_p2,_p3,_p4,_color,_val1,_val2,_val3,_val4)
	
	local alpha = math.min(_val1,_val2,_val3,_val4)
	--local alpha = ((_val1+_val2+_val3+_val4) / 4)
	
	--raster_rect(
	--	_p1,_p2,_p3,_p4,
	--	ColorRGBA(_color.R,_color.G,_color.B, 255 * alpha)
	--)

	--alpha = 0

	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(0,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val1-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(64,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val2-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(128,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val3-alpha) ),
		color.clear
	)
	
	gdt.VideoChip0:RasterCustomSprite(
		_p1,_p2,_p3,_p4,
		shading,
		vec2(128+64,0),vec2(64,64),
		ColorRGBA(_color.R,_color.G,_color.B, 255 * (_val4-alpha) ),
		color.clear
	)
end

local function raster_tri_sprite(_p1,_p2,_p3)
	gdt.VideoChip0:DrawTriangle(_p1,_p2,_p3,color.green)
end

local function shader_quad_basic(_p1,_p2,_p3,_p4,_shader_input)		
	FillQuad(_p1, _p2, _p3, _p4, _shader_input.color or color.white)
end

local function shader_tri_basic(_p1,_p2,_p3,_shader_input)		
	gdt.VideoChip0:FillTriangle(_p1,_p2,_p3,_shader_input.color or color.white)
end

-- update function is repeated every time tick

function update()
	local dt = gdt.CPU0.DeltaTime
	
	engine:update(dt)
	state_machine:update(dt)
	engine:post_update(dt)
	
	rg3d:push_look_at(engine.camera_pos, engine.camera_pos + engine.camera_dir, vec3(0,1,0))
	
	state_machine:draw()
end