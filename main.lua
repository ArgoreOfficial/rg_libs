

--[[ CONFIG ]]

GADGET = {
	ScreenWidth = 384,
	ScreenHeight = 192,
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

local canvas = love.graphics.newCanvas(GADGET.ScreenWidth, GADGET.ScreenHeight)

-- RG Layer
require( "RetroGadgets/rg" )

function love.load()	
	love.window.setMode(
		GADGET.ScreenWidth  * GADGET.Scale,
		GADGET.ScreenHeight * GADGET.Scale,
		{vsync=1}
	)
	
	canvas:setFilter("nearest","nearest")

	love.graphics.setCanvas(canvas)
	love.graphics.setLineStyle("rough") 
	love.graphics.setLineWidth(1) 
	
	dofile( "CPU0.lua" )
	
	love.graphics.setCanvas()
end

function love.draw()
	love.graphics.setCanvas(canvas)
	
	_update_gdt()
	if update ~= nil then
		update()
	end
	_display_print()
	
	love.graphics.setCanvas()
	love.graphics.draw(canvas,0,0,0,GADGET.Scale,GADGET.Scale)
end