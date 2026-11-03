local imgui = require('imgui')
local names = require('lib.names')
local moves = require('data.catalogue')
local durations = require('data.generated.preparation_times')
local spells = require('data.generated.spell_cast_times')
local monsters = require('data.monster_index')
local bar = {}
local by_name = {}
for id, move in pairs(moves) do
    local key = names.normalize(move.name)
    by_name[key] = by_name[key] or {}
    by_name[key][#by_name[key] + 1] = id
end

local function valid(value)
    return type(value) == 'number' and value == value and value >= 0 and value < math.huge
end

function bar.duration(event)
    if valid(event.estimated_duration) then return event.estimated_duration end
    if event.action == 'casting' then return spells[names.trim(event.move):lower()] end
    if event.category == 7 and durations[event.action_id] ~= nil then return durations[event.action_id] end
    local key, candidates = names.normalize(event.move), {}
    for _, id in ipairs(monsters[names.normalize(event.monster)] or {}) do
        if moves[id] and names.normalize(moves[id].name) == key then candidates[#candidates + 1] = id end
    end
    if #candidates == 0 then candidates = by_name[key] or {} end
    local duration
    for _, id in ipairs(candidates) do
        local value = durations[id]
        if not valid(value) or (duration ~= nil and duration ~= value) then return nil end
        duration = value
    end
    return duration
end

function bar.fraction(event, now)
    local duration = bar.duration(event)
    if duration == nil then return nil end
    if duration == 0 then return 1 end
    return math.max(0, math.min(1, (now - event.timestamp) / duration))
end

function bar.paint(event, now, x, y, width, height)
    local duration = bar.duration(event)
    local fraction = bar.fraction(event, now)
    local draw = imgui.GetWindowDrawList()
    local inset = 2
    draw:AddRectFilled({ x, y }, { x + width, y + height }, imgui.GetColorU32({ 0.1, 0.1, 0.13, 0.9 }), 3)
    local available = width - inset * 2
    local left, right
    if fraction then
        left, right = 0, available * fraction
    else
        -- No reliable duration: a moving segment rather than an invented ETA.
        local progress = 0.5 + 0.5 * math.sin(now * 3)
        left = progress * available * 0.7
        right = left + available * 0.3
    end
    if right > left then
        local color = event.action == 'casting' and { 0.55, 0.6, 1, 0.9 } or { 1, 0.8, 0.2, 0.9 }
        draw:AddRectFilled({ x + inset + left, y + inset },
            { x + inset + right, y + height - inset }, imgui.GetColorU32(color), 2)
    end
    return duration
end

function bar.draw(event, now, width, height, id)
    imgui.InvisibleButton('##preparation_bar_' .. id, { width, height })
    local x, y = imgui.GetItemRectMin()
    local duration = bar.paint(event, now, x, y, width, height)
    if imgui.IsItemHovered() then
        local text = duration and string.format('Estimated base preparation time: %.1fs.', duration)
            or 'Preparation time unknown; moving indicator only.'
        imgui.SetTooltip(text .. '\nServer changes, Fast Cast and latency may affect timing.\nA full bar waits for completion, interruption or timeout.')
    end
end

return bar
