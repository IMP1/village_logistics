local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_orders"

local selected_units = {}

local function selection(system, newly_selected_entities)
    selected_units = newly_selected_entities
end

local function get_options()
    local harvestable = true
    local carry       = true
    local produce     = true
    for _, unit in pairs(selected_units) do
        if not unit.components.harvester then
            harvestable = false
        end
        if not unit.components.carrier then
            harvestable = false
        end
        if not unit.components.producer then
            harvestable = false
        end
    end
    return {
        harvestable = harvestable,
        carry       = carry,
        produce     = produce,
    }
end

local harvest_filter = entity_manager.component_filter("harvestable")
local carry_filter   = entity_manager.component_filter("resource")
local craft_filter   = entity_manager.component_filter("producer")

local function click(system, wx, wy, button)
    if selected_units == 0 then return end

    print("click @ (" .. wx .. ", " .. wy .. ").")
    print(#selected_units .. " selected units.")

    local options = get_options()

    -- @TODO: get entities near location that are one of the options
    -- @TODO: present order options as a gui

    for k, v in pairs(options) do
        print(k, v)
    end

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