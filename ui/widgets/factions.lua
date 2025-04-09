local ffi = require("ffi")
local C = ffi.C
local helper = require("helper")

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
        return { r = 255, g = 255, b = 255, a = 100 } -- color white
    end
end

---
--- Sort factions by shortname
---
local function sortShortname(a, b)
    local aShortname = helper.handleFactionColors(a.shortname)
    local bShortname = helper.handleFactionColors(b.shortname)

    return aShortname < bShortname
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