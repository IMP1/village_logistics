local name = "tree"

local tree_image = love.graphics.newImage("res/gfx/tree_stages.png")

return {
    name = name,
    components = {
        location = {
            position = {0, 0},
        },
        renderable = {
            visible = true,
            texture = tree_image,
            quad    = love.graphics.newQuad(0, 0, 32, 48, 32, 144),
            colour  = {1, 1, 1},

        },
        harvestable = {
            resource   = "wood",
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