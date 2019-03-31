local name = "water"

return {
    name = name,
    components = {
        location = {
            position = {0, 0},
        },
        renderable = {
            visible = true,
            texture = love.graphics.newImage("res/gfx/tileset.png"),
            quad    = love.graphics.newQuad(128, 0, 32, 32, 128, 128),
            colour  = {1, 1, 1},
        },
        fluid = {
            depth     = 0,
            origin    = nil,
            is_source = false,
        },
    },
}