local entity_manager = require 'ecs.entity_manager'

local name = "pathing"

local filter = entity_manager.component_filter("location", "moveable")

local function update(system, entity, dt)
    
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}