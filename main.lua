
local tick = require("tick")

-- RG Layer
require("RetroGadgets.rg")

table.unpack = unpack 

function love.load()	
	love.graphics.setLineStyle("rough") 
	love.graphics.setLineWidth(1) 
	
	gdt.VideoChip0:RenderOnScreen()
	dofile( "Import/CPU0.lua" )
	love.graphics.setCanvas()

	tick.framerate = 60
end

function love.update(_dt)
	_update_gdt(tick.dt)
	_update_videochip(tick.dt)
end

-- TODO: configurable event channels

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

local t1 = 0
local fps = 1 / 60

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