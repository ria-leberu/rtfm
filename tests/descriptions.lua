package.path = './?.lua;' .. package.path
local drawn, positions, cursor = {}, {}, 0
package.loaded.imgui = {
    SameLine = function() cursor = 1 end,
    Text = function(text) drawn[#drawn + 1] = text; positions[#positions + 1] = cursor end,
}
package.loaded['lib.icons'] = { draw = function(kind, id, label)
    drawn[#drawn + 1] = kind == 'status' and ('status:' .. id) or kind
    positions[#positions + 1] = cursor
end }
local descriptions = require('lib.descriptions')
local overrides = require('data.moves')
local fulmination = { monster = 'Khimaira', move = 'Fulmination', action = 'uses', category = 11, action_id = 2028 }
local entry = descriptions.lookup(fulmination, overrides)
assert(entry.damage == 'lightning' and entry.statuses[1] == 4 and entry.statuses[2] == 10)
descriptions.draw(fulmination, overrides)
assert(table.concat(drawn, ',') == 'lightning,AoE,status:4,status:10')
for _, position in ipairs(positions) do assert(position == 1) end
assert(descriptions.lookup({ monster = 'Khimaira', move = 'Fossilizing Breath', action = 'readies' }, overrides).statuses[1] == 7)
assert(not descriptions.lookup({ monster = 'Other', move = 'Unknown move', action = 'uses' }, overrides))
assert(not descriptions.lookup({ monster = 'Other', move = 'Fire', action = 'casts', category = 4, action_id = 2028 }, overrides))
for _, action in ipairs({ 'casting', 'casts' }) do
    for spell, id in pairs({ Bio = 135, ['Bio II'] = 135, Blind = 5, Blindga = 5,
        Sleepga = 2, Breakga = 7, Diaga = 134, Poison = 3 }) do
        drawn, positions = {}, {}
        descriptions.draw({ monster = 'Test', move = spell, action = action, category = 4, action_id = 2028 }, overrides)
        assert(table.concat(drawn, ',') == 'status:' .. id, spell)
        assert(positions[1] == 1)
    end
end
assert(not descriptions.lookup({ monster = 'Test', move = 'Blindna', action = 'casts' }, overrides))
assert(descriptions.lookup({ monster = 'The Greater Manticore', move = 'Heat Breath', action = 'uses' }, overrides).damage == 'fire')
assert(descriptions.lookup({ monster = "The Aw'ghrah", move = 'Damnation Dive', action = 'uses' }, overrides).damage == 'physical')
assert(descriptions.lookup({ monster = 'Test', move = 'Test', action = 'uses' }, { test = { test = 'Blind' } }).statuses[1] == 5)
for id, move in pairs(require('data.catalogue')) do
    assert(type(id) == 'number' and type(move.name) == 'string' and type(move.source) == 'string')
    assert(move.damage_estimate == nil)
    for _, status in ipairs(move.statuses or {}) do assert(require('data.statuses')[status]) end
end
print('RTFM inline description checks passed.')
