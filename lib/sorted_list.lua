local sorted_list = {
    _VERSION     = 'v0.1.0',
    _DESCRIPTION = 'An ordered list-type table for lua.',
    _URL         = '',
    _LICENSE     = [[
        MIT License

        Copyright (c) 2017 Huw Taylor

        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:

        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    ]]
}

local sorted_list_mt = {}

local DEFAULT_FUNCTION = function(a, b) return a < b end

local sort_functions = {}

local normal_insert = false

local function insert(list, _, value)
    if value == nil then
        value = _
    end
    local func = sort_functions[list] or DEFAULT_FUNCTION
    local index = 1
    local obj = list[index]
    while obj ~= nil do
        if func(obj, value) then
            index = index + 1
            obj = list[index]
        else
            obj = nil
        end
    end
    normal_insert = true
    table.insert(list, index, value)
    normal_insert = false
end

local table_insert = table.insert
function table.insert(table, ...)
    if getmetatable(table) == sorted_list_mt and not normal_insert then
        insert(table, ...)
    else
        table_insert(table, ...)
    end
end

function sorted_list.new(initial_values, func)
    local key = {}
    setmetatable(key, sorted_list_mt)

    sort_functions[key] = func

    if initial_values then
        for _, val in ipairs(initial_values) do
            insert(key, _, val)
        end
    end

    return key
end

return sorted_list
