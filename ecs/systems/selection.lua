local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_selection"

local selected_entities = {}

local filter = entity_manager.component_filter("selectable", "location")

local function is_over(x, y, mx, my, leeway)
    local dx = mx - x
    local dy = my - y
    return dx*dx + dy*dy <= leeway*leeway
end

local function click(system, mx, my, button, wx, wy)
    local selection = {}
    for _, entity in pairs(entity_manager.get_entities(filter)) do
        local x, y = unpack(entity.components.location.position)
        local leeway = entity.components.selectable.size
        if is_over(x, y, wx, wy, leeway) then
            -- TODO: check priority + multiple
        end
    end
    print(wx, wy)
end

local function drag(system, mx, my, dx, dy, wx, wy)
    -- TODO: get entities in square that are selectable.
    print(wx, wy, dx, dy)
end

return {
    name    = name,
    filters = { 
        onclick = entity_manager.filter_none,
        ondrag  = entity_manager.filter_none,
    },
    events  = { 
        onclick = click,
        ondrag  = drag,
    },
}