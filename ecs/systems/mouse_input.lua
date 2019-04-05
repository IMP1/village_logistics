local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "mouse_input"

local filter = entity_manager.component_filter("transform")

local mouse_movement = {0, 0}
local mouse_down     = love.mouse.isDown(1)

local function mousedown(system, entity, mx, my, button)
    local ox, oy = unpack(entity.components.transform.translation)
    if button == 1 then
        mouse_movement = {mx + ox, my + oy}
    end
    mouse_down = true
end

local function mouseup(system, entity, mx, my, button)
    local dx, dy = 0, 0
    local ox, oy = unpack(entity.components.transform.translation)
    local wx = mx + ox
    local wy = my + oy
    if button == 1 then
        dx = wx - mouse_movement[1]
        dy = wy - mouse_movement[2]
    end
    if dx ~= 0 or dy ~= 0 then
        system_manager.broadcast("ondrag", wx, wy, dx, dy, mx, my)
    else
        system_manager.broadcast("onclick", wx, wy, button, mx, my)
    end
    mouse_down = false
end

local function mousemoved(system, entity, mx, my, dx, dy)
    local ox, oy = unpack(entity.components.transform.translation)
    local wx = mx + ox
    local wy = my + oy
    local x, y = unpack(mouse_movement)
    system_manager.broadcast("onpan", wx, wy, dx, dy, mouse_down, x, y, mx, my)
end

return {
    name    = name,
    filters = { 
        mousepressed  = filter,
        mousereleased = filter,
        mousemoved    = filter,
    },
    events  = { 
        mousepressed  = mousedown,
        mousereleased = mouseup,
        mousemoved    = mousemoved,
    },
}