addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.1.1'
addon.desc     = 'Working version that logs and displays mob TP moves.'
addon.commands = {'rtfm'}

require('common')
local imgui = require('imgui')

print('[RTFM] Addon loaded.')

------------------------------------------------------------
-- State
------------------------------------------------------------
local currentMove = nil
local displayTime = 5
local show_window = true

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
-- Command: /rtfm test | /rtfm toggle
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

    print('[RTFM] Usage: /rtfm test | /rtfm toggle')
    e.blocked = true
end)

ashita.events.register('text_in', 'rtfm_debug_direct', function(e)
    if not e or e.injected or not e.message then return end
    if e.mode ~= 105 then return end

    local raw = e.message
    local cleaned = strip_formatting(raw):trim()

    print('[RTFM DEBUG] CLEANED: "' .. cleaned .. '"')

    -- Set the full message directly for now
    currentMove = {
        monster = 'Unknown',
        verb = 'says',
        move = cleaned,
        timestamp = os.time()
    }
    print('[RTFM] Overlay triggered with raw message.')
end)

------------------------------------------------------------
-- Overlay: Draw the matched move
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
    imgui.SetNextWindowSize({300, 100}, ImGuiCond_FirstUseEver)

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
