local imgui = require('imgui')
local appearance = require('lib.appearance')
local names = require('lib.names')
local descriptions = require('lib.descriptions')
local action_roles = require('lib.action_roles')
local timing = require('lib.timing')
local sound_window = require('lib.sound_window')
local display_text = require('lib.display_text')
local icon_buttons = require('lib.icon_buttons')
local row_layout = require('lib.row_layout')
local preparation_bar = require('lib.preparation_bar')
local completion_animation = require('lib.completion_animation')
local party_order = require('lib.party_order')
local overlay = {}
local last_history_row
local was_minimized
local expanded_size = { 560, 380 }
local window_width = 560

local function window_button(id, kind, size)
    local clicked = imgui.InvisibleButton(id, { size, size })
    local x, y = imgui.GetItemRectMin()
    local draw = imgui.GetWindowDrawList()
    local color = imgui.GetColorU32(imgui.IsItemHovered() and { 1, 1, 1, 1 } or { 0.7, 0.7, 0.7, 1 })
    local a, b = size * 0.25, size * 0.75
    if kind == 'close' then
        draw:AddLine({ x + a, y + a }, { x + b, y + b }, color, 2)
        draw:AddLine({ x + b, y + a }, { x + a, y + b }, color, 2)
    elseif kind == 'restore' then
        draw:AddRect({ x + a, y + a }, { x + b, y + b }, color, 0, 0, 2)
    else
        draw:AddLine({ x + a, y + b }, { x + b, y + b }, color, 2)
    end
    if imgui.IsItemHovered() then
        imgui.SetTooltip(kind == 'close' and 'Hide RTFM (/rtfm to show)' or
            (kind == 'restore' and 'Show move history' or 'Show Readying/Casting only'))
    end
    return clicked
end

local function draw_affected(event, config, alignment, party_members)
    local players, full_names = display_text.players(event.affected_players, config.abbreviate_player_names, party_members)
    imgui.PushFont(imgui.GetFont(), imgui.GetFontSize() * config.affected_font_scale)
    imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.9, 0.2, 1 })
    local size = imgui.GetFontSize()
    if config.single_line_log then alignment:same_line(6, size) end
    local x, y = imgui.GetCursorScreenPos()
    alignment = alignment or row_layout.new(y, size)
    local draw = imgui.GetWindowDrawList()
    local color = imgui.GetColorU32({ 1, 0.9, 0.2, 1 })
    local center, tip = y + size * 0.5, x + size * 0.85
    local thickness = math.max(1, size * 0.09)
    -- Draw an arrow directly, independent of font glyph coverage.
    draw:AddLine({ x + size * 0.1, center }, { tip, center }, color, thickness)
    draw:AddLine({ tip - size * 0.3, center - size * 0.28 }, { tip, center }, color, thickness)
    draw:AddLine({ tip - size * 0.3, center + size * 0.28 }, { tip, center }, color, thickness)
    imgui.Dummy({ size, size })
    alignment:same_line(3, size)
    alignment:text(players, not config.single_line_log)
    if config.abbreviate_player_names and imgui.IsItemHovered() then
        imgui.SetTooltip(string.format('%d affected players:\n%s', #event.affected_players,
            full_names or table.concat(event.affected_players, '\n')))
    end
    imgui.PopStyleColor()
    imgui.PopFont()
end

local function settings_button(size)
    local clicked = imgui.InvisibleButton('##rtfm_settings', { size, size })
    local x, y = imgui.GetItemRectMin()
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

local function draw_rows(rows, pending, now, config, moves, move_alerts, mob_names, bounds, party_members)
    local changed = false
    for row = 1, #rows do
        local row_x, row_y = imgui.GetCursorPosX(), imgui.GetCursorPosY()
        local _, row_screen_y = imgui.GetCursorScreenPos()
        local font_size = imgui.GetFontSize()
        local icon_size = font_size * 1.4
        local alignment = row_layout.new(row_screen_y, icon_size)
        local gap = math.max(2, font_size * 0.25)
        local controls_width = icon_size * 2 + 2
        local timer_width = imgui.CalcTextSize('88:88.8')
        local controls_x = row_x + timer_width + gap
        local action_x = controls_x + controls_width + gap
        if pending then action_x = row_x end
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
        local text = display_text.action(event, config.compact_log_text, mob_names)
        local role = action_roles.lookup(event, moves)
        if not pending then
            imgui.SetCursorPos({ controls_x, row_y })
            if move_alerts then
                local selected = move_alerts:is_selected(event)
                if selected then
                    imgui.PushStyleColor(ImGuiCol_Button, appearance.button())
                    imgui.PushStyleColor(ImGuiCol_ButtonHovered, appearance.button('hover'))
                    imgui.PushStyleColor(ImGuiCol_ButtonActive, appearance.button('active'))
                end
                if icon_buttons.track('move_alert_' .. i, selected) then
                    move_alerts:set(event, not selected)
                    changed = true
                end
                if selected then imgui.PopStyleColor(3) end
                if imgui.IsItemHovered() then
                    local preparation = event.action == 'casts' and ' starts casting ' or ' readies '
                    imgui.SetTooltip('Alert when ' .. event.monster .. preparation .. event.move)
                end
                imgui.SameLine(0, 2)
                imgui.SetCursorPos({ controls_x + icon_size + 2, row_y })
                if icon_buttons.sound('move_sound_' .. i) then sound_window.open(event) end
            else
                -- Preserve the controls column when no tracking model is supplied.
                imgui.Dummy({ controls_width, icon_size })
            end
            imgui.SameLine(0, gap)
            local elapsed = timing.elapsed(age)
            local elapsed_width, elapsed_height = imgui.CalcTextSize(elapsed)
            imgui.SetCursorPosX(row_x + timer_width - elapsed_width)
            alignment:center(elapsed_height)
            imgui.PushStyleColor(ImGuiCol_Text, { 0.7, 0.7, 0.7, alpha })
            alignment:text(elapsed)
            if imgui.IsItemHovered() then imgui.SetTooltip('Minutes:seconds.tenths') end
            imgui.PopStyleColor()
        end
        if not pending then imgui.SameLine(0, gap) end
        imgui.SetCursorPosX(action_x)
        local _, text_height = imgui.CalcTextSize(text)
        alignment:center(text_height)
        if role then
            local x, y = imgui.GetCursorScreenPos()
            local width, height = imgui.CalcTextSize(text)
            local background = appearance.palette()[role]
            imgui.GetWindowDrawList():AddRectFilled({ x - 2, y }, { x + width + 2, y + height },
                imgui.GetColorU32(background), 2)
            if not tracked then color = { 1, 1, 1, alpha } end
        end
        local progress = not pending and completion_animation.state(event, now)
        if progress then
            local x, y = imgui.GetCursorScreenPos()
            local width, height = imgui.CalcTextSize(text)
            imgui.GetWindowDrawList():AddRectFilled({ x - 2, y - 1 }, { x + width + 2, y + height + 1 },
                imgui.GetColorU32({ 1, 0.85, 0.3, 0.2 * (1 - progress) }), 2)
        end
        imgui.PushStyleColor(ImGuiCol_Text, color)
        alignment:text(text)
        if imgui.IsItemHovered() then
            local details = descriptions.tooltip(event, moves)
            if config.compact_log_text or details ~= '' then
                imgui.SetTooltip(display_text.action(event, false) .. (details ~= '' and ('\n' .. details) or ''))
            end
        end
        imgui.PopStyleColor()
        local text_x, text_y = imgui.GetItemRectMin()
        if pending then
            completion_animation.remember(event, text_x, text_y, now)
            alignment:same_line(gap, icon_size)
            preparation_bar.draw(event, now, font_size * 8, icon_size, i)
        else
            completion_animation.draw(event, now, text_x, text_y, text, bounds)
        end
        descriptions.draw(event, moves, config.compact_log_text, alignment)
        if pending and event.preparation_target then
            alignment:same_line(6, font_size)
            imgui.PushStyleColor(ImGuiCol_Text, { 1, 0.9, 0.2, 1 })
            alignment:text('-> ' .. event.preparation_target)
            imgui.PopStyleColor()
        end
        local has_players = not pending and event.affected_players and #event.affected_players > 0
        if has_players and config.single_line_log then draw_affected(event, config, alignment, party_members) end
        if has_players and not config.single_line_log then
            imgui.SetCursorPosX(row_x)
            draw_affected(event, config, nil, party_members)
        end
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
    local minimized = config.overlay_minimized == true
    local line_height = imgui.GetTextLineHeightWithSpacing()
    local compact_height = 52 * scale + math.max(1, math.min(#tracker.pending, 3)) * line_height * 3
    imgui.SetNextWindowSize({ 560, 380 }, ImGuiCond_FirstUseEver)
    if minimized then
        imgui.SetNextWindowSize({ window_width, compact_height })
    elseif was_minimized then
        imgui.SetNextWindowSize(expanded_size)
    end
    imgui.SetNextWindowSizeConstraints({ 400, minimized and 80 or 260 }, { 10000, 10000 })
    was_minimized = minimized
    local visible = imgui.Begin('RTFM Log', is_open,
        bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoCollapse))
    if visible then
        window_width = imgui.GetWindowWidth()
        if not minimized then expanded_size = { window_width, imgui.GetWindowHeight() } end
        local party_members = config.abbreviate_player_names
            and party_order.snapshot(AshitaCore:GetMemoryManager():GetParty()) or nil
        local window_x, window_y = imgui.GetWindowPos()
        local bounds = { { window_x, window_y },
            { window_x + imgui.GetWindowWidth(), window_y + imgui.GetWindowHeight() } }
        local mob_names = config.compact_log_text and display_text.mob_names(tracker.recent, tracker.pending) or nil
        local _, header_y = imgui.GetCursorScreenPos()
        local header_size = imgui.GetFontSize() * 1.25
        imgui.PushFont(imgui.GetFont(), header_size)
        row_layout.new(header_y, header_size):text(minimized and 'Readying/Casting' or 'RTFM Log')
        imgui.PopFont()
        imgui.SameLine(0, 6 * scale)
        local gear_x = imgui.GetCursorScreenPos()
        imgui.SetCursorScreenPos({ gear_x, header_y })
        if settings_button(header_size) and config_open then config_open[1] = not config_open[1] end
        imgui.SameLine(0, 0)
        imgui.SetCursorScreenPos({ window_x + imgui.GetWindowWidth() - header_size * 2 - 16 * scale, header_y })
        if window_button('##rtfm_minimize', minimized and 'restore' or 'minimize', header_size) then
            config.overlay_minimized = not minimized
            changed = true
        end
        imgui.SameLine(0, 4 * scale)
        imgui.SetCursorScreenPos({ window_x + imgui.GetWindowWidth() - header_size - 12 * scale, header_y })
        if window_button('##rtfm_close', 'close', header_size) then is_open[1] = false end
        local line_height = imgui.GetTextLineHeightWithSpacing()
        local available_height = math.max(120, imgui.GetWindowHeight() - imgui.GetCursorPosY() - line_height - 20)
        local pending_height = math.min(math.max(1, math.min(#tracker.pending, 3)) * line_height * 3 + 12,
            available_height * 0.55)
        if minimized then pending_height = math.max(30, imgui.GetWindowHeight() - imgui.GetCursorPosY() - 12 * scale) end
        local history_height = available_height - pending_height
        if not minimized then
            if imgui.BeginChild('##rtfm_history', { 0, history_height }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
                if #tracker.recent == 0 then imgui.Text('No recent actions.') end
                changed = draw_rows(tracker.recent, false, now, config, moves, move_alerts, mob_names, bounds, party_members) or changed
                local newest = tracker.recent[#tracker.recent]
                if newest and newest ~= last_history_row then imgui.SetScrollHereY(1.0) end
                last_history_row = newest
            end
            imgui.EndChild()
            imgui.Separator()
            imgui.Text('Readying/Casting')
        end
        if imgui.BeginChild('##rtfm_pending', { 0, pending_height }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            if #tracker.pending == 0 then imgui.Text('No moves or spells being prepared.') end
            draw_rows(tracker.pending, true, now, config, moves, move_alerts, mob_names, bounds, party_members)
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
