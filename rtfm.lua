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


    -- Pattern: "<monster> readies <move>"
    -- Example: "Goblin Butcher readies Bomb Toss."
    -- Pattern: "<monster> readies <move>"


    local monster, move = msg:match('^%s*(.-)%s+readies%s+([^%.]+)')

    if monster and move then
        move = move:gsub('[%p%d%s]+$', '')

        local mob_entry = mob_data[monster]

        -- If not showing all mobs, and this mob isn't listed, stop
        if not show_all_mobs and not mob_entry then
            return
        end

        pending_move = {
            mob = monster,
            move = move,
            time = os.clock(),
            entry = mob_entry,
        }

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

        return
    end

    -- Pattern: "<monster> uses <move>"
    local umob, umove, target, dmg =
        msg:match('^%s*(.-)%s+uses%s+([^%.]+)%.?%s*(.-)%s+takes%s+(%d+)%s+points%s+of%s+damage')
    
    if not umob then
        umob, umove = msg:match('^%s*(.-)%s+uses%s+([^%.]+)')
    end

    if umob and umove then
        umove = umove:gsub('[%p%d%s]+$', '')

        if pending_move
            and pending_move.mob == umob
            and pending_move.move == umove
        then
            active_move = {
                mob  = umob,
                move = umove,
                hits = {},
                time = os.clock(),
                entry = pending_move.entry,
            }
            pending_move = nil
        end

            -- If damage was embedded in the same line, capture it immediately
        if active_move and target and dmg then
            table.insert(active_move.hits, {
                target = target,
                damage = tonumber(dmg),
            })
            active_move.time = os.clock()
        end

        return
    end

    -- Capture damage lines while a move is active
    if active_move then
        local target, dmg = msg:match('^(%S+) takes (%d+) points of damage')
        if target and dmg then
            table.insert(active_move.hits, {
                target = target,
                damage = tonumber(dmg),
            })
            active_move.time = os.clock()
            return
        end
    end

    -- Finalize active move after results stop coming in
    if active_move and os.clock() - active_move.time > 1.5 then
        local tag
        if active_move.entry then
            tag = active_move.entry.nm and 'NM' or 'Mob'
        else
            tag = 'Unlisted'
        end

        print(string.format(
            '[RTFM] %s | %s used %s on %d target(s)',
            tag,
            active_move.mob,
            active_move.move,
            #active_move.hits
        ))

        for _, hit in ipairs(active_move.hits) do
            print(string.format(
                '  - %s (%d dmg)',
                hit.target,
                hit.damage
            ))
        end

        active_move = nil
    end

end)
