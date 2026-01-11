addon.name     = 'rtfm'
addon.author   = 'Rialia'
addon.version  = '0.0.1'
addon.desc     = 'Learning addon: parse log lines step by step.'
addon.commands = { 'rtfm' }

require('common')
local mob_data = require('data.mobs')

local show_all_mobs = true  -- true = show all readies, false = only mobs in data list

local pending_move = nil
local active_move  = nil

print('[RTFM] addon loaded')

-- Removes Ashita formatting control chars (your original addon does this too)
local function strip_formatting(s)
    if not s then return '' end
    return s:gsub('[\31\30\127]', '')
end

-- IMPORTANT: Do NOT print every line inside text_in (can deadlock if you re-print recursively).
-- We'll print only when we matched something interesting.
ashita.events.register('text_in', 'rtfm_text_in', function (e)
    if not e or e.injected or not e.message then return end

    local msg = strip_formatting(e.message):trim()

    -- For now: only look at common "battle" modes used for readies lines.
    -- We'll expand this list later once you're comfortable.
    if e.mode ~= 100 and e.mode ~= 105 and e.mode ~= 110 then
        return
    end

    -- Pattern: "<monster> readies <move>"
    -- Example: "Goblin Butcher readies Bomb Toss."
    local monster, move = msg:match('^%s*(.-)%s+readies%s+([^%.]+)')

    if monster and move then
        move = move:gsub('[%p%d%s]+$', '')

            local mob_entry = mob_data[monster]

            -- If not showing all mobs, and this mob isn't listed, stop
            if not show_all_mobs and not mob_entry then
                return
            end

            local tag
            if mob_entry then
                tag = mob_entry.nm and 'NM' or 'Mob'
            else
                tag = 'Unlisted'
            end

            print(string.format(
                '[RTFM] %s | %s readies %s',
                tag, monster, move
            ))
    end
end)
