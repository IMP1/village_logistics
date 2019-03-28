local name = "camera_2d"

return {
    name = name,
    components = {
        viewport = {
            bounds = {0, 0, love.graphics.getWidth(), love.graphics.getHeight()},
        },
        transform = {
            translation = {0, 0},
            scale       = 1,
            rotation    = 0,
        },
    }
}