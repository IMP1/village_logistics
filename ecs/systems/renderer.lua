local entity_manager = require 'ecs.entity_manager'

local name = "renderer"

local function draw_renderable(entity)
    local visible = entity.components.renderable.visible
    if not visible then return end
    local x, y = unpack(entity.components.location.position)
    local texture = entity.components.renderable.texture
    local colour = entity.components.renderable.colour
    local quad = entity.components.renderable.quad
    love.graphics.setColor(colour)
    if quad then
        love.graphics.draw(texture, quad, x, y)
    else
        love.graphics.draw(texture, x, y)
    end
end

local world_filter = entity_manager.component_filter("location", "renderable")
local camera_filter = entity_manager.component_filter("viewport", "transform")

local function draw_world(camera)
    love.graphics.push()
    local x, y, w, h = unpack(camera.components.viewport.bounds)
    love.graphics.setScissor(x, y, w, h)
    local ox, oy = unpack(camera.components.transform.translation)
    love.graphics.translate(-ox, -oy)
    -- TODO: rotate and scale as well

    for _, entity in pairs(entity_manager.get_entities(world_filter)) do
        draw_renderable(entity)
    end

    love.graphics.setScissor()
    love.graphics.pop()
end

-- local gui_filter = entity_manager.component_filter("")
local function draw_gui()
-- TODO: draw GUI elements
end

local function draw(system)
    for _, camera in pairs(entity_manager.get_entities(camera_filter)) do
        draw_world(camera)
    end
    draw_gui()
end

return {
    name    = name,
    filters = {
        draw = entity_manager.filter_none,
    },
    events  = {
        draw = draw,
    },
}