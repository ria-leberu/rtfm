local names = require('lib.names')
local actors = {}
actors.__index = actors

function actors.new(config)
    return setmetatable({ config = config, cache = {}, refreshed_at = -math.huge }, actors)
end

function actors:is_excluded(name, now)
    local key = names.normalize(name)
    if self.config.blacklist_enabled and self.config.blacklist_mobs[key] then return true end
    local memory = AshitaCore:GetMemoryManager()
    local party = memory:GetParty()
    for i = 0, 17 do
        if (i == 0 or party:GetMemberIsActive(i) == 1)
            and names.normalize(party:GetMemberName(i)) == key then
            return true
        end
    end
    -- Share one entity scan across messages for a second instead of scanning
    -- every slot separately for every ready/result line.
    if now - self.refreshed_at >= 1 then
        self.cache = {}
        local entities = memory:GetEntity()
        for i = 0, 2303 do
            local entity_name = entities:GetName(i)
            if entity_name and entity_name ~= '' then
                local entity_key = names.normalize(entity_name)
                local flags = entities:GetSpawnFlags(i)
                local is_mob = bit.band(flags, 0x10) ~= 0
                local is_player = bit.band(flags, 0x01) ~= 0
                local is_pet = entities:GetTrustOwnerTargetIndex(i) ~= 0
                -- Exclusion wins if a PC/pet and monster share a display name.
                if is_player or is_pet then
                    self.cache[entity_key] = 'excluded'
                elseif is_mob and self.cache[entity_key] ~= 'excluded' then
                    self.cache[entity_key] = 'mob'
                end
            end
        end
        self.refreshed_at = now
    end
    if self.cache[key] then return self.cache[key] == 'excluded' end
    if self.config.guaranteed_mobs[key] then return false end
    -- A monster can enter the entity table after this second's shared scan.
    -- Recheck an unknown actor before the player-name fallback rejects its
    -- readying line (notably single-word NM names such as Tchakka).
    local entities = memory:GetEntity()
    local found_mob = false
    for i = 0, 2303 do
        local entity_name = entities:GetName(i)
        if entity_name and names.normalize(entity_name) == key then
            local flags = entities:GetSpawnFlags(i)
            if bit.band(flags, 0x01) ~= 0 or entities:GetTrustOwnerTargetIndex(i) ~= 0 then
                self.cache[key] = 'excluded'
                return true
            end
            if bit.band(flags, 0x10) ~= 0 then found_mob = true end
        end
    end
    if found_mob then
        self.cache[key] = 'mob'
        return false
    end
    -- Text-only fallback for actors absent from the entity table.
    return name:match('^[A-Z][a-z]+$') ~= nil
end

return actors
