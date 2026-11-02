-- Initial reviewed entries: upstream LandSandBoat mob_skills IDs.
-- Sources: https://github.com/LandSandBoat/server/tree/base/scripts/actions/mobskills
-- This describes upstream behavior, not verified private-server overrides.
return {
    [2022] = { name = 'Tenebrous Mist', area = 'AoE', note = 'TP reset', source = 'tenebrous_mist' },
    [2023] = { name = 'Thunderstrike', damage = 'lightning', area = 'AoE', statuses = { 10 }, source = 'thunderstrike' },
    [2024] = { name = 'Tourbillion', damage = 'physical', area = 'AoE', statuses = { 149 }, source = 'tourbillion' },
    [2025] = { name = 'Dreadstorm', damage = 'dark', area = 'AoE', statuses = { 28 }, source = 'dreadstorm' },
    [2026] = { name = 'Fossilizing Breath', area = 'Cone', statuses = { 7 }, source = 'fossilizing_breath' },
    [2027] = { name = 'Plague Swipe', damage = 'physical', area = 'Rear cone', statuses = { 135, 31 }, source = 'plague_swipe' },
    [2028] = { name = 'Fulmination', damage = 'lightning', area = 'AoE', statuses = { 4, 10 }, source = 'fulmination' },
}
