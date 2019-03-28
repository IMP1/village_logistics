local entity_manager = require 'ecs.entity_manager'

local name = "debugger"

local function print_info(system, entity)
    local i = get_stage(entity)
    if i > 0 and i ~= entity.components.harvestable.current_stage then
        local image = entity.components.harvestable.stages[i].image
        local quad = entity.components.harvestable.stages[i].quad
        entity.components.renderable.texture = image
        entity.components.renderable.quad = quad
    end
end

return {
    name    = name,
    filters = { onharvest = filter },
    events  = { postdraw = harvest },
}