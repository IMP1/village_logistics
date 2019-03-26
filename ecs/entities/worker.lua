
local name = "worker"

return {
    name = name,
    components = {
        worker = {}, -- TODO: rethink this
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