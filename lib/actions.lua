local names = require('lib.names')
local actions = {}
actions.__index = actions

function actions.new(config)
    return setmetatable({ config = config, pending = {}, recent = {} }, actions)
end

function actions.parse(message, mode, casting_modes)
    -- Color controls contain a marker AND a palette byte. Leaving the palette
    -- byte behind makes visually identical chat/resource names compare unequal.
    message = message:gsub('[\30\31].', ''):gsub('\127.', '\n')
    message = names.trim(message:gsub('[%z\1-\8\11\12\14-\31\127]', ''))
    local patterns = {
        { 'readies', 'readies' },
        { 'starts casting', 'casting' },
        { 'uses', 'uses' },
        { 'casts', 'casts' },
    }
    for _, pattern in ipairs(patterns) do
        local monster, move = message:match('^(.-)%s+' .. pattern[1] .. '%s+([^%.]+)')
        if monster and (pattern[2] ~= 'casting' or casting_modes[mode]) then
            -- Target suffixes occur on both spell and ability messages.
            move = move:match('^(.-)%s+on%s+') or move
            monster, move = names.trim(monster), names.trim(move)
            if monster ~= '' and move ~= '' then
                return { monster = monster, move = move, action = pattern[2] }
            end
        end
    end
end

-- Packet results are complete events, even if chat is filtered or injected.
function actions:attach_affected(result, now)
    return self:record(result, now)
end

function actions:update(now)
    for _, group in ipairs({ { self.pending, self.config.pending_timeout },
        { self.recent, self.config.display_time } }) do
        for i = #group[1], 1, -1 do
            if now - group[1][i].timestamp >= group[2] then
                table.remove(group[1], i)
            end
        end
    end
end

function actions:record(event, now)
    self:update(now)
    local row = {}
    for key, value in pairs(event) do row[key] = value end
    event = row
    event.id = names.normalize(event.monster) .. ':' .. names.normalize(event.move)
    local pending = event.action == 'readies' or event.action == 'casting'
    local matched
    for i = #self.pending, 1, -1 do
        if self.pending[i].id == event.id then
            matched = i
            break
        end
    end
    if pending and matched then return false end
    if not pending then
        if matched then table.remove(self.pending, matched) end
        -- Collapse short bursts of result lines, not the entire display lifetime.
        if not matched then
            for i = #self.recent, 1, -1 do
                local previous = self.recent[i]
                if previous.id == event.id and previous.action == event.action then
                    local age = now - previous.timestamp
                    if event.affected_players ~= nil then
                        if previous.affected_players == nil and age <= self.config.affected_match_window then
                            previous.affected_players = event.affected_players
                            return false
                        end
                        -- Each confirmed packet is a separate move execution.
                    elseif previous.affected_players ~= nil and age <= self.config.affected_match_window then
                        return false
                    elseif age < self.config.duplicate_window then
                        return false
                    end
                end
            end
        end
    end
    event.timestamp = now
    local list = pending and self.pending or self.recent
    local limit = pending and self.config.max_pending or self.config.max_recent
    table.insert(list, event)
    while #list > limit do table.remove(list, 1) end
    return true
end

return actions
