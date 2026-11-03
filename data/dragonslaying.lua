-- CatsEyeXI encounter overrides over the requested family templates.
-- See DRAGONSLAYING.md for sources, aliases and unconfirmed action mappings.
local monsters = {
    { name = 'Glacial Wyvern', aliases = { 'Glacial Wyvern' }, skill_list_id = 266, extra_moves = { 820 } },
    { name = 'Searing Eldrake', aliases = { 'Searing Eldrake' }, skill_list_id = 87 },
    { name = 'Blight Wyrm', aliases = { 'Blight Wyrm' }, skill_list_id = 87 },
    { name = 'Venomous Drake', aliases = { 'Venomous Drake' }, skill_list_id = 87 },
    { name = 'Midgardsormr', aliases = { 'Midgardsormr' }, skill_list_id = 260, extra_moves = { 955 } },
    { name = 'Arfarvegr', aliases = { 'Arfarvegr' }, skill_list_id = 260, extra_moves = { 955 } },
    { name = 'Skrudningr', aliases = { 'Skrudningr' }, skill_list_id = 260, extra_moves = { 955 } },
    { name = 'Brjota', aliases = { 'Brjota', 'Brjorta' }, skill_list_id = 470, extra_moves = { 688 } },
}
local wyvern = {
    dispellingwind = { area = 'AoE', note = 'Dispel' },
    dreadshriek = { area = 'AoE', statuses = { 4, 129 },
        note = 'CatsEyeXI adds Frost; its page calls this Deadly Shriek' },
    deadlydrive = { damage = 'physical' },
    fangrush = { damage = 'physical', note = 'Three hits' },
    windwall = { self_statuses = { 92, 36 }, note = 'CatsEyeXI adds Blink' },
    radiantbreath = { damage = 'light', area = 'Cone', statuses = { 13, 6 } },
    tailcrush = { damage = 'physical', statuses = { 3 } },
    thunderbreath = { damage = 'lightning', area = 'Cone' },
}
local dragon = {
    petroeyes = { area = 'Gaze cone', statuses = { 7 } },
    bodyslam = { damage = 'physical', area = 'AoE' },
    heavystomp = { damage = 'physical', area = 'AoE', statuses = { 4 } },
    flamebreath = { damage = 'fire', area = 'Cone' },
    windbreath = { damage = 'wind', area = 'Cone' },
    lodesong = { area = 'AoE', statuses = { 12 } },
    voidsong = { area = 'AoE', note = 'Removes status effects from players and monster' },
    thornsong = { self_statuses = { 153 } },
    chaosblade = { damage = 'dark', area = 'Cone', statuses = { 9 } },
    poisonbreath = { damage = 'water', area = 'Cone', statuses = { 3 } },
}
local wyrm = {
    absoluteterror = { statuses = { 28 }, note = 'Ignores shadows' },
    hurricanewing = { damage = 'wind', area = 'AoE', statuses = { 5 }, note = 'Removes shadows' },
    dragonbreath = { damage = 'fire', area = 'Cone', note = 'Ground breath uses the family reference; custom ground element unconfirmed' },
    flameblast = { area = 'AoE', note = 'Flying attack template; custom element supplied by CatsEyeXI encounter notes' },
    horridroar = { note = 'Dispel; enmity reduction; removes shadows' },
    spikeflail = { damage = 'physical', area = 'AoE', note = 'Rear target; knockback' },
}
local zilant = {
    abyssicbuster = { damage = 'magical', area = 'Cone',
        note = 'Element unconfirmed; Zilant reference marks lightning as needing verification' },
    chaosblast = { damage = 'dark', area = 'AoE', statuses = { 144, 145, 189 } },
    chillingroar = { area = 'AoE', statuses = { 28 } },
    dancingtail = { damage = 'physical', statuses = { 3 }, note = 'Rear target' },
    darkstar = { damage = 'dark', area = 'AoE', statuses = { 149, 167 } },
    dexterwing = { damage = 'physical', area = 'Right cone', statuses = { 147, 175 } },
    sinisterwing = { damage = 'physical', area = 'Left cone', statuses = { 146, 174 } },
    souldouse = { area = 'Cone', statuses = { 15 } },
    mightystrikes = { self_statuses = { 44 }, note = 'CatsEyeXI: approximately every two to three minutes' },
}
local function copy(template)
    local result = {}
    for name, entry in pairs(template) do
        local record = {}
        for field, value in pairs(entry) do record[field] = value end
        record.reference_note = 'Family-template repertoire; CatsEyeXI encounter changes applied where documented. Remaining moves need live confirmation.'
        result[name] = record
    end
    return result
end
local effects = {
    glacialwyvern = copy(wyvern),
    searingeldrake = copy(dragon), blightwyrm = copy(dragon), venomousdrake = copy(dragon),
    midgardsormr = copy(wyrm), arfarvegr = copy(wyrm), skrudningr = copy(wyrm),
    brjota = copy(zilant),
}
effects.brjorta = effects.brjota
effects.searingeldrake.bodyslam.statuses = { 128 }
effects.searingeldrake.heavystomp.statuses = { 4, 128 }
effects.searingeldrake.petroeyes.note = 'CatsEyeXI: enmity reset'
effects.blightwyrm.bodyslam.note = 'CatsEyeXI: absorbs HP; damage element not specified'
effects.midgardsormr.hurricanewing.statuses = { 5, 13 }
effects.midgardsormr.hurricanewing.self_statuses = { 37 }
effects.arfarvegr.hurricanewing.statuses = { 5, 133 }
effects.arfarvegr.hurricanewing.self_statuses = { 51 }
effects.skrudningr.hurricanewing.statuses = { 5, 10 }
effects.skrudningr.hurricanewing.self_statuses = { 38 }
for monster, element in pairs({ midgardsormr = 'earth', arfarvegr = 'water', skrudningr = 'lightning' }) do
    effects[monster].flameblast.damage = element
    effects[monster].flameblast.reference_note = 'CatsEyeXI documents the flying breath element. Matching it to Flame Blast is a Wyrm-template assumption; confirm the live action name.'
end
for _, monster in ipairs(monsters) do monster.replace_moves, monster.spells = true, {} end
for _, entry in pairs(effects.blightwyrm) do
    entry.reference_note = entry.reference_note .. ' CatsEyeXI also reports Doom, but does not name its triggering action.'
end
for _, entry in pairs(effects.venomousdrake) do
    entry.reference_note = entry.reference_note .. ' CatsEyeXI also reports Bio and Plague, but does not identify the triggering actions.'
end
return { monsters = monsters, effects = effects }
