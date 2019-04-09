local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_orders"

local selected_units = {}

local function selection(system, newly_selected_entities)
    selected_units = newly_selected_entities
end

local function click(system, wx, wy, button)
    print("click @ (" .. wx .. ", " .. wy .. ").")
    print(#selected_units .. " selected units.")
end

return {
    name    = name,
    filters = { 
        onselection = entity_manager.filter_none,
        onclick     = entity_manager.filter_none,
    },
    events  = { 
        onselection = selection,
        onclick     = click,
    },
}