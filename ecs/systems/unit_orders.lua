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

-- @NOTE: a lot of this gets much easier if you can't select more than one worker.
--        how great is the benefit to the player for that? when/how often do you
--        want more than one worker doing the same job?

-- @TODO: change to be one selected_unit

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

            local action
            if cmd.action == "produce" then
                action = function(gui_entity)
                    -- @TODO: open building menu for production
                end
            elseif cmd.action == "carry" then
                action = function(gui_entity)
                    -- @TODO: have next clicked place be target of carrying
                end
            elseif cmd.action == "harvest" then
                action = function(gui_entity)
                    local resource = entity_manager.load_blueprint(cmd.object.components.harvestable.resource)
                    print("mass of " .. resource.name .. " is " .. resource.components.resource.unit_mass .. "kg.")
                    if 
                    -- @TODO: need to check if resource that would be created by harvesting can be carried.
                    --        and if it if can, and the worker can also carry, have both options of just 
                    --        harvesting in place, or harvest and carry.
                end
            end

            entity_manager.add_component(button, "location", {
                position = {x-10, y - 32},
            })
            entity_manager.add_component(button, "gui", {
                draw = function(entity) 
                    -- @TODO: have icons for action. draw more than a red square.
                    local char = cmd.action:sub(1, 1)
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.rectangle("fill", 0, 0, 20, 20)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.print(char, 0, 0)
                end,
                is_over = function(entity, mx, my)
                    local x, y = unpack(entity.components.location.position)
                    return mx >= x and mx <= x + 20 and my >= y - 50 and my <= y + 50
                end,
                click = action,
            })
            cmd.button = button
        end
    end
    avaialble_actions = possible_commands
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