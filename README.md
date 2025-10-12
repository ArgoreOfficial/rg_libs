# rg_libs
various libraries and tools for RetroGadgets, as well as a LÖVE2D Compatibility Layer 

## LÖVE2D Layer
Fairly barebones right now but I'll keep working on it  

To use with your own, copy `conf.lua`, `main.lua`, `Import/` and `RetroGadgets/` from this repository  
At the top of `conf.lua` there is a table containing config for the gadget

To use vscode for debugging, also copy `.vscode` and install [Sumneko's Lua extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) and [Local Lua Debugger](https://marketplace.visualstudio.com/items?itemName=tomblind.local-lua-debugger-vscode)

Uses [bjornbytes' tick](https://github.com/bjornbytes/tick) for TPS limiting