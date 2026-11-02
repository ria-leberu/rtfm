package.path = './?.lua;' .. package.path
local browser = require('lib.catalogue_browser')
local alerts_class = require('lib.alerts')
local event = { monster = 'Moblin Topsman', move = 'Frypan', action = 'uses', category = 11, action_id = 1081 }
assert(browser.groups_for('The Moblin Topsman')[184])
local family = browser.search('family', 'Moblin')[1]
local move = browser.moves_for(family, 'Frypan')[1]
local rule = browser.rule(family, move, 'family')
local alerts = alerts_class.new()
alerts:set(event, true)
assert(alerts:is_selected(event) and alerts:is_selected(rule))
assert(#alerts:list() == 1 and alerts:list()[1].scope == 'family')
assert(alerts:list()[1].monster == 'Moblin')
alerts:set(rule, false)
assert(not alerts:is_selected(event) and not alerts:is_selected(rule))
alerts:set(rule, true)
alerts:set(event, false)
assert(not alerts:is_selected(rule))
local legacy = alerts_class.new({ moblintopsman = { frypan = true } })
assert(legacy.migrated and legacy:is_selected(rule))
assert(legacy.selected.moblintopsman == nil)
local restored = alerts_class.new(legacy.selected, legacy:list())
assert(restored:is_selected(event) and restored:is_selected(rule))
local preferred = alerts_class.new({ moblintopsman = { frypan = true } }, {
    { monster = 'Moblin', move = 'Frypan', scope = 'family', family_id = 184, enabled = false },
    { monster = 'Moblin Topsman', move = 'Frypan', enabled = true },
})
assert(not preferred:is_selected(event) and not preferred:is_selected(rule))
assert(browser.family_rule_for({ monster = 'Khimaira', move = 'Fossilizing Breath' }) == nil)
assert(browser.family_rule_for({ monster = 'Moblin Topsman', move = 'Custom unknown move' }) == nil)
if RTFM_TEST_PATH then
    local storage = require('lib.storage')
    assert(storage.save(RTFM_TEST_PATH, { rules = legacy:list() }))
    local saved = alerts_class.new(nil, storage.load(RTFM_TEST_PATH).rules)
    assert(saved:is_selected(event) and saved:is_selected(rule))
    os.remove(RTFM_TEST_PATH)
    os.remove(RTFM_TEST_PATH .. '.bak')
end
print('RTFM Moblin Topsman shared-family tracking checks passed.')
