local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "job_harvest_handler"

local filter = entity_manager.component_filter("location", "harvester", "job_harvest")

local function update(system, worker, dt)
    local job = worker.components.job_harvest
    local source = entity_manager.get_entity(job.resource_entity)
    local wx, wy = unpack(worker.components.location.position)
    local rx, ry = unpack(source.components.location.position)

    local dx = wx - rx
    local dy = wy - ry
    local dr = source.components.harvestable.reach

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

            -- @TODO: check for near enough existing resource of same type and add to that stack.

            local resource_id = entity_manager.load_entity(source.components.harvestable.resource)
            local resource = entity_manager.get_entity(resource_id)

            resource.components.resource.amount = amount
            resource.components.location.position = {unpack(worker.components.location.position)}
            source.components.harvestable.amount = source.components.harvestable.amount - amount

            system_manager.broadcast("onharvest", source, worker)

            -- @TODO: what when runs out? 
            --        replace this job with one to go to nearest entity of same resource type and harvest that.
        end

    end

end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}