local data = require('data.generated.browser')
local catalogue = require('data.catalogue')
local names = require('lib.names')
local browser = {}
local spell_names = require('data.generated.spells')
local spell_targets = {}
local known_spells = {}
for id, name in pairs(spell_names) do
    local key = names.normalize(name)
    if not known_spells[key] then
        local entry = { name = name, spell_id = id, kind = 'spell' }
        spell_targets[#spell_targets + 1] = entry
        known_spells[key] = entry
    end
end
local groups = {}
local raw_groups = {}
for _, group in ipairs(data.families) do
    raw_groups[group.family_id] = group
    for _, member in ipairs(group.members) do
        local key = names.normalize(member)
        groups[key] = groups[key] or {}
        groups[key][group.family_id] = true
    end
end
for _, addition in ipairs(require('data.notorious_additions')) do
    local existing
    for _, monster in ipairs(data.monsters) do
        if names.normalize(monster.name) == names.normalize(addition.name) then existing = monster; break end
    end
    local group = raw_groups[addition.skill_list_id]
    if group then
        if existing then
            existing.notorious = true
        else
            data.monsters[#data.monsters + 1] = { name = addition.name, aliases = addition.aliases,
                moves = group.moves, spells = addition.spells or {}, notorious = true, reviewed_addition = true }
        end
        for _, alias in ipairs(addition.aliases) do
            local key = names.normalize(alias)
            groups[key] = groups[key] or {}
            groups[key][addition.skill_list_id] = true
        end
    end
end
for member, ids in pairs(require('data.family_members')) do
    local key = names.normalize(member)
    groups[key] = groups[key] or {}
    for _, id in ipairs(ids) do
        groups[key][id] = true
        if raw_groups[id] then raw_groups[id].members[#raw_groups[id].members + 1] = member end
    end
end
local common_families = {}
local common_by_group = {}
local notorious_names = {}
for _, monster in ipairs(data.monsters) do
    if monster.notorious then
        notorious_names[names.normalize(monster.name)] = true
        for _, alias in ipairs(monster.aliases) do notorious_names[names.normalize(alias)] = true end
    end
end
for label, ids in pairs(require('data.family_categories')) do
    local moves, members = {}, {}
    for _, id in ipairs(ids) do
        local group = raw_groups[id]
        if group then
            for _, move in ipairs(group.moves) do moves[move] = true end
            for _, member in ipairs(group.members) do members[member] = true end
        end
    end
    local target = { name = label, family_id = ids[1], family_ids = ids, moves = {}, members = {} }
    for move in pairs(moves) do target.moves[#target.moves + 1] = move end
    for member in pairs(members) do target.members[#target.members + 1] = member end
    table.sort(target.moves)
    table.sort(target.members)
    common_families[#common_families + 1] = target
    for _, id in ipairs(ids) do common_by_group[id] = target end
end

function browser.groups_for(monster)
    return groups[names.normalize(monster)] or {}
end

function browser.family_rule_for(event)
    local monster, move = names.normalize(event.monster), names.normalize(event.move)
    if notorious_names[monster] then return nil end
    local chosen
    for id in pairs(groups[monster] or {}) do
        local family = common_by_group[id]
        if family then
            for _, move_id in ipairs(family.moves) do
                if catalogue[move_id] and names.normalize(catalogue[move_id].name) == move then
                    if chosen and chosen ~= family then return nil end
                    chosen = family
                end
            end
        end
    end
    if chosen then
        return { monster = chosen.name, move = event.move, scope = 'family',
            family_id = chosen.family_id, family_ids = chosen.family_ids }
    end
end

function browser.search(scope, query)
    local result = {}
    query = names.trim(query or ''):lower()
    local source = scope == 'spell' and spell_targets or (scope == 'family' and common_families or data.monsters)
    for _, entry in ipairs(source) do
        local eligible = scope ~= 'notorious' or entry.notorious == true
        local matches = eligible and entry.name:lower():find(query, 1, true) ~= nil
        if not matches and scope ~= 'family' then
            for _, alias in ipairs(entry.aliases or {}) do
                if eligible and alias:lower():find(query, 1, true) then matches = true; break end
            end
        end
        if matches then result[#result + 1] = entry end
    end
    table.sort(result, function(a, b) return a.name:lower() < b.name:lower() end)
    return result
end

function browser.moves_for(target, query)
    local result, seen = {}, {}
    local function signature(entry)
        local function statuses(values)
            local copy = {}
            for _, id in ipairs(values or {}) do copy[#copy + 1] = id end
            table.sort(copy)
            return table.concat(copy, ',')
        end
        return table.concat({ entry.damage or '', entry.area or '', entry.note or '',
            statuses(entry.statuses), statuses(entry.self_statuses) }, '|')
    end
    query = names.trim(query or ''):lower()
    for _, id in ipairs(target.moves) do
        local entry = catalogue[id]
        if entry and entry.name:lower():find(query, 1, true) then
            local key = names.normalize(entry.name)
            local move = seen[key]
            if move then
                move.variant_ids[#move.variant_ids + 1] = id
                if signature(move.description) ~= signature(entry) then move.varies = true end
            else
                move = { id = id, name = entry.name, description = entry, variant_ids = { id } }
                result[#result + 1] = move
                seen[key] = move
            end
        end
    end
    for _, id in ipairs(target.spells or {}) do
        local name = spell_names[id]
        if name and name:lower():find(query, 1, true) and not seen['spell:' .. names.normalize(name)] then
            seen['spell:' .. names.normalize(name)] = true
            result[#result + 1] = { id = id, name = name, kind = 'spell', variant_ids = { id } }
        end
    end
    table.sort(result, function(a, b)
        if a.name == b.name then return a.id < b.id end
        return a.name:lower() < b.name:lower()
    end)
    return result
end

function browser.rule(target, move, scope)
    return { monster = target.name, move = move.name,
        scope = scope == 'family' and 'family' or nil,
        family_id = scope == 'family' and target.family_id or nil,
        family_ids = scope == 'family' and target.family_ids or nil,
        kind = move.kind,
        aliases = scope ~= 'family' and target.aliases or nil }
end

return browser
