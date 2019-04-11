local entity_manager = require 'ecs.entity_manager'
local system_manager = require 'ecs.system_manager'

local name = "debugger"

local debugger_entity_id = entity_manager.load_entity("ecs/entities/debug_console.lua")
local console_command    = ""
local console_enabled    = false
local mouse_position     = { 0, 0 }

local messages_visible   = false
local max_debug_lines    = 12
local debug_messages     = {}

local function update_mouse_position(system, wx, wy)
    mouse_position = {wx, wy}
end

local function draw_console()
    local w = love.graphics.getWidth()
    local h = 32
    local x = 0
    local y = love.graphics.getHeight() - 32
    love.graphics.setColor(0, 0, 0, 0.5)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(1, 1, 1)
    local lh = (h - love.graphics.getFont():getHeight()) / 2
    love.graphics.print(console_command .. "_", x+lh, y+lh)
end

local function textinput(system, text)
    if console_enabled and text ~= "`" then
        console_command = console_command .. text
    end
end

local function interpret_argument(arg)
    return arg
end

local function perform_command()
    local args = {}
    for substring in console_command:gmatch("%S+") do
        local arg = interpret_argument(substring)
        table.insert(args, arg)
    end
    local command = args[1]
    table.remove(args, 1)
    -- @TODO: check if valid command?
    print(command, unpack(args))
    system_manager.broadcast("command_" .. command, unpack(args))
    console_command = ""
    if not love.keyboard.isDown("lshift") then
        entity_manager.remove_component(debugger_entity_id, "gui")
        console_enabled = false
    end
end

local function keypressed(system, key)
    if key == "`" then
        if console_enabled then
            entity_manager.remove_component(debugger_entity_id, "gui")
        else
            entity_manager.add_component(debugger_entity_id, "gui", {
                draw = draw_console,
            })
        end
        console_enabled = not console_enabled
    elseif console_enabled then
        if key == "backspace" then
            console_command = console_command:sub(1, console_command:len()-1)
        end
        if key == "return" or key == "enter" then
            perform_command()
        end
    elseif key == "tab" then
        messages_visible = not messages_visible
    end
end

local function spawn_object(system, object_name, ...)
    local x, y = unpack(mouse_position)
    local obj_id = entity_manager.load_entity("ecs/entities/" .. object_name .. ".lua")
    entity_manager.get_entity(obj_id).components.location.position = {x, y}

    for k, v in pairs(entity_manager.get_entity(obj_id).components) do
        print(k)
    end
end

local function meta_debug(system, command, ...)
    local args = {...}
    if command == "lines" then
        max_debug_lines = args[1]
    end
end

local function debug_message(system, ...)
    local message = ""
    for _, msg in ipairs({...}) do
        message = message .. tostring(msg) .. " "
    end
    table.insert(debug_messages, message)
end

local function draw(system)
    if messages_visible then
        love.graphics.setColor(1, 1, 1)
        local offset = math.max(0, #debug_messages - max_debug_lines)
        for i, line in ipairs(debug_messages) do
            love.graphics.print(line, 0, (i-1-offset) * 16)
        end
    end
end

return {
    name    = name,
    filters = { 
        textinput  = entity_manager.filter_none,
        keypressed = entity_manager.filter_none,
        onmove     = entity_manager.filter_none,

        command_spawn = entity_manager.filter_none,
        command_debug = entity_manager.filter_none,
        debug_message = entity_manager.filter_none,
        draw          = entity_manager.filter_none,
    },
    events  = { 
        textinput  = textinput,
        keypressed = keypressed,
        onmove     = update_mouse_position,

        command_spawn = spawn_object,
        command_debug = meta_debug,
        debug_message = debug_message,
        draw          = draw,
    },
}