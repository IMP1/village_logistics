local entity_manager = require 'ecs.entity_manager'

local name = "resource_degrade"

local filter = entity_manager.component_filter("renderable", "harvestable")

local function get_stage(entity)
    local count = entity.components.harvestable.amount
    for i, stage in ipairs(entity.components.harvestable.stages) do
        if count >= stage.count then
            return i
        end
    end
    return 0
end

local function harvest(system, entity)
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
    events  = { onharvest = harvest },
}