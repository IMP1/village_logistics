local entity_manager = require 'ecs.entity_manager'

local name = "renderer"

local draw = function(system, entity)
    local visible = entity.components.renderable.visible
    if not visible then return end
    local x, y = unpack(entity.components.location.position)
    local char = entity.components.renderable.character
    local colour = entity.components.renderable.colour
    love.graphics.setColor(colour)
    love.graphics.print(char, x, y)
end

local filter = entity_manager.component_filter("location", "renderable")

return {
    name   = name,
    filter = filter,
    events = {draw = draw},
}