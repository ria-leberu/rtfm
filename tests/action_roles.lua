package.path = './?.lua;' .. package.path
package.loaded.imgui = {}
local roles = require('lib.action_roles')
local function role(move, action)
    return roles.lookup({ monster = 'Test monster', move = move, action = action }, {})
end
assert(role('Meteor', 'casting') == 'offensive')
assert(role('Sleepga', 'casts') == 'offensive')
assert(role('Protect', 'casting') == 'defensive')
assert(role('Cure IV', 'casting') == 'defensive')
assert(role('Foot Kick', 'readies') == 'offensive')
assert(role('Rage', 'readies') == 'defensive')
assert(role('Unknown custom move', 'readies') == nil)
assert(role('Unknown custom spell', 'casting') == nil)
print('RTFM action role checks passed.')
