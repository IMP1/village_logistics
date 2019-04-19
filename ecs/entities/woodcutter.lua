local name = "woodcutter"

local building_image = love.graphics.newImage("res/gfx/woodcutter.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        selectable = {
            priority = 6,
            size     = 128,       -- radius around location
            offset   = {0, 0}, -- from location in world
        },
        renderable = {
            visible = true,
            texture = building_image,
            colour  = {1, 1, 1},
            offset  = {120, 96},
        },
        production = {
            recipes = {
                {
                    inputs = {
                        { resource = "wood", amount = 2 }
                    },
                    outputs = {
                        { resource = "logs", amount = 1 }
                    },
                    work_time = 1, -- seconds
                },
                {
                    inputs = {
                        { resource = "wood", amount = 2 }
                    },
                    outputs = {
                        { resource = "planks", amount = 1 }
                    },
                    work_time = 1, -- seconds
                },
            }
        },
        container = {}, -- @TODO: stacks, amounts, etc.
    }
}