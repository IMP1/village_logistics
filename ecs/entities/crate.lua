local name = "crate"

local crate_image = love.graphics.newImage("res/gfx/crate.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        selectable = {
            priority = 4,
            size     = 32,     -- radius around location
            offset   = {0, 0}, -- from location in world
        },
        renderable = {
            visible = true,
            texture = crate_image,
            colour  = {1, 1, 1},
            offset  = {16, 20},
        },
        container = {
            stacks     = 4,
            inventory  = {}, -- list of {resource="", amount=0}
            stack_size = 1,
            -- filters?
        },
    }
}