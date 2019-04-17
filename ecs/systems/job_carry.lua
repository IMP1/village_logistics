local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "job_carry_handler"

local filter = entity_manager.component_filter("location", "moveable", "carrier", "job_carry")

local function job_finished(worker)
    entity_manager.remove_component(worker, "job_carry")
end

local function is_at(worker, position)

end

local PICKUP_TIMER = 0.5
local PUTDOWN_TIMER = 0.5

local function update(system, worker, dt)
    local job = worker.components.job_carry
    local source = entity_manager.get_entity(job.source)
    local target = entity_manager.get_entity(job.target)

    if source == nil and not job.returning then
        job_finished(worker)
        return
    end
    if target == nil and job.returning then
        job_finished(worker)
        return
    end

    if is_at(worker, source.components.location.position) then
        -- @TODO: work out how much more worker can carry
        -- @TODO: if cannot carry any more, then go to target.
        if source.components.resource.amount > 0 then
            job.pickup_timer = job.pickup_timer + dt * worker.components.carrier.pickup_speed
            if job.pickup_timer >= PICKUP_TIMER then
                job.pickup_timer = job.pickup_timer - PICKUP_TIMER
                -- if can carry item
                    -- pick up item
            end
        end
        if source.components.resource.amount <= 0 then
            -- delete it
        end
        return
    end
    
    if is_at(worker, target.components.location.position) then
        -- do equivilent of picking up for putting down
        return
    end

    if worker.components.moveable and not worker.components.moveable.path then
        local wx, wy = unpack(worker.components.location.position)
        local destination
        if job.returning then
            destination = target
        else
            destination = source
        end
        local x, y = unpack(destination.components.location.position)
        local path = pathfinder.path({wx, wy}, {x, y})
        worker.components.moveable.path = path
    end
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}
