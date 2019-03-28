local entity_manager = require 'ecs.entity_manager'

local name = "camera_input"

local MOVE_SPEED = 256 -- pixels / second

local filter = entity_manager.component_filter("viewport", "transform")

local function move(system, entity, dt)
    local dx, dy = 0, 0
    if love.keyboard.isDown("w") then
        dy = dy - MOVE_SPEED * dt
    end
    if love.keyboard.isDown("a") then
        dx = dx - MOVE_SPEED * dt
    end
    if love.keyboard.isDown("s") then
        dy = dy + MOVE_SPEED * dt
    end
    if love.keyboard.isDown("d") then
        dx = dx + MOVE_SPEED * dt
    end
    if dx ~= 0 or dy ~= 0 then
        local x, y = unpack(entity.components.transform.translation)
        entity.components.transform.translation = {x + dx, y + dy}
    end
end

-- TODO: on resize, resize the viewport with respect to the change in window dimensions

return {
    name    = name,
    filters = { update = filter },
    events  = { update = move },
}