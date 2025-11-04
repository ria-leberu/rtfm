addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.1.2'
addon.desc     = 'Displays and logs monster TP moves.'
addon.commands = {'rtfm'}

require('common')
local imgui = require('imgui')

print('[RTFM] Addon loaded.')

------------------------------------------------------------
-- State
------------------------------------------------------------
local currentMove = nil
local displayTime = 10
local show_window = true
local debug_log_all = false

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

    if args[2] and args[2]:any('test') then
        currentMove = {
            monster = 'DebugMob',
            verb = 'readies',
            move = 'TestMove',
            timestamp = os.time()
        }
        print('[RTFM] Test move triggered.')
        e.blocked = true
        return
    end

    if args[2] and args[2]:any('toggle') then
        show_window = not show_window
        print(string.format('[RTFM] Window toggled: %s', show_window and 'ON' or 'OFF'))
        e.blocked = true
        return
    end

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

    if monster and verb and move then
        move = move:gsub('[%p%d%s]+$', '') -- remove trailing .1, etc.
        currentMove = {
            monster = monster,
            verb = verb,
            move = move,
            timestamp = os.time()
        }
        print(string.format('[RTFM] Matched: %s %s %s', monster, verb, move))
    else
        currentMove = {
            monster = 'Unknown',
            verb = 'says',
            move = cleaned,
            timestamp = os.time()
        }
        print('[RTFM] Fallback to full message.')
    end
end)

------------------------------------------------------------
-- Overlay: show move for N seconds
------------------------------------------------------------
ashita.events.register('d3d_present', 'rtfm_present', function()
    if not show_window then return end

    local now = os.time()
    local showText = false
    local delta = 0

    if currentMove then
        delta = now - currentMove.timestamp
        if delta < displayTime then
            showText = true
        end
    end

    imgui.SetNextWindowBgAlpha(0.8)
    imgui.SetNextWindowSize({ 300, 100 }, ImGuiCond_FirstUseEver)

    local is_open = imgui.Begin('RTFM Overlay', state.is_open, bit.bor(
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_NoSavedSettings,
        ImGuiWindowFlags_AlwaysAutoResize
    ))

    if is_open then
        if showText then
            imgui.Text(string.format('%s %s %s', currentMove.monster, currentMove.verb, currentMove.move))
            imgui.Text(string.format('(%.2f seconds ago)', delta))
        else
            imgui.Text('Waiting for monster move...')
        end
    end

    imgui.End()
end)
