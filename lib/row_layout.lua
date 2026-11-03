local imgui = require('imgui')
local layout = {}
layout.__index = layout

function layout.new(top, height)
    return setmetatable({ top = top, height = height }, layout)
end

function layout:center(height)
    local x = imgui.GetCursorScreenPos()
    imgui.SetCursorScreenPos({ x, self.top + (self.height - height) / 2 })
end

function layout:same_line(gap, height)
    imgui.SameLine(0, gap)
    self:center(height)
end

function layout:text(text, wrapped)
    local _, height = imgui.CalcTextSize(text)
    self:center(wrapped and imgui.GetFontSize() or height)
    -- A group clears the baseline inherited from preceding buttons.
    imgui.BeginGroup()
    if wrapped then imgui.TextWrapped(text) else imgui.Text(text) end
    imgui.EndGroup()
end

return layout
