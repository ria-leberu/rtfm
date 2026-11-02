local names = require('lib.names')
local imgui = require('imgui')
local icons = require('lib.icons')
local catalogue = require('data.catalogue')
local statuses = require('data.statuses')
local descriptions = {}
local by_name = {}
local damage_labels = {
    physical = 'Physical damage', lightning = 'Thunder damage', fire = 'Fire damage',
    ice = 'Ice damage', wind = 'Wind damage', earth = 'Earth damage', water = 'Water damage',
    light = 'Light damage', dark = 'Dark damage',
}
local legacy_statuses = { choke = 130, blind = 5, bind = 11, mpdown = 145, paralyze = 4, flash = 156 }
for _, entry in pairs(catalogue) do by_name[names.normalize(entry.name)] = entry end

function descriptions.lookup(event, overrides)
    local monster_moves = overrides[names.normalize(event.monster)]
    local override = monster_moves and monster_moves[names.normalize(event.move)]
    if type(override) == 'table' then return override end
    if type(override) == 'string' and override ~= '' then
        local id = legacy_statuses[names.normalize(override)]
        return id and { statuses = { id } } or { note = override }
    end
    -- Only TP-move IDs belong to this catalogue, not spell/JA IDs.
    if event.category == 11 and catalogue[event.action_id] then return catalogue[event.action_id] end
    if event.action == 'casts' or event.action == 'casting' then return nil end
    return by_name[names.normalize(event.move)]
end

function descriptions.draw(event, overrides)
    local entry = descriptions.lookup(event, overrides)
    if not entry then return end
    local size = 16
    if entry.damage then
        imgui.SameLine(0, 4)
        icons.draw(entry.damage, nil, damage_labels[entry.damage] or entry.damage, size)
    end
    if entry.area then
        imgui.SameLine(0, 4)
        imgui.Text(entry.area)
    end
    for _, id in ipairs(entry.statuses or {}) do
        imgui.SameLine(0, 4)
        icons.draw('status', id, statuses[id] or ('Status ' .. id), size)
    end
    if entry.note then
        imgui.SameLine(0, 4)
        imgui.Text(entry.note)
    end
end

return descriptions
