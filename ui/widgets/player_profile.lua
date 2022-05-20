local ffi = require("ffi")
local C = ffi.C

local output = {}

function output.handle()
    local playersector = C.GetContextByClass(C.GetPlayerID(), "sector", false)
    local data = {}

    data.name = ffi.string(C.GetPlayerName())
    data.factionname = ffi.string(C.GetPlayerFactionName(true))
    data.credits = GetPlayerMoney()
    data.playersector = ffi.string(C.GetComponentName(playersector))

    return data;
end

return output