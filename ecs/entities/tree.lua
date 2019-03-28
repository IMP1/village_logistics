local name = "tree"

return {
    name = name,
    components = {
        location = {
            position = {0, 0},
        },
        renderable = {
            visible = true,
            texture = love.graphics.newImage("res/gfx/tree_stages.png"),
            quad    = love.graphics.newQuad(0, 0, 32, 32, 64, 96),
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
                    quad = love.graphics.newQuad(0, 0, 32, 32, 64, 96),
                },
                {
                    count = 30,
                    image = tree_image,
                    quad = love.graphics.newQuad(0, 32, 32, 32, 64, 96),
                },
                {
                    count = 0,
                    image = tree_image,
                    quad = love.graphics.newQuad(0, 64, 32, 32, 64, 96),
                },
            },
            current_stage = 1,
        },
    }
}