
local name = "player"

return {
    name = name,
    components = {
        player = {},
        location = {
            position = {0, 0},
        },
        renderable = {
            visible   = true,
            colour    = {1, 0, 0},
            character = "@",
        },
    }
}