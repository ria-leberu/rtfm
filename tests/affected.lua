-- Run from the addon directory with Lua 5.1 / LuaJIT.
package.path = './?.lua;' .. package.path
local affected = require('lib.affected')
local actions = require('lib.actions')
local config = require('config')
local widths = {}
ashita = { bits = { unpack_be = function(data, _, offset, length)
    table.insert(widths, { offset, length })
    local result = 0
    for i = 0, length - 1 do
        local bit_offset = offset + i
        local byte = data:byte(math.floor(bit_offset / 8) + 1)
        result = result + (math.floor(byte / 2 ^ (bit_offset % 8)) % 2) * 2 ^ i
    end
    return result
end } }

local function packet_bytes(category, targets, action_id)
    local bits = {}
    local function write(value, count)
        for i = 0, count - 1 do bits[#bits + 1] = math.floor(value / 2 ^ i) % 2 end
    end
    write(0, 40)
    write(100, 32) -- actor server id
    write(#targets, 6)
    write(0, 4)
    write(category, 4)
    write(action_id or (category == 11 and 300 or 44), 16)
    write(517, 16) -- nonzero unknown field must never become the action ID
    write(0, 32)
    for _, target in ipairs(targets) do
        write(target.id, 32)
        write(#target.messages, 4)
        for _, message in ipairs(target.messages) do
            write(0, 5 + 12 + 7 + 3)
            write(123, 17)
            write(message, 10)
            write(0, 31)
            write(target.additional and 1 or 0, 1)
            if target.additional then
                write(0, 10)
                write(0, 17)
                write(target.additional, 10)
            end
            write(target.spikes and 1 or 0, 1)
            if target.spikes then
                write(0, 10)
                write(0, 14)
                write(1, 10)
            end
        end
    end
    local bytes = {}
    for i = 1, #bits, 8 do
        local byte = 0
        for j = 0, 7 do byte = byte + (bits[i + j] or 0) * 2 ^ j end
        bytes[#bytes + 1] = string.char(byte)
    end
    return table.concat(bytes)
end
local function decode(data)
    return affected.parse({ id = 0x028, size = #data, data_raw = data })
end
local data = packet_bytes(11, {
    { id = 201, messages = { 185, 185 }, spikes = true },
    { id = 202, messages = { 242 } },
    { id = 203, messages = { 188 } }, -- miss
    { id = 204, messages = { 85 } }, -- full resist
    { id = 205, messages = { 185 } }, -- trust
    { id = 206, messages = { 185 } }, -- pet
    { id = 207, messages = { 238 } }, -- healing
    { id = 208, messages = { 0 }, additional = 163 },
    { id = 209, messages = { 999 } }, -- unknown outcome
})
local packet = assert(decode(data))
assert(packet.actor_id == 100 and packet.action_id == 300 and #packet.targets == 9)
assert(widths[1][1] == 40 and widths[1][2] == 32)
assert(widths[5][1] == 86 and widths[5][2] == 16)
assert(not decode(data:sub(1, #data - 6)))
assert(not decode(packet_bytes(1, {})))
assert(not affected.parse({ id = 0x028, injected = true, data_raw = data, size = #data }))

local entity_names = { 'Kirin', 'Zeta', 'Alpha', 'Missed', 'Resisted', 'Trust', 'Pet', 'Healed', 'Beta', 'Unknown' }
local ids = { 100, 201, 202, 203, 204, 205, 206, 207, 208, 209 }
local entities = {
    GetServerId = function(_, i) return ids[i + 1] or 0 end,
    GetName = function(_, i) return entity_names[i + 1] end,
    GetSpawnFlags = function(_, i) return i == 0 and 0x10 or 1 end,
    GetTrustOwnerTargetIndex = function(_, i) return (i == 5 or i == 6) and 1000 or 0 end,
}
bit = { band = function(a, b) return a == b and b or 0 end }
local resources = {
    GetString = function(_, key, id)
        assert(key == 'monsters.abilities' and id == 44)
        return 'Mortal Ray'
    end,
    GetSpellById = function(_, id) assert(id == 44); return { Name = { 'Fire II' } } end,
}
local result = assert(affected.resolve(packet, entities, resources))
assert(table.concat(result.affected_players, ', ') == 'Alpha, Beta, Zeta')
assert(result.monster == 'Kirin' and result.move == 'Mortal Ray')
local spell = assert(affected.resolve(decode(packet_bytes(4, {
    { id = 201, messages = { 2 } },
})), entities, resources))
assert(spell.move == 'Fire II' and spell.action == 'casts')
local missed = assert(affected.resolve(decode(packet_bytes(11, {
    { id = 203, messages = { 188 } }, { id = 204, messages = { 85 } },
})), entities, resources))
assert(#missed.affected_players == 0)

-- Khimaira regression: real chat color controls leave invisible palette bytes
-- behind if only the control marker itself is removed.
for _, move in ipairs({ { 2025, 'Dreadstorm', 185 }, { 2026, 'Fossilizing Breath', 242 } }) do
    local khimaira_entities = setmetatable({
        GetName = function(_, i) return i == 0 and 'Khimaira' or entity_names[i + 1] end,
    }, { __index = entities })
    local khimaira_resources = { GetString = function(_, key, id)
        assert(key == 'monsters.abilities' and id == move[1] - 256)
        return move[2]
    end }
    local report = assert(affected.resolve(assert(decode(packet_bytes(11, {
        { id = 201, messages = { move[3] } },
        { id = 202, messages = { 242 } },
    }, move[1]))), khimaira_entities, khimaira_resources))
    local colored = '\30\106Khimaira\30\1 uses \31\68' .. move[2] .. '\30\1.\127\49'
    local parsed = assert(actions.parse(colored, 185, config.casting_modes))
    assert(parsed.monster == 'Khimaira' and parsed.move == move[2])
    for _, packet_first in ipairs({ true, false }) do
        local khimaira_tracker = actions.new(config)
        if packet_first then khimaira_tracker:attach_affected(report, 0) end
        khimaira_tracker:record(parsed, 0.1)
        if not packet_first then khimaira_tracker:attach_affected(report, 0.2) end
        assert(table.concat(khimaira_tracker.recent[1].affected_players, ', ') == 'Alpha, Zeta')
        parsed = assert(actions.parse(colored, 185, config.casting_modes))
    end
end

local function completion(monster, move)
    return { monster = monster or 'Kirin', move = move or 'Mortal Ray', action = 'uses' }
end
local tracker = actions.new(config)
local burst = actions.new(config)
local function packet_result(actor_id, players)
    return { monster = 'Khimaira', move = 'Fossilizing Breath', action = 'uses',
        actor_id = actor_id, action_id = 2026, category = 11, affected_players = players }
end
assert(burst:record(packet_result(100, { 'Rialia' }), 0))
assert(not burst:record(packet_result(100, { 'Rialia' }), 0.05))
assert(not burst:record(packet_result(100, { 'Alpha' }), 0.1))
assert(#burst.recent == 1)
assert(table.concat(burst.recent[1].affected_players, ', ') == 'Alpha, Rialia')
assert(burst:record(packet_result(101, { 'Zeta' }), 0.2))
assert(#burst.recent == 2) -- same monster name, different server ID
assert(burst:record({ monster = 'Khimaira', move = 'Fossilizing Breath', action = 'readies' }, 0.3))
assert(burst:record(packet_result(100, { 'Rialia' }), 0.4))
assert(#burst.recent == 3) -- a new preparation denotes a genuine repeat
assert(not burst:record(packet_result(100, { 'Beta' }), 0.45))
assert(#burst.recent == 3)
assert(table.concat(burst.recent[3].affected_players, ', ') == 'Beta, Rialia')
assert(burst:record(packet_result(100, { 'Rialia' }), 3))
assert(#burst.recent == 4)
-- Packets before text, duplicate result lines, and later casts stay separate.
tracker:attach_affected(result, 1)
tracker:record(completion(), 1.1)
assert(tracker.recent[1].affected_players[1] == 'Alpha')
assert(not tracker:record(completion(), 1.2))
tracker:record(completion(), 3)
assert(tracker.recent[2].affected_players == nil)
tracker:attach_affected({ monster = 'Kirin', move = 'Mortal Ray', action = 'uses', affected_players = { 'Zeta' } }, 3.1)
assert(#tracker.recent[2].affected_players == 1)
assert(#tracker.recent[1].affected_players == 3)
tracker:record(completion('Genbu'), 3.2)
assert(tracker.recent[3].affected_players == nil)
tracker:record(completion('Kirin', 'Fulmination'), 3.3)
assert(tracker.recent[4].affected_players == nil)
tracker:attach_affected(result, 10)
tracker:update(12)
assert(tracker.recent[#tracker.recent].affected_players ~= nil)
tracker:record(completion(), 12)
assert(tracker.recent[#tracker.recent].affected_players == nil)

-- Verify the subtitle uses a smaller font and restores it before subsequent rows.
local texts, font_depth, current_size = {}, 0, 16
package.loaded.imgui = {
    SetNextWindowSizeConstraints = function() end,
    GetTextLineHeightWithSpacing = function() return 20 end,
    GetCursorScreenPos = function() return 0, 0 end,
    InvisibleButton = function() return false end,
    IsItemHovered = function() return false end,
    GetColorU32 = function() return 0 end,
    GetWindowDrawList = function() return { AddLine = function() end, AddCircle = function() end } end,
    GetWindowHeight = function() return 380 end, GetCursorPosY = function() return 30 end,
    SetScrollHereY = function() end,
    SetNextWindowBgAlpha = function() end, SetNextWindowSize = function() end,
    Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, child_flags, window_flags)
        assert(type(child_flags) == 'number' and type(window_flags) == 'number')
        return true
    end, EndChild = function() end,
    PushStyleColor = function() end, PopStyleColor = function() end,
    SameLine = function() end, Separator = function() end,
    Text = function(text) assert(font_depth == 0); texts[#texts + 1] = text end,
    GetFont = function() return {} end, GetFontSize = function() return current_size end,
    PushFont = function(_, size) assert(size < current_size); font_depth = font_depth + 1 end,
    PopFont = function() font_depth = font_depth - 1 end,
    TextWrapped = function(text) assert(font_depth == 1); texts[#texts + 1] = text end,
}
bit.bor = function() return 0 end
ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_AlwaysAutoResize = 0, 0, 0
require('lib.overlay').draw({ true }, { recent = { {
    monster = 'Kirin', move = 'Mortal Ray', action = 'uses', timestamp = 1,
    affected_players = { 'Alpha', 'Zeta' },
} }, pending = {} }, 2, config, {})
local found_hit = false
for _, text in ipairs(texts) do if text == 'Hit: Alpha, Zeta.' then found_hit = true end end
assert(found_hit and font_depth == 0)
texts = {}
require('lib.overlay').draw({ true }, { recent = { {
    monster = 'Kirin', move = 'Mortal Ray', action = 'uses', timestamp = 1,
    affected_players = {},
} }, pending = {} }, 2, config, {})
assert(#texts == 5 and font_depth == 0)
print('RTFM affected-player checks passed.')
