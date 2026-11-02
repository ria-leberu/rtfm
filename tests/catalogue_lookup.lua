package.path = './?.lua;' .. package.path
package.loaded.imgui = {}
package.loaded['lib.icons'] = {}
package.loaded['data.catalogue'] = {
    [1001] = { name = 'Shared Move', damage = 'physical', statuses = { 4, 5 } },
    [1002] = { name = 'Shared Move', damage = 'fire', statuses = { 5 } },
    [1003] = { name = 'Shared Move', damage = 'physical', statuses = { 5, 4 } },
}
package.loaded['data.generated.monsters'] = { first = { 1001 }, second = { 1002 }, equivalent = { 1001, 1003 } }
package.loaded['data.statuses'] = {}
local descriptions = require('lib.descriptions')
local function lookup(monster)
    return descriptions.lookup({ monster = monster, move = 'Shared Move', action = 'readies' }, {})
end
assert(lookup('First').damage == 'physical')
assert(lookup('Second').damage == 'fire')
assert(lookup('Equivalent').damage == 'physical')
assert(lookup('Unknown') == nil) -- never pick an arbitrary variant by name
assert(descriptions.lookup({ monster = 'Unknown', move = 'Shared Move', category = 11, action_id = 1002 }, {}).damage == 'fire')
assert(descriptions.lookup({ monster = 'First', move = 'Shared Move', category = 11, action_id = 1002 },
    { first = { sharedmove = { note = 'Custom server override' } } }).note == 'Custom server override')
print('RTFM monster-specific catalogue lookup checks passed.')
