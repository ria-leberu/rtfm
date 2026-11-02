package.path = './?.lua;' .. package.path
local alerts_class = require('lib.alerts')
local browser = require('lib.catalogue_browser')
local alerts = alerts_class.new()
local phase, styles, spell_name = 'any', 0, 'Sleepga'
local active_tab_verified = false
package.loaded.imgui = {
    SetNextWindowSize = function() end, Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, a, b) assert(type(a) == 'number' and type(b) == 'number'); return true end,
    EndChild = function() end, Text = function() end, TextWrapped = function() end,
    SameLine = function() end, Separator = function() end,
    PushStyleColor = function() styles = styles + 1 end,
    PopStyleColor = function(count) styles = styles - (count or 1); assert(styles >= 0) end,
    InputText = function(label, value)
        value[1] = label == 'Specific enemy' and 'King Behemoth' or spell_name
        return true
    end,
    Selectable = function(label) return label:match('^' .. spell_name .. '##') ~= nil end,
    Button = function(label)
        if label == 'Spells' then
            if phase == 'enemy' then assert(styles == 3); active_tab_verified = true end
            return true
        end
        return (phase == 'any' and label == 'Track##spell_any') or
            (phase == 'enemy' and label == 'Track##spell_enemy')
    end,
}
package.loaded['lib.descriptions'] = { draw = function() end }
local window = require('lib.browser_window')
window.open()
assert(window.draw(alerts) and styles == 0)
assert(alerts:is_selected({ monster = 'Other Boss', move = 'Sleepga', action = 'casting' }))
assert(not alerts:is_selected({ monster = 'Other Boss', move = 'Sleepga', action = 'readies' }))
phase, spell_name = 'enemy', 'Meteor'
assert(window.draw(alerts) and styles == 0 and active_tab_verified)
assert(alerts:is_selected({ monster = 'King Behemoth', move = 'Meteor', action = 'casting' }))
assert(not alerts:is_selected({ monster = 'Other Boss', move = 'Meteor', action = 'casting' }))
alerts:set({ monster = 'Any enemy', move = 'Breakga', scope = 'spell', kind = 'spell' }, true)
assert(alerts:is_selected({ monster = 'Other Boss', move = 'Breakga', action = 'casting' }))
alerts:set({ monster = 'Other Boss', move = 'Sleepga', action = 'casting' }, false)
assert(not alerts:is_selected({ monster = 'Other Boss', move = 'Sleepga', action = 'casting' }))
assert(alerts:is_selected({ monster = 'Another Boss', move = 'Sleepga', action = 'casting' }))
local restored = alerts_class.new(alerts.selected, alerts:list())
assert(restored:is_selected({ monster = 'King Behemoth', move = 'Meteor', action = 'casting' }))
assert(restored:is_selected({ monster = 'Another Boss', move = 'Breakga', action = 'casting' }))
assert(not restored:is_selected({ monster = 'Other Boss', move = 'Sleepga', action = 'casting' }))
if RTFM_TEST_PATH then
    local storage = require('lib.storage')
    assert(storage.save(RTFM_TEST_PATH, { rules = alerts:list() }))
    local saved = alerts_class.new(nil, storage.load(RTFM_TEST_PATH).rules)
    assert(saved:is_selected({ monster = 'Another Boss', move = 'Breakga', action = 'casting' }))
    os.remove(RTFM_TEST_PATH)
    os.remove(RTFM_TEST_PATH .. '.bak')
end
assert(#browser.search('spell', 'Sleepga') == 2) -- name variants, not duplicate IDs
assert(#browser.search('notorious', 'Absolute Virtue') == 1)
print('RTFM spell scope, active-tab, and persistence checks passed.')
