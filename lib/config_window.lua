local imgui = require('imgui')
local browser_window = require('lib.browser_window')
local window = {}
local names = require('lib.names')
local sound_window = require('lib.sound_window')
local search = { '' }

local function tracked_groups(alerts)
    local groups, result = {}, {}
    for _, rule in ipairs(alerts:list()) do
        if rule.kind ~= 'spell' and rule.scope ~= 'spell' then
            local key = (rule.scope or 'monster') .. ':' .. names.normalize(rule.monster)
            local group = groups[key]
            if not group then
                group = { name = rule.monster, scope = rule.scope, rules = {}, active = false }
                groups[key] = group
            end
            group.rules[#group.rules + 1] = rule
            group.active = group.active or rule.enabled
        end
    end
    for _, group in pairs(groups) do if group.active then result[#result + 1] = group end end
    table.sort(result, function(a,b) return a.name:lower() < b.name:lower() end)
    return result
end

function window.draw(is_open, alerts, config)
    if not is_open[1] then return browser_window.draw(alerts) end
    local changed = false
    imgui.SetNextWindowSize({ 680, 680 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Settings', is_open, ImGuiWindowFlags_NoCollapse) then
        if imgui.Button('Browse families / notorious monsters') then browser_window.open() end
        imgui.SameLine()
        if imgui.Button('Track spells') then browser_window.open_spells() end
        imgui.Text('Search enemies, NMs, families, moves and spells')
        imgui.SetNextItemWidth(math.max(180, imgui.GetWindowWidth() - 100))
        local submitted = imgui.InputText('##rtfm_global_search', search, 128, ImGuiInputTextFlags_EnterReturnsTrue or 32)
        imgui.SameLine()
        if imgui.Button('Search') or submitted then browser_window.open_search(search[1]) end
        imgui.Separator()
        imgui.Text('Tracked families / named enemies')
        if imgui.BeginChild('##tracked_families', { 0, 170 }, 1, 0) then
            local groups = tracked_groups(alerts)
            if #groups == 0 then imgui.Text('No tracked families or enemies.') end
            for i, group in ipairs(groups) do
                imgui.Text((group.scope == 'family' and 'Family: ' or 'Enemy: ') .. group.name)
                imgui.SameLine()
                if imgui.Button('Edit##group_' .. i) then browser_window.open_group(group) end
                imgui.SameLine()
                if imgui.Button('Remove##group_' .. i) then
                    for _, rule in ipairs(group.rules) do alerts:remove(rule) end
                    changed = true
                end
                imgui.Separator()
            end
        end
        imgui.EndChild()
        if imgui.CollapsingHeader('Alerts and sounds', ImGuiTreeNodeFlags_DefaultOpen or 32) then
            local sound_enabled = { config.sound_alerts_enabled }
            if imgui.Checkbox('Enable sound alerts', sound_enabled) then
                config.sound_alerts_enabled = sound_enabled[1]
                changed = true
            end
            if imgui.Button('Manage sounds') then sound_window.open() end
            local center_alert = { config.center_alert_enabled }
            if imgui.Checkbox('Flashing center-screen alerts for tracked moves / spells', center_alert) then
                config.center_alert_enabled = center_alert[1]
                changed = true
            end
            local extra = { config.center_alert_extra_seconds }
            if imgui.SliderInt('Keep banner after preparation (seconds)', extra, 0, 30) then
                config.center_alert_extra_seconds = math.max(0, math.min(30, extra[1]))
                changed = true
            end
        end
        if imgui.CollapsingHeader('Log appearance', ImGuiTreeNodeFlags_DefaultOpen or 32) then
            local single_line = { config.single_line_log }
            if imgui.Checkbox('Move, description and affected players on one line', single_line) then
                config.single_line_log = single_line[1]
                changed = true
            end
            local scale = { math.floor(config.log_font_scale * 100 + 0.5) }
            local player_names = { config.abbreviate_player_names }
            if imgui.Checkbox('Show all affected names as 3 letters', player_names) then
                config.abbreviate_player_names = player_names[1]
                changed = true
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip('Show every affected player using three letters, grouped by party in client slot order. Hover for full names. Non-alliance players appear under Other.')
            end
            local compact = { config.compact_log_text }
            if imgui.Checkbox('Compact log text (abbreviations / symbols)', compact) then
                config.compact_log_text = compact[1]
                changed = true
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip('~ means readying; cast~ means casting. Mob names are abbreviated unless they collide. Hover for full text. Player names stay unchanged.')
            end
            if imgui.SliderInt('Log text size (%)', scale, 75, 200) then
                config.log_font_scale = scale[1] / 100
                changed = true
            end
        end
        if imgui.CollapsingHeader('History', ImGuiTreeNodeFlags_DefaultOpen or 32) then
            local limit = { config.max_recent }
            if imgui.InputInt('Moves in log', limit) then
                config.max_recent = math.max(1, math.min(250, limit[1]))
                changed = true
            end
            local retention = { config.log_retention_minutes }
            if imgui.SliderInt('Log retention (minutes)', retention, 1, 15) then
                config.log_retention_minutes = math.max(1, math.min(15, retention[1]))
                changed = true
            end
            imgui.Text('Elapsed: 00:00.0 (minutes:seconds.tenths).')
        end
        if imgui.CollapsingHeader('Enemy filters', ImGuiTreeNodeFlags_DefaultOpen or 32) then
            local party_only = { config.party_enemies_only }
            if imgui.Checkbox('Only enemies engaged with my party/alliance', party_only) then
                config.party_enemies_only = party_only[1]
                changed = true
            end
        end

    end
    imgui.End()
    if browser_window.draw(alerts) then changed = true end
    return changed
end

return window
