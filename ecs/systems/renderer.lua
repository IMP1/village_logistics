local entity_manager = require 'ecs.entity_manager'

local name = "renderer"

local predraw_filter = entity_manager.component_filter("viewport", "transform")
local predraw = function(system, entity)
    love.graphics.push()
    local x, y, w, h = unpack(entity.components.viewport.bounds)
    love.graphics.setScissor(x, y, w, h)

    local ox, oy = unpack(entity.components.transform.translation)
    love.graphics.translate(-ox, -oy)
    -- TODO: rotate and scale as well
end

local draw_filter = entity_manager.component_filter("location", "renderable")
local draw = function(system, entity)
    local visible = entity.components.renderable.visible
    if not visible then return end
    local x, y = unpack(entity.components.location.position)
    local texture = entity.components.renderable.texture
    local colour = entity.components.renderable.colour
    love.graphics.setColor(colour)
    love.graphics.draw(texture, x, y)
end

local postdraw_filter = entity_manager.component_filter("viewport", "transform")
local postdraw = function(system, entity)
    love.graphics.setScissor()
    love.graphics.pop()
end

return {
    name    = name,
    filters = {
        predraw  = predraw_filter,
        draw     = draw_filter,
        postdraw = postdraw_filter,
    },
    events  = {
        predraw  = predraw,
        draw     = draw,
        postdraw = postdraw,
    },
}