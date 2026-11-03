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
        -- Category 8's interruption marker is not a spell ID.
        if result.category == 8 and result.action_id == 28787 then
            result.interrupted = true
            return result
        end
        result.preparing = result.category == 7 or result.category == 8
        if result.category == 8 and result.action_id ~= 24931 then
            error('Unsupported casting marker: ' .. tostring(result.action_id) .. ' actor=' .. tostring(result.actor_id))
        end
        if not result.preparing and result.category ~= 4 and result.category ~= 6 and result.category ~= 11 then return end
        for _ = 1, count do
            local target = { id = read(32), hit = false }
            local action_count = read(4)
            for _ = 1, action_count do
                read(5) -- reaction
                read(12) -- animation
                read(7) -- special effect
                read(3) -- knockback
                local param = read(17) -- preparation ID, or result amount / status
                if not target.action_id then target.action_id = param end
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
        if result.preparing then
            result.preparation_marker = result.action_id
            result.action_id = result.targets[1] and result.targets[1].action_id
            if not result.action_id or result.action_id == 0 then
                error('Missing preparation ID: actor=' .. tostring(result.actor_id) .. ' category=' .. tostring(result.category))
            end
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
    if not actor then return nil, 'actor absent from entity table' end
    if not actor.monster then return nil, 'actor is not a monster: ' .. actor.name end
    if packet.interrupted then
        return { actor_id = packet.actor_id, monster = actor.name, action = 'interrupted',
            category = packet.category }
    end
    local move, cast_time
    if packet.category == 11 or packet.category == 7 then
        if packet.action_id < 256 then return nil, 'monster ability ID below 256' end
        move = resources:GetString('monsters.abilities', packet.action_id - 256, 2)
    else
        local resource
        if packet.category == 4 or packet.category == 8 then resource = resources:GetSpellById(packet.action_id)
        else resource = resources:GetAbilityById(packet.action_id + 512) end
        move = resource and resource.Name[1]
        if packet.category == 8 and resource and type(resource.CastTime) == 'number' then
            cast_time = resource.CastTime * 0.25 -- Ashita resource units are quarter-seconds.
        end
    end
    if type(move) ~= 'string' or move == '' then return nil, 'action resource name unavailable' end
    local players, seen, target_ids = {}, {}, {}
    for _, target in ipairs(packet.targets) do
        target_ids[#target_ids + 1] = target.id
        local entity = resolved[target.id]
        if target.hit and entity and entity.player and not seen[target.id] then
            seen[target.id] = true
            table.insert(players, entity.name)
        end
    end
    table.sort(players)
    if packet.preparing then
        local primary = packet.targets[1]
        local target = primary and resolved[primary.id]
        return {
            actor_id = packet.actor_id, action_id = packet.action_id, category = packet.category,
            monster = actor.name, move = move:gsub('%z+$', ''),
            action = packet.category == 8 and 'casting' or 'readies',
            preparation_target = target and target.name or nil,
            preparation_target_id = primary and primary.id or nil,
            estimated_duration = cast_time,
            target_ids = target_ids,
        }
    end
    return {
        actor_id = packet.actor_id, action_id = packet.action_id, category = packet.category,
        monster = actor.name, move = move:gsub('%z+$', ''),
        action = packet.category == 4 and 'casts' or 'uses',
        affected_players = players,
        target_ids = target_ids,
    }
end

return affected
