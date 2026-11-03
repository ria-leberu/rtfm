local imgui = require('imgui')
local appearance = require('lib.appearance')
local buttons = {}

local function draw_button(id, kind, selected, tooltip)
    local size = imgui.GetFontSize() * 1.4
    local clicked = imgui.Button('##' .. id, { size, size })
    local x, y = imgui.GetItemRectMin()
    local draw = imgui.GetWindowDrawList()
    local color = imgui.GetColorU32(selected and appearance.palette().tracked or { 0.9, 0.9, 0.9, 1 })
    local thickness = math.max(1, size * 0.06)
    if kind == 'track' then
        local center, points = { x + size / 2, y + size / 2 }, {}
        for i = 0, 9 do
            local angle, radius = -math.pi / 2 + i * math.pi / 5, size * (i % 2 == 0 and 0.34 or 0.15)
            points[#points + 1] = { center[1] + math.cos(angle) * radius, center[2] + math.sin(angle) * radius }
        end
        for i, point in ipairs(points) do
            local next_point = points[i % #points + 1]
            if selected then draw:AddTriangleFilled(center, point, next_point, color)
            else draw:AddLine(point, next_point, color, thickness) end
        end
    else
        local function point(a,b) return { x + size * a, y + size * b } end
        local points = { point(0.2,0.38), point(0.35,0.38), point(0.52,0.23),
            point(0.52,0.77), point(0.35,0.62), point(0.2,0.62) }
        for i, p in ipairs(points) do draw:AddLine(p, points[i % #points + 1], color, thickness) end
        draw:AddLine(point(0.65,0.36), point(0.73,0.5), color, thickness)
        draw:AddLine(point(0.73,0.5), point(0.65,0.64), color, thickness)
        draw:AddLine(point(0.77,0.26), point(0.88,0.5), color, thickness)
        draw:AddLine(point(0.88,0.5), point(0.77,0.74), color, thickness)
    end
    if imgui.IsItemHovered() then imgui.SetTooltip(tooltip) end
    return clicked
end

function buttons.track(id, selected)
    return draw_button(id, 'track', selected, selected and 'Untrack this move / spell' or 'Track this move / spell')
end

function buttons.sound(id)
    return draw_button(id, 'sound', false, 'Choose alert sound for this move / spell')
end

return buttons
