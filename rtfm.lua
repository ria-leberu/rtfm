addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.5.0'
addon.desc     = 'Displays, logs, and learns monster TP moves and spells.'
addon.commands = { 'rtfm' }

require('common')
local imgui    = require('imgui')
local moveData = require('moves')

print('[RTFM] Addon loaded.')

------------------------------------------------------------
-- Paths / Persistence
------------------------------------------------------------
local base_path    = AshitaCore:GetInstallPath()
local data_dir     = base_path .. 'addons\\rtfm\\data'
local learned_path = data_dir .. '\\mobs_learned.lua'

------------------------------------------------------------
-- Config
------------------------------------------------------------
local DISPLAY_TIME    = 60.0
local READIES_TIMEOUT = 10.0
local SAVE_INTERVAL   = 10.0

------------------------------------------------------------
-- State
------------------------------------------------------------
local show_window     = true
local debug_log_all   = false
local recentMoves     = {}
local pendingActions  = {}
local learned_moves   = {}
local learned_dirty   = false
local last_save       = os.clock()
local lastMonster     = nil
local state           = { is_open = { true } }
local auto_learn      = false

local emode_mob_readies = {
    [28]  = true,
    [30]  = true,
    [32]  = true,
    [40]  = true,
    [104] = true,
    [105] = true,
    [107] = true,
    [110] = true,
    [112] = true,
    [177] = true,
    [185] = true,
} 

local emode_mob_uses = {
    [28]  = true,
    [30]  = true,
    [32]  = true,
    [40]  = true,
    [104] = true,
    [107] = true,
    [111] = true,
    [112] = true,
    [185] = true,
} 

local emode_mob_casting = {
    [51]  = true,
    [52]  = true,
} 

local guaranteed_mobs = {
    ['seiryu']  = true,
    ['byakko']  = true,
    ['suzaku']  = true,
    ['genbu']   = true,
    ['kirin']   = true,
    ['sarameya'] = true,
    ['battosai'] = true,
    ['gensai'] = true,
    ['tinnin'] = true,
}

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function strip_formatting(s)
    if not s then return '' end
    return s:gsub('[\31\30\127]', '')
end

local function normalize(s)
    if not s then return '' end
    s = s:lower()
    s = s:gsub('^the%s+', '')
    s = s:gsub("[’']", '')
    s = s:gsub('%s+', '')
    s = s:gsub('[%p%d]+$', '')
    return s
end

local function create_id(monster, move)
    return normalize(monster) .. ':' .. normalize(move)
end

------------------------------------------------------------
-- Curated / Learned Lookup
------------------------------------------------------------
local function is_known_move(monster, move)
    local m = normalize(monster)
    local a = normalize(move)
    return (moveData[m] and moveData[m][a]) ~= nil
end

------------------------------------------------------------
-- Learned Move Recording
------------------------------------------------------------
local function learn_move(monster, move)
    local m = normalize(monster)
    local a = normalize(move)

    learned_moves[m] = learned_moves[m] or {}

    if not learned_moves[m][a] then
        learned_moves[m][a] = true
        learned_dirty = true
        print(string.format('[RTFM] Learned: %s → %s', monster, move))
    end
end

local function ensure_directory(path)
    os.execute(string.format('mkdir "%s"', path))
end

local function save_learned()
    if not learned_dirty then return end

    ensure_directory(data_dir)

    local f = io.open(learned_path, 'w')
    if not f then
        print('[RTFM] ERROR: Failed to write learned moves file.')
        return
    end

    f:write('return {\n')
    for mob, moves in pairs(learned_moves) do
        f:write(string.format('    ["%s"] = {\n', mob))
        for move, _ in pairs(moves) do
            f:write(string.format('        ["%s"] = true,\n', move))
        end
        f:write('    },\n')
    end
    f:write('}\n')
    f:close()

    learned_dirty = false
    last_save = os.clock()
    print('[RTFM] Learned moves saved.')
end

------------------------------------------------------------
-- Load learned file (if exists)
------------------------------------------------------------
do
    local ok, data = pcall(dofile, learned_path)
    if ok and type(data) == 'table' then
        learned_moves = data
        print('[RTFM] Loaded learned moves.')
    end
end

local function is_player_or_trust(name)
    if not name then return false end
    local lname = name:lower()

    if guaranteed_mobs[lname] then
        return false
    end

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

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function find_pending(id, move)
    for i = #pendingActions, 1, -1 do
        if pendingActions[i].id == id
        or normalize(pendingActions[i].move) == normalize(move) then
            return i
        end
    end
    return nil
end

local function recent_contains(id)
    for i = 1, #recentMoves do
        if recentMoves[i].id == id then return true end
    end
    return false
end

------------------------------------------------------------
-- text_in (robust parser + learning)
------------------------------------------------------------
ashita.events.register('text_in', 'rtfm_text_in', function(e)
    if not e or e.injected or not e.message then return end

    local msg = strip_formatting(e.message):trim()
    if debug_log_all then
        print(string.format('[RTFM][%d] %s', e.mode, msg))
    end

    local monster, move, verb

    monster, move = msg:match('^%s*(.-)%s+readies%s+([^%.]+)')
    if monster and move and not is_player_or_trust(monster) then
        move = move:gsub('[%p%d%s]+$', '')
        table.insert(pendingActions, {
            id        = create_id(monster, move),
            monster   = monster,
            move      = move,
            action    = 'readies',
            timestamp = os.clock()
        })
        lastMonster = monster
        return
    end

    --------------------------------------------------------
    -- STARTS CASTING
    --------------------------------------------------------
    if emode_mob_casting[e.mode] then
        monster, move = msg:match('^%s*(.-)%s+starts casting%s+([^%.]+)')
        if monster and move and not is_player_or_trust(monster) then
            move = move:gsub('[%p%d%s]+$', '')
            table.insert(pendingActions, {
                id        = create_id(monster, move),
                monster   = monster,
                move      = move,
                action    = 'casting',
                timestamp = os.clock()
            })
            lastMonster = monster
            return
        end
    end

    --------------------------------------------------------
    -- USES / CASTS (learning happens here)
    --------------------------------------------------------
    monster, move = msg:match('^%s*(.-)%s+uses%s+([^%.]+)')
    verb = 'uses'

    if not monster then
        monster, move = msg:match('^%s*(.-)%s+casts%s+([^%.]+)')
        verb = 'casts'
    end

    if emode_mob_uses[e.mode] then
        if monster and move and not is_player_or_trust(monster) then
            move = move:gsub('[%p%d%s]+$', '')
            local id = create_id(monster, move)

            local idx = find_pending(id, move)
            if idx then table.remove(pendingActions, idx) end

            if not recent_contains(id) then
                table.insert(recentMoves, {
                    id        = id,
                    monster   = monster,
                    move      = move,
                    action    = verb,
                    timestamp = os.clock()
                })
            end

            -- Learn ONLY TP moves (ignore spells)
            if verb == 'uses' and auto_learn then
                learn_move(monster, move)
            end

            return
        end
    end



end)

------------------------------------------------------------
-- Overlay UI
------------------------------------------------------------
ashita.events.register('d3d_present', 'rtfm_present', function()
    if not show_window then return end

    local now = os.clock()

    -- Cleanup
    for i = #recentMoves, 1, -1 do
        if (now - recentMoves[i].timestamp) > DISPLAY_TIME then
            table.remove(recentMoves, i)
        end
    end
    for i = #pendingActions, 1, -1 do
        if (now - pendingActions[i].timestamp) > READIES_TIMEOUT then
            table.remove(pendingActions, i)
        end
    end

    -- Autosave learned data
    if learned_dirty and (now - last_save) > SAVE_INTERVAL then
        save_learned()
    end

    imgui.SetNextWindowBgAlpha(0.85)
    imgui.SetNextWindowSize({ 520, 140 }, ImGuiCond_FirstUseEver)

    imgui.Begin('RTFM Overlay', state.is_open,
        bit.bor(ImGuiWindowFlags_NoResize,
                ImGuiWindowFlags_NoCollapse,
                ImGuiWindowFlags_AlwaysAutoResize))

    --------------------------------------------------------
    -- Recent actions (colored + fading)
    --------------------------------------------------------
    if #recentMoves == 0 then
        imgui.Text('No recent actions.')
    else
        for i, m in ipairs(recentMoves) do
            local age   = now - m.timestamp
            local alpha = 1.0 - math.min(age / DISPLAY_TIME, 1.0)^2.5

            local color = (m.action == 'uses')
                and {1.0, 0.3, 0.3, alpha}     -- red
                or  {0.8, 0.4, 1.0, alpha}     -- purple

            local text = string.format('%s used %s', m.monster, m.move)

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
    -- Pending actions (pulsing)
    --------------------------------------------------------
    if #pendingActions > 0 then
        imgui.Separator()
        imgui.Text('Preparing...')

        for i, p in ipairs(pendingActions) do
            local age   = now - p.timestamp
            local pulse = 0.6 + 0.4 * math.abs(math.sin(now * 3.0))
            local alpha = 1.0 - math.min(age / READIES_TIMEOUT, 1.0)^2.5

            local color
            if p.action == 'casting' then
                color = {0.6, 0.6 * pulse, 1.0 * pulse, alpha}  -- blue
            else
                color = {1.0, 1.0 * pulse, 0.3 * pulse, alpha}  -- yellow
            end

            local verb = (p.action == 'casting') and 'starts casting' or 'readies'
            local text = string.format('%s %s %s', p.monster, verb, p.move)

            imgui.PushStyleColor(ImGuiCol_Text, color)
            imgui.Text(text)
            imgui.PopStyleColor()

            imgui.SameLine()
            imgui.PushStyleColor(ImGuiCol_Text, {0.7, 0.7, 0.7, alpha * 0.8})
            imgui.Text(string.format('(%.1fs ago)', age))
            imgui.PopStyleColor()

            if i < #pendingActions then imgui.Separator() end
        end
    end

    imgui.End()
end)

