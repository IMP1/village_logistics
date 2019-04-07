local entity_manager = require 'ecs.entity_manager'

local name = "renderer"

local world_filter   = entity_manager.component_filter("location", "renderable")
local overlay_filter = entity_manager.component_filter("location", "gui")
local gui_filter     = entity_manager.component_filter("viewport", "gui")
local camera_filter  = entity_manager.component_filter("viewport", "transform")

local function draw_renderable(entity)
    local visible = entity.components.renderable.visible
    if not visible then return end
    local x, y = unpack(entity.components.location.position)
    local ox, oy = unpack(entity.components.renderable.offset or {0, 0})
    local r = 0 -- TODO: get these from somewhere
    local sx, sx = 1, 1
    local colour = entity.components.renderable.colour or {1, 1, 1}
    local texture = entity.components.renderable.texture
    local shape = entity.components.renderable.shape
    
    if texture then
        love.graphics.setColor(colour)
        local quad = entity.components.renderable.quad
        if quad then
            love.graphics.draw(texture, quad, x, y, r, sx, sy, ox, oy)
        else
            love.graphics.draw(texture, x, y, r, sx,sy, ox, oy)
        end
    elseif shape then
        local points = entity.components.renderable.shape.points
        local fill_colour = entity.components.renderable.fill_colour
        if fill_colour then
            love.graphics.setColor(fill_colour)
            love.graphics.polygon("fill", points)
        end
        love.graphics.setColor(colour)
        love.graphics.polygon("line", points)
    end
end

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
    for _, entity in pairs(entity_manager.get_entities(overlay_filter)) do
        draw_renderable(entity)
    end

    love.graphics.setScissor()
    love.graphics.pop()
end

local function draw_gui_element(entity)
    -- TODO: draw GUI elements
end

local function draw_gui()
    for _, entity in pairs(entity_manager.get_entities(gui_filter)) do
        draw_gui_element(entity)
    end
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