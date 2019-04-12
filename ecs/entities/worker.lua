local name = "worker"

return {
    name = name,
    components = {
        selectable = {
            priority = 10,
            size     = 32,       -- radius around location
            offset   = {0, 24}, -- from location in world
        },
        harvester = {
            -- harvest speeds?
        },
        carrier = {
            max_weight = 2, -- kg
            -- resource limits?
        },
        producer = {
            -- work speed?
        },
        moveable = {
            -- speed
            -- path
        },
        location = {
            position = {100, 100, 1},
        },
        renderable = {
            visible = true,
            colour  = {1, 1, 1},
            texture = love.graphics.newImage("res/gfx/worker_male.png"),
            quad    = love.graphics.newQuad(32, 0, 32, 48, 96, 192),
            offset  = {16, 48},
        },
    }
}