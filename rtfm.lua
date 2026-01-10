addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.3.7'
addon.desc     = 'Displays and logs monster TP moves and spells.'
addon.commands = {'rtfm'}

require('common')
local imgui = require('imgui')
local moveData = require('moves')

print('[RTFM] Addon loaded.')

------------------------------------------------------------
-- State
------------------------------------------------------------
local displayTime     = 60
local readiesTimeout  = 10
local show_window     = true
local debug_log_all   = false
local recentMoves     = {}
local pendingReadies  = {}
local state           = { is_open = { true } }
local lastMonster     = nil


------------------------------------------------------------
-- Memory Probe
------------------------------------------------------------
local mem_last_report = os.clock()
local MEM_REPORT_INTERVAL = 60.0 -- seconds

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function strip_formatting(s)
    if not s then return '' end
    return s:gsub('[\31\30\127]', '')
end

-- Normalize monster/move names for consistent matching
local function normalize(s)
    if not s then return '' end
    s = s:lower()
    s = s:gsub('^the%s+', '')      -- drop leading "The "
    s = s:gsub("[’']", "")         -- drop apostrophes in names like Aw'aern
    s = s:gsub('%s+', '')          -- drop spaces
    s = s:gsub('[%p%d]+$', '')     -- drop trailing punctuation/digits
    return s
end

local function create_id(monster, move)
    return normalize(monster) .. ':' .. normalize(move)
end

local function lookup_desc(monster, move)
    local m_id = normalize(monster)
    local a_id = normalize(move)
    return (moveData[m_id] and moveData[m_id][a_id])
        or (moveData["default"] and moveData["default"][a_id])
        or ''
end

-- Returns true if the given name belongs to a PC, trust, or allied unit (not a monster)
local function is_player_or_trust(name)
    if not name then return false end
    local lname = name:lower()

    local party = AshitaCore:GetMemoryManager():GetParty()
    local ents  = AshitaCore:GetMemoryManager():GetEntity()

    -- Your own character
    local myname = party:GetMemberName(0)
    if myname and myname:lower() == lname then
        return true
    end

    -- Party and alliance members
    for i = 0, 17 do
        if party:GetMemberIsActive(i) == 1 then
            local pname = party:GetMemberName(i)
            if pname and pname:lower() == lname then
                return true
            end
        end
    end

    -- Scan all entities for PC / Trust / Pet types
    for i = 0, 2303 do
        local ename = ents:GetName(i)
        if ename and ename:lower() == lname then
            local etype = ents:GetType(i)
            -- 1 = PC, 2 = Trust, 5 = Pet (exclude all of these)
            if etype == 1 or etype == 2 or etype == 5 then
                return true
            end
        end
    end

    -- Heuristic fallback: player-style naming (capitalized, no spaces or apostrophes)
    if name:match("^[A-Z][a-z]+$") then
        return true
    end

    return false
end


-- Helper: try to find pending entry by exact or loose move match
local function find_pending(id, move)
    for i = #pendingReadies, 1, -1 do
        if pendingReadies[i].id == id
        or normalize(pendingReadies[i].move) == normalize(move) then
            return i
        end
    end
    return nil
end

local function recent_contains(id)
    for i = 1, #recentMoves do
        if recentMoves[i].id == id then
            return true
        end
    end
    return false
end

------------------------------------------------------------
-- Commands
------------------------------------------------------------
ashita.events.register('command', 'rtfm_command', function(e)
    local args = e.command:args()
    if #args == 0 or not args[1]:any('/rtfm') then return end

    if args[2] and args[2]:any('test') then
        table.insert(pendingReadies, {
            id        = create_id('DebugMob', 'TestMove'),
            monster   = 'DebugMob',
            move      = 'TestMove',
            action    = 'casting',
            -- timestamp = os.time()
            timestamp = os.clock()

        })
        print('[RTFM] Test move added.')
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

    print('[RTFM] Usage: /rtfm test | toggle | log')
    e.blocked = true
end)

------------------------------------------------------------
-- text_in handler
------------------------------------------------------------
ashita.events.register('text_in', 'rtfm_text_in', function(e)
    if not e or e.injected or not e.message then return end

    local cleaned = strip_formatting(e.message):trim()
    if debug_log_all then
        print(string.format('[RTFM] [MODE %d] %s', e.mode, cleaned))
    end

    local monster, move

    --------------------------------------------------------
    -- READIES
    --------------------------------------------------------
    if e.mode == 100 or e.mode == 105 or e.mode == 110 then
        monster, move = cleaned:match('^%s*(.-)%s+readies%s+([^%.]+)')
        if monster and move then
            if cleaned:lower():find('on ' .. monster:lower()) then return end -- self-cast guard
            if not is_player_or_trust(monster) then
                move = move:gsub('[%p%d%s]+$', '')
                lastMonster = monster
                local id = create_id(monster, move)
                table.insert(pendingReadies, {
                    id        = id,
                    monster   = monster,
                    move      = move,
                    action    = 'readies',
                    -- timestamp = os.time()
                    timestamp = os.clock()
                })
            end
        end
    end

    --------------------------------------------------------
    -- CASTING
    --------------------------------------------------------
    if e.mode == 51 or e.mode == 52 then
        monster, move = cleaned:match('^(.+)%s+starts casting%s+([^%.]+)')
        if monster and move then
            if cleaned:lower():find('on ' .. monster:lower()) then return end -- self-cast guard
            if not is_player_or_trust(monster) then
                move = move:gsub('[%p%d%s]+$', '')
                lastMonster = monster
                local id = create_id(monster, move)
                table.insert(pendingReadies, {
                    id        = id,
                    monster   = monster,
                    move      = move,
                    action    = 'casting',
                    -- timestamp = os.time()
                    timestamp = os.clock()

                })
            end
        end
    end

    --------------------------------------------------------
    -- USES / CASTS
    --------------------------------------------------------
    if e.mode == 28 or e.mode == 30 or e.mode == 31 or e.mode == 32 or
    e.mode == 40 or e.mode == 104 or e.mode == 111 or e.mode == 112 then

        local verb
        monster, move = cleaned:match('^%s*(.-)%s+uses%s+([^%.]+)')
        verb = 'uses'

        if not (monster and move) then
            monster, move = cleaned:match('^%s*(.-)%s+casts%s+([^%.]+)')
            verb = 'casts'
        end

        if monster and move then
            if cleaned:lower():find('on ' .. monster:lower()) then return end -- self-cast guard
            if not is_player_or_trust(monster) then
                move = move:gsub('[%p%d%s]+$', '')
                lastMonster = monster
                local id = create_id(monster, move)

                local idx = find_pending(id, move)
                if idx then
                    table.remove(pendingReadies, idx)
                end

                if not recent_contains(id) then
                    table.insert(recentMoves, {
                        id        = id,
                        monster   = monster,
                        move      = move,
                        action    = verb,
                        -- timestamp = os.time()
                        timestamp = os.clock()

                    })
                end
            end
        end
    end

    --------------------------------------------------------
    -- FALLBACK: effect-only lines
    --------------------------------------------------------
    if e.mode == 27 or e.mode == 29 or e.mode == 121 then
        local selfMonster, selfMove = cleaned:match('^%s*(.-)%s+uses%s+([^%.]+)')
        if not (selfMonster and selfMove) then
            selfMonster, selfMove = cleaned:match('^%s*(.-)%s+casts%s+([^%.]+)')
        end

        if not (selfMonster and selfMove) and lastMonster then
            if cleaned:find('gains the effect of')
            or cleaned:find('receives the effect of')
            or cleaned:find('effects disappear') then
                selfMonster = cleaned:match('^(The%s*.+?)%s') or lastMonster
                selfMove = 'Status Effect'
            end
        end

        if selfMonster and selfMove then
            if cleaned:lower():find('on ' .. selfMonster:lower()) then return end -- self-cast guard
            if not is_player_or_trust(selfMonster) then
                selfMove = selfMove:gsub('[%p%d%s]+$', '')
                local id = create_id(selfMonster, selfMove)
                if not recent_contains(id) then
                    table.insert(recentMoves, {
                        id        = id,
                        monster   = selfMonster,
                        move      = selfMove,
                        action    = 'uses',
                        -- timestamp = os.time()
                        timestamp = os.clock()

                    })
                end
            end
        end
    end
end)

------------------------------------------------------------
-- Overlay UI
------------------------------------------------------------
ashita.events.register('d3d_present', 'rtfm_present', function()

    -- local now = os.clock()

    --------------------------------------------------------
    -- Memory probe (always runs)
    --------------------------------------------------------
    -- if (now - mem_last_report) >= MEM_REPORT_INTERVAL then
    --     mem_last_report = now

    -- local mem = addon.instance:get_memory_usage()
    --     print(string.format(
    --         '[RTFM] Memory usage: %.2f KB | recent=%d | pending=%d',
    --         mem / 1024,
    --         #recentMoves,
    --         #pendingReadies
    --     ))
    -- end

    --------------------------------------------------------
    -- Cleanup (should also always run)
    --------------------------------------------------------
    -- for i = #recentMoves, 1, -1 do
    --     if (now - recentMoves[i].timestamp) > displayTime then
    --         table.remove(recentMoves, i)
    --     end
    -- end
    -- for i = #pendingReadies, 1, -1 do
    --     if (now - pendingReadies[i].timestamp) > readiesTimeout then
    --         table.remove(pendingReadies, i)
    --     end
    -- end

    if not show_window then return end

    local now = os.clock()
    -- local now_sec = os.time()
    local now_sec = os.clock()


    -- Cleanup expired entries
    for i = #recentMoves, 1, -1 do
        if (now_sec - recentMoves[i].timestamp) > displayTime then
            table.remove(recentMoves, i)
        end
    end
    for i = #pendingReadies, 1, -1 do
        if (now_sec - pendingReadies[i].timestamp) > readiesTimeout then
            table.remove(pendingReadies, i)
        end
    end

    imgui.SetNextWindowBgAlpha(0.8)
    imgui.SetNextWindowSize({ 500, 120 + (#recentMoves * 40) }, ImGuiCond_FirstUseEver)

    local is_open = imgui.Begin('RTFM Overlay', state.is_open, bit.bor(
        ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoCollapse,
        ImGuiWindowFlags_AlwaysAutoResize
    ))

    --------------------------------------------------------
    -- Recent "uses" / "casts"
    --------------------------------------------------------
    if #recentMoves == 0 then
        imgui.Text('No recent actions.')
    else
        for i = 1, #recentMoves do
            local move = recentMoves[i]
            local age = now_sec - move.timestamp
            local alpha = 1.0 - math.min(age / displayTime, 1.0)^2.5
            local color = (move.action == 'uses') and {1.0, 0.3, 0.3, alpha} or {0.8, 0.4, 1.0, alpha}

            local desc = lookup_desc(move.monster, move.move)
            local text = string.format('%s -> %s', move.monster, move.move)
            if desc ~= '' then text = text .. ' (' .. desc .. ')' end

            imgui.PushStyleColor(ImGuiCol_Text, color)
            imgui.Text(text)
            imgui.PopStyleColor()

            imgui.SameLine()
            imgui.PushStyleColor(ImGuiCol_Text, {0.7, 0.7, 0.7, alpha * 0.8})
            imgui.Text(string.format('(%.1fs ago)', age))
            imgui.PopStyleColor()

            if i < #recentMoves then imgui.Separator() end
        end
    end

    --------------------------------------------------------
    -- Pulsing "readies" / "casting"
    --------------------------------------------------------
    if #pendingReadies > 0 then
        imgui.Separator()
        imgui.Text('Preparing...')

        for i = 1, #pendingReadies do
            local move = pendingReadies[i]
            local age = now_sec - move.timestamp
            local pulse = 0.6 + 0.4 * math.abs(math.sin(now * 3.0))
            local alpha = 1.0 - math.min(age / readiesTimeout, 1.0)^2.5

            local color
            if move.action == 'casting' then
                color = {0.6, 0.6 * pulse, 1.0 * pulse, alpha}
            else
                color = {1.0, 1.0 * pulse, 0.3 * pulse, alpha}
            end

            local desc = lookup_desc(move.monster, move.move)
            local verb = (move.action == 'casting') and 'starts casting' or 'readies'
            local text = string.format('%s %s %s', move.monster, verb, move.move)
            if desc ~= '' then text = text .. ' (' .. desc .. ')' end

            imgui.PushStyleColor(ImGuiCol_Text, color)
            imgui.Text(text)
            imgui.PopStyleColor()

            imgui.SameLine()
            imgui.PushStyleColor(ImGuiCol_Text, {0.7, 0.7, 0.7, alpha * 0.8})
            imgui.Text(string.format('(%.1fs ago)', age))
            imgui.PopStyleColor()

            if i < #pendingReadies then imgui.Separator() end
        end
    end

    imgui.End()
end)
