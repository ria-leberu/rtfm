addon.name = 'rtfm'
addon.author = 'Rialia'
addon.version = '0.1.0'
addon.desc = 'Displays, logs, and learns monster TP moves and spells.'
addon.commands = { 'rtfm' }

require('common')
local imgui = require('imgui')
local names = require('lib.names')
local storage = require('lib.storage')
local config = require('config')
local timing = require('lib.timing')
local overlay = require('lib.overlay')
local center_alert = require('lib.center_alert')
local config_window = require('lib.config_window')
local sounds = require('lib.sounds')
local sound_window = require('lib.sound_window')
local actions = require('lib.actions')
local affected = require('lib.affected')
local engagement = require('lib.engagement')
local moves = require('data.moves')
local base_path = addon.path or (AshitaCore:GetInstallPath() .. 'addons\\rtfm\\')
local data_dir = base_path .. 'data\\'
local learned_path = data_dir .. 'mobs_learned.lua'
local preferences_path = data_dir .. 'preferences.lua'
local is_open = { true }
local config_open = { false }
local learned_dirty = false
local preferences_dirty = false
local now = imgui.GetTime
local last_save = now()
local learned_moves = storage.load(learned_path)
local preferences = storage.load(preferences_path)
sounds.init(config, base_path, preferences)
if type(preferences.sound_alerts_enabled) == 'boolean' then config.sound_alerts_enabled = preferences.sound_alerts_enabled end
config.log_retention_minutes = timing.retention_minutes(preferences.log_retention_minutes)
local move_alerts = require('lib.alerts').new(preferences.move_alerts, preferences.move_alert_entries)
if move_alerts.migrated then preferences_dirty = true end
if type(preferences.max_recent) == 'number' and preferences.max_recent == preferences.max_recent then
    config.max_recent = math.max(1, math.min(250, math.floor(preferences.max_recent)))
end

for _, key in ipairs({ 'guaranteed_mobs', 'blacklist_mobs' }) do
    config[key] = names.map(config[key])
end
if type(preferences.auto_learn) == 'boolean' then config.auto_learn = preferences.auto_learn end
if type(preferences.is_open) == 'boolean' then is_open[1] = preferences.is_open end
if type(preferences.party_enemies_only) == 'boolean' then config.party_enemies_only = preferences.party_enemies_only end
if type(preferences.log_font_scale) == 'number' and preferences.log_font_scale == preferences.log_font_scale then
    config.log_font_scale = math.max(0.75, math.min(2, preferences.log_font_scale))
end
if type(preferences.single_line_log) == 'boolean' then config.single_line_log = preferences.single_line_log end
if type(preferences.compact_log_text) == 'boolean' then config.compact_log_text = preferences.compact_log_text end
if type(preferences.center_alert_enabled) == 'boolean' then config.center_alert_enabled = preferences.center_alert_enabled end

-- Normalize saved and curated keys at the boundary so all lookups agree.
local normalized_learned = {}
for monster, entries in pairs(learned_moves) do
    if type(monster) == 'string' and type(entries) == 'table' then
        local key = names.normalize(monster)
        normalized_learned[key] = normalized_learned[key] or {}
        for move, value in pairs(entries) do
            if type(move) == 'string' and value == true then
                normalized_learned[key][names.normalize(move)] = true
            end
        end
    end
end
learned_moves = normalized_learned
local normalized_moves = {}
for monster, entries in pairs(moves) do
    normalized_moves[names.normalize(monster)] = names.map(entries)
end
moves = normalized_moves
local tracker = actions.new(config)
local actors = require('lib.actors').new(config)

local function save()
    if not learned_dirty and not preferences_dirty then return end
    ashita.fs.create_dir(data_dir)
    if learned_dirty and storage.save(learned_path, learned_moves) then learned_dirty = false end
    if preferences_dirty and storage.save(preferences_path, {
        auto_learn = config.auto_learn,
        is_open = is_open[1],
        move_alerts = move_alerts.selected,
        move_alert_entries = move_alerts:list(),
        max_recent = config.max_recent,
        log_retention_minutes = config.log_retention_minutes,
        party_enemies_only = config.party_enemies_only,
        log_font_scale = config.log_font_scale,
        single_line_log = config.single_line_log,
        compact_log_text = config.compact_log_text,
        center_alert_enabled = config.center_alert_enabled,
        sound_alerts_enabled = config.sound_alerts_enabled,
        sound_overrides = sounds.overrides,
    }) then
        preferences_dirty = false
    end
end

if move_alerts.migrated then save() end

local function help()
    print('[RTFM] /rtfm [show|hide|toggle|config|reload|learn on|learn off|debug on|debug off|help]')
end

ashita.events.register('command', 'rtfm_command', function(e)
    local args = e.command:args()
    if not args[1] or args[1]:lower() ~= '/rtfm' then return end
    e.blocked = true
    local command = args[2] and args[2]:lower() or 'toggle'
    if command == 'show' or command == 'hide' or command == 'toggle' then
        if command == 'toggle' then is_open[1] = not is_open[1]
        else is_open[1] = command == 'show' end
        preferences_dirty = true
    elseif command == 'config' or command == 'settings' then
        config_open[1] = not config_open[1]
    elseif command == 'reload' then
        save()
        AshitaCore:GetChatManager():QueueCommand(1, '/addon reload rtfm')
        return
    elseif command == 'debug' and args[3] and (args[3]:lower() == 'on' or args[3]:lower() == 'off') then
        config.debug_log_all = args[3]:lower() == 'on'
        print('[RTFM] Debug logging ' .. (config.debug_log_all and 'enabled.' or 'disabled.'))
    elseif command == 'learn' and args[3] and (args[3]:lower() == 'on' or args[3]:lower() == 'off') then
        config.auto_learn = args[3]:lower() == 'on'
        preferences_dirty = true
        print('[RTFM] Learning ' .. (config.auto_learn and 'enabled.' or 'disabled.'))
    else
        help()
    end
    if preferences_dirty then save() end
end)

local function record_event(event, timestamp, verified_monster)
    if config.blacklist_enabled and config.blacklist_mobs[names.normalize(event.monster)] then return end
    if not verified_monster and actors:is_excluded(event.monster, timestamp) then return end
    if config.party_enemies_only then
        local memory = AshitaCore:GetMemoryManager()
        if not engagement.matches(event, memory:GetEntity(), memory:GetParty()) then return end
    end
    local added = tracker:record(event, timestamp)
    if config.debug_log_all then
        print(string.format('[RTFM][row] %s %s %s: %s (recent=%d, pending=%d)',
            event.monster, event.action, event.move, added and 'added' or 'merged/ignored',
            #tracker.recent, #tracker.pending))
    end
    if not added then return end
    if (event.action == 'readies' or event.action == 'casting') and move_alerts:is_selected(event) then
        sounds.play(event)
    end
    if event.action == 'uses' then
        local monster, move = names.normalize(event.monster), names.normalize(event.move)
        if config.auto_learn then
            learned_moves[monster] = learned_moves[monster] or {}
            if not learned_moves[monster][move] then
                learned_moves[monster][move] = true
                learned_dirty = true
                print(string.format('[RTFM] Learned: %s -> %s', event.monster, event.move))
            end
        end
    end
end

ashita.events.register('packet_in', 'rtfm_affected_players', function(e)
    if e.id == 0x00B then save() end -- leaving the zone, including logout
    local packet, err = affected.parse(e)
    if err and config.debug_log_all then print('[RTFM][result] Decode failed: ' .. tostring(err)) end
    if not packet then return end
    local result = affected.resolve(packet, AshitaCore:GetMemoryManager():GetEntity(),
        AshitaCore:GetResourceManager())
    if result and result.action == 'interrupted' then
        tracker:interrupt(result)
        return
    end
    if config.debug_log_all then
        local messages = {}
        for _, target in ipairs(packet.targets) do
            messages[#messages + 1] = string.format('%u:%s', target.id, tostring(target.message))
        end
        print(string.format('[RTFM][result] category=%d action=%d move=%s targets=%s players=%s',
            packet.category, packet.action_id, result and result.move or '(unresolved)',
            table.concat(messages, ','), result and table.concat(result.affected_players or {}, ',') or '(unresolved)'))
    end
    if result then record_event(result, now(), true) end
end)

ashita.events.register('text_in', 'rtfm_text_in', function(e)
    if not e or e.injected or not e.message then return end
    if config.debug_log_all then print(string.format('[RTFM][%s] %s', tostring(e.mode), e.message)) end
    local event = actions.parse(e.message)
    if event and event.action == 'interrupted' then
        tracker:interrupt(event)
        return
    end
    -- Completion packets already supply the move and its targets. Chat can be
    -- delayed or reformatted by other addons, so it must not create a second row.
    if event and (event.action == 'readies' or event.action == 'casting') then
        record_event(event, now(), false)
    end
end)

ashita.events.register('d3d_present', 'rtfm_present', function()
    local timestamp = now()
    tracker:update(timestamp)
    if timestamp - last_save >= config.save_interval then
        save()
        last_save = timestamp
    end
    local was_open = is_open[1]
    local changed = overlay.draw(is_open, tracker, timestamp, config, moves, move_alerts, config_open)
    if config_window.draw(config_open, move_alerts, config) then changed = true end
    if sound_window.draw(config) then changed = true end
    center_alert.draw(tracker, move_alerts, config, timestamp)
    if changed then
        preferences_dirty = true
    end
    if is_open[1] ~= was_open then preferences_dirty = true end
    if changed or is_open[1] ~= was_open then save() end
end)

ashita.events.register('unload', 'rtfm_unload', function()
    save()
    require('lib.icons').clear()
end)
print('[RTFM] Addon loaded.')
