local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_orders"

local selected_units    = {}
local avaialble_actions = {}

local function selection(system, newly_selected_entities)
    selected_units    = newly_selected_entities
    for _, action in pairs(avaialble_actions) do
        entity_manager.delete_entity(action.button)
    end
    avaialble_actions = {}
end

local function get_options()
    local harvest = true
    local carry   = true
    local produce = true
    for _, unit in pairs(selected_units) do
        for k, v in pairs(unit.components) do print(k) end
        if not unit.components.harvester then
            harvest = false
        end
        if not unit.components.carrier then
            carry = false
        end
        if not unit.components.producer then
            produce = false
        end
    end
    return {
        harvest = harvest,
        foobar  = 12,
        carry   = carry,
        produce = produce,
    }
end

local function get_filter_for_click(wx, wy, leeway)
    return function(entity)
        if not entity.components.location then return false end
        local x, y = unpack(entity.components.location.position)
        local dx = x - wx
        local dy = y - wy
        local r = leeway or 16
        return dx*dx + dy*dy <= r*r
    end
end

local function create_command_options(wx, wy)
    local possible_actions = get_options()

    local possible_commands = {}
    for _, entity in pairs(entity_manager.get_entities(get_filter_for_click(wx, wy))) do
        if possible_actions.harvest and entity.components.harvestable then
            table.insert(possible_commands, {object = entity, action = "harvest"})
        end
        if possible_actions.carry and entity.components.resource then
            table.insert(possible_commands, {object = entity, action = "carry"})
        end
        if possible_actions.produce and entity.components.producer then
            table.insert(possible_commands, {object = entity, action = "produce"})
        end
    end

    print(#possible_commands, "possible commands.")

    if #possible_commands > 0 then
        for _, cmd in pairs(possible_commands) do
            print(cmd.action, cmd.object.name)
            local x, y = unpack(cmd.object.components.location.position)
            local button = entity_manager.create_entity("button")
            print(x-10, y-32)
            entity_manager.add_component(button, "location", {
                position = {x-10, y - 32},
            })
            entity_manager.add_component(button, "gui", {
                draw = function() 
                    -- @TODO: have icons for action. draw more than a red square.
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.rectangle("fill", 0, 0, 20, 20)
                    -- @TODO: some actions will need something else to be selected,
                    --        and so should create a new list of available_actions.
                    -- @TODO: some actions should fire off to give the units jobs,
                    --        and should delete any buttons, and clear the available_actions.

                    -- @TODO: should harvest + carry be an option? Yeah! If the worker can do both, 
                    --        and the resource generated from harvesting can be carried by them, then sure!
                end,
            })
            cmd.button = button
        end
        avaialble_actions = possible_commands
    end
end

local function select_command(wx, wy)

end

local function click(system, wx, wy, button)
    if #avaialble_actions > 0 then
        select_command(wx, wy)
    elseif #selected_units > 0 then
        create_command_options(wx, wy)
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