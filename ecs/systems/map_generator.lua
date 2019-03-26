local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "map_generator"

local function rand(min, max)
    return min + math.floor(math.random() * (max-min))
end

-- Trees

local function add_tree(map, x, y, prob)
    if y < 1 or y > #map    then return false end
    if x < 1 or x > #map[y] then return false end
    if map[y][x] ~= ""      then return false end
    if math.random() > prob then return false end

    map[y][x] = "tree"
    local tree = entity_manager.create_entity("tree")
    entity_manager.add_component(tree, "location", {
        position = {(x-1) * 32, (y-1) * 32}
    })
    entity_manager.add_component(tree, "renderable", {
        visible   = true,
        texture   = love.graphics.newImage("res/gfx/tree.png"),
        colour    = {1, 1, 1},
    })
    -- TODO: harvestable is unused
    entity_manager.add_component(tree, "harvestable", {
        resource   = "wood",
        amount     = 100,
        work_time  = 1,
        on_exhaust = function() end,
    })
    print("made tree @ ", x, y)
    return true
end

local function create_forest(map, x, y, spread, prob)
    if prob == nil then prob = 1 end

    local success = add_tree(map, x, y, prob)
    if not success then 
        return 
    end
    if prob < 0.1 then 
        return 
    end
    create_forest(map, x-1, y, spread*0.9, prob * spread)
    create_forest(map, x+1, y, spread*0.9, prob * spread)
    create_forest(map, x, y-1, spread*0.9, prob * spread)
    create_forest(map, x, y+1, spread*0.9, prob * spread)
end

-- Hills

local generate = function(system, entity)
    print("generating...")
    entity_manager.remove_component(entity.id, "generatable")
    local heights = {}
    local object_map = {}

    local width  = entity.components.map.width
    local height = entity.components.map.height

    -- Create empty tables
    for j = 1, height do
        heights[j] = {}
        object_map[j] = {}
        for i = 1, width do
            heights[j][i] = 1
            object_map[j][i] = ""
        end
    end

    -- Add forests
    local forest_spread = 1 -- get from generatable component
    for i = 1, 2 do 
        local x = rand(1, width)
        local y = rand(1, height)
        create_forest(object_map, x, y, forest_spread)
    end

    -- Add hills
    -- Smooth hills

    -- Add rivers

    -- Make a background image
    entity_manager.add_component(entity.id, "tilemap", {
        heights = heights
    })
    local grass_tile = love.graphics.newImage("res/gfx/grass_plain.png")
    local grass_quad = love.graphics.newQuad(0, 0, 32, 32, 32, 23)
    local background_texture = love.graphics.newSpriteBatch(grass_tile, width * height)
    for j, row in ipairs(heights) do
        for i, height in ipairs(row) do
            background_texture:add(grass_quad, (i-1) * 32, (j-1) * 32)
        end
    end
    background_texture:flush()
    entity_manager.add_component(entity.id, "renderable", {
        visible = true,
        colour  = {1, 1, 1},
        texture = background_texture,
    })
    entity_manager.add_component(entity.id, "location", {
        position = {0, 0}
    })

    system_manager.disable_system(system.id)
end 

local filter = entity_manager.component_filter("map", "generatable")

return {
    name    = name,
    filters = { enable = filter },
    events  = { enable = generate },
}