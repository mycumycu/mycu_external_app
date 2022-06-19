local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library

local output = {}

function output.handle()
    local data = {}
    local mapMenu = Lib.Get_Egosoft_Menu("MapMenu")
    local missionBriefingMenu = Lib.Get_Egosoft_Menu("MissionBriefingMenu")

    local numMissions = GetNumMissions()

    for i = 1, numMissions do
        local entry = mapMenu.getMissionInfoHelper(i)

        if entry.active then
            local missionDetails = missionBriefingMenu.getMissionIDInfoHelper(ConvertIDTo64Bit(entry.ID))
            table.insert(data, missionDetails)
            break
        end
    end

    return data
end

return output