local imgui = require('imgui')
local names = require('lib.names')
local overlay = {}
local verbs = { readies = 'readies', casting = 'starts casting', uses = 'used', casts = 'cast' }

local function draw_rows(rows, pending, now, config, moves)
    for i, event in ipairs(rows) do
        local age = math.max(0, now - event.timestamp)
        local duration = pending and config.pending_timeout or config.display_time
        local alpha = 1 - math.min(age / duration, 1) ^ 2.5
        local pulse = pending and (0.6 + 0.4 * math.abs(math.sin(now * 3))) or 1
        local highlighted = config.highlight_mobs[names.normalize(event.monster)]
        local color
        if highlighted then
            color = { 0.2, pulse, 0.2, alpha }
        elseif event.action == 'casting' or event.action == 'casts' then
            color = { 0.6, 0.6 * pulse, pulse, alpha }
        elseif pending then
            color = { 1, pulse, 0.3 * pulse, alpha }
        else
            color = { 1, 0.3, 0.3, alpha }
        end
        local text = string.format('%s%s %s %s', highlighted and '>>> ' or '',
            event.monster, verbs[event.action], event.move)
        imgui.PushStyleColor(ImGuiCol_Text, color)
        imgui.Text(text)
        imgui.PopStyleColor()
        imgui.SameLine()
        imgui.PushStyleColor(ImGuiCol_Text, { 0.7, 0.7, 0.7, alpha })
        imgui.Text(string.format('(%.1fs ago)', age))
        local mob_moves = moves[names.normalize(event.monster)]
        local description = mob_moves and mob_moves[names.normalize(event.move)]
        if description and description ~= '' then imgui.Text('Effect: ' .. description) end
        imgui.PopStyleColor()
        if i < #rows then imgui.Separator() end
    end
end

function overlay.draw(is_open, tracker, now, config, moves)
    if not is_open[1] then return end
    imgui.SetNextWindowBgAlpha(0.85)
    imgui.SetNextWindowSize({ 520, 140 }, ImGuiCond_FirstUseEver)
    local visible = imgui.Begin('RTFM Overlay', is_open,
        bit.bor(ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_AlwaysAutoResize))
    if visible then
        if #tracker.recent == 0 then imgui.Text('No recent actions.') end
        draw_rows(tracker.recent, false, now, config, moves)
        if #tracker.pending > 0 then
            imgui.Separator()
            imgui.Text('Readying...')
            draw_rows(tracker.pending, true, now, config, moves)
        end
    end
    imgui.End()
end

return overlay
