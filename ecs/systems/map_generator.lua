local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "map_generator"

local function rand(min, max)
    min = math.floor(min)
    max = math.floor(max)
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
    return true
end

local function create_forest(map, x, y, size, spread, prob)
    if size == 0 then return end
    if prob == nil then prob = 1 end

    local success = add_tree(map, x, y, prob)
    if not success then 
        return 
    end
    create_forest(map, x-1, y, size-1, spread * 0.95, prob * spread)
    create_forest(map, x+1, y, size-1, spread * 0.95, prob * spread)
    create_forest(map, x, y-1, size-1, spread * 0.95, prob * spread)
    create_forest(map, x, y+1, size-1, spread * 0.95, prob * spread)
end

-- Hills
local function get_height(map, x, y)
    if map[y] and map[y][x] then
        return map[y][x]
    else
        return nil
    end
end

local function set_height(map, x, y, height)
    if map[y] and map[y][x] then
        map[y][x] = height
    end
end

local function smooth_terrain(map)
    local new_map = {}
    for y, row in pairs(map) do
        new_map[y] = {}
        for x, height in pairs(row) do
            new_map[y][x] = 0
            local region_height = 0
            local neighbour_count = 0
            for j = -1, 1 do
                for i = -1, 1 do
                    local neighbour_height = get_height(map, x + i, y + j)
                    if neighbour_height then
                        region_height = region_height + neighbour_height
                        neighbour_count = neighbour_count + 1
                    end
                end
            end
            local smoothed_height = region_height / neighbour_count
            for j = -1, 1 do
                for i = -1, 1 do
                    set_height(new_map, x + i, y + j, smoothed_height)
                end
            end
        end
    end
    for y, row in pairs(new_map) do
        for x, height in pairs(row) do
            map[y][x] = height
        end
    end
end

local function create_hill(map, x, y, size, smooth)
    map[y][x] = size
    for i = 1, smooth do
        smooth_terrain(map)
    end
end

local generate = function(system, entity)
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

    -- Map parameters
    -- TODO: get from generatable component
    local forest_amount = 4
    local forest_size   = 40
    local forest_spread = 0.9
    local hill_amount   = 4
    local hill_size     = 40
    local hill_smooth   = 1

    -- Add forests
    local forest_count = rand(forest_amount/2, forest_amount)
    print(forest_count, "forests")
    for i = 1, forest_count do 
        local x = rand(1, width)
        local y = rand(1, height)
        create_forest(object_map, x, y, forest_size, forest_spread)
    end

    -- Add hills
    local hill_count = rand(hill_amount/2, hill_amount)
    for i = 1, hill_count do
        local x = rand(1, width)
        local y = rand(1, height)
        create_hill(heights, x, y, hill_size, hill_smooth)
    end

    -- Add rivers

    -- Make a background image
    entity_manager.add_component(entity.id, "tilemap", {
        heights = heights
    })
    local grass_tile = love.graphics.newImage("res/gfx/grass_plain.png")
    local grass_quad = love.graphics.newQuad(0, 0, 32, 32, 32, 23)
    local background_texture = love.graphics.newSpriteBatch(grass_tile, width * height)
    for j, row in ipairs(heights) do
        print(unpack(row))
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