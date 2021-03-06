local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "job_carry_handler"

local filter = entity_manager.component_filter("location", "moveable", "container", "conveyor", "job_carry")

local function job_finished(worker)
    entity_manager.remove_component(worker, "job_carry")
end

local DEFAULT_DISTANCE_LEEWAY = 32
local function is_at(worker, position, leeway)
    local wx, wy = unpack(worker.components.location.position)
    local x, y = unpack(position)
    local dx, dy = x - wx, y - wy
    local dr = leeway or DEFAULT_DISTANCE_LEEWAY
    return dx * dx + dy * dy < dr * dr
end

local PICKUP_TIMER = 0.5
local PUTDOWN_TIMER = 0.5

local function pick_up(worker, job, source, target, dt)
    local resource = source.components.resource
    local carrier_container = worker.components.container

    local max_stack = math.floor(resource.max_stack * carrier_container.stack_size)

    local first_stack_with_room = 0
    local room_for_resource = 0
    for i = carrier_container.stacks, 1, -1 do
        local stack = carrier_container.inventory[i]
        if stack == nil then
            first_stack_with_room = i
            room_for_resource = room_for_resource + max_stack
        elseif stack.resource == resource.name then
            first_stack_with_room = i
            room_for_resource = room_for_resource + math.max(0, max_stack - stack.amount)
        end
    end
    local resource_stack = carrier_container.inventory[first_stack_with_room]

    if room_for_resource <= 0 then
        if not worker.components.moveable.path then
            local wx, wy = unpack(worker.components.location.position)
            local x, y = unpack(target.components.location.position)
            local path = pathfinder.path({wx, wy}, {x, y})
            worker.components.moveable.path = path
            job.returning = true
        end
    
    elseif resource.amount > 0 then
        if resource_stack == nil then
            resource_stack = { resource = resource.name, amount = 0}
            worker.components.container.inventory[first_stack_with_room] = resource_stack
        end
        job.pickup_timer = job.pickup_timer + dt * worker.components.conveyor.pickup_speed
        if job.pickup_timer >= PICKUP_TIMER then
            job.pickup_timer = job.pickup_timer - PICKUP_TIMER
            resource.amount = resource.amount - 1
            resource_stack.amount = resource_stack.amount + 1
            if not job.resource_name then
                job.resource_name = resource.name
            end
            print("picking up " .. job.resource_name)
        end
    end

    if resource.amount <= 0 then
        entity_manager.delete_entity(source)
        job.returning = true
    end
end

local function put_down(worker, job, source, target, dt)
    local container = target.components.container
    
    local amount_carried = 0
    local stack_carrying = 0
    for i = worker.components.container.stacks, 1, -1 do
        local stack = worker.components.container.inventory[i]
        if stack and stack.resource == job.resource_name then
            amount_carried = amount_carried + stack.amount
            stack_carrying = i
        end
    end

    local resource = entity_manager.load_blueprint(job.resource_name).components.resource
    local resource_stack = worker.components.container.inventory[stack_carrying]

    local first_stack_with_room = 0
    local room_for_resource = 0
    for i = container.stacks, 1, -1 do
        local stack = container.inventory[i]
        if stack == nil then
            first_stack_with_room = i
            room_for_resource = room_for_resource + resource.max_stack * container.stack_size
        elseif stack.resource == resource.name then
            first_stack_with_room = i
            room_for_resource = room_for_resource + math.max(0, (resource.max_stack * container.stack_size) - stack.amount)
        end
    end
    local container_stack = container.inventory[first_stack_with_room]

    if room_for_resource <= 0 then
        job_finished(worker)

    elseif amount_carried <= 0 then
        job.returning = false

    else
        if container_stack == nil then
            container_stack = { resource = resource.name, amount = 0}
            container.inventory[first_stack_with_room] = container_stack
        end
        job.putdown_timer = job.putdown_timer + dt * worker.components.conveyor.putdown_speed
        if job.putdown_timer >= PUTDOWN_TIMER then
            job.putdown_timer = job.putdown_timer - PUTDOWN_TIMER
            resource_stack.amount = resource_stack.amount - 1
            container_stack.amount = container_stack.amount + 1
            print("putting down " .. job.resource_name)
        end

    end

end

local function move(worker, job, source, target)
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

    if not job.returning and is_at(worker, source.components.location.position) then
        pick_up(worker, job, source, target, dt)

    elseif job.returning and is_at(worker, target.components.location.position) then
        put_down(worker, job, source, target, dt)

    elseif worker.components.moveable and not worker.components.moveable.path then
        move(worker, job, source, target)
    end
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}
