local timing = {}

function timing.retention_minutes(value)
    if type(value) ~= 'number' or value ~= value then return 3 end
    return math.max(1, math.min(15, value))
end

function timing.elapsed(age)
    local ticks = math.floor(math.max(0, age) * 100 + 0.000001)
    local seconds, hundredths = math.floor(ticks / 100), ticks % 100
    if seconds < 120 then return string.format('%d.%02ds', seconds, hundredths) end
    return string.format('%dm %02d.%02ds', math.floor(seconds / 60), seconds % 60, hundredths)
end

return timing
