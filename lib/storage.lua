local storage = {}

local function serialize(value)
    if type(value) == 'string' then return string.format('%q', value) end
    if type(value) == 'boolean' or type(value) == 'number' then return tostring(value) end
    assert(type(value) == 'table', 'Unsupported saved value')
    local keys, lines = {}, { '{\n' }
    for key in pairs(value) do table.insert(keys, key) end
    table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
    for _, key in ipairs(keys) do
        table.insert(lines, '[' .. serialize(key) .. '] = ' .. serialize(value[key]) .. ',\n')
    end
    table.insert(lines, '}')
    return table.concat(lines)
end

local function exists(path)
    local file = io.open(path, 'r')
    if not file then return false end
    file:close()
    return true
end

function storage.load(path)
    for _, candidate in ipairs({ path, path .. '.bak' }) do
        if exists(candidate) then
            local chunk, err = loadfile(candidate)
            if chunk then
                setfenv(chunk, {})
                local ok, value = pcall(chunk)
                if ok and type(value) == 'table' then return value end
                err = value
            end
            print('[RTFM] Unable to load ' .. candidate .. ': ' .. tostring(err))
        end
    end
    return {}
end

-- Windows rename cannot replace an existing file. Keep the previous save as a
-- backup, and restore it if installing the fully written temporary file fails.
function storage.save(path, value)
    local ok, result = pcall(function()
        local content = 'return ' .. serialize(value) .. '\n'
        local temporary = path .. '.tmp'
        local file, err = io.open(temporary, 'w')
        if not file then error(err) end
        local written, write_err = file:write(content)
        local closed, close_err = file:close()
        if not written or not closed then error(write_err or close_err) end
        local had_original = exists(path)
        if had_original then
            if exists(path .. '.bak') then assert(os.remove(path .. '.bak')) end
            assert(os.rename(path, path .. '.bak'))
        end
        local installed, install_err = os.rename(temporary, path)
        if not installed then
            if had_original then os.rename(path .. '.bak', path) end
            error(install_err)
        end
        return true
    end)
    if not ok then print('[RTFM] Save failed: ' .. tostring(result)) end
    return ok
end

return storage
