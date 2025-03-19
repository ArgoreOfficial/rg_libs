-- RetroGadgets API layer for LÖVE2D

function _G.rg_unimplemented()
    error "Unimplemented RG Function"
end

require("RetroGadgets/vec")
require("RetroGadgets/color")
require("RetroGadgets/print")
require("RetroGadgets/gdt")

_G.bit32 = require("RetroGadgets.bit32")

return nil