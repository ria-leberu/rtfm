local imgui = require('imgui')
local browser_window = require('lib.browser_window')
local window = {}
local editing, error_message
local enemy_input, move_input, enabled_input = { '' }, { '' }, { true }

function window.draw(is_open, alerts, config)
    if not is_open[1] then return browser_window.draw(alerts) end
    local changed = false
    imgui.SetNextWindowSize({ 580, 450 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Settings', is_open, ImGuiWindowFlags_NoCollapse) then
        local limit = { config.max_recent }
        if imgui.InputInt('Moves in log', limit) then
            config.max_recent = math.max(1, math.min(250, limit[1]))
            changed = true
        end
        local party_only = { config.party_enemies_only }
        if imgui.Checkbox('Only enemies engaged with my party/alliance', party_only) then
            config.party_enemies_only = party_only[1]
            changed = true
        end
        if imgui.Button('Browse families / notorious monsters') then browser_window.open() end
        imgui.Text('Saved move alerts')
        imgui.TextWrapped('Enable, edit, or remove alerts saved from the move log.')
        if imgui.BeginChild('##saved_move_alerts', { 0, 230 }, 1, 0) then
            local entries = alerts:list()
            if #entries == 0 then imgui.Text('No saved move alerts.') end
            for i, entry in ipairs(entries) do
                local enabled = { entry.enabled }
                if imgui.Checkbox('##enabled_' .. i, enabled) then
                    alerts:set(entry, enabled[1])
                    if editing == entry then enabled_input[1] = enabled[1] end
                    changed = true
                end
                imgui.SameLine()
                imgui.Text((entry.scope == 'family' and 'Family: ' or '') .. entry.monster .. ': ' .. entry.move
                    .. (entry.kind == 'spell' and ' (spell)' or ''))
                if entry.scope == nil and imgui.Button('Edit##' .. i) then
                    editing, error_message = entry, nil
                    enemy_input[1], move_input[1], enabled_input[1] = entry.monster, entry.move, entry.enabled
                end
                imgui.SameLine()
                if imgui.Button('Remove##' .. i) then
                    alerts:remove(entry)
                    if editing == entry then editing, error_message = nil, nil end
                    changed = true
                end
                imgui.Separator()
            end
        end
        imgui.EndChild()
        if editing then
            imgui.InputText('Enemy', enemy_input, 128)
            imgui.InputText('Move', move_input, 128)
            imgui.Checkbox('Alert enabled', enabled_input)
            if imgui.Button('Save entry') then
                local ok, err = alerts:replace(editing,
                    { monster = enemy_input[1], move = move_input[1] }, enabled_input[1])
                if ok then
                    editing, error_message, changed = nil, nil, true
                else
                    error_message = err
                end
            end
            imgui.SameLine()
            if imgui.Button('Cancel') then editing, error_message = nil, nil end
            if error_message then imgui.TextWrapped(error_message) end
        end
    end
    imgui.End()
    if browser_window.draw(alerts) then changed = true end
    return changed
end

return window
