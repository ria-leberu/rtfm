local names = require('lib.names')
local timing = require('lib.timing')
local actions = {}
actions.__index = actions

local function merge_players(previous, incoming)
    local players, seen = {}, {}
    for _, list in ipairs({ previous.affected_players or {}, incoming.affected_players or {} }) do
        for _, player in ipairs(list) do
            local key = player:lower()
            if not seen[key] then
                seen[key] = true
                players[#players + 1] = player
            end
        end
    end
    table.sort(players)
    previous.affected_players = players
end

function actions.new(config)
    return setmetatable({ config = config, pending = {}, recent = {} }, actions)
end

function actions.parse(message)
    -- Color controls contain a marker AND a palette byte. Leaving the palette
    -- byte behind makes visually identical chat/resource names compare unequal.
    message = message:gsub('[\30\31].', ''):gsub('\127.', '\n')
    message = names.trim(message:gsub('[%z\1-\8\11\12\14-\31\127]', ''))
    local interrupted = message:match("^(.-)'s casting is interrupted[%.!]?$")
    if interrupted then return { monster = names.trim(interrupted), action = 'interrupted' } end
    local patterns = {
        { 'readies', 'readies' },
        { 'starts casting', 'casting' },
        { 'uses', 'uses' },
        { 'casts', 'casts' },
    }
    for _, pattern in ipairs(patterns) do
        local monster, move = message:match('^(.-)%s+' .. pattern[1] .. '%s+([^%.]+)')
        if monster then
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
    local retention = timing.retention_minutes(self.config.log_retention_minutes) * 60
    for i = #self.recent, 1, -1 do
        if now - self.recent[i].timestamp >= retention then table.remove(self.recent, i) end
    end
    for i = #self.pending, 1, -1 do
        local timeout = self.pending[i].action == 'casting' and (self.config.casting_timeout or 15)
            or self.config.pending_timeout
        if now - self.pending[i].timestamp >= timeout then
            table.remove(self.pending, i)
        end
    end
    while #self.recent > self.config.max_recent do table.remove(self.recent, 1) end
end

function actions:interrupt(event)
    local removed = false
    for i = #self.pending, 1, -1 do
        local previous = self.pending[i]
        local same_actor = previous.actor_id and event.actor_id and previous.actor_id == event.actor_id
            or (not (previous.actor_id and event.actor_id)
                and names.normalize(previous.monster) == names.normalize(event.monster))
        if previous.action == 'casting' and same_actor then
            table.remove(self.pending, i)
            removed = true
        end
    end
    return removed
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
        local previous = self.pending[i]
        local spell = event.action == 'casting' or event.action == 'casts'
        if previous.id == event.id and (previous.action == 'casting') == spell
            and (not previous.actor_id or not event.actor_id or previous.actor_id == event.actor_id) then
            matched = i
            break
        end
    end
    if pending and matched then
        -- Packet preparation enriches an existing chat row without restarting
        -- its timer or playing its selected alert sound a second time.
        local previous = self.pending[matched]
        if event.actor_id then
            for _, key in ipairs({ 'actor_id', 'action_id', 'category', 'preparation_target',
                'preparation_target_id', 'target_ids', 'estimated_duration' }) do
                if event[key] ~= nil then previous[key] = event[key] end
            end
        end
        return false
    end
    if not pending then
        if matched then
            event.preparation_row = self.pending[matched]
            table.remove(self.pending, matched)
        end
        -- Collapse short bursts of result lines, not the entire display lifetime.
        if not matched then
            for i = #self.recent, 1, -1 do
                local previous = self.recent[i]
                if previous.id == event.id and previous.action == event.action
                    and (not previous.actor_id or not event.actor_id or previous.actor_id == event.actor_id)
                    and (not previous.action_id or not event.action_id or previous.action_id == event.action_id)
                    and (not previous.category or not event.category or previous.category == event.category) then
                    local age = now - previous.timestamp
                    if event.affected_players ~= nil then
                        if age <= self.config.affected_match_window then
                            -- A move can deliver repeated or split result packets.
                            -- Merge their players; a new preparation above starts
                            -- a separate execution even inside this short window.
                            merge_players(previous, event)
                            return false
                        end
                    elseif previous.affected_players ~= nil and age <= self.config.affected_match_window then
                        return false
                    elseif age < self.config.duplicate_window then
                        return false
                    end
                    break
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
