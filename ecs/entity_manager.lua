local uuid = require 'lib.uuid'

local entity_manager = {}

entity_manager.filter_none = "NO_EVENTS"

local entities = {} -- list of entities

local function new_entity(name)
    local new_id = uuid()
    return {
        id         = new_id,
        name       = name,
        components = {}, -- table of component_name => component_data
    }
end

local function entity_index(id)
    for i, e in ipairs(entities) do
        if e.id == id then
            return i
        end
    end
    return 0
end

local function entity_has_components(entity, component_names)
    for _, component_name in pairs(component_names) do
        if not entity.components[component_name] then
            return false
        end
    end
    return true
end

function entity_manager.component_filter(...)
    local component_names = {...}
    local filter = function(entity)
        return entity_has_components(entity, component_names)
    end
    return filter
end

function entity_manager.get_entities(filter)
    local result = {}
    for _, entity in pairs(entities) do
        if filter(entity) then
            table.insert(result, entity)
        end
    end
    return result
end

function entity_manager.load_entity(path)
    if not love.filesystem.exists(path) then
        error(string.format("Could not find entity '%s'", path))
    end
    local data = love.filesystem.load(path)()
    if data.id then 
        -- loading from save file
        table.insert(entities, data)
        return data.id
    else 
        -- creating from template
        local id = entity_manager.create_entity(data.name)
        for component, params in pairs(data.components) do
            entity_manager.add_component(id, component, params)
        end
        return id
    end
end

function entity_manager.create_entity(name)
    local entity = new_entity(name)
    table.insert(entities, entity)
    return entity.id
end

function entity_manager.delete_entity(entity_id)
    local index = entity_index(entity_id)
    table.remove(entities, index)
end

function entity_manager.add_component(entity_id, component_name, options)
    local index = entity_index(entity_id)
    if index == 0 then
        return
    end

    local entity = entities[index]
    if entity.components[component_name] then
        local message = "Entity '%s' already has component '%s'. Replacing its values."
        print("WARNING: " .. string.format(message, entity.name, component_name))
    end
    entity.components[component_name] = (options or {})
end

function entity_manager.get_component(entity_id, component_name)
    local index = entity_index(entity_id)
    if entities[index] then
        return entities[index].components[component_name]
    end
end

function entity_manager.remove_component(entity_id, component_name)
    local index = entity_index(entity_id)
    if index == 0 then
        return
    end

    local entity = entities[index]
    entity.components[component_name] = nil
end

return entity_manager