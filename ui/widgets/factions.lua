local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library

local output = {}

---
--- Get the relation color table
--- Format: { r = 0, g = 0, b = 0, a = 0 }
---
local function relationColor(faction)
    local holomapcolor = Helper.getHoloMapColors()

    if GetFactionData(faction, "ishostile") then
        return holomapcolor.hostilecolor
    elseif GetFactionData(faction, "isenemy") then
        return holomapcolor.enemycolor
    else
        return Helper.color.white
    end
end

---
--- Sort factions by shortname
---
local function sortShortname(a, b)
    return a.shortname < b.shortname
end

---
---
---
function output.handle()
    local factions = GetLibrary("factions")

    for i, faction in ipairs(factions) do
        faction.shortname = GetFactionData(faction.id, "shortname")
        faction.color = relationColor(faction.id)
        faction.icon = nil
        faction.hasMilitaryLicence = HasLicence("player", "militaryship", faction.id)
        faction.hasCapitalLicence = HasLicence("player", "capitalship", faction.id)
        faction.currentGameTime = C.GetCurrentGameTime()
    end

    table.sort(factions, sortShortname)

    return factions
end

return output