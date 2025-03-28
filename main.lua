

--[[ CONFIG ]]

GADGET = {
	ScreenWidth = 384,
	ScreenHeight = 292,
	Scale = 2
}

--[[ END CONFIG ]]


-- TODO:
--[[

CONFIG = require("RetroGadgets/rg_config")
CONFIG:VideoChip(0, 256, 128)
CONFIG:KeyboardChip()

require( "RetroGadgets/rg" )
_setup_rg_runtime(CONFIG)

]]


-- LÖVE2D setup

-- RG Layer
require( "RetroGadgets/rg" )

function love.load()	
	love.window.setMode(
		GADGET.ScreenWidth  * GADGET.Scale,
		GADGET.ScreenHeight * GADGET.Scale,
		{vsync=1}
	)

	love.graphics.setLineStyle("rough") 
	love.graphics.setLineWidth(1) 
	
	gdt.VideoChip0:RenderOnScreen()
	dofile( "CPU0.lua" )
	love.graphics.setCanvas()
end

function love.update(_dt)
	_update_gdt(_dt)
end

function love.keypressed(key, scancode, isrepeat)
	if eventChannel1 then
		eventChannel1(nil, KeyboardChipEvent(true, false, _keycode_l2d_to_rg(key), "KeyboardChipEvent"))
	end
end

function love.keyreleased(key, scancode, isrepeat)
	if eventChannel1 then
		eventChannel1(nil, KeyboardChipEvent(false, true, _keycode_l2d_to_rg(key), "KeyboardChipEvent"))
	end
end

function love.draw()
	love.graphics.setCanvas(gdt.VideoChip0._current_renderbuffer._Canvas)
	
	if update ~= nil then
		update()
	end
	
	love.graphics.setCanvas()
	love.graphics.setColor(1, 1, 1, 1)
	
	love.graphics.draw(gdt.VideoChip0._screen_buffer._Canvas,0,0,0,GADGET.Scale,GADGET.Scale)
	_display_print()
end