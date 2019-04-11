local name = "woodcutter"

-- local building_image = love.graphics.newImage("res/gfx/tree_stages.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        renderable = {
            visible = true,
            texture = tree_image,
            quad    = love.graphics.newQuad(0, 0, 32, 48, 32, 144),
            colour  = {1, 1, 1},
        },
        producer = {
            recipes = {
                {
                    inputs = {
                        { resource = "wood", amount = 2 }
                    }
                    outputs = {
                        { resource = "logs", amount = 1 }
                    }
                    work_time = 1 -- seconds
                },
                {
                    inputs = {
                        { resource = "wood", amount = 2 }
                    }
                    outputs = {
                        { resource = "planks", amount = 1 }
                    }
                    work_time = 1 -- seconds
                },
            }
        },
        container = {}, -- @TODO: stacks, amounts, etc.
    }
}