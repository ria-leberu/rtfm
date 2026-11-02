package.path = './?.lua;' .. package.path
bit = { band = function(a, b) return math.floor(a / b) % 2 == 1 and b or 0 end }
local engagement = require('lib.engagement')
local party_data = {
    [0] = { id = 100, index = 10 },
    [6] = { id = 200, index = 20 }, -- another alliance party
    [12] = { id = 300, index = 30 },
}
local party = {
    GetMemberIsActive = function(_, i) return party_data[i] and 1 or 0 end,
    GetMemberServerId = function(_, i) return party_data[i] and party_data[i].id or 0 end,
    GetMemberTargetIndex = function(_, i) return party_data[i] and party_data[i].index or 0 end,
}
local claim, target, status = 0, 0, 1
local entities = {
    GetName = function(_, i) return i == 50 and 'Khimaira' or '' end,
    GetServerId = function(_, i) return i == 50 and 500 or (i == 40 and 400 or 0) end,
    GetSpawnFlags = function(_, i) return i == 50 and 0x10 or 0 end,
    GetClaimStatus = function() return claim end,
    GetStatus = function() return status end,
    GetTargetedIndex = function() return target end,
    GetPetTargetIndex = function(_, i) return i == 10 and 40 or 0 end,
}
local event = { monster = 'Khimaira', actor_id = 500 }
assert(not engagement.matches(event, entities, party))
claim = 65536 + 200
assert(engagement.matches(event, entities, party))
claim, target = 0, 30
assert(engagement.matches(event, entities, party))
status = 0
assert(not engagement.matches(event, entities, party))
status, target = 1, 40
assert(engagement.matches(event, entities, party))
target = 999
assert(not engagement.matches(event, entities, party))
event.target_ids = { 300 }
assert(engagement.matches(event, entities, party))
event.target_ids = { 400 }
assert(engagement.matches(event, entities, party))
event.target_ids = { 999 }
assert(not engagement.matches(event, entities, party))
event.actor_id, target = nil, 20
assert(engagement.matches(event, entities, party))
local parsed = require('lib.actions').parse('Khimaira starts casting Thunder IV.', 999, {})
assert(parsed and parsed.action == 'casting' and parsed.move == 'Thunder IV')
print('RTFM party-engagement checks passed.')
