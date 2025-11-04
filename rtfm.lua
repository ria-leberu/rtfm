addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.1.3'
addon.desc     = 'Displays and logs monster TP moves.'
addon.commands = {'rtfm'}

require('common')
local imgui = require('imgui')

print('[RTFM] Addon loaded.')

------------------------------------------------------------
-- State
------------------------------------------------------------
local displayTime   = 60
local show_window   = true
local debug_log_all = false
local recentMoves   = {}
local maxMoves      = 5

-- ImGui requires a mutable pointer for window visibility
local state = {
    is_open = { true }
}

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function strip_formatting(s)
    if not s then return '' end
    return s:gsub('[\31\30\127]', '')
end

------------------------------------------------------------
-- /rtfm commands: test | toggle | log
------------------------------------------------------------
ashita.events.register('command', 'rtfm_command', function(e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/rtfm') then return end

    --------------------------------------------------------
    -- /rtfm test : insert fake move
    --------------------------------------------------------
    if args[2] and args[2]:any('test') then
        local entry = {
            monster   = 'DebugMob',
            verb      = 'readies',
            move      = 'TestMove',
            timestamp = os.time()
        }
        table.insert(recentMoves, entry)
        if #recentMoves > maxMoves then table.remove(recentMoves, 1) end
        print('[RTFM] Test move added.')
        e.blocked = true
        return
    end

    --------------------------------------------------------
    -- /rtfm toggle : show / hide overlay
    --------------------------------------------------------
    if args[2] and args[2]:any('toggle') then
        show_window = not show_window
        print(string.format('[RTFM] Window toggled: %s', show_window and 'ON' or 'OFF'))
        e.blocked = true
        return
    end

    --------------------------------------------------------
    -- /rtfm log : toggle debug log output
    --------------------------------------------------------
    if args[2] and args[2]:any('log') then
        debug_log_all = not debug_log_all
        print(string.format('[RTFM] Raw mode logging: %s', debug_log_all and 'ON' or 'OFF'))
        e.blocked = true
        return
    end

    print('[RTFM] Usage: /rtfm test | /rtfm toggle | /rtfm log')
    e.blocked = true
end)

------------------------------------------------------------
-- text_in: parse monster moves, optionally log all
------------------------------------------------------------
ashita.events.register('text_in', 'rtfm_text_in', function(e)
    if not e or e.injected or not e.message then return end

    local cleaned = strip_formatting(e.message):trim()

    if debug_log_all then
        print(string.format('[RTFM] [MODE %d] %s', e.mode, cleaned))
    end

    -- Only handle known monster TP move messages
    if e.mode ~= 105 then return end

    local monster, verb, move = cleaned:match('^(.+) (readies) (.+)%.%d$')

    local entry
    if monster and verb and move then
        move = move:gsub('[%p%d%s]+$', '') -- remove trailing .1, etc.
        entry = {
            monster   = monster,
            verb      = verb,
            move      = move,
            timestamp = os.time()
        }
    else
        entry = {
            monster   = 'Unknown',
            verb      = 'says',
            move      = cleaned,
            timestamp = os.time()
        }
        print('[RTFM] Fallback to full message.')
    end

    table.insert(recentMoves, entry)
    if #recentMoves > maxMoves then table.remove(recentMoves, 1) end
end)

------------------------------------------------------------
-- Overlay: show up to the last N moves for displayTime
------------------------------------------------------------
ashita.events.register('d3d_present', 'rtfm_present', function()
    if not show_window then return end

    local now = os.time()

    -- prune expired entries
    for i = #recentMoves, 1, -1 do
        if (now - recentMoves[i].timestamp) > displayTime then
            table.remove(recentMoves, i)
        end
    end

    imgui.SetNextWindowBgAlpha(0.8)
    imgui.SetNextWindowSize({ 300, 100 + (#recentMoves * 40) }, ImGuiCond_FirstUseEver)

    local is_open = imgui.Begin('RTFM Overlay', state.is_open, bit.bor(
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoSavedSettings,
        ImGuiWindowFlags_AlwaysAutoResize
    ))

    if #recentMoves == 0 then
        imgui.Text('Waiting for monster move...')
    else
        for i = 1, #recentMoves do
            local move = recentMoves[i]
            local age = now - move.timestamp
            local life_ratio = math.min(age / displayTime, 1.0)

            -- fade stronger toward the end (ease-out curve)
            local alpha = 1.0 - (life_ratio ^ 2.5)

            -- Use a color fade (ImGuiCol_Text sets the color of text)
            local text_color = {1.0, 1.0, 1.0, alpha} -- RGBA

            imgui.PushStyleColor(ImGuiCol_Text, text_color)
            imgui.Text(string.format('%s %s %s', move.monster, move.verb, move.move))
            imgui.PopStyleColor()

            imgui.SameLine()
            imgui.PushStyleColor(ImGuiCol_Text, {0.7, 0.7, 0.7, alpha * 0.8})
            imgui.Text(string.format('(%.1fs ago)', age))
            imgui.PopStyleColor()

            if i < #recentMoves then imgui.Separator() end
        end
    end


    imgui.End()
end)
