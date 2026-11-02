package.path = './?.lua;' .. package.path
local texts, children, scrolls, child = {}, {}, {}, nil
local click_gear = true
package.loaded.imgui = {
    SetNextWindowBgAlpha = function() end, SetNextWindowSize = function() end,
    SetNextWindowSizeConstraints = function() end,
    Begin = function(title) assert(title == 'RTFM Log'); return true end, End = function() end,
    GetTextLineHeightWithSpacing = function() return 20 end,
    GetCursorScreenPos = function() return 0, 0 end,
    InvisibleButton = function(id) assert(id == '##rtfm_settings'); return click_gear end,
    GetColorU32 = function() return 0 end,
    GetWindowDrawList = function() return { AddLine = function() end, AddCircle = function() end } end,
    GetWindowHeight = function() return 260 end, GetCursorPosY = function() return 30 end,
    IsItemHovered = function() return false end,
    BeginChild = function(id, size, child_flags, window_flags)
        assert(type(child_flags) == 'number' and type(window_flags) == 'number')
        child = id
        children[#children + 1] = { id = id, height = size[2] }
        return true
    end,
    EndChild = function() child = nil end,
    SetScrollHereY = function(ratio) assert(ratio == 1); scrolls[#scrolls + 1] = child end,
    Text = function(text) texts[#texts + 1] = { text = text, child = child } end,
    PushStyleColor = function() end, PopStyleColor = function() end,
    SameLine = function() end, Separator = function() end,
}
bit = { bor = function() return 0 end }
local overlay = require('lib.overlay')
local tracker = {
    recent = {
        { monster = 'Khimaira', move = 'Old move', action = 'uses', timestamp = 1 },
        { monster = 'Khimaira', move = 'New move', action = 'uses', timestamp = 2 },
    },
    pending = { { monster = 'Khimaira', move = 'Dreadstorm', action = 'readies', timestamp = 3 } },
}
local settings_open = { false }
overlay.draw({ true }, tracker, 4, require('config'), {}, nil, settings_open)
assert(settings_open[1])
assert(texts[1].text == 'RTFM Log')
assert(texts[2].text == 'Khimaira used Old move')
assert(texts[4].text == 'Khimaira used New move')
assert(texts[6].text == 'Readying / Casting' and texts[6].child == '##rtfm_pending')
assert(texts[7].text == 'Khimaira readies Dreadstorm')
assert(children[1].id == '##rtfm_history' and children[2].id == '##rtfm_pending')
assert(children[1].height + children[2].height <= 210)
assert(scrolls[1] == '##rtfm_history' and scrolls[2] == '##rtfm_pending')
click_gear, texts, children, scrolls = false, {}, {}, {}
overlay.draw({ true }, tracker, 4, require('config'), {}, nil, settings_open)
assert(#scrolls == 1 and scrolls[1] == '##rtfm_pending') -- history can be browsed when idle
tracker.recent[#tracker.recent + 1] = { monster = 'Khimaira', move = 'Latest move', action = 'uses', timestamp = 5 }
scrolls = {}
overlay.draw({ true }, tracker, 5, require('config'), {}, nil, settings_open)
assert(scrolls[1] == '##rtfm_history')
texts, children, scrolls = {}, {}, {}
tracker.pending = {}
overlay.draw({ true }, tracker, 6, require('config'), {}, nil, settings_open)
assert(children[2].id == '##rtfm_pending' and children[2].height > 0)
assert(texts[#texts].text == 'No moves or spells being prepared.')
tracker.pending = { { monster = 'Khimaira', move = 'Thunder IV', action = 'casting', timestamp = 6 } }
texts = {}
overlay.draw({ true }, tracker, 7, require('config'), {}, nil, settings_open)
assert(texts[#texts - 1].text == 'Khimaira starts casting Thunder IV')
print('RTFM log layout checks passed.')
