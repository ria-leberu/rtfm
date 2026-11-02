local imgui = require('imgui')
local sounds = require('lib.sounds')
local files = require('lib.sound_files')
local window = {}
local is_open = { false }
local target, chosen, message

function window.open(event)
    target = event
    chosen = event and sounds.overrides[sounds.key(event)] or nil
    local ok, err = sounds.refresh()
    message, is_open[1] = ok and nil or err, true
end

function window.draw(config)
    if not is_open[1] then return false end
    local changed = false
    imgui.SetNextWindowSize({ 650, 420 }, ImGuiCond_FirstUseEver)
    if imgui.Begin('RTFM Sounds', is_open, ImGuiWindowFlags_NoCollapse) then
        imgui.Text(target and ('Sound for ' .. target.move) or 'Sound library')
        if target then
            imgui.TextWrapped('Applies to this move or spell across all enemies. Tracking is configured separately.')
            if imgui.Button('Use default alert.wav') then
                sounds.assign(target, nil); chosen, changed = nil, true
            end
        end
        imgui.TextWrapped('Place your WAV files in this folder:')
        imgui.TextWrapped(sounds.folder())
        imgui.TextWrapped('Open this path in Windows Explorer and copy your WAV files into it.')
        if imgui.Button('Refresh') then
            local ok, err = sounds.refresh()
            message = ok and 'Sound list refreshed.' or err
        end
        imgui.TextWrapped('WAV files only (PCM recommended), up to 32 MB. Click Refresh after adding or removing files.')
        if target then
            imgui.TextWrapped('Current: ' .. (sounds.overrides[sounds.key(target)] or 'alert.wav (default)'))
        else
            imgui.TextWrapped('Choose a move or spell Sound button to assign a file from this list.')
        end
        if imgui.BeginChild('##sound_library', { 0, 160 }, 1, ImGuiWindowFlags_HorizontalScrollbar or 0x800) then
            if imgui.Selectable('alert.wav (default)', chosen == nil) then chosen = nil end
            for i, sound in ipairs(sounds.library) do
                local name = sound:match('[^\\]+$') or sound
                if imgui.Selectable(name .. '##sound_' .. i, chosen == sound) then chosen = sound end
            end
        end
        imgui.EndChild()
        if target and imgui.Button('Use selected sound') then
            local ok, err = true, nil
            if chosen then ok, err = files.validate(chosen) end
            if ok then sounds.assign(target, chosen); changed, message = true, 'Sound saved.'
            else message = err end
        end
        if target then imgui.SameLine() end
        if imgui.Button('Preview') then
            local ok, err = sounds.play(nil, chosen)
            message = ok and 'Preview played.' or tostring(err)
        end
        if not config.sound_alerts_enabled then imgui.Text('Sound alerts are off (including previews).') end
        if message then imgui.TextWrapped(message) end
    end
    imgui.End()
    return changed
end

return window
