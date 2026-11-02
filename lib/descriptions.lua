local names = require('lib.names')
local imgui = require('imgui')
local icons = require('lib.icons')
local catalogue = require('data.catalogue')
local statuses = require('data.statuses')
local spell_statuses = require('data.spell_statuses')
local spell_damage = require('data.generated.spell_damage')
local display_text = require('lib.display_text')
local monster_index = require('data.generated.monsters')
local descriptions = {}
local by_name = {}
local damage_labels = {
    physical = 'Physical damage', lightning = 'Thunder damage', fire = 'Fire damage',
    ice = 'Ice damage', wind = 'Wind damage', earth = 'Earth damage', water = 'Water damage',
    light = 'Light damage', dark = 'Dark damage',
}
local legacy_statuses = { choke = 130, blind = 5, bind = 11, mpdown = 145, paralyze = 4, flash = 156 }
for id, entry in pairs(catalogue) do
    local key = names.normalize(entry.name)
    by_name[key] = by_name[key] or {}
    table.insert(by_name[key], id)
end

local function signature(entry)
    local function effect_set(values)
        local copy = {}
        for _, id in ipairs(values or {}) do copy[#copy + 1] = id end
        table.sort(copy)
        return table.concat(copy, ',')
    end
    return table.concat({ entry.damage or '', entry.area or '', entry.note or '',
        effect_set(entry.statuses), effect_set(entry.self_statuses) }, '|')
end

local function unambiguous(candidates)
    local result, expected
    for _, id in ipairs(candidates) do
        local entry = catalogue[id]
        if entry then
            local value = signature(entry)
            if expected and expected ~= value then return nil end
            expected = value
            if not result or (result.automated and not entry.automated) then result = entry end
        end
    end
    return result
end

function descriptions.lookup(event, overrides)
    local monster_moves = overrides[names.normalize(event.monster)]
    local override = monster_moves and monster_moves[names.normalize(event.move)]
    if type(override) == 'table' then return override end
    if type(override) == 'string' and override ~= '' then
        local id = legacy_statuses[names.normalize(override)]
        return id and { statuses = { id } } or { note = override }
    end
    if event.action == 'casts' or event.action == 'casting' or event.kind == 'spell' then
        local key = names.trim(event.move):lower()
        local effects, damage = spell_statuses[key], spell_damage[key]
        return (effects or damage) and { statuses = effects, damage = damage, automated = true } or nil
    end
    -- Only TP-move IDs belong to this catalogue, not spell/JA IDs.
    if event.category == 11 and catalogue[event.action_id] then return catalogue[event.action_id] end
    local move_key = names.normalize(event.move)
    local candidates = {}
    for _, id in ipairs(monster_index[names.normalize(event.monster)] or {}) do
        if catalogue[id] and names.normalize(catalogue[id].name) == move_key then
            candidates[#candidates + 1] = id
        end
    end
    if #candidates > 0 then return unambiguous(candidates) end
    return unambiguous(by_name[move_key] or {})
end

function descriptions.draw(event, overrides, compact)
    local entry = descriptions.lookup(event, overrides)
    if not entry then return end
    local size = imgui.GetFontSize()
    local gap = compact and 2 or 4
    if entry.damage then
        imgui.SameLine(0, gap)
        imgui.Text('[')
        imgui.SameLine(0, 2)
        local label = damage_labels[entry.damage] or entry.damage
        icons.draw(entry.damage, nil, label, size, label .. (entry.automated and ' (upstream; unverified)' or ''))
        imgui.SameLine(0, 2)
        imgui.Text(']')
    end
    if entry.area then
        imgui.SameLine(0, gap)
        imgui.Text(entry.area)
    end
    local has_statuses = #(entry.statuses or {}) > 0 or #(entry.self_statuses or {}) > 0
    if has_statuses then
        imgui.SameLine(0, gap)
        imgui.Text('(')
    end
    for _, id in ipairs(entry.statuses or {}) do
        imgui.SameLine(0, gap)
        local label = statuses[id] or ('Status ' .. id)
        icons.draw('status', id, label, size, label .. (entry.automated and ' (possible target effect; upstream)' or ''))
    end
    for _, id in ipairs(entry.self_statuses or {}) do
        imgui.SameLine(0, gap)
        local label = statuses[id] or ('Status ' .. id)
        icons.draw('status', id, label, size, 'Self: ' .. label .. ' (possible effect; upstream)')
    end
    if has_statuses then
        imgui.SameLine(0, 2)
        imgui.Text(')')
    end
    if entry.note then
        imgui.SameLine(0, gap)
        imgui.Text(compact and display_text.shorten(entry.note) or entry.note)
        if compact and imgui.IsItemHovered() then imgui.SetTooltip(entry.note) end
    end
end

return descriptions
