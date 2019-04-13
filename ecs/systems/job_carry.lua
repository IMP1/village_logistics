local pathfinder     = require 'lib.pathfinder'
local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "job_carry_handler"

local filter = entity_manager.component_filter("location", "resource", "job_carry")

local function next_job(last_job, worker)

end


local function update(system, worker, dt)
    
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}