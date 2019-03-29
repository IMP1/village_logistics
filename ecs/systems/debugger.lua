local entity_manager = require 'ecs.entity_manager'

local name = "debugger"

local function print_info(system)
    love.graphics.print("Debug Info", 0, 0)
end

return {
    name    = name,
    filters = { draw = entity_manager.filter_none },
    events  = { draw = print_info },
}