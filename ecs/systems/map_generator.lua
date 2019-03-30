local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "map_generator"

local function rand(min, max)
    min = math.floor(min)
    max = math.floor(max)
    return min + math.floor(math.random() * (max-min))
end

-- Trees

local function add_tree(map, x, y)
    if y < 1 or y > #map    then return false end
    if x < 1 or x > #map[y] then return false end
    if map[y][x] ~= ""      then return false end

    map[y][x] = "tree"

    local tree = entity_manager.load_entity("ecs/entities/tree.lua")
    local location = entity_manager.get_component(tree, "location")
    location.position = {(x-1) * 32, (y-1) * 32}

    return true
end

local function create_forest(map, x, y, size, spread, prob)
    if size == 0 then return end
    if prob == nil then prob = 1 end

    if math.random() > prob then
        return
    end
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
local function get_tile(map, x, y)
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
                    local neighbour_height = get_tile(map, x + i, y + j)
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
            map[y][x] = math.floor(height + 0.5)
        end
    end
end

local function create_hill(map, x, y, size, smooth)
    map[y][x] = size
    for i = 1, smooth do
        smooth_terrain(map)
    end
end

-- Lakes
local function add_water(map, x, y, depth, origin, is_source)
    if y < 1 or y > #map    then return false end
    if x < 1 or x > #map[y] then return false end
    if map[y][x] ~= ""      then return false end


    map[y][x] = "water"

    local water = entity_manager.load_entity("ecs/entities/water.lua")
    local location = entity_manager.get_component(water, "location")
    location.position = {(x-1) * 32, (y-1) * 32}
    -- TODO: fluid is unused
    local fluid = entity_manager.get_component(water, "fluid")
    fluid.depth     = depth
    fluid.origin    = origin
    fluid.is_source = is_source
    return true
end

local function create_lake(obj_map, height_map, x, y, size, height)
    if size <= 0 then return end
    if height == nil then
        height = height_map[y][x]
    end
    if height_map[y][x] ~= height then
        return 
    end
    local spreads = {}
    if get_tile(height_map, x - 1, y) == height then
        table.insert(spreads, {x-1, y})
    end
    if get_tile(height_map, x + 1, y) == height then
        table.insert(spreads, {x+1, y})
    end
    if get_tile(height_map, x, y - 1) == height then
        table.insert(spreads, {x, y-1})
    end
    if get_tile(height_map, x, y + 1) == height then
        table.insert(spreads, {x, y+1})
    end
    if obj_map[y][x] == "" then
        height_map[y][x] = height_map[y][x] - 1
        add_water(obj_map, x, y, 1, nil, false)
    end
    if #spreads > 0 then
        local direction = rand(1, #spreads)
        local spread_x, spread_y = unpack(spreads[direction])
        create_lake(obj_map, height_map, spread_x, spread_y, size-1, height)
    end
end

-- Rivers
local function create_river(obj_map, height_map, x, y, bend)
    -- TODO: create rivers
end

local function neighbours(obj_map, x, y, tile_type)
    -- TODO: replace this as a bit flag mask thing
    -- 0-15 based on combinations
    local count = 0
    for j = -1, 1 do
        for i = -1, 1 do
            if get_tile(obj_map) == tile_type and not (i == 0 and j == 0) then
                count = count + 1
            end
        end
    end
    return count
end

local function fix_autotiles(obj_map, height_map)
    for y, row in pairs(obj_map) do
        for x, tile in pairs(row) do
            if tile == "water" then
                -- TODO: give autotile depending on neighbour count
            end
        end
    end
end

local function generate(system, entity)
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
    local forest_amount = entity.components.map.setup_params.forest_amount
    local forest_size   = entity.components.map.setup_params.forest_size
    local forest_spread = entity.components.map.setup_params.forest_spread
    local hill_amount   = entity.components.map.setup_params.hill_amount
    local hill_size     = entity.components.map.setup_params.hill_size
    local hill_smooth   = entity.components.map.setup_params.hill_smooth
    local lake_amount   = entity.components.map.setup_params.lake_amount
    local lake_size     = entity.components.map.setup_params.lake_size
    local river_amount  = entity.components.map.setup_params.river_amount
    local river_bends   = entity.components.map.setup_params.river_bends

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
    print(hill_count, "hills")
    for i = 1, hill_count do
        local x = rand(1, width)
        local y = rand(1, height)
        create_hill(heights, x, y, hill_size, hill_smooth)
    end

    -- Add lakes
    local lake_count = rand(lake_amount/2, lake_amount)
    print(lake_count, "lakes")
    for i = 1, lake_count do
        local x = rand(1, width)
        local y = rand(1, height)
        create_lake(object_map, heights, x, y, lake_size)
    end

    -- Add rivers
    local river_count = rand(river_amount/2, river_amount)
    print(river_count, "rivers")
    for i = 1, river_count do
        local x = rand(1, width)
        local y = rand(1, height)
        create_river(object_map, heights, x, y, river_bends)
    end

    fix_autotiles(object_map, heights)

    -- Make a background image
    entity_manager.add_component(entity.id, "heightmap", {
        heights = heights,
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