local names = require('lib.names')
local alerts = {}
alerts.__index = alerts

function alerts.new(saved, entries)
    local self = setmetatable({ selected = {}, entries = {} }, alerts)
    if type(saved) == 'table' then
        for monster, moves in pairs(saved) do
            if type(monster) == 'string' and type(moves) == 'table' then
                for move, enabled in pairs(moves) do
                    if type(move) == 'string' and enabled == true then
                        self:set({ monster = monster, move = move }, true)
                    end
                end
            end
        end
    end
    if type(entries) == 'table' then
        for _, entry in pairs(entries) do
            if type(entry) == 'table' and type(entry.monster) == 'string'
                and type(entry.move) == 'string' and type(entry.enabled) == 'boolean' then
                self:set(entry, entry.enabled)
            end
        end
    end
    return self
end

function alerts:is_selected(event)
    local moves = self.selected[names.normalize(event.monster)]
    return moves ~= nil and moves[names.normalize(event.move)] == true
end

function alerts:set(event, enabled)
    local monster, move = names.normalize(event.monster), names.normalize(event.move)
    if monster == '' or move == '' then return end
    self.entries[monster] = self.entries[monster] or {}
    local entry = self.entries[monster][move]
    if not entry then
        entry = { monster = names.trim(event.monster), move = names.trim(event.move) }
        self.entries[monster][move] = entry
    end
    entry.enabled = enabled == true
    if enabled then
        self.selected[monster] = self.selected[monster] or {}
        self.selected[monster][move] = true
    elseif self.selected[monster] then
        self.selected[monster][move] = nil
        if next(self.selected[monster]) == nil then self.selected[monster] = nil end
    end
end

function alerts:list()
    local entries = {}
    for _, moves in pairs(self.entries) do
        for _, entry in pairs(moves) do entries[#entries + 1] = entry end
    end
    table.sort(entries, function(a, b)
        local left, right = a.monster:lower(), b.monster:lower()
        return left == right and a.move:lower() < b.move:lower() or left < right
    end)
    return entries
end

function alerts:remove(event)
    local monster, move = names.normalize(event.monster), names.normalize(event.move)
    self:set(event, false)
    if self.entries[monster] then
        self.entries[monster][move] = nil
        if next(self.entries[monster]) == nil then self.entries[monster] = nil end
    end
end

function alerts:replace(original, replacement, enabled)
    local monster, move = names.normalize(replacement.monster), names.normalize(replacement.move)
    if monster == '' or move == '' then return false, 'Enter both an enemy and a move.' end
    local same = monster == names.normalize(original.monster) and move == names.normalize(original.move)
    if not same and self.entries[monster] and self.entries[monster][move] then
        return false, 'That enemy/move entry already exists.'
    end
    self:remove(original)
    self:set(replacement, enabled)
    return true
end

return alerts
