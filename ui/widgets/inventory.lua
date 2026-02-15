local output = {
    -- Properties to exclude from hash calculation (frequently changing non-essential data)
    hashExclusions = { "currentGameTime" }
}

local function getCategory(ware)
    local iscraftingresource, ismodpart, isprimarymodpart, ispersonalupgrade, tradeonly, ispaintmod, isbraneitem =
        GetWareData(ware, "iscraftingresource", "ismodpart", "isprimarymodpart", "ispersonalupgrade", "tradeonly", "ispaintmod", "isbraneitem")

    if iscraftingresource or ismodpart or isprimarymodpart then
        return "crafting", ReadText(1001, 2827)     -- Crafting Wares
    elseif ispersonalupgrade then
        return nil, nil  -- filtered out (Spacesuit Upgrades)
    elseif tradeonly then
        return "tradeonly", ReadText(1001, 2829)    -- Trade Wares
    elseif ispaintmod then
        return "paintmod", ReadText(1001, 8510)     -- Paint Modifications
    elseif not isbraneitem then
        return "useful", ReadText(1001, 2828)       -- General Wares
    end
    return nil, nil  -- filtered out (brane items)
end

function output.handle()
    local data = {}

    -- Get police faction for illegal ware checks
    local playerZone = GetPlayerContextByClass("zone")
    local policeFaction = GetComponentData(playerZone, "policefaction")

    local rawInv = GetPlayerInventory()

    for ware, wareData in pairs(rawInv) do
        local categoryId, categoryName = getCategory(ware)
        if categoryId then
            local name = GetWareData(ware, "name")
            local isIllegal = policeFaction and IsWareIllegalTo(ware, "player", policeFaction) or false

            data[ware] = {
                name = name,
                amount = wareData.amount,
                price = wareData.price,
                illegal = isIllegal,
                category = {
                    id = categoryId,
                    name = categoryName
                }
            }
        end
    end

    return data
end

return output
