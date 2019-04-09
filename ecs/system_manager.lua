local uuid = require 'lib.uuid'

local system_manager = {}

local systems        = {} -- list of systems
local entity_manager = nil

local function new_system(options)
    local new_id = uuid()
    return {
        id      = new_id,
        enabled = false,
        name    = options.name    or "unnamed_system",
        filters = options.filters or {},
        events  = options.events  or {},
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
        if system.filters[event_name] == nil then
            local message = string.format("the filter for '%s' is nil.", event_name)
            print("WARNING: " .. message .. "It will not run for this event.")
            print("Give it a filter, or use `entity_manager.filter_none`.")
        elseif system.filters[event_name] == entity_manager.filter_none then
            system.events[event_name](system, ...)
        else
            local entities = entity_manager.get_entities(system.filters[event_name])
            for _, entity in pairs(entities) do
                system.events[event_name](system, entity, ...)
            end
        end
    end
end

function system_manager.set_entity_manager(manager)
    entity_manager = manager
end

function system_manager.bind(entity_manager)
    system_manager.set_entity_manager(entity_manager)
    entity_manager.set_system_manager(system_manager)
end

function system_manager.load_system(path, enable)
    if not love.filesystem.exists(path) then
        error(string.format("Could not find system '%s'", path))
    end
    local data = love.filesystem.load(path)()
    local id = system_manager.create_system(data)
    if enable then
        system_manager.enable_system(id)
    end
    return id
end

function system_manager.create_system(options)
    local system = new_system(options)
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

function system_manager.running_systems()
    local result = {}
    for _, system in ipairs(systems) do
        if system.enabled then
            table.insert(result, system.name)
        end
    end
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
    handle_global_event("predraw")
    handle_global_event("draw")
    handle_global_event("postdraw")
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