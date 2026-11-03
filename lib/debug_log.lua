local debug_log = {}
debug_log.__index = debug_log

function debug_log.new(directory)
    return setmetatable({ directory = directory, path = directory .. 'rtfm-debug.txt' }, debug_log)
end

-- Keep two bounded files, and close each write so a client crash loses as little
-- evidence as possible. Logging failures must never stop action processing.
function debug_log:write(message)
    local ok, err = pcall(function()
        ashita.fs.create_dir(self.directory)
        local file = io.open(self.path, 'rb')
        if file then
            local size = file:seek('end')
            file:close()
            if size and size >= 5 * 1024 * 1024 then
                local previous = self.directory .. 'rtfm-debug-previous.txt'
                os.remove(previous)
                assert(os.rename(self.path, previous))
            end
        end
        local output, reason = io.open(self.path, 'ab')
        assert(output, reason)
        local clean = tostring(message):gsub('[%z\1-\31\127]', function(c)
            return string.format('\\x%02X', c:byte())
        end)
        local written, write_error = output:write(os.date('%Y-%m-%d %H:%M:%S'), ' ', clean, '\r\n')
        local closed, close_error = output:close()
        assert(written, write_error)
        assert(closed, close_error)
    end)
    if not ok and not self.warned then
        self.warned = true
        print('[RTFM] Unable to write debug log: ' .. tostring(err))
    end
    return ok
end

return debug_log
