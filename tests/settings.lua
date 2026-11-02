-- Run from the addon directory with Lua 5.1 / LuaJIT.
package.path = './?.lua;' .. package.path
local alerts = require('lib.alerts')
local config = require('config')
assert(config.max_recent == 25)
local saved_alerts = alerts.new()
saved_alerts:set({ monster = 'Khimaira', move = 'Fossilizing Breath' }, true)
local phase, child_depth = 'disable', 0
package.loaded.imgui = {
    SetNextWindowSize = function() end, Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, child_flags, window_flags)
        assert(type(child_flags) == 'number' and type(window_flags) == 'number')
        child_depth = child_depth + 1
        return true
    end,
    EndChild = function() child_depth = child_depth - 1 end,
    Text = function() end, TextWrapped = function() end, SameLine = function() end,
    Separator = function() end,
    InputInt = function(_, value)
        if phase == 'limit' then value[1] = 999; return true end
        return false
    end,
    Checkbox = function(label, value)
        if phase == 'filter' and label == 'Only enemies engaged with my party/alliance' then
            value[1] = true
            return true
        end
        if phase == 'disable' and label == '##enabled_1' then value[1] = false; return true end
        return false
    end,
    InputText = function(label, value)
        if phase == 'save' then
            value[1] = label == 'Enemy' and 'Khimaira EX' or 'Dreadstorm'
            return true
        end
        return false
    end,
    Button = function(label)
        return (phase == 'edit' and label == 'Edit##1')
            or (phase == 'save' and label == 'Save entry')
            or (phase == 'remove' and label == 'Remove##1')
    end,
}
local settings = require('lib.config_window')
assert(settings.draw({ true }, saved_alerts, config))
assert(not saved_alerts:list()[1].enabled)
phase = 'edit'
assert(not settings.draw({ true }, saved_alerts, config))
phase = 'save'
assert(settings.draw({ true }, saved_alerts, config))
local entry = saved_alerts:list()[1]
assert(entry.monster == 'Khimaira EX' and entry.move == 'Dreadstorm' and not entry.enabled)
phase = 'limit'
assert(settings.draw({ true }, saved_alerts, config) and config.max_recent == 250)
assert(child_depth == 0)
phase = 'filter'
assert(settings.draw({ true }, saved_alerts, config) and config.party_enemies_only)

-- Exercise the real disk serializer/loader, including the previous-save backup.
local path = RTFM_TEST_PATH or os.tmpname()
local storage = require('lib.storage')
local ok, err = pcall(function()
    assert(storage.save(path, { move_alert_entries = saved_alerts:list(), max_recent = 25,
        party_enemies_only = config.party_enemies_only }))
    local loaded = storage.load(path)
    assert(loaded.party_enemies_only == true)
    local restored = alerts.new(loaded.move_alerts, loaded.move_alert_entries)
    assert(#restored:list() == 1 and restored:list()[1].enabled == false)
    assert(restored:list()[1].monster == 'Khimaira EX')
    restored:set(restored:list()[1], true)
    assert(storage.save(path, { move_alert_entries = restored:list(), max_recent = 25 }))
    loaded = storage.load(path)
    restored = alerts.new(nil, loaded.move_alert_entries)
    assert(restored:is_selected({ monster = 'Khimaira EX', move = 'Dreadstorm' }))
end)
os.remove(path)
os.remove(path .. '.bak')
os.remove(path .. '.tmp')
assert(ok, err)
phase = 'remove'
assert(settings.draw({ true }, saved_alerts, config))
assert(#saved_alerts:list() == 0 and next(saved_alerts.selected) == nil)

local history_config = require('config')
history_config.max_recent = 25
local tracker = require('lib.actions').new(history_config)
for i = 1, 30 do
    tracker:record({ monster = 'Khimaira', move = 'Move ' .. i, action = 'uses' }, i)
end
assert(#tracker.recent == 25 and tracker.recent[1].move == 'Move 6')
tracker:update(10000)
assert(#tracker.recent == 25)
history_config.max_recent = 10
tracker:update(10001)
assert(#tracker.recent == 10 and tracker.recent[1].move == 'Move 21')
print('RTFM settings and persistence checks passed.')
