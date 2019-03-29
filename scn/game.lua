local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local Base = require 'scn.base'
local Scene = {}
setmetatable(Scene, Base)
Scene.__index = Scene

function Scene.new()
    local self = Base.new("game")
    setmetatable(self, Scene)

    system_manager.set_entity_manager(entity_manager)
    system_manager.hook()

    entity_manager.load_entity("ecs/entities/map.lua")
    system_manager.load_system("ecs/systems/map_generator.lua", true)

    entity_manager.load_entity("ecs/entities/worker.lua")
    entity_manager.load_entity("ecs/entities/camera.lua")

    system_manager.load_system("ecs/systems/camera_input.lua", true)
    system_manager.load_system("ecs/systems/renderer.lua", true)
    system_manager.load_system("ecs/systems/resource_degrade.lua", true)
    system_manager.load_system("ecs/systems/mouse_input.lua", true)
    system_manager.load_system("ecs/systems/selection.lua", true)
    
    system_manager.load_system("ecs/systems/debugger.lua", true)

    return self
end

function Scene:update(dt)
    system_manager.update(dt)
end

function Scene:draw()
    system_manager.draw()
end

return Scene