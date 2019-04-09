local name = "debug_console"

return {
    name = name,
    components = {
        viewport = {
            bounds = {0, love.graphics.getHeight() - 48, love.graphics.getWidth(), 48},
        },
    }
}