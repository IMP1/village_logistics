require 'lib.table_util'
local scene_manager = require 'scn.scn_manager'

local INITIAL_SCENE = require 'scn.game'

-- REMOVE when update to latest LOVE version
local old_set_colour = love.graphics.setColor
function love.graphics.setColor(r, g, b, a)
    if not g and type(r) == "table" then
        r, g, b, a = unpack(r)
    end
    old_set_colour(r*256, g*256, b*256, (a or 1)*256)
end
-- /REMOVE

function love.load()
    math.randomseed(os.time())
    math.random(); math.random(); math.random()
    love.graphics.setDefaultFilter("nearest", "nearest")
    scene_manager.hook()
    scene_manager.setScene(INITIAL_SCENE.new())
end

function love.update(dt)
    scene_manager.update(dt)
end

function love.draw()
    scene_manager.draw()
end
