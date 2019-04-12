local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'

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

        print("too far away: pathing...")
        

        -- @TODO: path to the object.
    else
        if not job.timer then
            job.timer = 0
        end
        job.timer = job.timer + dt * worker.components.harvester.speed

        if job.timer >= source.components.harvestable.work_time then
            local amount = math.floor(job.timer / source.components.harvestable.work_time)
            job.timer = job.timer - source.components.harvestable.work_time

            local resource_id = entity_manager.load_entity(source.components.harvestable.resource)
            local resource = entity_manager.get_entity(resource_id)

            resource.components.resource.amount = amount
            resource.components.location.position = unpack(worker.components.location.position)

        end

    end

end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}