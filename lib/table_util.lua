function table.filter(t, func)
    local out = {}
    for i, elem in pairs(t) do
        if func(elem, i) then
            table.insert(out, elem)
        end
    end
    return out
end

