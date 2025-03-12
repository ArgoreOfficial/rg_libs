local _print_stack = {}

function _G._display_print()
    local now = love.timer.getTime()
    local lifetime = 5.0

    for i,v in ipairs(_print_stack) do
        if now - v.t > lifetime then
            table.remove(_print_stack,i)
        else
            love.graphics.print(v.str, 0, (i-1)*16)
        end
    end
end

function _G.print(...)
    res = ""
    local pargs = {...}
    for i,v in ipairs(pargs) do
        res = res .. tostring(v) .. "\t"
    end
    
    table.insert(_print_stack, { str=res, t=love.timer.getTime() })
    if #_print_stack*16 > love.graphics.getHeight() then
        table.remove(_print_stack,1)
    end
end

return nil