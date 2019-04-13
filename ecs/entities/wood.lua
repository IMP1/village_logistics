local name = "wood"

local wood_image = love.graphics.newImage("res/gfx/planks.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        resource = {
            amount    = 1,   -- number of units in this stack
            unit_mass = 1,   -- kg per unit
            max_stack = 100, -- max number of units that can be in this stack.
        },
        renderable = {
            visible = true,
            texture = wood_image,
            quad    = love.graphics.newQuad(0, 0, 32, 32, 32 ,64),
            colour  = {1, 1, 1},
            offset  = {16, 16},
        },
        selectable = {
            priority = 2,
            size     = 24,     -- radius around location
            offset   = {0, 0}, -- from location in world
        },
    }
}