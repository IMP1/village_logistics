local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "unit_selection"

local filter = entity_manager.component_filter("selectable")

local function select(system, entity, mx, my, button, wx, wy)
    print(wx, wy)
end

return {
    name    = name,
    filters = { 
        onclick = filter,
    },
    events  = { 
        onclick = select,
    },
}