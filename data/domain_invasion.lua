-- Reviewed CatsEyeXI Domain Invasion roster and per-monster effects.
-- See DOMAIN_INVASION.md for sources and retail fallback limitations.
local roster = {
    { 'Colkhab', { 3002, 3003, 3004, 3005, 3006, 3007 } },
    { 'Tchakka', { 3011, 3012, 3013, 3014, 3015, 3016 } },
    { 'Achuka', { 3020, 3021, 3022, 3023, 3024, 3025, 3026 } },
    { 'Yumcax', { 3057, 3058, 3059, 3060, 3061, 3062 } },
    { 'Hurkan', { 3072, 3073, 3074, 3075, 3076, 3077 } },
    { 'Kumhau', { 3137, 3138, 3139, 3140, 3141, 3142 } },
    { 'Velkk Intruder', { 2988, 688 } },
    { 'Amphisbaena', { 633, 628, 629, 632 } },
    { 'Tamandua', { 633, 628, 629, 632 } },
    { 'Battosai', { 1828, 1829, 1830, 1831, 1834, 1835, 1836 } },
    { 'Gensai', { 1828, 1829, 1830, 1831, 1834, 1835, 1836 } },
    { 'Tortuga', { 805, 806, 809 } },
    { 'Cryptodira', { 805, 806, 809 } },
}
local effects = {
    colkhab = {
        mandibularlashing = { damage = 'physical', statuses = { 10, 3 } },
        vespinehurricane = { damage = 'wind', area = 'Cone', statuses = { 167, 147 }, note = 'Ignores shadows' },
        stingervolley = { damage = 'wind', area = 'Cone', statuses = { 4, 20 }, note = 'Zombie curse; ignores shadows' },
        droningwhirlwind = { damage = 'wind', area = 'AoE', note = 'Dispel; gains aura; removes shadows' },
        incisivedenouement = { damage = 'physical', note = 'Enmity reset' },
        incisiveapotheosis = { area = 'Cone', statuses = { 1 }, note = 'Weakness; enmity reset; damage element unspecified' },
    },
    tchakka = {
        aquaticlance = { damage = 'water', area = 'Cone', statuses = { 167, 149 } },
        carcharianverve = { damage = 'water', note = 'Gains aura' },
        marinemayhem = { damage = 'water', area = 'AoE', statuses = { 147, 133 } },
        pelagiccleaver = { damage = 'physical', area = 'AoE', statuses = { 144 } },
        protolithicpuncture = { damage = 'physical', note = 'Critical damage; enmity reset' },
        tidalguillotine = { damage = 'water', area = 'Cone', note = 'Critical damage; removes shadows' },
    },
    achuka = {
        batholithicshell = { self_statuses = { 34, 37, 33, 91, 190 } },
        blisteringroar = { damage = 'physical', area = 'AoE', statuses = { 28 }, self_statuses = { 93 }, note = 'Gains aura; removes three shadows' },
        incineratinglahar = { damage = 'fire', area = 'AoE', statuses = { 1 } },
        pyroclasticsurge = { damage = 'fire', area = 'AoE', statuses = { 21 } },
        searingserration = { damage = 'physical', note = 'Removes four shadows' },
        tyrannicalblow = { damage = 'fire', statuses = { 31 }, note = 'Ignores shadows' },
        volcanicstasis = { damage = 'fire', area = 'Cone', note = 'Dispel; ignores shadows' },
    },
    yumcax = {
        canopierce = { damage = 'earth', area = 'AoE', statuses = { 131 }, note = 'Damage split between targets' },
        pottedplant = { damage = 'earth', area = 'AoE', statuses = { 11, 13 } },
        fireflyfandango = { damage = 'light', area = 'AoE', statuses = { 4, 156, 145 } },
        rootoftheproblem = { damage = 'magical', statuses = { 136, 137, 138, 139, 140, 141, 142 }, note = 'Absorbs buffs and TP; stats down cannot be erased' },
        uproot = { damage = 'light', area = 'AoE', statuses = { 13 }, self_statuses = { 42 }, note = 'HP reduction; enmity reset; removes own ailments; gains aura' },
        tiiimbeeer = { damage = 'earth', area = 'AoE', statuses = { 15, 31, 11, 136, 137, 138, 139, 140, 141, 142 } },
    },
    hurkan = {
        brownout = { damage = 'lightning', area = 'Cone', statuses = { 5, 13 } },
        crashingthunder = { damage = 'lightning', area = 'AoE', note = 'Knockback; gains aura' },
        reverberatingcry = { damage = 'lightning', area = 'AoE', statuses = { 167, 404 } },
        reversecurrent = { damage = 'lightning', area = 'AoE', statuses = { 10 } },
        sparkstorm = { damage = 'lightning', area = 'Cone', statuses = { 146, 174 }, note = 'TP reduction' },
        staticprison = { damage = 'lightning', area = 'AoE', statuses = { 4, 132 }, note = 'Multiple buff dispel' },
    },
    kumhau = {
        bitingabrogation = { damage = 'ice', area = 'AoE', statuses = { 4 }, note = 'Knockback; dispels four buffs' },
        brainfreeze = { damage = 'ice', area = 'Cone', statuses = { 16 } },
        glacialtomb = { damage = 'ice', area = 'AoE', statuses = { 259 } },
        glassynova = { damage = 'ice', area = 'AoE', statuses = { 136, 137, 138, 139, 140, 141, 142 }, note = 'Full dispel including food' },
        permafrostrequiem = { damage = 'ice', area = 'AoE', statuses = { 28 } },
        polarroar = { damage = 'ice', area = 'AoE', statuses = { 11 }, note = 'Knockback; gains aura; removes shadows' },
    },
    velkkintruder = {
        glutinousdart = { damage = 'physical' },
        mightystrikes = { self_statuses = { 44 }, note = 'Used at 75%, 50% and 25% HP' },
    },
}
local behemoth = {
    howl = { self_statuses = { 68 } },
    wildhorn = { damage = 'physical' },
    thunderbolt = { damage = 'lightning', area = 'AoE', statuses = { 10, 132 } },
    flamearmor = { self_statuses = { 34 } },
}
local hydra = {
    pyricblast = { damage = 'fire', statuses = { 31 } },
    pyricbulwark = { self_statuses = { 152 } },
    polarblast = { damage = 'ice', statuses = { 4 } },
    polarbulwark = { self_statuses = { 150 } },
    trembling = { damage = 'physical', area = 'AoE', statuses = { 4, 3 } },
    serpentinetail = { damage = 'physical' },
    nervegas = { area = 'AoE', statuses = { 3, 9 } },
}
local turtle = {
    headbutt = { damage = 'physical', statuses = { 146 } },
    tortoisestomp = { damage = 'physical', statuses = { 149 } },
    aquabreath = { damage = 'water', statuses = { 133 } },
}
effects.amphisbaena, effects.tamandua = behemoth, behemoth
effects.battosai, effects.gensai = hydra, hydra
effects.tortuga, effects.cryptodira = turtle, turtle
local monsters = {}
for _, record in ipairs(roster) do
    monsters[#monsters + 1] = { name = record[1], aliases = { record[1] },
        extra_moves = record[2], replace_moves = true, spells = {} }
end
for monster, entries in pairs(effects) do
    local retail = monster == 'yumcax' or monster == 'hurkan' or monster == 'kumhau'
    for _, entry in pairs(entries) do
        entry.reference_note = retail
            and 'Retail family reference; CatsEyeXI lists this move but leaves its effects unspecified.'
            or 'CatsEyeXI Domain Invasion reference; base effects supplemented by pinned upstream data where needed.'
    end
end
return { monsters = monsters, effects = effects }
