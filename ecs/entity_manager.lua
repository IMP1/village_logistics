local uuid = require 'lib.uuid'

local entity_manager = {}

entity_manager.filter_none = "NO_EVENTS"

local entities       = {} -- list of entities
local system_manager = nil

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

function entity_manager.set_system_manager(manager)
    system_manager = manager
end

function entity_manager.bind(system_manager)
    entity_manager.set_system_manager(system_manager)
    system_manager.set_entity_manager(entity_manager)
end

function entity_manager.component_filter(...)
    local component_names = {...}
    local filter = function(entity)
        return entity_has_components(entity, component_names)
    end
    return filter
end

function entity_manager.get_entity(entity_id)
    local index = entity_index(entity_id)
    return entities[index]
end

function entity_manager.get_entities(filter)
    if filter == nil then
        return entities
    end
    
    local result = {}
    for _, entity in pairs(entities) do
        if filter(entity) then
            table.insert(result, entity)
        end
    end
    return result
end

function entity_manager.entity_name(entity_id)
    local index = entity_index(entity_id)
    if not entities[index] then
        return nil
    end
    return entities[index].name
end

function entity_manager.load_blueprint(path)
    if not love.filesystem.exists(path) then
        error(string.format("Could not find entity '%s'", path))
    end
    return love.filesystem.load(path)()
end

function entity_manager.load_entity(path)
    local data = entity_manager.load_blueprint(path)
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
    local index
    if type(entity_id) == "table" and entity_id.components then
        index = entity_index(entity_id.id)
    else
        index = entity_index(entity_id)
    end
    table.remove(entities, index)
end

function entity_manager.add_component(entity_id, component_name, options)
    local entity
    if type(entity_id) == "table" and entity_id.components then
        entity = entity_id
    else
        local index = entity_index(entity_id)
        if index == 0 then
            return
        end
        entity = entities[index]
    end

    if entity.components[component_name] then
        local message = "Entity '%s' already has component '%s'. Replacing its values."
        print("WARNING: " .. string.format(message, entity.name, component_name))
    end
    entity.components[component_name] = (options or {})

    if system_manager then
        system_manager.broadcast("add_component_" .. component_name, entity)
    end
end

function entity_manager.get_component(entity_id, component_name)
    local index = entity_index(entity_id)
    if entities[index] then
        return entities[index].components[component_name]
    end
end

function entity_manager.remove_component(entity_id, component_name)
    local entity
    if type(entity_id) == "table" and entity_id.components then
        entity = entity_id
    else
        local index = entity_index(entity_id)
        if index == 0 then
            return
        end
        entity = entities[index]
    end

    
    if system_manager then
        system_manager.broadcast("remove_component_" .. component_name, entity)
    end
    
    entity.components[component_name] = nil
end

return entity_manager