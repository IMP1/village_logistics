-- Look at:
--   * https://www.gamedev.net/forums/topic/669843-the-simple-funnel-algorithm-pre-visited/
--   * [great paper on pathfinding using navmeshes](http://paper.ijcsns.org/07_book/201212/20121208.pdf)
--   * http://www.koffeebird.com/2014/05/towards-modified-simple-stupid-funnel.html
--   * http://digestingduck.blogspot.co.uk/2010/03/simple-stupid-funnel-algorithm.html

require 'lib.astar'

local pathfinder = {}

local map = {}

local function triangle_area(a, b, c)
    return (a[1] - c[1]) * (b[2] - a[2]) - (a[1] - b[1]) * (c[2] - a[2])
end

local function vertex_equal(v1, v2, epsilon)
    if #v1 ~= #v2 then return false end

    if epsilon == nil then epsilon = 0.001 end

    local dist_squared = (v1[1] - v2[1]) ^ 2 + (v1[2] - v2[2]) ^ 2
    return dist_squared < epsilon ^ 2
end

local function polygon_contains_point(polygon, point, line_is_inside)
    for i = 1, #polygon, 2 do
        local j = i + 1

        local i2 = i + 2
        local j2 = i + 3

        if i2 > #polygon then 
            i2 = 1
            j2 = 2
        end

        local x1 = polygon[i]  - point[1]
        local y1 = polygon[j]  - point[2]
        local x2 = polygon[i2] - point[1]
        local y2 = polygon[j2] - point[2]

        local a = x2 * y1 - x1 * y2

        if a == 0 and not line_is_inside then 
            return false
        elseif a < 0 then 
            return false
        end
    end

    return true
end

local function shared_line_segment(polygon1, polygon2)
    for line_start_x = 1, #polygon1, 2 do
        local line_start_y = line_start_x + 1

        local line_end_x = line_start_x + 2
        local line_end_y = line_start_x + 3
        if line_end_x > #polygon1 then
            line_end_x = 1
            line_end_y = 2
        end

        for i = 1, #polygon2, 2 do
            local j = i + 2
            if j > #polygon2 then j = 1 end

            if (polygon1[line_start_x] == polygon2[j]   and 
                polygon1[line_start_y] == polygon2[j+1] and
                polygon1[line_end_x]   == polygon2[i]   and 
                polygon1[line_end_y]   == polygon2[i+1])
            or 
               (polygon1[line_start_x] == polygon2[i]   and 
                polygon1[line_start_y] == polygon2[i+1] and
                polygon1[line_end_x]   == polygon2[j]   and 
                polygon1[line_end_y]   == polygon2[j+1])
            then   
                return {
                    polygon2[i], polygon2[i+1], 
                    polygon2[j], polygon2[j+1]
                }
            end 
        end    
    end
    return nil
end

local function adjacent_node_function(node, neighbour)
    return shared_line_segment(node, neighbour)
end

local function offset_corner_point(corner_point, line_segments, offset)
    -- @OPTIMISE: this is heavy on the trigonmetry functions
    local other_ends = {}
    for _, line in pairs(line_segments) do
        if line[1] == corner_point[1] and line[2] == corner_point[2] then
            table.insert(other_ends, {line[3], line[4]})
        elseif line[3] == corner_point[1] and line[4] == corner_point[2] then
            table.insert(other_ends, {line[1], line[2]})
        end
    end

    local sum_offset_sin = 0
    local sum_offset_cos = 0
    for _, other_end in pairs(other_ends) do
        local dx = other_end[1] - corner_point[1]
        local dy = other_end[2] - corner_point[2]
        local angle = math.atan2(dy, dx)
        sum_offset_sin = sum_offset_sin + math.sin(angle)
        sum_offset_cos = sum_offset_cos + math.cos(angle) 
    end

    local offset_angle = math.atan2(sum_offset_sin, sum_offset_cos)

    return {
        corner_point[1] + offset * math.cos(offset_angle),
        corner_point[2] + offset * math.sin(offset_angle),
    }
end


local function funnel(start_point, target_point, polygon_path, agent_size)
    local point_path = {}

    -- create line segments (referred to as 'portals' in most articles)
    local line_segments = {}
    for i = 1, #polygon_path-1 do
        line_segment = shared_line_segment(polygon_path[i], polygon_path[i+1])
        table.insert(line_segments, line_segment)
    end
    -- add target point as a final line segment to cross.
    table.insert(line_segments, {target_point[1], target_point[2], target_point[1], target_point[2]})

    -- Init scan state
    local apex_index  = 1
    local left_index  = 1
    local right_index = 1

    local apex_vertex  = start_point
    local left_vertex  = {line_segments[1][1], line_segments[1][2]}
    local right_vertex = {line_segments[1][3], line_segments[1][4]}

    table.insert(point_path, start_point)

    local i = 0
    while i < #line_segments do
        i = i + 1
        local left = {line_segments[i][1], line_segments[i][2]}
        local right = {line_segments[i][3], line_segments[i][4]}

        local continue = false

        -- Update right vertex.
        if (not continue) and triangle_area(apex_vertex, right_vertex, right) <= 0 then
            if vertex_equal(apex_vertex, right_vertex) or triangle_area(apex_vertex, left_vertex, right) > 0 then
                -- Tighten the funnel.
                right_vertex = right
                right_index = i
            else
                -- Right over left, insert left to path and restart scan from portal left point.

                -- Move the point along away from the edge of the vertex.
                local new_path_point = left_vertex
                local should_not_offset = (apex_index == 1) and 
                                          (i == #line_segments) and 
                                          (left_index == i or right_index == i)
                if not should_not_offset then
                    new_path_point = offset_corner_point(new_path_point, line_segments, agent_size * 2)
                end
                table.insert(point_path, new_path_point)

                -- Make current left the new apex.
                apex_vertex = left_vertex
                apex_index = left_index
                -- Reset portal
                left_vertex = apex_vertex
                right_vertex = apex_vertex
                left_index = apex_index
                right_index = apex_index
                -- Restart scan
                i = apex_index
                continue = true
            end
        end

        -- Update left vertex.
        if (not continue) and triangle_area(apex_vertex, left_vertex, left) >= 0 then
            if vertex_equal(apex_vertex, left_vertex) or triangle_area(apex_vertex, right_vertex, left) < 0 then
                -- Tighten the funnel.
                left_vertex = left
                left_index = i
            else
                -- Left over right, insert right to path and restart scan from portal right point.

                -- Move the point along away from the edge of the vertex.
                local new_path_point = right_vertex
                local should_not_offset = (apex_index == 1) and 
                                          (i == #line_segments) and 
                                          (left_index == i or right_index == i)
                if not should_not_offset then
                    new_path_point = offset_corner_point(new_path_point, line_segments, agent_size * 2)
                end
                table.insert(point_path, new_path_point)


                -- Make current right the new apex.
                apex_vertex = right_vertex
                apex_index = right_index
                -- Reset portal
                left_vertex = apex_vertex
                right_vertex = apex_vertex
                left_index = apex_index
                right_index = apex_index
                -- Restart scan
                i = apex_index
                continue = true
            end
        end
    end

    table.insert(point_path, target_point)

    return point_path
end

function pathfinder.map(newMap)
    if newMap == nil then
        return map
    else
        map = newMap
    end
end

function pathfinder.path(starting_point, target_point, agent_size)
    local starting_polygon = nil
    local target_polygon = nil

    for _, polygon in pairs(map) do
        if polygon_contains_point(polygon, starting_point) then
            starting_polygon = polygon
        end
        if polygon_contains_point(polygon, target_point) then
            target_polygon = polygon
        end
    end

    if starting_polygon == nil then
        print("could not locate starting polygon. starting point = " .. starting_point[1] .. ", " .. starting_point[2])
        return nil
    end
    if target_polygon == nil then
        print("could not locate target polygon. target point = " .. target_point[1] .. ", " .. target_point[2])
        return nil
    end

    local point_path = {}

    if starting_polygon ~= target_polygon then
        local polygon_path = astar.path(starting_polygon, target_polygon, map, false, adjacent_node_function) -- a* with polygons
        if polygon_path then
            point_path = funnel(starting_point, target_point, polygon_path, (agent_size or 0))
        else
            error("No path. D:")
        end
    end

    table.insert(point_path, target_point)

    return point_path
end

return pathfinder
