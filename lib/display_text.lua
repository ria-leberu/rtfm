local display = {}
local words = {
    Fossilizing = 'Foss.', Breath = 'Br.', Lightning = 'Ltng.', Thunder = 'Thun.',
    Physical = 'Phys.', Magical = 'Mag.', Damage = 'Dmg', damage = 'dmg',
    Attack = 'ATK', Defense = 'DEF', Accuracy = 'ACC', Evasion = 'EVA',
    Resistance = 'Res.', Regeneration = 'Regen', Additional = 'Add.',
    Down = '-', Boost = '+', Increased = '+', Decreased = '-',
}
local tiers = { II = '2', III = '3', IV = '4', V = '5', VI = '6' }
local titles = { king = 'K.', queen = 'Q.', greater = 'Gr.', lesser = 'L.',
    lord = 'Ld.', lady = 'Ly.', ancient = 'Anc.', arch = 'Arch.' }

function display.mob(name)
    local shortened = name:gsub('^[Tt][Hh][Ee]%s+', ''):gsub('%s+[Tt][Hh][Ee]%s+.+$', '')
    local tokens = {}
    for token in shortened:gmatch('%S+') do tokens[#tokens + 1] = token end
    -- Keep the last word distinctive, including its punctuation and numerals.
    for i = 1, #tokens - 1 do
        local token = tokens[i]
        local initial = token:match('[%z\1-\127\194-\244][\128-\191]*')
        tokens[i] = titles[token:lower()] or (token:match('^%a%.$') and token)
            or (initial and (initial .. '.') or token)
    end
    return #tokens > 0 and table.concat(tokens, ' ') or name
end

function display.mob_names(...)
    local originals, result = {}, {}
    for _, rows in ipairs({ ... }) do
        for _, event in ipairs(rows) do
            local key = event.monster:lower()
            originals[key], result[key] = event.monster, display.mob(event.monster)
        end
    end
    -- Expansion can expose another collision, so continue until names are unique.
    local changed
    repeat
        changed = false
        local owners = {}
        for key, label in pairs(result) do
            local other = owners[label:lower()]
            if other and other ~= key then
                if result[key] ~= originals[key] then result[key], changed = originals[key], true end
                if result[other] ~= originals[other] then result[other], changed = originals[other], true end
            else owners[label:lower()] = key end
        end
    until not changed
    return result
end

function display.shorten(text)
    return (text:gsub('%a+', function(word) return words[word] or word end))
end

function display.action(event, compact, mob_names)
    local verbs = { readies = 'readies', casting = 'starts casting', uses = 'used', casts = 'cast' }
    if not compact then return event.monster .. ' ' .. verbs[event.action] .. ' ' .. event.move end
    local move = display.shorten(event.move)
    if event.action == 'casting' or event.action == 'casts' then
        move = move:gsub('%s+([IV]+)$', function(tier) return tiers[tier] or (' ' .. tier) end)
    end
    local verb = event.action == 'readies' and ' ~ ' or (event.action == 'casting' and ' cast~ ' or ': ')
    local monster = mob_names and mob_names[event.monster:lower()] or display.mob(event.monster)
    return monster .. verb .. move
end

return display
