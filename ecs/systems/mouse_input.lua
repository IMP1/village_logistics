local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "mouse_input"

local filter = entity_manager.component_filter("transform")

local mouse_movement = {0, 0}

local function mousedown(system, entity, mx, my, button)
    local ox, oy = unpack(entity.components.transform.translation)
    if button == 1 then
        mouse_movement = {mx + ox, my + oy}
    end
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
        system_manager.broadcast("ondrag", mx, my, dx, dy, wx, wy)
    else
        system_manager.broadcast("onclick", mx, my, button, wx, wy)
    end
end

return {
    name    = name,
    filters = { 
        mousepressed  = filter,
        mousereleased = filter,
    },
    events  = { 
        mousepressed  = mousedown,
        mousereleased = mouseup,
    },
}