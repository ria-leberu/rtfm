-- Run from the addon directory with Lua 5.1 / LuaJIT.
package.path = './?.lua;' .. package.path
local alerts = require('lib.alerts')
local selected = alerts.new({
    ['The Khimaira'] = { ['Fossilizing Breath'] = true, Dreadstorm = false },
    malformed = 'ignored', [4] = { bad = true },
})
local breath = { monster = 'Khimaira', move = 'Fossilizing Breath', action = 'uses', timestamp = 0 }
assert(selected:is_selected(breath))
assert(not selected:is_selected({ monster = 'Khimaira', move = 'Dreadstorm' }))
assert(not selected:is_selected({ monster = 'Other monster', move = 'Fossilizing Breath' }))
selected:set(breath, false)
assert(not selected:is_selected(breath) and next(selected.selected) == nil)

-- Drive the real overlay's checkbox and verify that repeated log rows share
-- selection state while retaining unique ImGui widget IDs.
local click, checked, ids = true, {}, {}
package.loaded.imgui = {
    SetNextWindowSizeConstraints = function() end,
    GetTextLineHeightWithSpacing = function() return 20 end,
    GetCursorScreenPos = function() return 0, 0 end,
    InvisibleButton = function() return false end,
    GetColorU32 = function() return 0 end,
    GetWindowDrawList = function() return { AddLine = function() end, AddCircle = function() end } end,
    GetWindowHeight = function() return 380 end, GetCursorPosY = function() return 30 end,
    SetScrollHereY = function() end,
    SetNextWindowBgAlpha = function() end, SetNextWindowSize = function() end,
    Begin = function() return true end, End = function() end,
    BeginChild = function(_, _, child_flags, window_flags)
        assert(type(child_flags) == 'number' and type(window_flags) == 'number')
        return true
    end, EndChild = function() end,
    PushStyleColor = function() end, PopStyleColor = function() end,
    SameLine = function() end, Separator = function() end, Text = function() end,
    IsItemHovered = function() return false end,
    Button = function(label)
        local text, id = label:match('^(.-)(##.*)$')
        assert(not ids[id]); ids[id] = true
        assert(text == 'Track' or text == 'Untrack')
        checked[#checked + 1] = text == 'Untrack'
        if #checked == 1 and click ~= nil then return true end
        return false
    end,
}
bit = { bor = function() return 0 end }
ImGuiWindowFlags_NoResize, ImGuiWindowFlags_NoCollapse, ImGuiWindowFlags_AlwaysAutoResize = 0, 0, 0
local config = require('config')
local overlay = require('lib.overlay')
local tracker = { recent = { breath, breath }, pending = {} }
assert(overlay.draw({ true }, tracker, 1, config, {}, selected))
assert(checked[1] == false and checked[2] == true)
assert(selected:is_selected(breath))
local restored = alerts.new(selected.selected)
assert(restored:is_selected(breath))
click, checked, ids = false, {}, {}
assert(overlay.draw({ true }, tracker, 1, config, {}, selected))
assert(checked[1] == true and checked[2] == false)
assert(not selected:is_selected(breath))
local history = selected:list()
assert(#history == 1 and history[1].enabled == false)
local disabled_restored = alerts.new(selected.selected, history)
assert(#disabled_restored:list() == 1 and not disabled_restored:is_selected(breath))
assert(disabled_restored:replace(history[1], { monster = 'Khimaira', move = 'Dreadstorm' }, true))
assert(disabled_restored:is_selected({ monster = 'Khimaira', move = 'Dreadstorm' }))
assert(not disabled_restored:is_selected(breath))
local new_entry = disabled_restored:list()[1]
local ok = disabled_restored:replace(new_entry, { monster = '', move = '' }, true)
assert(not ok and disabled_restored:is_selected(new_entry))
disabled_restored:set(breath, true)
assert(not disabled_restored:replace(new_entry, breath, true))
assert(#disabled_restored:list() == 2)
disabled_restored:remove(new_entry)
assert(#disabled_restored:list() == 1)
click, checked, ids = nil, {}, {}
assert(not overlay.draw({ true }, tracker, 1, config, {}, selected))
assert(not overlay.draw({ false }, tracker, 1, config, {}, selected))
print('RTFM selectable-alert checks passed.')
