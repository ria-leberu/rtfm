package.path = './?.lua;' .. package.path
local browser = require('lib.catalogue_browser')
local alerts = require('lib.alerts').new()
local phase, styles, child_depth = 'king_known', 0, 0
local selected_spell_id = browser.search('spell', 'Meteor')[1].spell_id
local enemy_name, spell_query = 'King Behemoth', 'Breakga'
package.loaded.imgui = {
    SetNextWindowSize = function() end, Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, a, b)
        assert(type(a) == 'number' and type(b) == 'number'); child_depth = child_depth + 1; return true
    end,
    EndChild = function() child_depth = child_depth - 1 end,
    SameLine = function() end, Text = function() end, TextWrapped = function() end, Separator = function() end,
    PushStyleColor = function() styles = styles + 1 end,
    PopStyleColor = function(count) styles = styles - (count or 1); assert(styles >= 0) end,
    InputText = function(label, value)
        if label == 'Search catalogue' then value[1] = 'King Behemoth' end
        if label == 'Search spells' then value[1] = spell_query end
        if label == 'Enemy name' then
            if phase == 'king_known' then assert(value[1] == 'King Behemoth') end
            if phase == 'family' then assert(value[1] == '') end
            value[1] = enemy_name
        end
        return true
    end,
    Selectable = function(label) return label:match('^King Behemoth##') ~= nil end,
    Button = function(label)
        if phase == 'king_known' and (label == 'Notorious monsters' or label == 'Track spells') then return true end
        if (phase == 'king_add' or phase == 'family') and label == 'Add another spell' then return true end
        local prefix = phase == 'king_known' and 'Track' or 'Add & track'
        return label == prefix .. '##picker_spell_' .. selected_spell_id
    end,
}
package.loaded['lib.descriptions'] = { draw = function() end }
local window = require('lib.browser_window')
window.open()
assert(window.draw(alerts))
assert(child_depth == 0 and styles == 0)
assert(alerts:is_selected({ monster = 'King Behemoth', move = 'Meteor', action = 'casting' }))
phase = 'king_add'
selected_spell_id = browser.search('spell', 'Breakga')[1].spell_id
assert(require('lib.spell_picker').draw(alerts))
assert(alerts:is_selected({ monster = 'King Behemoth', move = 'Breakga', action = 'casting' }))
assert(not alerts:is_selected({ monster = 'Other Boss', move = 'Breakga', action = 'casting' }))
local king = browser.search('notorious', 'King Behemoth')[1]
assert(#browser.moves_for(king, 'Breakga') == 0)
assert(#browser.spells_for(king, alerts) == 2)
phase, enemy_name, spell_query = 'family', 'Moblin Topsman', 'Sleepga'
selected_spell_id = browser.search('spell', 'Sleepga')[1].spell_id
local picker = require('lib.spell_picker')
picker.open(browser.search('family', 'Moblin')[1], 'family')
assert(picker.draw(alerts))
assert(alerts:is_selected({ monster = 'Moblin Topsman', move = 'Sleepga', action = 'casting' }))
assert(not alerts:is_selected({ monster = 'Other Moblin', move = 'Sleepga', action = 'casting' }))
assert(not alerts:is_selected({ monster = 'Any enemy', move = 'Sleepga', scope = 'spell' }))
assert(styles == 0 and child_depth == 0)
local restored = require('lib.alerts').new(alerts.selected, alerts:list())
assert(restored:is_selected({ monster = 'King Behemoth', move = 'Breakga', action = 'casting' }))
assert(#browser.moves_for(king, 'Breakga') == 0)
assert(#browser.spells_for(king, restored) == 2)
print('RTFM contextual spell-picker checks passed.')
