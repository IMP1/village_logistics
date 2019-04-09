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
    local selection = {}
    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local ox, oy = unpack(entity.components.selectable.offset or {0, 0})
        local leeway = entity.components.selectable.size
        local priority = entity.components.selectable.priority
        if is_over(x - ox, y - oy, wx, wy, leeway) then
            if #selection == 0 then
                table.insert(selection, entity)
            elseif selection[1].components.selectable.multiple and
                   priority == selection[1].components.selectable.priority then
                table.insert(selection, entity)
            elseif priority > selection[1].components.selectable.priority then
                selection = {}
                table.insert(selection, entity)
            end
        end
    end
    if #selection > 0 then
        system_manager.broadcast("onselection", selection)
    end
end

local function drag(system, wx, wy, dx, dy)
    local selection = {}
    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local ox, oy = unpack(entity.components.selectable.offset or {0, 0})
        local priority = entity.components.selectable.priority
        -- TODO: create a rectangle using min to get top-left and max to get bottom-right
        if is_in(x - ox, y - oy, wx-dx, wy-dy, dx, dy) then
            if #selection == 0 then
                table.insert(selection, entity)
            elseif selection[1].components.selectable.multiple and
                   priority == selection[1].components.selectable.priority then
                table.insert(selection, entity)
            elseif priority > selection[1].components.selectable.priority then
                selection = {}
                table.insert(selection, entity)
            end
        end
    end
    if #selection > 0 then
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
local function selection(system, newly_selected_entities)
    for _, entity in pairs(entity_manager.get_entities(selected_filter)) do
        entity_manager.remove_component(entity.id, "selected")
    end
    for _, entity in pairs(newly_selected_entities) do
        entity_manager.add_component(entity, "selected")
    end
end

local function unselected(system, entity)
    local indication = entity.components.selected.indication
    if indication then
        entity_manager.delete_entity(indication)
    end
end

local function selected(system, entity)
    if entity.components.renderable then
        local indication = entity_manager.create_entity("selection_indication")
        local entity_location = entity.components.location
        entity_manager.add_component(indication, "location", entity_location)
        local icon = love.graphics.newCanvas(100, 100)
        love.graphics.setCanvas(icon)
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
        onpan       = entity_manager.filter_none,

        add_component_selected    = entity_manager.filter_none,
        remove_component_selected = entity_manager.filter_none,
    },
    events  = { 
        onselection = selection,
        onclick     = click,
        ondrag      = drag,
        onpan       = move,

        add_component_selected    = selected,
        remove_component_selected = unselected,
    },
}