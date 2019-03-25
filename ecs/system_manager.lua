local uuid = require 'lib.uuid'

local system_manager = {}

local systems        = {} -- list of systems
local entity_manager = nil

local function new_system(name)
    local new_id = uuid()
    return {
        id      = new_id,
        name    = name,
        enabled = false,
        filter  = function(e) return false end,
        events  = {},
    }
end

local function system_index(id)
    for i, s in ipairs(systems) do
        if s.id == id then
            return i
        end
    end
    return 0
end

local function handle_local_event(system, event_name, ...)
    if system.enabled and system.events[event_name] then
        local entities = entity_manager.get_entities(system.filter)
        for _, entity in pairs(entities) do
            system.events[event_name](system, entity, ...)
        end
    end
end

function system_manager.set_entity_manager(manager)
    entity_manager = manager
end

function system_manager.create_system(name, filter, events)
    local system = new_system(name)
    if filter then
        system.filter = filter
    end
    if events then 
        system.events = events
    end
    table.insert(systems, system)
    return system.id
end

function system_manager.delete_system(system_id)
    local index = system_index(system_id)
    table.remove(systems, index)
end

function system_manager.enable_system(system_id)
    local index = system_index(system_id)
    if index == 0 then 
        return 
    end

    systems[index].enabled = true
    handle_local_event(systems[index], "enable")
end

function system_manager.disable_system(system_id)
    local index = system_index(system_id)
    if index == 0 then 
        return 
    end

    handle_local_event(systems[index], "disable")
    systems[index].enabled = false
end

local function handle_global_event(event_name, ...)
    for _, system in pairs(systems) do
        handle_local_event(system, event_name, ...)
    end
end

function system_manager.update(dt)
    handle_global_event("update", dt)
end

function system_manager.draw()
    handle_global_event("draw")
end

function system_manager.hook()
    for event_name, func in pairs(love.handlers) do
        love.handlers[event_name] = function(...)
            func(...)
            handle_global_event(event_name, ...)
        end
    end
end

function system_manager.broadcast(message, ...)
    handle_global_event(message, ...)
end

return system_manager