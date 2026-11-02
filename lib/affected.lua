-- Read-only 0x028 result decoding. Field layout follows the action packet
-- format used by the installed Ashita addons (chains / XIUI).
local affected = {}

-- Successful damage, drains, dispels, and status outcomes. Unknown messages are
-- deliberately omitted rather than counting every targeted player as hit.
local hit_messages = {}
for _, id in ipairs({
    1, 2, 67, 110, 157, 161, 162, 163, 164, 165,
    185, 186, 187, 194, 197, 225, 226, 227, 228, 230, 231,
    236, 237, 242, 243, 252, 264, 265, 266, 267, 268, 269, 270, 271, 272,
    274, 275, 281, 329, 330, 331, 332, 333, 334, 335, 341, 342, 362, 363,
    366, 369, 370, 379, 403, 404, 405, 406, 519, 520, 521, 522,
    533, 534, 645, 646, 652, 730, 736, 737, 746, 747, 748, 749, 750,
    751, 752, 753, 754, 755, 757, 778, 792, 802, 803, 804, 805,
}) do hit_messages[id] = true end

function affected.parse(e)
    if not e or e.id ~= 0x028 or e.injected or not e.data_raw
        or type(e.size) ~= 'number' or e.size < 19 then return end
    local offset = 40
    local function read(length)
        if offset + length > e.size * 8 then error('Truncated action packet') end
        local value = ashita.bits.unpack_be(e.data_raw, 0, offset, length)
        offset = offset + length
        return value
    end
    local ok, packet = pcall(function()
        local result = { actor_id = read(32), targets = {} }
        local count = read(6)
        read(4)
        result.category = read(4)
        -- These are two separate 16-bit fields. Read the action ID at bit 86
        -- directly; masking a combined unpack_be value can select the unknown
        -- field instead, preventing the resource name from matching chat.
        result.action_id = read(16)
        read(16)
        read(32)
        if result.category ~= 4 and result.category ~= 6 and result.category ~= 11 then return end
        for _ = 1, count do
            local target = { id = read(32), hit = false }
            local action_count = read(4)
            for _ = 1, action_count do
                read(5) -- reaction
                read(12) -- animation
                read(7) -- special effect
                read(3) -- knockback
                read(17) -- amount / status
                local message = read(10)
                target.message = message
                read(31)
                if hit_messages[message] then target.hit = true end
                if read(1) == 1 then
                    read(10)
                    read(17)
                    if hit_messages[read(10)] then target.hit = true end
                end
                if read(1) == 1 then
                    -- Spikes affect the attacker, not this target.
                    read(10)
                    read(14)
                    read(10)
                end
            end
            table.insert(result.targets, target)
        end
        return result
    end)
    if ok then return packet end
    return nil, packet
end

function affected.resolve(packet, entities, resources)
    local wanted = { [packet.actor_id] = true }
    for _, target in ipairs(packet.targets) do wanted[target.id] = true end
    local resolved = {}
    for i = 0, 2303 do
        local id = entities:GetServerId(i)
        if wanted[id] then
            local name = entities:GetName(i)
            if name and name ~= '' then
                local flags = entities:GetSpawnFlags(i)
                local pet = entities:GetTrustOwnerTargetIndex(i) ~= 0
                resolved[id] = {
                    name = name,
                    player = bit.band(flags, 0x01) ~= 0 and not pet,
                    monster = bit.band(flags, 0x10) ~= 0 and not pet,
                }
            end
        end
    end
    local actor = resolved[packet.actor_id]
    if not actor or not actor.monster then return end
    local move
    if packet.category == 11 then
        if packet.action_id < 256 then return end
        move = resources:GetString('monsters.abilities', packet.action_id - 256, 2)
    else
        local resource
        if packet.category == 4 then resource = resources:GetSpellById(packet.action_id)
        else resource = resources:GetAbilityById(packet.action_id + 512) end
        move = resource and resource.Name[1]
    end
    if type(move) ~= 'string' or move == '' then return end
    local players, seen = {}, {}
    for _, target in ipairs(packet.targets) do
        local entity = resolved[target.id]
        if target.hit and entity and entity.player and not seen[target.id] then
            seen[target.id] = true
            table.insert(players, entity.name)
        end
    end
    table.sort(players)
    return {
        monster = actor.name, move = move:gsub('%z+$', ''),
        action = packet.category == 4 and 'casts' or 'uses',
        affected_players = players,
    }
end

return affected
