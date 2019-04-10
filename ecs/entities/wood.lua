local name = "wood"

local wood_image = love.graphics.newImage("res/gfx/tree.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        resource = {
            amount    = 1,
            unit_mass = 1,
        },
        renderable = {
            visible = true,
            texture = wood_image,
            colour  = {1, 1, 1},
        },
    }
}