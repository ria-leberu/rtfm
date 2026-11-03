-- Monster-specific upstream descriptions. Sources are matching scripts under
-- LandSandBoat/server/scripts/actions/mobskills/<source>.lua.
-- Add private-server overrides here when behavior differs from upstream.
local moves = {
    greatermanticore = {
        greatwhirlwind = { damage = 'wind', area = 'Cone', statuses = { 130 }, source = 'great_whirlwind' },
        greatsandstorm = { damage = 'earth', statuses = { 5 }, source = 'great_sandstorm' },
        heatbreath = { damage = 'fire', area = 'Cone', source = 'heat_breath' },
        tailsmash = { damage = 'physical', statuses = { 11 }, source = 'tail_smash' },
        tailswing = { damage = 'physical', statuses = { 11 }, source = 'tail_swing' },
        riddle = { area = 'AoE', statuses = { 145 }, source = 'riddle' },
        deadlyhold = { damage = 'physical', source = 'deadly_hold' },
    },
    awghrah = {
        actinicburst = { area = 'AoE', statuses = { 156 }, source = 'actinic_burst' },
        coremeltdown = { note = 'Magic AoE', source = 'core_meltdown' }, -- element unresolved upstream
        hexidiscs = { damage = 'physical', area = 'Cone', source = 'hexidiscs' },
        damnationdive = { damage = 'physical', area = 'Cone', statuses = { 10 }, source = 'damnation_dive' },
        sickleslash = { damage = 'physical', source = 'sickle_slash' },
        vorpalblade = { damage = 'physical', source = 'vorpal_blade' },
    },
}
local omega = require('data.omega_moves')
moves['proto-omega'], moves['neo-omega'] = omega, omega
for monster, entries in pairs(require('data.domain_invasion').effects) do
    moves[monster] = entries
end
for monster, entries in pairs(require('data.dragonslaying').effects) do
    moves[monster] = entries
end
return moves
