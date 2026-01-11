-- Inventory widget reporter

local ffi = require("ffi")
local C = ffi.C

ffi.cdef[[
    typedef uint64_t UniverseID;
    UniverseID GetPlayerZoneID(void);
]]

local output = {
    -- Properties to exclude from hash calculation (frequently changing non-essential data)
    hashExclusions = { "currentGameTime" }
}

local function normalize_inventory(raw)
    local out = {}
    if not raw or type(raw) ~= "table" then return out end

    local isArray = false
    for k, _ in pairs(raw) do
        if type(k) == "number" then isArray = true; break end
    end

    if isArray then
        for _, entry in ipairs(raw) do
            if type(entry) == "table" then
                local id = entry.id or entry.ware or entry[1]
                local count = entry.count or entry.amount or entry[2] or 0
                if id then table.insert(out, { id = tostring(id), count = tonumber(count) or 0 }) end
            end
        end
    else
        for k, v in pairs(raw) do
            if type(k) == "string" then
                table.insert(out, { id = tostring(k), count = tonumber(v) or 0 })
            end
        end
    end

    return out
end

function output.handle()
    local data = {}

    -- Get police faction for illegal ware checks
    local playerZoneID = C.GetPlayerZoneID()
    local policeFaction = GetComponentData(ConvertStringTo64Bit(tostring(playerZoneID)), "policefaction")

    local rawInv = GetPlayerInventory()
    local inventory = {}

    for ware, wareData in pairs(rawInv) do
        local name = GetWareData(ware, "name")
        local isIllegal = false
        if policeFaction then
            isIllegal = IsWareIllegalTo(ware, "player", policeFaction)
        end

        inventory[ware] = {
            name = name,
            amount = wareData.amount,
            price = wareData.price,
            illegal = isIllegal
        }
    end

    data.inventory = inventory
    data.policeFaction = policeFaction

    return data
end

return output
