local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_orders"

local selected_unit     = nil
local avaialble_actions = {}

-- @BUG: clicking on resource created button and then also triggers button press. somehow.

local function selection(system, newly_selected_entity)
    selected_unit = newly_selected_entity
    for _, action in pairs(avaialble_actions) do
        entity_manager.delete_entity(action.button)
    end
    avaialble_actions = {}
end

local function get_options()
    local harvest = true
    local carry   = true
    local produce = true
    for k, v in pairs(selected_unit.components) do print(k) end
    if not selected_unit.components.harvester then
        harvest = false
    end
    if not selected_unit.components.carrier then
        carry = false
    end
    if not selected_unit.components.producer then
        produce = false
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
        local r = leeway or 16
        if entity.components.selectable then
            local ox, oy = unpack(entity.components.selectable.offset)
            x = x - ox
            y = y - oy
            r = entity.components.selectable.size
        end
        local dx = x - wx
        local dy = y - wy
        return dx*dx + dy*dy <= r*r
    end
end

local function create_command_options(wx, wy)
    local possible_actions = get_options()

    local possible_commands = {}
    for _, entity in pairs(entity_manager.get_entities(get_filter_for_click(wx, wy))) do
        if possible_actions.harvest and entity.components.harvestable then
            table.insert(possible_commands, {object = entity, action = "harvest"})
            if possible_actions.carry then
                local resource = entity_manager.load_blueprint(entity.components.harvestable.resource)
                local carrier = selected_unit.components.carrier
                if carrier and carrier.max_weight >= resource.components.resource.unit_mass then
                    table.insert(possible_commands, {object = entity, action = "harvest-and-carry"})
                end
            end
        end
        if possible_actions.carry and entity.components.resource then
            table.insert(possible_commands, {object = entity, action = "carry"})
        end
        if possible_actions.produce and entity.components.production then
            table.insert(possible_commands, {object = entity, action = "produce"})
        end
    end

    print(#possible_commands, "possible commands.")

    if #possible_commands > 0 then
        for i, cmd in pairs(possible_commands) do
            local action
            if cmd.action == "produce" then
                action = function(gui_entity)
                    -- @TODO: open building menu for production
                end
            elseif cmd.action == "carry" then
                action = function(gui_entity)
                    -- @TODO: have next clicked place be target of carrying
                end
            elseif cmd.action == "harvest-and-carry" then
                action = function(gui_entity)
                    -- @TODO: have next clicked place be target of carrying
                end
            elseif cmd.action == "harvest" then
                action = function(gui_entity)

                    -- @TODO: need to check if resource that would be created by harvesting can be carried.
                    --        and if it if can, and the worker can also carry, have both options of just 
                    --        harvesting in place, or harvest and carry.
                end
            end

            local x, y = unpack(cmd.object.components.location.position)
            local button = entity_manager.create_entity("button")

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
    elseif selected_unit then
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