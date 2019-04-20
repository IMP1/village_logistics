local entity_manager = require 'ecs.entity_manager'

local name = "camera_input"

local MOVE_SPEED = 256 -- pixels / second

local console_filter = entity_manager.component_filter("console", "gui")

local screen_width  = love.graphics.getWidth()
local screen_height = love.graphics.getHeight()

local filter = entity_manager.component_filter("viewport", "transform")
local function move(system, entity, dt)
    if #entity_manager.get_entities(console_filter) > 0 then
        return
    end
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

local function resize(system, entity, new_width, new_height)
    local old_width, old_height = screen_width, screen_height
    local scale_x = new_width  / old_width
    local scale_y = new_height / old_height
    local x, y, w, h = unpack(entity.components.viewport.bounds)

    entity.components.viewport.bounds = {
        x * scale_x, y * scale_y,
        w * scale_x, h * scale_y,
    }

end

return {
    name    = name,
    filters = { 
        update = filter,
        resize = filter,
    },
    events  = { 
        update = move,
        resize = resize,
    },
}