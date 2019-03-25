local Scene = {}
Scene.__index = Scene
function Scene:__tostring()
    return "Scene " .. self.name
end

function Scene.new(name)
    local self = {}
    setmetatable(self, Scene)
    self.name = name
    return self
end

function Scene:load()
end

function Scene:keyPressed(key, isRepeat)
end

function Scene:keyReleased(key, isRepeat)
end

function Scene:keyTyped(text)
end

function Scene:mousePressed(mx, my, key)
end

function Scene:mouseReleased(mx, my, key)
end

function Scene:update(dt, mx, my)
end

function Scene:draw()
end

function Scene:close()
end

return Scene