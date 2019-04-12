local name = "tree"

local tree_image = love.graphics.newImage("res/gfx/tree_stages.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0, 1},
        },
        selectable = {
            priority = 1,
            size     = 32,      -- radius around location
            offset   = {0, 24}, -- from location in world
        },
        renderable = {
            visible = true,
            texture = tree_image,
            colour  = {1, 1, 1},
            quad    = love.graphics.newQuad(0, 0, 32, 48, 32, 144),
            offset  = {16, 48},
        },
        harvestable = {
            resource   = "ecs/entities/wood.lua",
            reach      = 32,
            max_amount = 100,
            amount     = 100,
            work_time  = 0.5, -- seconds / amount
            on_exhaust = function() end,
            stages     = {
                {
                    count = 80,
                    image = tree_image,
                    quad = love.graphics.newQuad(0, 0, 32, 48, 32, 144),
                },
                {
                    count = 30,
                    image = tree_image,
                    quad = love.graphics.newQuad(0, 48, 32, 48, 32, 144),
                },
                {
                    count = 0,
                    image = tree_image,
                    quad = love.graphics.newQuad(0, 96, 32, 48, 32, 144),
                },
            },
            current_stage = 1,
        },
    }
}
