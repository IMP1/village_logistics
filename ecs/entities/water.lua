local name = "tree"

return {
    name = name,
    components = {
        location = {
            position = {0, 0},
        },
        renderable = {
            visible = true,
            texture = love.graphics.newImage("res/gfx/water.png"),
            colour  = {1, 1, 1},
        },
        fluid = {
            depth     = 0,
            origin    = nil,
            is_source = false,
        },
    },
}