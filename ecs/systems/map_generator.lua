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
    if y < 1 or y > #map    then return nil end
    if x < 1 or x > #map[y] then return nil end
    if map[y][x] ~= 0       then return nil end

    local tree = entity_manager.load_entity("ecs/entities/tree.lua")
    local location = entity_manager.get_component(tree, "location")
    location.position = {(x-1) * 32, (y-1) * 32, 1}

    map[y][x] = tree

    return tree
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
    if y < 1 or y > #map    then return nil end
    if x < 1 or x > #map[y] then return nil end
    if map[y][x] ~= 0       then return nil end

    local water = entity_manager.load_entity("ecs/entities/water.lua")
    local location = entity_manager.get_component(water, "location")
    location.position = {(x-1) * 32, (y-1) * 32, 0}
    -- TODO: fluid is unused
    local fluid = entity_manager.get_component(water, "fluid")
    fluid.depth     = depth
    fluid.origin    = origin
    fluid.is_source = is_source

    map[y][x] = water

    return water
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
    if obj_map[y][x] == 0 then
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

local function neighbours(map, x, y, func)
    local neighbour_flags = 0
    if func(get_tile(map, x, y-1)) then
        neighbour_flags = neighbour_flags + 1
    end
    if func(get_tile(map, x+1, y)) then
        neighbour_flags = neighbour_flags + 2
    end
    if func(get_tile(map, x, y+1)) then
        neighbour_flags = neighbour_flags + 4
    end
    if func(get_tile(map, x-1, y)) then
        neighbour_flags = neighbour_flags + 8
    end
    return neighbour_flags
end

local function draw_autotiles(background_spritebatch, obj_map, height_map)
    for j, row in pairs(obj_map) do
        for i, tile in pairs(row) do
            if entity_manager.entity_name(tile) == "water" then
                local is_land = function(obj)
                    return entity_manager.entity_name(obj) ~= "water" 
                end
                local neighbouring_waters = neighbours(obj_map, i, j, is_land)
                local x = 128 + 32 * math.floor(neighbouring_waters / 4)
                local y = 32 * (neighbouring_waters % 4)
                local water_quad = love.graphics.newQuad(x, y, 32, 32, 256, 256)
                local water_tile = entity_manager.get_component(tile, "renderable")
                water_tile.quad = water_quad
            end
        end
    end
    for j, row in pairs(height_map) do
        for i, tile in pairs(row) do
            local is_lower = function(height)
                if height == nil then
                    return false
                end
                return height < tile
            end
            local is_water = function(obj)
                return entity_manager.entity_name(obj) == "water"
            end
            local neighbouring_hills = neighbours(height_map, i, j, is_lower)
            local neighbouring_water = neighbours(obj_map, i, j, is_water)
            neighbouring_hills = neighbouring_hills - neighbouring_water
            local x = 32 * math.floor(neighbouring_hills / 4)
            local y = 32 * (neighbouring_hills % 4)
            local hill_quad = love.graphics.newQuad(x, y, 32, 32, 256, 256)
            background_spritebatch:add(hill_quad, (i-1) * 32, (j-1) * 32)
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
            object_map[j][i] = 0
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

    -- Make a background image
    entity_manager.add_component(entity.id, "heightmap", {
        heights = heights,
    })
    local tileset = love.graphics.newImage("res/gfx/tileset.png")

    local background_texture = love.graphics.newSpriteBatch(tileset, width * height)

    draw_autotiles(background_texture, object_map, heights)
    background_texture:flush()

    entity_manager.add_component(entity.id, "renderable", {
        visible = true,
        colour  = {1, 1, 1},
        texture = background_texture,
    })
    entity_manager.add_component(entity.id, "location", {
        position = {0, 0, 0}
    })

    system_manager.disable_system(system.id)
end 

local filter = entity_manager.component_filter("map", "generatable")

return {
    name    = name,
    filters = { enable = filter },
    events  = { enable = generate },
}