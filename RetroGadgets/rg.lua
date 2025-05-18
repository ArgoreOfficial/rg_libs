-- RetroGadgets API layer for LÖVE2D

function _G.rg_unimplemented()
    error "Unimplemented RG Function"
end

require("RetroGadgets.vec")
require("RetroGadgets.color")
require("RetroGadgets.print")
require("RetroGadgets.gdt")
require("RetroGadgets.keyboardchip")

_G.bit32 = require("RetroGadgets.bit32")

local require_orig = require
require = function(_modname)
    return require_orig("Import." .. _modname)
end

return nil