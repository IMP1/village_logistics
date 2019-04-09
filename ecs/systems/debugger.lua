local entity_manager = require 'ecs.entity_manager'

local name = "debugger"

local debugger_entity_id = entity_manager.load_entity("ecs/entities/debug_console.lua")
local console_command    = ""
local enabled            = false

local function textinput(system, text)
    if text == "`" then
        if entity_manager.get_component(debugger_entity_id, "console") then
            entity_manager.remove_component(debugger_entity_id, "console")
            entity_manager.remove_component(debugger_entity_id, "gui")
        else
            entity_manager.add_component(debugger_entity_id, "console")
            entity_manager.add_component(debugger_entity_id, "gui")
        end
    end
end

-- @TODO: have gui draw somehow 
--        maybe just for now give each gui a draw function, which the renderer handles

-- @TODO: have commands for creating workers where the mouse is. 
--        maybe commands also fire events? command_<command_name> *args

return {
    name    = name,
    filters = { 
        textinput = entity_manager.filter_none,
    },
    events  = { 
        textinput = textinput,
    },
}