local imgui = require('imgui')
local animation = {}
local positions = setmetatable({}, { __mode = 'k' })
local duration = 0.55

function animation.remember(event, x, y, now)
    positions[event] = { x = x, y = y, timestamp = now }
end

function animation.state(event, now)
    local origin = event.preparation_row and positions[event.preparation_row]
    local age = now - event.timestamp
    if not origin or age < 0 or age >= duration or event.timestamp - origin.timestamp > 1 then return nil end
    return age / duration, origin
end

function animation.draw(event, now, x, y, text, bounds)
    local progress, origin = animation.state(event, now)
    if not progress then return end
    local eased = 1 - (1 - progress)^3
    local size = imgui.GetFontSize()
    local position = { origin.x + (x - origin.x) * eased + math.sin(progress * math.pi) * size * 0.4,
        origin.y + (y - origin.y) * eased }
    local draw = imgui.GetForegroundDrawList()
    draw:PushClipRect(bounds[1], bounds[2], true)
    draw:AddText(imgui.GetFont(), size, position,
        imgui.GetColorU32({ 1, 0.9, 0.35, (1 - progress) * 0.9 }), text)
    draw:PopClipRect()
end

return animation
