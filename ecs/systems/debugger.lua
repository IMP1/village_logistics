local entity_manager = require 'ecs.entity_manager'

local name = "debugger"

local function print_info(system)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Debug Info", 0, 0)
end

return {
    name    = name,
    filters = { draw = entity_manager.filter_none },
    events  = { draw = print_info },
}