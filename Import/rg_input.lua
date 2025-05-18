
local input = {}

local _maps   = {} -- [ "Jump" ] -> { name="Jump", target=table:0x0000 }
local _events = {} -- [ "Jump" ] -> { name="Jump", target=function:0x0000 }
local _map_binds   = {} -- [KeyboardChip.Space] -> { name="Jump", delta=1 }
local _event_binds = {} -- [KeyboardChip.Space] -> { name="Jump" }

function input:create_map(_name, _target)
    local bind  = {}
    bind.name   = _name
    bind.target = _target
    
    if type(_target) == "table" then
        _maps[_name] = _maps
    elseif type(_target) == "function" then
        _events[_name] = bind
    else
        print("Error")
    end
end

function input:bind_key(_name, _key_name, _map_delta)
    if _maps[_name] == nil then
        return -- error
    end

    local bind = {}
    bind.name = _name
    bind.delta = _map_delta or 0 
    _map_binds[ _key_name ] = bind
end

function input:poll_events()
    for k,v in pairs(_event_binds) do
        if GetButton(k) then
            _events[k].target()
        end
    end
end

-- CPU0.lua

local move_input = {}
input:create_map("Move", move_input)
input:bind("Move", "D", 1)
input:bind("Move", "A", -1)
input:bind("Move", "DPadRight", 1)
input:bind("Move", "DPadLeft", -1)

local function jump_event()
    print( "Boing!" )
end

input:create_map("Jump", jump_event)
input:bind("Jump", "Space")
input:bind("Jump", "ActionBottomRow1")

function Update()
    input:poll_events()

    print( move_input.Value )
end

