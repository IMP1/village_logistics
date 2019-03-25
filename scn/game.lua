local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local Base = require 'scn.base'
local Scene = {}
setmetatable(Scene, Base)
Scene.__index = Scene

local function load_entity(path)
    local data = love.filesystem.load(path)()
    local id = entity_manager.create_entity(data.name)
    for component, params in pairs(data.components) do
        entity_manager.add_component(id, component, params)
    end
    return id
end

local function load_system(path, enable)
    local data = love.filesystem.load(path)()
    local id = system_manager.create_system(data.name, data.filter, data.events)
    if enable then
        system_manager.enable_system(id)
    end
    return id
end

function Scene.new()
    local self = Base.new("game")
    setmetatable(self, Scene)

    system_manager.set_entity_manager(entity_manager)
    system_manager.hook()

    local player = load_entity("ecs/entities/player.lua")
    local renderer = load_system("ecs/systems/renderer.lua", true)

    local map = entity_manager.create_entity("map")
    entity_manager.add_component(map, "map", {width=50, height=50})
    entity_manager.add_component(map, "generatable")

    load_system("ecs/systems/map_generator.lua", true)

    return self
end

function Scene:update(dt)
    system_manager.update(dt)
end

function Scene:draw()
    system_manager.draw()
end

return Scene