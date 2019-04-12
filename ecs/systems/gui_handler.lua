local entity_manager = require 'ecs.entity_manager'

local name = "gui_handler"

local filter = function(x, y)
    return function(entity)
        if entity.components.gui then
            return entity.components.gui.is_over and entity.components.gui.is_over(entity, x, y)
        end
        return false
    end
end

local function click(system, wx, wy)
    for _, entity in pairs(entity_manager.get_entities(filter(wx, wy))) do
        local gui = entity.components.gui
        if not gui.disabled and gui.click then
            gui.click(entity)
        end
    end
end

return {
    name    = name,
    filters = { onclick = entity_manager.filter_none },
    events  = { onclick = click },
}