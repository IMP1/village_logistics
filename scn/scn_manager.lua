local SceneManager = {}

function SceneManager.hook()
    for event_name, func in pairs(love.handlers) do
        if SceneManager[event_name] then
            love.handlers[event_name] = function(...)
                func(...)
                SceneManager[event_name](...)
            end
        end
    end
end

local current_scene = nil
local scene_stack = {}

local function closeScene()
    if current_scene then
        current_scene:close()
    end
end

local function loadScene()
    if current_scene then
        current_scene:load()
    end
end

function SceneManager.scene()
    return current_scene
end

function SceneManager.peekScene()
    return scene_stack[#scene_stack]
end

function SceneManager.clearTo(new_scene)
    while current_scene do
        SceneManager.popScene()
    end
    SceneManager.pushScene(new_scene)
end

function SceneManager.setScene(new_scene)
    closeScene()
    current_scene = new_scene
    loadScene()
end

function SceneManager.pushScene(new_scene)
    table.insert(scene_stack, current_scene)
    current_scene = new_scene
    loadScene()
end

function SceneManager.popScene()
    closeScene()
    current_scene = table.remove(scene_stack)
end

------------------------------------------------
-- Methods to pass along to relevant scene(s) --
------------------------------------------------
function SceneManager.keypressed(key, is_repeat)
    if current_scene and current_scene.keyPressed then 
        current_scene:keyPressed(key, is_repeat)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundKeypressed and scene ~= current_scene then
            scene:backgroundKeyPressed(key, is_repeat)
        end
    end
end

function SceneManager.textinput(text)
    if current_scene and current_scene.keyTyped then
        current_scene:keyTyped(text)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundKeyTyped and scene ~= current_scene then
            scene:backgroundKeyTyped(text)
        end
    end
end

function SceneManager.mousepressed(mx, my, key)
    if current_scene and current_scene.mousePressed then
        current_scene:mousePressed(mx, my, key)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMousePressed and scene ~= current_scene then
            scene:backgroundMousePressed(mx, my, key)
        end
    end
end

function SceneManager.mousereleased(mx, my, key)
    if current_scene and current_scene.mouseReleased then
        current_scene:mouseReleased(mx, my, key)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMouseReleased and scene ~= current_scene then
            scene:backgroundMouseReleased(mx, my, key)
        end
    end
end

function SceneManager.wheelmoved(mx, my, dx, dy)
    if current_scene and current_scene.mouseScrolled then
        current_scene:mouseScrolled(mx, my, dxm, dy)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundMouseScrolled and scene ~= current_scene then
            scene:backgroundMouseScrolled(mx, my, dxm, dy)
        end
    end
end

function SceneManager.update(dt)
    local mx, my = love.mouse.getPosition()
    if current_scene and current_scene.update then
        current_scene:update(dt, mx, my)
    end
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundUpdate and scene ~= current_scene then
            scene:backgroundUpdate(dt, mx, my)
        end
    end
end

function SceneManager.draw()
    for _, scene in pairs(scene_stack) do
        if scene and scene.backgroundDraw and scene ~= current_scene then
            scene:backgroundDraw()
        end
    end
    if current_scene and current_scene.draw then
        current_scene:draw()
    end
end

return SceneManager