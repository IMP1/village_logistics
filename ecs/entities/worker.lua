local name = "worker"

return {
    name = name,
    components = {
        selectable = {},
        harvester = {
            -- harvest speeds?
        },
        carrier = {
            -- resource limits?
        },
        moveable = {
            -- speed
            -- path
        },
        location = {
            position = {0, 0},
        },
        renderable = {
            visible = true,
            colour  = {1, 1, 1},
            texture = love.graphics.newImage("res/gfx/man.png"),
        },
    }
}