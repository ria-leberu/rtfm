local imgui = require('imgui')
local alert = {}
local outline_offsets = { { -1, -1 }, { 0, -1 }, { 1, -1 }, { -1, 0 },
    { 1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 } }

local function characters(line)
    return line:gmatch('[%z\1-\127\194-\244][\128-\191]*')
end

local function line_width(line)
    local width = 0
    for character in characters(line) do
        local advance = imgui.CalcTextSize(character)
        width = width + advance
    end
    return width
end

function alert.draw(tracker, alerts, config, now)
    if not config.center_alert_enabled then return end
    local lines = {}
    for _, event in ipairs(tracker.pending) do
        if alerts:is_selected(event) then
            lines[#lines + 1] = event.monster .. (event.action == 'casting' and ' casting ' or ' readying ') .. event.move
                .. (event.preparation_target and (' -> ' .. event.preparation_target) or '')
        end
    end
    if #lines == 0 then return end
    local display = imgui.GetIO().DisplaySize
    if display.x <= 0 or display.y <= 0 then return end
    local font, size, width = imgui.GetFont(), 40, 0
    imgui.PushFont(font, size)
    for _, line in ipairs(lines) do width = math.max(width, line_width(line)) end
    imgui.PopFont()
    if width > display.x * 0.9 then size = size * display.x * 0.9 / width end
    imgui.PushFont(font, size)
    width = 0
    for _, line in ipairs(lines) do width = math.max(width, line_width(line)) end
    local amplitude = size * 0.12
    local line_height = imgui.GetTextLineHeightWithSpacing() + amplitude * 2
    local height = #lines * line_height + 24
    width = width + 32
    imgui.SetNextWindowPos({ (display.x - width) / 2, (display.y - height) / 2 }, ImGuiCond_Always)
    imgui.SetNextWindowSize({ width, height }, ImGuiCond_Always)
    local flags = bit.bor(ImGuiWindowFlags_NoTitleBar, ImGuiWindowFlags_NoResize,
        ImGuiWindowFlags_NoMove, ImGuiWindowFlags_NoScrollbar, ImGuiWindowFlags_NoSavedSettings,
        ImGuiWindowFlags_NoInputs, ImGuiWindowFlags_NoBackground, ImGuiWindowFlags_NoFocusOnAppearing)
    if imgui.Begin('##rtfm_center_alert', { true }, flags) then
        local x, y = imgui.GetWindowPos()
        -- One smooth pulse per second; keep the text readable at its dimmest.
        local alpha = 0.35 + 0.65 * (0.5 + 0.5 * math.cos(now * 2 * math.pi))
        local thickness = math.max(1, size / 20)
        -- Finish all outlines before the yellow fill so adjacent glyphs stay clear.
        for pass = 1, 2 do
            imgui.PushStyleColor(ImGuiCol_Text, pass == 1 and { 0, 0, 0, alpha } or { 1, 0.9, 0.2, alpha })
            for row, line in ipairs(lines) do
                local offset = 0
                local left = x + (width - line_width(line)) / 2
                local baseline = y + 12 + amplitude + (row - 1) * line_height
                for character in characters(line) do
                    local wave = math.sin(offset / math.max(size, 1) * 0.7 - now * 4) * amplitude
                    if pass == 1 then
                        for _, shift in ipairs(outline_offsets) do
                            imgui.SetCursorScreenPos({ left + offset + shift[1] * thickness,
                                baseline + wave + shift[2] * thickness })
                            imgui.Text(character)
                        end
                    else
                        imgui.SetCursorScreenPos({ left + offset, baseline + wave })
                        imgui.Text(character)
                    end
                    local advance = imgui.CalcTextSize(character)
                    offset = offset + advance
                end
            end
            imgui.PopStyleColor()
        end
    end
    imgui.End()
    imgui.PopFont()
end

return alert
