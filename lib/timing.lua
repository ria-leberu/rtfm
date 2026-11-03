local timing = {}

function timing.banner_extra(value)
    if type(value) ~= 'number' or value ~= value then return 5 end
    return math.max(0, math.min(30, value))
end

function timing.retention_minutes(value)
    if type(value) ~= 'number' or value ~= value then return 3 end
    return math.max(1, math.min(15, value))
end

function timing.elapsed(age)
    local ticks = math.floor(math.max(0, age) * 10 + 0.000001)
    local seconds, tenths = math.floor(ticks / 10), ticks % 10
    return string.format('%02d:%02d.%d', math.floor(seconds / 60), seconds % 60, tenths)
end

return timing
