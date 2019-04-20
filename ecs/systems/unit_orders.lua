local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_orders"

local selected_unit     = nil
local avaialble_actions = {}
local chosen_action     = nil -- before running it
local selected_action   = nil

local gui_clicked_this_frame = false

-- @TODO: make jobs their own entities, reworking components. (new branch!)

local function deselect_unit()
    if selected_unit then
        print("deselecting unit")
        entity_manager.remove_component(selected_unit.id, "selected")
    end
end

local function stop_on_path()
    if selected_unit.components.moveable then
        selected_unit.components.moveable.path = nil
    end
end

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
    if not selected_unit.components.harvester then
        harvest = false
    end
    if not selected_unit.components.conveyor then
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

local function select_target(wx, wy)
    print("selecting target")
    if selected_action.name == "carry" then
        local containers = entity_manager.get_entities(entity_manager.component_filter("location", "container"))
        containers = table.filter(containers, function(elem)
            return not elem.components.conveyor
        end)
        if #containers > 0 then
            if #containers > 1 then
                table.sort(containers, function(a, b)
                    local ax, ay = unpack(a.components.location.position)
                    local bx, by = unpack(b.components.location.position)
                    local dx_a, dy_a = ax - wx, ay - wy
                    local dx_b, dy_b = bx - wx, by - wy
                    return dx_a*dx_a + dy_a*dy_a < dx_b*dx_b + dy_b*dy_b
                end)
            end
            local nearest = containers[1]
            entity_manager.add_component(selected_unit, "job_carry", {
                source        = selected_action.source.id,
                target        = nearest.id,
                resource_name = nil,
                pickup_timer  = 0,
                putdown_timer = 0,
            })
            selected_action = nil
            stop_on_path()
        end
    end
    selection(nil, selected_unit)
end

local function select_command(wx, wy)
    print("selecting command")
    chosen_action()
end

local function create_command_options(wx, wy)
    print("selecting unit", selected_unit.name)
    local possible_actions = get_options()

    local possible_commands = {}
    for _, entity in pairs(entity_manager.get_entities(get_filter_for_click(wx, wy))) do
        if possible_actions.harvest and entity.components.harvestable then
            table.insert(possible_commands, {object = entity, action = "harvest"})
            if possible_actions.carry then
                local carrier = selected_unit.components.conveyor
                if carrier then
                    table.insert(possible_commands, {object = entity, action = "harvest_and_carry"})
                end
            end
        end
        if possible_actions.carry and entity.components.resource then
            table.insert(possible_commands, {object = entity, action = "carry"})
        elseif possible_actions.carry and entity.components.container then
            table.insert(possible_commands, {object = entity, action = "carry"})
        end
        if possible_actions.produce and entity.components.production then
            table.insert(possible_commands, {object = entity, action = "produce"})
        end
    end

    if #possible_commands > 0 then
        for i, cmd in pairs(possible_commands) do
            local action
            local icon
            if cmd.action == "produce" then
                action = function()
                    -- @TODO: open building menu for production
                end
                icon = "P"
            elseif cmd.action == "carry" then
                action = function()
                    selected_action = {
                        name   = "carry",
                        source = cmd.object
                    }
                end
                icon = "C"
            elseif cmd.action == "harvest_and_carry" then
                action = function()
                    -- @TODO: have next clicked place be target of carrying
                end
                icon = "HC"
            elseif cmd.action == "harvest" then
                action = function()
                    print("adding job_havest component")
                    entity_manager.add_component(selected_unit, "job_harvest", {
                        resource_entity = cmd.object.id,
                        resource_path   = cmd.object.components.harvestable.resource,
                    })
                    stop_on_path()
                    selection(nil)
                end
                icon = "H"
            end

            local ox, oy = unpack(cmd.object.components.location.position)
            local button = entity_manager.create_entity("button")

            local radial_menu_radius = 48

            local theta = -math.pi/2 + i * (2 * math.pi / #possible_commands)
            local x = ox + math.cos(theta) * radial_menu_radius
            local y = oy + math.sin(theta) * radial_menu_radius

            entity_manager.add_component(button, "location", {
                position = {x-10, y - 32},
            })
            entity_manager.add_component(button, "gui", {
                draw = function(entity) 
                    -- @TODO: have icons for action. draw more than a red square with a letter.
                    local char = icon
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.rectangle("fill", 0, 0, 20, 20)
                    love.graphics.setColor(0, 0, 0)
                    love.graphics.print(char, 0, 0)
                end,
                is_over = function(entity, mx, my)
                    local x, y = unpack(entity.components.location.position)
                    return mx >= x and mx <= x + 20 and my >= y - 50 and my <= y + 50
                end,
                click = function()
                    gui_clicked_this_frame = true
                    action()
                end,
            })
            cmd.button = button
        end
    elseif selected_unit.components.moveable then
        local ox, oy = unpack(selected_unit.components.location.position)
        local path = pathfinder.path({ox, oy}, {wx, wy})
        selected_unit.components.moveable.path = path
        entity_manager.remove_component(selected_unit, "job_harvest")
        entity_manager.remove_component(selected_unit, "job_carry")
                      
    end
    avaialble_actions = possible_commands
end

local function click(system, wx, wy, button)
    print("click")
    if selected_action and not gui_clicked_this_frame and button == 2 then
        select_target(wx, wy)
    elseif #avaialble_actions > 0 and button == 2 then
        -- select_command(wx, wy) -- handled by gui buttons
    elseif selected_unit and button == 2 then
        create_command_options(wx, wy)
    end
    gui_clicked_this_frame = false
end

local function keypressed(system, key)
    if key == "escape" then
        deselect_unit()
    end
end

return {
    name    = name,
    filters = {
        onselection = entity_manager.filter_none,
        onclick     = entity_manager.filter_none,
        keypressed  = entity_manager.filter_none,
    },
    events  = {
        onselection = selection,
        onclick     = click,
        keypressed  = keypressed,
    },
}