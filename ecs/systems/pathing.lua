local entity_manager = require 'ecs.entity_manager'

local name = "pathing"

local filter = entity_manager.component_filter("location", "moveable")

local function is_at()
end

local function update(system, entity, dt)
    if entity.components.moveable.path then
        local speed = entity.components.moveable.speed

    end
end

return {
    name    = name,
    filters = { update = filter },
    events  = { update = update },
}

-- FROM OTHER GAME (https://github.com/IMP1/sapphire_shadows/blob/master/cls_person.lua)

break here this shouldn't = work'

local function update_movement(self, dt)
    local next_point = self.path[1]
    if not self:is_turned_towards(next_point) then
        self:turn_towards(next_point, self.turn_speed, dt)
        return
    end

    if self:is_at(next_point[1], next_point[2], 5) then
        table.remove(self.path, 1)
        if #self.path == 0 then
            self.path = nil
        end
    else
        self:move_towards(next_point, self:speed(), dt)
    end
end


function Person:is_at(x, y, epsilon)
    return (x - self.position[1])^2 + (y - self.position[2])^2 <= (epsilon or 1)^2
end

function Person:move_towards(position, speed, dt)
    local ox, oy = self:get_position()
    local dx = position[1] - ox
    local dy = position[2] - oy
    local r = math.atan2(dy, dx)
    local mx = speed * dt * math.cos(r)
    local my = speed * dt * math.sin(r)
    self.position = {ox + mx, oy + my}
end