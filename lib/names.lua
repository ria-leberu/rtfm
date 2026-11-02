local names = {}

function names.trim(value)
    return (value:gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Keep numerals and meaningful punctuation (e.g. Fire II and -EX).
function names.normalize(value)
    value = names.trim(value or ''):lower():gsub('^the%s+', '')
    return (value:gsub('’', "'"):gsub("'", ''):gsub('%s+', ''))
end

function names.map(values)
    local result = {}
    for key, value in pairs(values) do
        result[names.normalize(key)] = value
    end
    return result
end

return names
