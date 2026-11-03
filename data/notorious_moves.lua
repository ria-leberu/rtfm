local groups = {}
for _, group in ipairs(require('data.generated.browser').families) do groups[group.family_id] = group.moves end

return function(addition)
    local moves, seen = {}, {}
    local function add(id)
        if not seen[id] then moves[#moves + 1], seen[id] = id, true end
    end
    for _, id in ipairs(addition.skill_list_ids or { addition.skill_list_id }) do
        for _, move in ipairs(groups[id] or {}) do add(move) end
    end
    for _, move in ipairs(addition.extra_moves or {}) do add(move) end
    table.sort(moves)
    return moves
end
