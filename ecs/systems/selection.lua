local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_selection"

local drag_rectangle = nil

local filter = entity_manager.component_filter("selectable", "location")

local function is_over(x, y, mx, my, leeway)
    local dx = mx - x
    local dy = my - y
    return dx*dx + dy*dy <= leeway*leeway
end

local function is_in(x, y, ox, oy, w, h)
    return x >= ox and y >= oy and x <= ox + w and y <= oy + h
end

local function click(system, wx, wy, button)
    if button ~= 1 then return end

    local selection = nil
    local nearest_distance_squared = 0

    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local ox, oy = unpack(entity.components.selectable.offset or {0, 0})
        x = x - ox
        y = y - oy
        local leeway = entity.components.selectable.size
        local priority = entity.components.selectable.priority
        local distance_squared = (x - wx)*(x - wx) + (y - wy)*(y - wy)
        if is_over(x, y, wx, wy, leeway) then
            if selection == nil then
                selection = entity
                nearest_distance_squared = distance_squared
            elseif priority > selection.components.selectable.priority then
                selection = entity
                nearest_distance_squared = distance_squared
            elseif priority == selection.components.selectable.priority and
                   distance_squared < nearest_distance_squared then
                selection = entity
                nearest_distance_squared = distance_squared
            end
        end
    end

    if selection then
        system_manager.broadcast("onselection", selection)
    end
end

local function drag(system, wx, wy, dx, dy)
    local selection = nil

    local x1, x2 = math.min(wx, wx-dx), math.max(wx, wx-dx)
    local y1, y2 = math.min(wy, wy-dy), math.max(wy, wy-dy)

    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local ox, oy = unpack(entity.components.selectable.offset or {0, 0})
        x = x - ox
        y = y - oy
        local priority = entity.components.selectable.priority
        if is_in(x, y, x1, y1, x2-x1, y2-y1) then
            if selection == nil then
                selection = entity
            elseif priority > selection.components.selectable.priority then
                selection = entity
            end
        end
    end

    if selection then
        system_manager.broadcast("onselection", selection)
    end

    entity_manager.delete_entity(drag_rectangle)
    drag_rectangle = nil
end

local function move(system, wx, wy, dx, dy, mouse_down, ox, oy)
    if not mouse_down then
        if drag_rectangle then
            entity_manager.delete_entity(drag_rectangle)
        end
        drag_rectangle = nil
        return
    end
    if not drag_rectangle then
        drag_rectangle = entity_manager.create_entity("drag_rectangle")
        entity_manager.add_component(drag_rectangle, "location", {
            position = {0, 0}
        })
        entity_manager.add_component(drag_rectangle, "renderable", {
            visible = true,
            colour  = {1, 1, 0},
            shape   = {
                points = {0, 0, 0, 0, 0, 0},
            },
        })
    end
    local x1, x2 = math.min(ox, wx), math.max(ox, wx)
    local y1, y2 = math.min(oy, wy), math.max(oy, wy)
    local shape = entity_manager.get_component(drag_rectangle, "renderable").shape
    shape.points = {x1, y1, x2, y1, x2, y2, x1, y2}
end

local selected_filter = entity_manager.component_filter("selected")
local function selection(system, newly_selected_entity)
    for _, entity in pairs(entity_manager.get_entities(selected_filter)) do
        entity_manager.remove_component(entity.id, "selected")
    end
    if newly_selected_entity then    
        entity_manager.add_component(newly_selected_entity, "selected")
    end
end

local function delete_indication(system, entity)
    local indication = entity.components.selected.indication
    if indication then
        entity_manager.delete_entity(indication)
    end
end

local function create_indication(system, entity)
    if entity.components.renderable then
        local indication = entity_manager.create_entity("selection_indication")
        local entity_location = entity.components.location
        entity_manager.add_component(indication, "location", entity_location)
        local icon = love.graphics.newCanvas(100, 100)
        love.graphics.setCanvas(icon)
        love.graphics.setColor(1, 1, 0)
        love.graphics.ellipse("line", 50, 50, 25, 20)
        love.graphics.setCanvas()

        entity_manager.add_component(indication, "renderable", {
            visible = true,
            colour  = {1, 1, 0}, 
            texture = icon,
            offset  = {50, 50},
            layer   = 0.5
        })
        local selected = entity.components.selected
        selected.indication = indication
    end
end

return {
    name    = name,
    filters = { 
        onselection = entity_manager.filter_none,
        onclick     = entity_manager.filter_none,
        ondrag      = entity_manager.filter_none,
        onmove      = entity_manager.filter_none,

        add_component_selected    = entity_manager.filter_none,
        remove_component_selected = entity_manager.filter_none,
    },
    events  = { 
        onselection = selection,
        onclick     = click,
        ondrag      = drag,
        onmove      = move,

        add_component_selected    = create_indication,
        remove_component_selected = delete_indication,
    },
}