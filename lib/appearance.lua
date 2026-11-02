local config = require('config')
local appearance = {}
local palettes = {
    { offensive = { 1, 0.5, 0.5, 0.16 }, defensive = { 0.55, 0.82, 1, 0.16 },
      tracked = { 0.2, 1, 0.2, 1 }, button = { 0.1, 0.45, 0.1, 1 } },
    { offensive = { 1, 0.65, 0.2, 0.18 }, defensive = { 0.35, 0.7, 1, 0.18 },
      tracked = { 1, 0.9, 0.45, 1 }, button = { 0.42, 0.32, 0.08, 1 } },
    { offensive = { 1, 0.45, 0.65, 0.18 }, defensive = { 0.3, 0.9, 0.8, 0.18 },
      tracked = { 1, 0.85, 0.9, 1 }, button = { 0.45, 0.15, 0.3, 1 } },
    { offensive = { 1, 1, 1, 0.18 }, defensive = { 1, 1, 1, 0.08 },
      tracked = { 1, 1, 1, 1 }, button = { 0.35, 0.35, 0.35, 1 } },
}
function appearance.palette()
    return palettes[(config.color_mode or 0) + 1] or palettes[1]
end
function appearance.button(state)
    local base = appearance.palette().button
    local extra = state == 'hover' and 0.12 or (state == 'active' and -0.05 or 0)
    return { math.max(0, math.min(1, base[1] + extra)),
        math.max(0, math.min(1, base[2] + extra)), math.max(0, math.min(1, base[3] + extra)), 1 }
end
return appearance
