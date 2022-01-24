local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library

local mapMenu
local external = {
    output = {
        player = {},
        activeMissions = {},
        missionoffers = {},
        logbook = {},
    }
};

local function init ()
    -- DebugError("ea.lua: INIT")
    RegisterEvent("externalapp.getMessages", external.getOutput)
    mapMenu = Lib.Get_Egosoft_Menu("MapMenu")
end

function external.getOutput (_, param)
    -- DebugError("ea.lua: getMessages()")
    external.output.logbook = {}

    external.getPlayerName()
    external.getPlayerFaction()
    external.getPlayerCredits()
    external.getPlayerSector()
    external.getActiveMissions()
    external.getLogbook()
    external.getMissionOfferList()

    AddUITriggeredEvent("eventlog_ui_trigger", "data_feed", external.formatOutput(external.output))
end


function external.getPlayerName()
    external.output.player.name = ffi.string(C.GetPlayerName());
end

function external.getPlayerFaction()
    external.output.player.factionname = ffi.string(C.GetPlayerFactionName(true));
end

function external.getPlayerCredits()
    external.output.player.credits = GetPlayerMoney();
end

function external.getPlayerSector()
    local playersector = C.GetContextByClass(C.GetPlayerID(), "sector", false)
    external.output.player.playersector = ffi.string(C.GetComponentName(playersector))
end

function external.getLogbook()

    local maxEntries = 100
    local logbookCategory = "all"
    local logbookNumEntries = GetNumLogbook(logbookCategory)
    local numQuery = math.min(maxEntries, logbookNumEntries)

    local startIndex = logbookNumEntries - maxEntries + 1
    local logbook = GetLogbook(startIndex, numQuery, logbookCategory) or {}

    for i = #logbook, 1, -1 do
        local entry = logbook[i]
        entry.passedtime = Helper.getPassedTime(entry.time)

        -- local textcolor = entry.highlighted and Helper.color.red or Helper.standardColor
        -- DebugError("ea.lua: title " .. tostring(entry.title))

        table.insert(external.output.logbook, entry)
    end
end

function external.getActiveMissions()
    external.output.activeMissions = {}

    local numMissions = GetNumMissions()
    for i = 1, numMissions do
        local entry = mapMenu.getMissionInfoHelper(i)
        if entry.active then
            table.insert(external.output.activeMissions, entry)
        end
    end
end

function external.formatAsJSON(obj, buffer)
    local _type = type(obj)
    if _type == "table" then
        buffer[#buffer + 1] = '{"'
        if next(obj) ~= nil then
            for key, value in next, obj, nil do
                buffer[#buffer + 1] = tostring(key) .. '":'
                external.formatAsJSON(value, buffer)
                buffer[#buffer + 1] = ',"'
            end
            buffer[#buffer] = '}'
        else
            buffer[#buffer] = '""'
        end

    elseif _type == "string" then
        obj = string.gsub(obj, "\r?\n", "<br />")
        obj = string.gsub(obj, "A", "<span class='grey'>")
        obj = string.gsub(obj, "B", "<span class='blue'>")
        obj = string.gsub(obj, "C", "<span class='cyan'>")
        obj = string.gsub(obj, "G", "<span class='green'>")
        obj = string.gsub(obj, "M", "<span class='magenta'>")
        obj = string.gsub(obj, "O", "<span class='unknown'>")
        obj = string.gsub(obj, "R", "<span class='red'>")
        obj = string.gsub(obj, "U", "<span class='pale-blue'>")
        obj = string.gsub(obj, "W", "<span class='white'>")
        obj = string.gsub(obj, "Y", "<span class='yellow'>")
        obj = string.gsub(obj, "Z", "<span class='pale-grey'>")
        obj = string.gsub(obj, "X", "</span>")
        obj = string.gsub(obj, "", "")
        buffer[#buffer + 1] = '"' .. obj .. '"'
    elseif _type == "boolean" or _type == "number" then
        buffer[#buffer + 1] = tostring(obj)
    else
        buffer[#buffer + 1] = '"???' .. _type .. '???"'
    end
end

function external.formatOutput(obj)
    if obj == nil then
        return "null"
    else
        local buffer = {}
        external.formatAsJSON(obj, buffer)
        return table.concat(buffer)
    end
end

function external.getMissionOfferList()

    local missionOfferCategories = {
        { category = "plot", },
        { category = "guild", },
        { category = "coalition", },
        { category = "other", },
    }

    local totalMissionOfferList = {}
    for _, entry in ipairs(missionOfferCategories) do
        totalMissionOfferList[entry.category] = {}
    end

    local missionOfferList, missionOfferIDs = {}, {}
    Helper.ffiVLA(missionOfferList, "uint64_t", C.GetNumCurrentMissionOffers, C.GetCurrentMissionOffers, true)
    for i, id in ipairs(missionOfferList) do
        missionOfferIDs[tostring(id)] = i
    end

    for _, entry in ipairs(missionOfferCategories) do
        if entry.category == "guild" then
            for i, data in ipairs(totalMissionOfferList[entry.category]) do
                for j = #data.missions, 1, -1 do
                    if missionOfferIDs[data.missions[j].ID] then
                        missionOfferIDs[totalMissionOfferList[entry.category][i].missions[j].ID] = nil
                    else
                        if not totalMissionOfferList[entry.category][i].missions[j].accepted then
                            totalMissionOfferList[entry.category][i].missions[j].expired = true
                        end
                    end
                end
            end
        else
            for i = #totalMissionOfferList[entry.category], 1, -1 do
                if missionOfferIDs[totalMissionOfferList[entry.category][i].ID] then
                    missionOfferIDs[totalMissionOfferList[entry.category][i].ID] = nil
                else
                    if not totalMissionOfferList[entry.category][i].accepted then
                        totalMissionOfferList[entry.category][i].expired = true
                    end
                end
            end
        end
    end

    for id in pairs(missionOfferIDs) do
        local name, description, difficulty, threadtype, maintype, subtype, subtypename, faction, reward, rewardtext, briefingobjectives, activebriefingstep, briefingmissions, oppfaction, licence, missiontime, duration, _, _, _, _, actor = GetMissionOfferDetails(ConvertStringToLuaID(id))
        local missionGroup = C.GetMissionGroupDetails(ConvertStringTo64Bit(id))
        local groupID, groupName = ffi.string(missionGroup.id), ffi.string(missionGroup.name)
        local onlineinfo = C.GetMissionOnlineInfo(ConvertStringTo64Bit(id))
        local onlinechapter, onlineid = ffi.string(onlineinfo.chapter), ffi.string(onlineinfo.onlineid)

        if maintype ~= "tutorial" then
            local entry = {
                ["name"] = name,
                ["description"] = description,
                ["difficulty"] = difficulty,
                ["missionGroup"] = { id = groupID, name = groupName },
                ["threadtype"] = threadtype,
                ["type"] = subtype,
                ["faction"] = faction or "",
                ["oppfaction"] = oppfaction or "",
                ["licence"] = licence,
                ["reward"] = reward,
                ["rewardtext"] = rewardtext,
                ["briefingobjectives"] = briefingobjectives,
                ["activebriefingstep"] = activebriefingstep,
                ["duration"] = duration,
                ["missiontime"] = missiontime,
                ["ID"] = id,
                ["actor"] = actor,
                ["onlinechapter"] = onlinechapter,
                ["onlineID"] = onlineid,
                ["subMissions"] = {},
            }

            if entry.missionGroup.id ~= "" then
                local index = 0
                for i, data in ipairs(totalMissionOfferList["guild"]) do
                    if data.id == entry.missionGroup.id then
                        index = i
                        break
                    end
                end
                if index ~= 0 then
                    table.insert(totalMissionOfferList["guild"][index].missions, entry)
                else
                    table.insert(totalMissionOfferList["guild"], { id = entry.missionGroup.id, name = entry.missionGroup.name, missions = { entry } })
                end
            else
                if maintype == "plot" then
                    table.insert(totalMissionOfferList["plot"], entry or 0)
                elseif onlinechapter ~= "" then
                    table.insert(totalMissionOfferList["coalition"], entry)
                else
                    table.insert(totalMissionOfferList["other"], entry)
                end
            end
        end
    end

    table.sort(totalMissionOfferList["guild"], Helper.sortName)
    for _, entry in ipairs(totalMissionOfferList["guild"]) do
        table.sort(entry.missions, external.missionOfferSorter)
    end
    table.sort(totalMissionOfferList["plot"], external.missionOfferSorter)
    table.sort(totalMissionOfferList["coalition"], external.missionOfferSorter)
    table.sort(totalMissionOfferList["other"], external.missionOfferSorter)

    external.output.missionOffers = totalMissionOfferList
end

function external.missionOfferSorter(a, b)
    if a.name == b.name then
        return a.ID > b.ID
    end
    return a.name < b.name
end

init()