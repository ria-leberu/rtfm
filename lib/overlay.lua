local imgui = require('imgui')
local appearance = require('lib.appearance')
local names = require('lib.names')
local descriptions = require('lib.descriptions')
local action_roles = require('lib.action_roles')
local timing = require('lib.timing')
local overlay = {}
local verbs = { readies = 'readies', casting = 'starts casting', uses = 'used', casts = 'cast' }
local last_history_row

local function draw_affected(event, config)
    local players = table.concat(event.affected_players, ', ')
    imgui.PushFont(imgui.GetFont(), imgui.GetFontSize() * config.affected_font_scale)
    imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.9, 0.2, 1 })
    if config.single_line_log then imgui.SameLine(0, 6) end
    local size = imgui.GetFontSize()
    local x, y = imgui.GetCursorScreenPos()
    local draw = imgui.GetWindowDrawList()
    local color = imgui.GetColorU32({ 1, 0.9, 0.2, 1 })
    local center, tip = y + size * 0.5, x + size * 0.85
    local thickness = math.max(1, size * 0.09)
    -- Draw an arrow directly, independent of font glyph coverage.
    draw:AddLine({ x + size * 0.1, center }, { tip, center }, color, thickness)
    draw:AddLine({ tip - size * 0.3, center - size * 0.28 }, { tip, center }, color, thickness)
    draw:AddLine({ tip - size * 0.3, center + size * 0.28 }, { tip, center }, color, thickness)
    imgui.Dummy({ size, size })
    imgui.SameLine(0, 3)
    if config.single_line_log then imgui.Text(players) else imgui.TextWrapped(players) end
    imgui.PopStyleColor()
    imgui.PopFont()
end

local function settings_button()
    local size = imgui.GetTextLineHeightWithSpacing()
    local x, y = imgui.GetCursorScreenPos()
    local clicked = imgui.InvisibleButton('##rtfm_settings', { size, size })
    local hovered = imgui.IsItemHovered()
    local color = imgui.GetColorU32(hovered and { 1, 1, 1, 1 } or { 0.7, 0.7, 0.7, 1 })
    local draw = imgui.GetWindowDrawList()
    local center = { x + size / 2, y + size / 2 }
    -- Draw the gear directly so it does not depend on an icon font.
    local points = {}
    for i = 0, 31 do
        local radius = size * ((i % 4 == 0 or i % 4 == 3) and 0.43 or 0.32)
        local angle = i * math.pi / 16
        points[#points + 1] = { center[1] + math.cos(angle) * radius, center[2] + math.sin(angle) * radius }
    end
    for i, point in ipairs(points) do draw:AddLine(point, points[i % #points + 1], color, 1.5) end
    draw:AddCircle(center, size * 0.14, color, 12, 1.5)
    if hovered then imgui.SetTooltip('Settings') end
    return clicked
end

local function draw_rows(rows, pending, now, config, moves, move_alerts)
    local changed = false
    for row = 1, #rows do
        local i = row
        local event = rows[i]
        local age = math.max(0, now - event.timestamp)
        local alpha = 1
        local pulse = pending and (0.6 + 0.4 * math.abs(math.sin(now * 3))) or 1
        local tracked = move_alerts and move_alerts:is_selected(event)
        local color
        if tracked then
            color = appearance.palette().tracked
        elseif event.action == 'casting' or event.action == 'casts' then
            color = { 0.6, 0.6 * pulse, pulse, alpha }
        elseif pending then
            color = { 1, pulse, 0.3 * pulse, alpha }
        else
            color = { 1, 0.3, 0.3, alpha }
        end
        local text = string.format('%s %s %s',
            event.monster, verbs[event.action], event.move)
        local role = action_roles.lookup(event, moves)
        if not pending and move_alerts then
            local selected = move_alerts:is_selected(event)
            local label = selected and 'Untrack' or 'Track'
            if selected then
                imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
                imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
                imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
            end
            local button_width, button_height = imgui.CalcTextSize(label)
            local scale = config.log_font_scale
            if imgui.Button(label .. '##move_alert_' .. i,
                { button_width + 8 * scale, button_height + 6 * scale }) then
                move_alerts:set(event, not selected)
                changed = true
            end
            if selected then imgui.PopStyleColor(3) end
            if imgui.IsItemHovered() then
                local preparation = event.action == 'casts' and ' starts casting ' or ' readies '
                imgui.SetTooltip('Alert when ' .. event.monster .. preparation .. event.move)
            end
            imgui.SameLine()
        end
        if role then
            local x, y = imgui.GetCursorScreenPos()
            local width, height = imgui.CalcTextSize(text)
            local background = appearance.palette()[role]
            imgui.GetWindowDrawList():AddRectFilled({ x - 2, y }, { x + width + 2, y + height },
                imgui.GetColorU32(background), 2)
            if not tracked then color = { 1, 1, 1, alpha } end
        end
        imgui.PushStyleColor(ImGuiCol_Text, color)
        imgui.Text(text)
        imgui.PopStyleColor()
        descriptions.draw(event, moves)
        local has_players = not pending and event.affected_players and #event.affected_players > 0
        if has_players and config.single_line_log then draw_affected(event, config) end
        imgui.SameLine()
        imgui.PushStyleColor(ImGuiCol_Text, { 0.7, 0.7, 0.7, alpha })
        imgui.Text(timing.elapsed(age))
        if has_players and not config.single_line_log then draw_affected(event, config) end
        imgui.PopStyleColor()
        if row < #rows then imgui.Separator() end
    end
    return changed
end

function overlay.draw(is_open, tracker, now, config, moves, move_alerts, config_open)
    if not is_open[1] then return false end
    local changed = false
    local scale = config.log_font_scale
    imgui.PushFont(imgui.GetFont(), imgui.GetFontSize() * scale)
    imgui.SetNextWindowBgAlpha(0.85)
    imgui.SetNextWindowSize({ 560, 380 }, ImGuiCond_FirstUseEver)
    imgui.SetNextWindowSizeConstraints({ 400, 260 }, { 10000, 10000 })
    local visible = imgui.Begin('RTFM Log', is_open,
        bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse))
    if visible then
        if settings_button() and config_open then config_open[1] = not config_open[1] end
        imgui.SameLine()
        imgui.Text('RTFM Log')
        local line_height = imgui.GetTextLineHeightWithSpacing()
        local available_height = math.max(120, imgui.GetWindowHeight() - imgui.GetCursorPosY() - line_height - 20)
        local pending_height = math.min(math.max(1, math.min(#tracker.pending, 3)) * line_height * 3 + 12,
            available_height * 0.55)
        local history_height = available_height - pending_height
        if imgui.BeginChild('##rtfm_history', { 0, history_height }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            if #tracker.recent == 0 then imgui.Text('No recent actions.') end
            changed = draw_rows(tracker.recent, false, now, config, moves, move_alerts)
            local newest = tracker.recent[#tracker.recent]
            if newest and newest ~= last_history_row then imgui.SetScrollHereY(1.0) end
            last_history_row = newest
        end
        imgui.EndChild()
        imgui.Separator()
        imgui.Text('Readying/Casting')
        if imgui.BeginChild('##rtfm_pending', { 0, pending_height }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            if #tracker.pending == 0 then imgui.Text('No moves or spells being prepared.') end
            draw_rows(tracker.pending, true, now, config, moves, move_alerts)
            -- Keep the newest preparation visible if several enemies act.
            imgui.SetScrollHereY(1.0)
        end
        imgui.EndChild()
    end
    imgui.End()
    imgui.PopFont()
    return changed
end

return overlay
