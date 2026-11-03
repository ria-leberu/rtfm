local names = require('lib.names')
local alerts = {}
alerts.__index = alerts
local function is_spell(event)
    return event.kind == 'spell' or event.action == 'casting' or event.action == 'casts'
        or event.category == 4 or event.category == 8
end
local function family_key(event)
    return (is_spell(event) and 'spell:' or '') .. names.normalize(event.move)
end

function alerts.new(saved, entries)
    local self = setmetatable({ selected = {}, entries = {}, family_entries = {}, spell_entries = {} }, alerts)
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
                if entry.scope ~= 'family' then self:set(entry, entry.enabled) end
            end
        end
    end
    -- Existing explicit family choices win over migrated legacy mob entries.
    if type(entries) == 'table' then
        for _, entry in pairs(entries) do
            if type(entry) == 'table' and entry.scope == 'family' and type(entry.monster) == 'string'
                and type(entry.move) == 'string' and type(entry.enabled) == 'boolean' then
                self:set(entry, entry.enabled)
            end
        end
    end
    return self
end

function alerts:is_selected(event)
    local monster, move = names.normalize(event.monster), names.normalize(event.move)
    if event.scope == 'spell' then
        return self.spell_entries[move] ~= nil and self.spell_entries[move].enabled
    end
    if event.scope == 'family' then
        local key = family_key(event)
        local ids = event.family_ids or { event.family_id }
        if #ids == 0 then return false end
        for _, id in ipairs(ids) do
            local group = self.family_entries[id]
            if not group or not group[key] or not group[key].enabled then return false end
        end
        return true
    end
    local direct = self.entries[monster] and self.entries[monster][move]
    if direct and (direct.kind ~= 'spell' or is_spell(event)) then return direct.enabled end
    local alias_enabled = false
    for _, moves in pairs(self.entries) do
        local entry = moves[move]
        if entry and (entry.kind ~= 'spell' or is_spell(event)) then
            for _, alias in ipairs(entry.aliases or {}) do
                if names.normalize(alias) == monster then
                    if not entry.enabled then return false end
                    alias_enabled = true
                end
            end
        end
    end
    if alias_enabled then return true end
    if next(self.family_entries) then
        for id in pairs(require('lib.catalogue_browser').groups_for(event.monster)) do
            local entry = self.family_entries[id] and self.family_entries[id][family_key(event)]
            if entry and entry.enabled then return true end
        end
    end
    return is_spell(event) and self.spell_entries[move] ~= nil and self.spell_entries[move].enabled or false
end

function alerts:set(event, enabled)
    if event.scope == nil and not is_spell(event) then
        local family_rule = require('lib.catalogue_browser').family_rule_for(event)
        if family_rule then
            event = family_rule
            self.migrated = true
        end
    end
    local monster, move = names.normalize(event.monster), names.normalize(event.move)
    if monster == '' or move == '' then return end
    if event.scope == 'spell' then
        self.spell_entries[move] = { monster = 'Any enemy', move = names.trim(event.move),
            scope = 'spell', kind = 'spell', enabled = enabled == true }
        return
    end
    if event.scope == 'family' then
        local key = family_key(event)
        for _, id in ipairs(event.family_ids or { event.family_id }) do
            if type(id) == 'number' and id >= 1 and id % 1 == 0 then
                self.family_entries[id] = self.family_entries[id] or {}
                self.family_entries[id][key] = {
                    monster = names.trim(event.monster), move = names.trim(event.move),
                    scope = 'family', family_id = id, enabled = enabled == true,
                    kind = is_spell(event) and 'spell' or nil,
                }
            end
        end
        return
    end
    self.entries[monster] = self.entries[monster] or {}
    local entry = self.entries[monster][move]
    if not entry then
        entry = { monster = names.trim(event.monster), move = names.trim(event.move) }
        self.entries[monster][move] = entry
    end
    entry.enabled = enabled == true
    if is_spell(event) then entry.kind = 'spell' end
    if type(event.aliases) == 'table' then
        local aliases = {}
        for _, alias in ipairs(event.aliases) do
            if type(alias) == 'string' then aliases[#aliases + 1] = alias end
        end
        entry.aliases = aliases
    end
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
    for _, moves in pairs(self.family_entries) do
        for _, entry in pairs(moves) do entries[#entries + 1] = entry end
    end
    for _, entry in pairs(self.spell_entries) do entries[#entries + 1] = entry end
    table.sort(entries, function(a, b)
        local left, right = a.monster:lower(), b.monster:lower()
        if left ~= right then return left < right end
        if a.move:lower() ~= b.move:lower() then return a.move:lower() < b.move:lower() end
        if a.scope ~= b.scope then return (a.scope or 'monster') < (b.scope or 'monster') end
        return (a.family_id or 0) < (b.family_id or 0)
    end)
    return entries
end

function alerts:remove(event)
    if event.scope == 'spell' then self.spell_entries[names.normalize(event.move)] = nil; return end
    if event.scope == 'family' then
        for _, id in ipairs(event.family_ids or { event.family_id }) do
            local moves = self.family_entries[id]
            if moves then
                moves[family_key(event)] = nil
                if next(moves) == nil then self.family_entries[id] = nil end
            end
        end
        return
    end
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
    if monster == names.normalize(original.monster) and replacement.aliases == nil then
        replacement.aliases = original.aliases
    end
    replacement.kind = replacement.kind or original.kind
    self:remove(original)
    self:set(replacement, enabled)
    return true
end

return alerts
