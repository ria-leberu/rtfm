local files = {}
local ffi, kernel

local function windows()
    if kernel then return end
    ffi = require('ffi')
    ffi.cdef[[
        typedef struct {
            unsigned long attributes, times[6], size_high, size_low, reserved[2];
            char name[260]; char alternate[14];
        } RTFM_SOUND_FIND_DATA;
        void* __stdcall FindFirstFileA(const char*, RTFM_SOUND_FIND_DATA*);
        int __stdcall FindNextFileA(void*, RTFM_SOUND_FIND_DATA*);
        int __stdcall FindClose(void*);
    ]]
    kernel = ffi.load('kernel32')
end

function files.list(path)
    local ok, result = pcall(function()
        windows()
        local entries, data = {}, ffi.new('RTFM_SOUND_FIND_DATA[1]')
        local handle = kernel.FindFirstFileA(path:gsub('[\\/]+$', '') .. '\\*', data)
        if handle == ffi.cast('void*', -1) then error('Cannot read this folder.') end
        repeat
            local name = ffi.string(data[0].name)
            local directory = bit.band(data[0].attributes, 16) ~= 0
            if name ~= '.' and name ~= '..' and (directory or name:lower():match('%.wav$')) then
                entries[#entries + 1] = { name = name, directory = directory }
            end
        until kernel.FindNextFileA(handle, data) == 0
        kernel.FindClose(handle)
        table.sort(entries, function(a,b)
            if a.directory ~= b.directory then return a.directory end
            return a.name:lower() < b.name:lower()
        end)
        return entries
    end)
    if ok then return result end
    return nil, tostring(result)
end

function files.exists(path)
    local file = io.open(path, 'rb')
    if not file then return false end
    file:close()
    return true
end

function files.validate(path)
    if not path:lower():match('%.wav$') then return false, 'Choose a WAV file.' end
    local file = io.open(path, 'rb')
    if not file then return false, 'Cannot open the sound file.' end
    local header, size = file:read(12), file:seek('end')
    file:close()
    if not header or not size or size < 44 or header:sub(1,4) ~= 'RIFF' or header:sub(9,12) ~= 'WAVE' then
        return false, 'This file is not a RIFF/WAVE sound.'
    end
    if not size or size > 32 * 1024 * 1024 then return false, 'Sound files must be under 32 MB.' end
    return true
end

return files
