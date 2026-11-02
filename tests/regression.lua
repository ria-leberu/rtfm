-- Run from the addon directory with Lua 5.1 or LuaJIT:
-- lua tests/regression.lua
package.path = './?.lua;' .. package.path
local names = require('lib.names')
local actions = require('lib.actions')
local config = require('config')

assert(names.normalize("The Aw'ghrah") == 'awghrah')
assert(names.normalize('Fire II') ~= names.normalize('Fire III'))
assert(names.map({ ['Wild Baelfyr'] = true }).wildbaelfyr)
assert(require('data.moves').greatermanticore.greatwhirlwind == 'Choke')
local function event(text)
    return assert(actions.parse(text, 51, config.casting_modes))
end
assert(event('Kirin casts Fire II on Rialia.').move == 'Fire II')
assert(event('Kirin starts casting Fire III on Rialia.').move == 'Fire III')
assert(not actions.parse('Rialia says hello.', 51, config.casting_modes))

local tracker = actions.new(config)
assert(tracker:record(event('Kirin readies Mortal Ray.'), 0))
assert(tracker:record(event('Genbu readies Mortal Ray.'), 0))
assert(tracker:record(event('Kirin uses Mortal Ray.'), 1))
assert(#tracker.pending == 1 and tracker.pending[1].monster == 'Genbu')
assert(not tracker:record(event('Kirin uses Mortal Ray.'), 1.1))
assert(tracker:record(event('Kirin uses Mortal Ray.'), 2))
assert(#tracker.recent == 2)
assert(tracker:record(event('Kirin readies Mortal Ray.'), 2.1))
assert(tracker:record(event('Kirin uses Mortal Ray.'), 2.2))
assert(#tracker.recent == 3)
tracker:update(200)
assert(#tracker.pending == 0 and #tracker.recent == 0)
for i = 1, 150 do tracker:record(event('Kirin uses Fire II.'), 200 + i) end
assert(#tracker.recent == config.max_recent)

-- Exercise save failures and backup recovery without touching real files.
local real_io, real_os, real_loadfile = io, os, loadfile
local files, fail_install, fail_write = {}, false, false
io = { open = function(path, mode)
    if mode == 'r' then
        if not files[path] then return nil end
        return { close = function() return true end }
    end
    local content = ''
    return {
        write = function(_, value)
            if fail_write then return nil, 'simulated write failure' end
            content = content .. value
            return true
        end,
        close = function() files[path] = content; return true end,
    }
end }
os = {
    remove = function(path) files[path] = nil; return true end,
    rename = function(source, target)
        if fail_install and source:match('%.tmp$') then return nil, 'simulated rename failure' end
        if not files[source] then return nil, 'missing source' end
        files[target], files[source] = files[source], nil
        return true
    end,
}
loadfile = function(path) return loadstring(files[path] or '') end
local storage = require('lib.storage')
assert(storage.save('test.lua', { ['quoted"name'] = { ['Fire II'] = true } }))
assert(storage.load('test.lua')['quoted"name']['Fire II'])
local original = files['test.lua']
fail_write = true
assert(not storage.save('test.lua', { changed = true }))
assert(files['test.lua'] == original)
fail_write, fail_install = false, true
assert(not storage.save('test.lua', { changed = true }))
assert(files['test.lua'] == original)
fail_install = false
assert(storage.save('test.lua', { changed = true }))
files['test.lua'] = 'not valid Lua'
assert(storage.load('test.lua')['quoted"name']['Fire II'])
io, os, loadfile = real_io, real_os, real_loadfile

-- Load the actual entry point with host stubs and drive its registered events.
local callbacks, clock, saves, sounds, scans = {}, 0, {}, 0, 0
local entities = {
    GetName = function(_, i) if i == 0 then scans = scans + 1; return 'Kirin' end end,
    GetSpawnFlags = function() return 0x10 end,
    GetTrustOwnerTargetIndex = function() return 0 end,
}
local party = {
    GetMemberIsActive = function() return 0 end,
    GetMemberName = function(_, i) if i == 0 then return 'Rialia' end end,
}
AshitaCore = { GetMemoryManager = function()
    return { GetParty = function() return party end, GetEntity = function() return entities end }
end }
addon = { path = 'mock/' }
ashita = {
    events = { register = function(name, _, callback) callbacks[name] = callback end },
    fs = { create_dir = function() end },
    misc = { play_sound = function() sounds = sounds + 1 end },
}
bit = { band = function(a, b) return a == b and b or 0 end }
package.loaded.common = {}
package.loaded.imgui = { GetTime = function() return clock end }
local displayed_tracker
package.loaded['lib.overlay'] = { draw = function(open, tracker)
    assert(not open[1])
    displayed_tracker = tracker
end }
package.loaded['lib.affected'] = {
    parse = function(e) return e.fixture end,
    resolve = function(packet) return packet end,
}
AshitaCore.GetResourceManager = function() return {} end
package.loaded['lib.storage'] = {
    load = function() return {} end,
    save = function(path, value) saves[path] = value; return true end,
}
dofile('rtfm.lua')
local function command(text)
    local value = setmetatable({}, { __index = { args = function() return text end } })
    local e = { command = value }
    callbacks.command(e)
    assert(e.blocked)
end
command({ '/rtfm', 'hide' })
command({ '/rtfm', 'learn', 'on' })
command({ '/rtfm', 'highlight', 'The', 'Greater', 'Manticore' })
callbacks.text_in({ message = 'Kirin uses Mortal Ray.', mode = 51 })
callbacks.text_in({ message = 'Kirin uses Mortal Ray.', mode = 51 })
assert(scans == 1 and sounds == 1)
clock = 1
callbacks.text_in({ message = 'Kirin uses Mortal Ray.', mode = 51 })
assert(sounds == 2)
clock = 11
callbacks.d3d_present()
assert(saves['mock/data\\mobs_learned.lua'].kirin.mortalray)
assert(saves['mock/data\\preferences.lua'].highlight_mobs.greatermanticore)
assert(saves['mock/data\\preferences.lua'].is_open == false)
callbacks.text_in({ message = 'Kirin uses Fulmination.', mode = 51 })
callbacks.unload()
assert(saves['mock/data\\mobs_learned.lua'].kirin.fulmination)

-- Reproduce the user's confirmed packet without any matching chat callback.
clock = 20
callbacks.packet_in({ fixture = {
    monster = 'Khimaira', move = 'Fossilizing Breath', action = 'uses',
    affected_players = { 'Rialia' },
} })
callbacks.text_in({ injected = true, message = 'Khimaira uses Fossilizing Breath.', mode = 185 })
callbacks.d3d_present()
local breath = displayed_tracker.recent[#displayed_tracker.recent]
assert(breath.monster == 'Khimaira' and breath.move == 'Fossilizing Breath')
assert(breath.affected_players[1] == 'Rialia')
clock = 22
callbacks.packet_in({ fixture = {
    monster = 'Khimaira', move = 'Dreadstorm', action = 'uses',
    affected_players = { 'Rialia' },
} })
callbacks.d3d_present()
local dreadstorm = displayed_tracker.recent[#displayed_tracker.recent]
assert(dreadstorm.move == 'Dreadstorm' and dreadstorm.affected_players[1] == 'Rialia')

-- Known entities take precedence over name heuristics and configured exceptions.
local actor_filter = require('lib.actors').new({
    blacklist_enabled = true, blacklist_mobs = {}, guaranteed_mobs = { outsider = true },
})
entities.GetName = function(_, i)
    if i == 0 then return 'Outsider' end
    if i == 1 then return 'Dragon' end
    if i == 2 then return 'Pet' end
end
entities.GetSpawnFlags = function(_, i) return i == 0 and 0x01 or 0x10 end
entities.GetTrustOwnerTargetIndex = function(_, i) return i == 2 and 10 or 0 end
assert(actor_filter:is_excluded('Outsider', 20))
assert(actor_filter:is_excluded('Rialia', 20))
assert(actor_filter:is_excluded('Pet', 20))
assert(not actor_filter:is_excluded('Dragon', 20))
print('RTFM regression checks passed.')
