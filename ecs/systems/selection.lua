local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_selection"

local selected_entities = {}
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
        selected_entities = selection
    end
end

local function drag(system, wx, wy, dx, dy)
    local selection = {}
    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local ox, oy = unpack(entity.components.selectable.offset or {0, 0})
        local priority = entity.components.selectable.priority
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
        selected_entities = selection
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
            position = {}
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

return {
    name    = name,
    filters = { 
        onclick = entity_manager.filter_none,
        ondrag  = entity_manager.filter_none,
        onpan   = entity_manager.filter_none,
    },
    events  = { 
        onclick = click,
        ondrag  = drag,
        onpan   = move,
    },
}