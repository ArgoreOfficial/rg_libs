local _print_stack = {}

function _G._display_print()
    local now = love.timer.getTime()
    local lifetime = 5.0

    for i,v in ipairs(_print_stack) do
        if now - v.t > lifetime then
            table.remove(_print_stack,i)
        else
            local font = love.graphics.getFont()
            local width  = font:getWidth (v.str)
            local height = font:getHeight()
            
            love.graphics.setColor(0,0,0,1)
            love.graphics.rectangle("fill", 0, (i-1)*16, width, height)
            love.graphics.setColor(1,1,1,1)
            love.graphics.print(v.str, 0, (i-1)*16)
        end
    end
end

function _G.print(...)
    local res = ""
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