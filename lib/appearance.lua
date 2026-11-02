local appearance = {}
local palettes = {
    { offensive = { 1, 0.5, 0.5, 0.16 }, defensive = { 0.55, 0.82, 1, 0.16 },
      tracked = { 0.2, 1, 0.2, 1 }, button = { 0.1, 0.45, 0.1, 1 } },

}
function appearance.palette()
    return palettes[1]
end
function appearance.button(state)
    local base = appearance.palette().button
    local extra = state == 'hover' and 0.12 or (state == 'active' and -0.05 or 0)
    return { math.max(0, math.min(1, base[1] + extra)),
        math.max(0, math.min(1, base[2] + extra)), math.max(0, math.min(1, base[3] + extra)), 1 }
end
return appearance
