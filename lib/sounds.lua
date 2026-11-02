local names = require('lib.names')
local files = require('lib.sound_files')
local sounds = { library = {}, overrides = {} }
local config, root

function sounds.init(settings, base_path, saved)
    config, root = settings, base_path .. 'sounds\\'
    sounds.library, sounds.overrides = {}, {}
    for key, path in pairs(type(saved.sound_overrides) == 'table' and saved.sound_overrides or {}) do
        if type(key) == 'string' and type(path) == 'string' and path:lower():match('%.wav$') then
            sounds.overrides[key] = path
        end
    end
end

function sounds.key(event)
    local spell = event.kind == 'spell' or event.scope == 'spell' or event.action == 'casting'
        or event.action == 'casts' or event.category == 4 or event.category == 8
    return (spell and 'spell:' or 'move:') .. names.normalize(event.move)
end

function sounds.path(event)
    local path = event and sounds.overrides[sounds.key(event)]
    return path and files.exists(path) and path or root .. 'alert.wav'
end

function sounds.play(event, path)
    if not config.sound_alerts_enabled then return false, 'Sound alerts are off.' end
    path = path or sounds.path(event)
    if not files.exists(path) then path = root .. 'alert.wav' end
    local ok, err = pcall(ashita.misc.play_sound, path)
    if ok and err == false then ok, err = false, 'Unable to play this WAV file.' end
    if not ok and path ~= root .. 'alert.wav' then
        ok, err = pcall(ashita.misc.play_sound, root .. 'alert.wav')
        if ok and err == false then ok, err = false, 'Unable to play alert.wav.' end
    end
    return ok, err
end

function sounds.refresh()
    local entries, err = files.list(root)
    if not entries then return false, err end
    sounds.library = {}
    for _, entry in ipairs(entries) do
        if not entry.directory and entry.name:lower() ~= 'alert.wav' then
            sounds.library[#sounds.library + 1] = root .. entry.name
        end
    end
    return true
end

function sounds.assign(event, path)
    sounds.overrides[sounds.key(event)] = path
end

function sounds.folder() return root end
return sounds
