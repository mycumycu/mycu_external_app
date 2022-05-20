local ffi = require("ffi")
local C = ffi.C

local output = {}

function output.handle()
    local data = {}
    local maxEntries = 100
    local logbookCategory = "all"
    local logbookNumEntries = GetNumLogbook(logbookCategory)
    local numQuery = math.min(maxEntries, logbookNumEntries)

    local startIndex = math.max(1, logbookNumEntries - maxEntries + 1)
    local logbook = GetLogbook(startIndex, numQuery, logbookCategory) or {}

    for i = #logbook, 1, -1 do
        local entry = logbook[i]
        entry.passedtime = Helper.getPassedTime(entry.time)
        table.insert(data, entry)
    end

    return data
end

return output