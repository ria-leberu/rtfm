local data = require('data.generated.browser')
local catalogue = require('data.catalogue')
local names = require('lib.names')
local overrides = require('data.moves')
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
local reviewed_moves = require('data.notorious_moves')
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
    local moves = reviewed_moves(addition)
    if #moves > 0 then
        if existing then
            existing.notorious = true
            existing.moves = moves
            existing.spells = addition.spells or existing.spells
            local aliases = {}
            for _, alias in ipairs(existing.aliases or {}) do aliases[names.normalize(alias)] = true end
            existing.aliases = existing.aliases or {}
            for _, alias in ipairs(addition.aliases) do
                if not aliases[names.normalize(alias)] then
                    existing.aliases[#existing.aliases + 1] = alias
                    aliases[names.normalize(alias)] = true
                end
            end
        else
            data.monsters[#data.monsters + 1] = { name = addition.name, aliases = addition.aliases,
                moves = moves, spells = addition.spells or {}, notorious = true, reviewed_addition = true }
        end
        for _, alias in ipairs(addition.aliases) do
            local key = names.normalize(alias)
            groups[key] = groups[key] or {}
            for _, id in ipairs(addition.skill_list_ids or { addition.skill_list_id }) do groups[key][id] = true end
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
            local monster_overrides = overrides[names.normalize(target.name)]
            local description = monster_overrides and monster_overrides[key] or entry
            local move = seen[key]
            if move then
                move.variant_ids[#move.variant_ids + 1] = id
                if signature(move.description) ~= signature(description) then move.varies = true end
            else
                move = { id = id, name = entry.name, description = description, variant_ids = { id } }
                result[#result + 1] = move
                seen[key] = move
            end
        end
    end
    table.sort(result, function(a, b)
        if a.name == b.name then return tostring(a.id) < tostring(b.id) end
        return a.name:lower() < b.name:lower()
    end)
    return result
end

-- Build once; queries search all scopes regardless of the active browse tab.
-- A move hit retains its owner so selecting it opens the correct tracking rule.
local search_records
function browser.search_all(query)
    if not search_records then
        search_records = {}
        local function add(target, scope)
            search_records[#search_records + 1] = { target = target, scope = scope }
            if target.moves then
                local seen = {}
                for _, id in ipairs(target.moves) do
                    local move = catalogue[id]
                    if move and not seen[names.normalize(move.name)] then
                        seen[names.normalize(move.name)] = true
                        search_records[#search_records + 1] = { target = target, scope = scope, move = move.name }
                    end
                end
            end
        end
        for _, target in ipairs(common_families) do add(target, 'family') end
        local known, additional = {}, {}
        for _, target in ipairs(data.monsters) do
            known[names.normalize(target.name)] = true
            for _, alias in ipairs(target.aliases or {}) do known[names.normalize(alias)] = true end
            add(target, target.notorious and 'notorious' or 'monster')
        end
        -- Reviewed family members can be absent from imported mob pools.
        for _, family in ipairs(common_families) do
            for _, member in ipairs(family.members) do
                local key = names.normalize(member)
                if not known[key] then
                    local target = additional[key] or { name = member, moves = {}, seen = {} }
                    additional[key] = target
                    for _, id in ipairs(family.moves) do
                        if not target.seen[id] then target.moves[#target.moves + 1], target.seen[id] = id, true end
                    end
                end
            end
        end
        for _, target in pairs(additional) do target.seen = nil; add(target, 'monster') end
        for _, target in ipairs(spell_targets) do add(target, 'spell') end
    end
    local result = {}
    local key = names.normalize(query)
    if key == '' then return result end
    for _, record in ipairs(search_records) do
        local target = record.target
        local matches = names.normalize(record.move or target.name):find(key, 1, true) ~= nil
        if not record.move and not matches then
            for _, alias in ipairs(target.aliases or {}) do
                if names.normalize(alias):find(key, 1, true) then matches = true; break end
            end
        end
        if matches then
            local copy = {}
            for field, value in pairs(target) do copy[field] = value end
            copy.catalogue_scope, copy.focus_move = record.scope, record.move
            copy.exact_match = names.normalize(record.move or target.name) == key
            local label = record.scope == 'family' and 'Family' or (record.scope == 'notorious' and 'NM'
                or (record.scope == 'spell' and 'Spell' or 'Enemy'))
            copy.result_label = record.move and ('[Move] ' .. record.move .. ' - ' .. target.name)
                or ('[' .. label .. '] ' .. target.name)
            result[#result + 1] = copy
        end
    end
    table.sort(result, function(a,b)
        if a.exact_match ~= b.exact_match then return a.exact_match end
        return a.result_label:lower() < b.result_label:lower()
    end)
    return result
end

function browser.spells_for(target, alerts)
    local result, seen = {}, {}
    local source = target
    if not source.spells then
        for _, monster in ipairs(data.monsters) do
            local matches = names.normalize(monster.name) == names.normalize(target.name)
            for _, alias in ipairs(monster.aliases or {}) do
                if names.normalize(alias) == names.normalize(target.name) then matches = true end
            end
            if matches then source = monster; break end
        end
    end
    for _, id in ipairs(source.spells or {}) do
        local name = spell_names[id]
        if name and not seen[names.normalize(name)] then
            seen[names.normalize(name)] = true
            result[#result + 1] = { spell_id = id, name = name, kind = 'spell' }
        end
    end
    if alerts then
        local aliases = { [names.normalize(target.name)] = true }
        for _, alias in ipairs(target.aliases or {}) do aliases[names.normalize(alias)] = true end
        for _, rule in ipairs(alerts:list()) do
            local key = names.normalize(rule.move)
            if rule.kind == 'spell' and rule.scope == nil and aliases[names.normalize(rule.monster)]
                and not seen[key] then
                local spell = known_spells[key]
                result[#result + 1] = { spell_id = spell and spell.spell_id or ('saved_' .. key),
                    name = rule.move, kind = 'spell' }
                seen[key] = true
            end
        end
    end
    table.sort(result, function(a, b)
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

function browser.tracked_filter(alerts)
    local enemies, families, spells = {}, {}, {}
    for _, rule in ipairs(alerts:list()) do
        if rule.enabled then
            if rule.kind == 'spell' or rule.scope == 'spell' then spells[names.normalize(rule.move)] = true end
            if rule.scope == 'family' then
                families[rule.family_id] = true
            elseif rule.scope ~= 'spell' then
                enemies[names.normalize(rule.monster)] = true
                for _, alias in ipairs(rule.aliases or {}) do enemies[names.normalize(alias)] = true end
            end
        end
    end
    return function(target, scope)
        scope = target.catalogue_scope or scope
        if scope == 'spell' then return spells[names.normalize(target.name)] == true end
        if target.focus_move then
            return alerts:is_selected(browser.rule(target, { name = target.focus_move }, scope))
        end
        if scope == 'family' then
            for _, id in ipairs(target.family_ids or { target.family_id }) do if families[id] then return true end end
            return false
        end
        if enemies[names.normalize(target.name)] then return true end
        for _, alias in ipairs(target.aliases or {}) do if enemies[names.normalize(alias)] then return true end end
        for id in pairs(browser.groups_for(target.name)) do if families[id] then return true end end
        return false
    end
end

return browser
