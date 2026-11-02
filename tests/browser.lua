package.path = './?.lua;' .. package.path
local browser = require('lib.catalogue_browser')
local alerts_class = require('lib.alerts')
local names = require('lib.names')
local monsters = browser.search('monster', 'Khimaira')
local families = browser.search('family', 'Khimaira')
local monster, family
for _, entry in ipairs(monsters) do if entry.name == 'Khimaira' then monster = entry end end
for _, entry in ipairs(families) do if entry.name == 'Khimaira' then family = entry end end
assert(monster and family and family.family_id == 168)
assert(#browser.moves_for(monster, '') >= 7)
assert(#browser.moves_for(family, 'Fossilizing Breath') == 1)
assert(#browser.search('monster', 'no such catalogue entry xyz') == 0)
local move = browser.moves_for(monster, 'Fossilizing Breath')[1]
local alerts = alerts_class.new()
local alias_rule = browser.rule({ name = 'Khimaira', aliases = { 'Khimaira', 'Trial Khimaira' } }, move, 'monster')
alerts:set(alias_rule, true)
assert(alerts:is_selected({ monster = 'Trial Khimaira', move = move.name }))
alerts:set(alerts:list()[1], true) -- toggling a saved row must retain aliases
assert(alerts:is_selected({ monster = 'Trial Khimaira', move = move.name }))
alerts:remove(alias_rule)

local phase, child_depth = 'monster_track', 0
local visible_targets = {}
package.loaded.imgui = {
    SetNextWindowSize = function() end, Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, child_flags, flags)
        assert(type(child_flags) == 'number' and type(flags) == 'number')
        child_depth = child_depth + 1
        return true
    end,
    EndChild = function() child_depth = child_depth - 1 end,
    SameLine = function() end, Text = function() end, TextWrapped = function() end,
    Separator = function() end, PushStyleColor = function() end, PopStyleColor = function() end,
    InputText = function(label, value)
        assert(label ~= 'Search moves')
        if phase == 'paginate' or phase == 'paginate_next' then value[1] = ''; return true end
        value[1] = 'Khimaira'
        return true
    end,
    Selectable = function(label)
        visible_targets[#visible_targets + 1] = label
        if phase == 'paginate' or phase == 'paginate_next' then return false end
        return label:match('^Khimaira##') ~= nil
    end,
    Button = function(label)
        if phase == 'paginate' then return false end
        if phase == 'paginate_next' then return label == 'Next##catalogue_page' end
        if phase == 'monster_track' and label == 'Notorious monsters' then return true end
        if phase == 'family_track' and label == 'Common families' then return true end
        if phase == 'family_untrack' then return label == 'Untrack##catalogue_move_2026' end
        return label == 'Track##catalogue_move_2026'
    end,
}
package.loaded['lib.descriptions'] = { draw = function() end }
local window = require('lib.browser_window')
window.open()
assert(window.draw(alerts) and child_depth == 0)
assert(alerts:is_selected({ monster = 'Khimaira', move = move.name }))
alerts:set({ monster = 'Khimaira', move = move.name }, false)
phase = 'family_track'
assert(window.draw(alerts) and child_depth == 0)
local family_rule = browser.rule(family, move, 'family')
assert(alerts:is_selected(family_rule))
assert(not alerts:is_selected({ monster = 'Khimaira', move = move.name })) -- explicit exception
local other
for _, member in ipairs(family.members) do
    if names.normalize(member) ~= 'khimaira' then other = member; break end
end
assert(other and alerts:is_selected({ monster = other, move = move.name }))
local common = browser.search('family', '')
assert(#common < 200)
assert(#browser.search('family', 'TRUST') == 0)
assert(#browser.search('family', 'Jug_') == 0)
local named = browser.search('notorious', '')
for _, target in ipairs(named) do assert(target.notorious == true) end
assert(#named > 100 and #named < #browser.search('monster', ''))
assert(#browser.search('notorious', 'Khimaira') > 0)
local king = browser.search('notorious', 'King Behemoth')
assert(#king == 1 and king[1].name == 'King Behemoth')
assert(#browser.moves_for(king[1], '') == 6)
assert(#browser.moves_for(king[1], 'Meteor') == 0)
assert(browser.spells_for(king[1])[1].name == 'Meteor')
assert(#browser.search('notorious', 'Absolute Virtue') == 1)
local moblin = browser.search('family', 'Moblin')[1]
local moblin_moves = browser.moves_for(moblin, '')
local seen_names = {}
for _, entry in ipairs(moblin_moves) do
    local key = names.normalize(entry.name)
    assert(not seen_names[key]); seen_names[key] = true
end
assert(#moblin_moves == 5)
assert(#browser.moves_for(moblin, 'Smokebomb')[1].variant_ids == 2)
for _, target in ipairs(common) do
    local unique = {}
    for _, entry in ipairs(browser.moves_for(target, '')) do
        local key = names.normalize(entry.name)
        assert(not unique[key]); unique[key] = true
    end
end
local crab = browser.search('family', 'Crab')[1]
assert(crab.name == 'Crab' and #crab.family_ids == 3)
local crab_move = browser.moves_for(crab, '')[1]
local grouped_rule = browser.rule(crab, crab_move, 'family')
alerts:set(grouped_rule, true)
assert(alerts:is_selected(grouped_rule))
for _, id in ipairs(crab.family_ids) do
    assert(alerts:is_selected({ monster = 'Crab', move = crab_move.name, scope = 'family', family_id = id }))
end
alerts:set(grouped_rule, false)
assert(not alerts:is_selected(grouped_rule))
local restored = alerts_class.new(alerts.selected, alerts:list())
assert(restored:is_selected(family_rule))
assert(restored:is_selected({ monster = other, move = move.name }))
assert(not restored:is_selected({ monster = 'Khimaira', move = move.name }))
if RTFM_TEST_PATH then
    local storage = require('lib.storage')
    assert(storage.save(RTFM_TEST_PATH, { move_alerts = alerts.selected, move_alert_entries = alerts:list() }))
    local disk = storage.load(RTFM_TEST_PATH)
    local disk_alerts = alerts_class.new(disk.move_alerts, disk.move_alert_entries)
    assert(disk_alerts:is_selected(family_rule))
    assert(disk_alerts:is_selected({ monster = other, move = move.name }))
    assert(not disk_alerts:is_selected({ monster = 'Khimaira', move = move.name }))
    os.remove(RTFM_TEST_PATH)
    os.remove(RTFM_TEST_PATH .. '.bak')
end
phase = 'family_untrack'
assert(window.draw(alerts))
assert(not alerts:is_selected(family_rule))
assert(not alerts:is_selected({ monster = other, move = move.name }))
restored:remove(family_rule)
assert(not restored:is_selected({ monster = other, move = move.name }))
phase, visible_targets = 'paginate', {}
window.draw(alerts)
assert(#visible_targets == 25)
local first_page = visible_targets[1]
phase, visible_targets = 'paginate_next', {}
window.draw(alerts)
assert(#visible_targets == 25 and visible_targets[1] ~= first_page)
print('RTFM catalogue browser and scoped alert checks passed.')
