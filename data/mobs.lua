-- data/mobs.lua
-- Simple whitelist of mobs and their TP moves

local mobs = {
    ["The Moblin Topsman"] = {
        moves = {
            ["Crispy Candle"] = true,
            ["Power Attack"] = true,
        },
        nm = false,
    },

    ["Mee Deggi the Punisher"] = {
        moves = {
            ["Bomb Toss"] = true,
            ["Goblin Rush"] = true,
        },
        nm = true,
    },
}

return mobs
