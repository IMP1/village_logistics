local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "job_harvest_handler"

local filter = entity_manager.component_filter("location", "harvester", "job_harvest")

local nearby_sources_filter = function(resource, x, y)
    return function(entity)
        if not entity.components.location    then return false end
        if not entity.components.harvestable then return false end

        return entity.components.harvestable.resource == resource
    end
end

local NEARBY_STACK_DISTANCE = 32

local nearby_stack_filter = function(resource_name, x, y, leeway)
    return function(entity)
        local leeway = leeway or NEARBY_STACK_DISTANCE
        if not entity.components.location then return false end
        if not entity.components.resource then return false end

        if entity.name ~= resource_name then return false end

        local ox, oy = unpack(entity.components.location.position)
        local dx, dy = x - ox, y - oy
        local dr = leeway

        return dx*dx + dy*dy <= dr*dr
    end
end

local function next_job(last_job, worker)
    local wx, wy = unpack(worker.components.location.position)
    local nearby_sources = entity_manager.get_entities(nearby_sources_filter(last_job.resource_path, wx, wy))

    if #nearby_sources == 0 then
        entity_manager.remove_component(worker, "job_harvest")
    else
        table.sort(nearby_sources, function(a, b)
            local ax, ay = unpack(a.components.location.position)
            local bx, by = unpack(b.components.location.position)
            local dx_a, dy_a = ax - wx, ay - wy
            local dx_b, dy_b = bx - wx, by - wy
            return dx_a*dx_a + dy_a*dy_a < dx_b*dx_b + dy_b*dy_b
        end)
        last_job.resource_entity = nearby_sources[1].id
    end
end

-- @TODO: factor out this code from update method
local function new_stack(resource_path, amount, x, y)
    local resource_id = entity_manager.load_entity(resource_path)
    local resource = entity_manager.get_entity(resource_id)
    resource.components.resource.amount = amount
    -- @TODO: have the position be slightly offset from the worker.
    resource.components.location.position = { x, y }
end

local function update(system, worker, dt)
    local job = worker.components.job_harvest
    local source = entity_manager.get_entity(job.resource_entity)

    if source == nil then -- someone else finished harvesting this
        next_job(job, worker)
        return
    end

    local wx, wy = unpack(worker.components.location.position)
    local rx, ry = unpack(source.components.location.position)

    local dx = rx - wx
    local dy = ry - wy
    local dr = source.components.harvestable.reach

    do
        local r = math.atan2(dy, dx)
        rx = rx - math.cos(r) * source.components.harvestable.reach / 2
        ry = ry - math.sin(r) * source.components.harvestable.reach / 2
    end

    if dx*dx + dy*dy > dr*dr then
        if worker.components.moveable and not worker.components.moveable.path then
            local path = pathfinder.path({wx, wy}, {rx, ry})
            worker.components.moveable.path = path
        end
    else
        if not job.timer then
            job.timer = 0
        end
        job.timer = job.timer + dt * worker.components.harvester.speed

        if job.timer >= source.components.harvestable.work_time then
            local amount = math.floor(job.timer / source.components.harvestable.work_time)
            amount = math.min(amount, source.components.harvestable.amount)
            job.timer = job.timer - source.components.harvestable.work_time

            local resource_name = entity_manager.load_blueprint(source.components.harvestable.resource).name
            local nearby_stacks = entity_manager.get_entities(nearby_stack_filter(resource_name, wx, wy))
            if #nearby_stacks > 0 then
                if #nearby_stacks > 1 then
                    table.sort(nearby_stacks, function(a, b)
                        local ax, ay = unpack(a.components.location.position)
                        local bx, by = unpack(b.components.location.position)
                        local dx_a, dy_a = ax - wx, ay - wy
                        local dx_b, dy_b = bx - wx, by - wy
                        return dx_a*dx_a + dy_a*dy_a < dx_b*dx_b + dy_b*dy_b
                    end)
                end
                local nearest_stack = nearby_stacks[1]
                if nearest_stack.components.resource.amount + amount > nearest_stack.components.resource.max_stack then
                    amount = amount - (nearest_stack.components.resource.max_stack - nearest_stack.components.resource.amount)
                    nearest_stack.components.resource.amount = nearest_stack.components.resource.max_stack

                    new_stack(source.components.harvestable.resource, amount, wx, wy)
                else
                    nearest_stack.components.resource.amount = nearest_stack.components.resource.amount + amount
                end
            else
                new_stack(source.components.harvestable.resource, amount, wx, wy)
            end

            source.components.harvestable.amount = source.components.harvestable.amount - amount

            system_manager.broadcast("onharvest", source, worker)

            if source.components.harvestable.amount <= 0 then
                next_job(job, worker)
                entity_manager.delete_entity(source)
            end
        end

    end

end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}