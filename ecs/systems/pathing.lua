local entity_manager = require 'ecs.entity_manager'

local name = "pathing"

local filter = entity_manager.component_filter("location", "moveable")

local LEEWAY = 5 -- pixels

local function is_at(x, y, ox, oy, dr)
    local dx = x - ox
    local dy = y - oy
    return dx*dx + dy*dy <= dr * dr
end

local function move_towards(entity, position, speed, dt)
    local ox, oy = unpack(entity.components.location.position)
    local dx = position[1] - ox
    local dy = position[2] - oy
    local r = math.atan2(dy, dx)
    local mx = speed * dt * math.cos(r)
    local my = speed * dt * math.sin(r)
    -- @TODO: check for overshoot?
    entity.components.location.position = { ox + mx, oy + my }
end

local function update(system, entity, dt)
    local movement = entity.components.moveable
    if movement.path then
        local speed = entity.components.moveable.speed
        local next_point = movement.path[1]

        local ox, oy = unpack(entity.components.location.position)
        local x, y = unpack(next_point)
        if is_at(ox, oy, x, y, LEEWAY) then
            table.remove(movement.path, 1)
            if #movement.path == 0 then
                movement.path = nil
            end
        else
            move_towards(entity, next_point, speed, dt)
        end
    end
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}
