local ffi = require("ffi")
local C = ffi.C

local output = {}

function output.handle()
    local data = {}

    local endtime = C.GetCurrentGameTime()
    local starttime = math.max(0, endtime - 3600) -- just last hour
    local maxEntries = 100 -- but no more than that

    -- transaction entries with data
    local container = C.GetPlayerID()
    local n = C.GetNumTransactionLog(container, starttime, endtime)
    local buf = ffi.new("TransactionLogEntry[?]", n)
    n = C.GetTransactionLog(buf, n, container, starttime, endtime)

    for i = 0, n - 1 do
        local partnername = ffi.string(buf[i].partnername)

        local entry = {
            time = buf[i].time,
            money = tonumber(buf[i].money) / 100,
            entryid = ConvertStringTo64Bit(tostring(buf[i].entryid)),
            eventtype = ffi.string(buf[i].eventtype),
            eventtypename = ffi.string(buf[i].eventtypename),
            partner = buf[i].partnerid,
            partnername = (partnername ~= "") and (partnername .. " (" .. ffi.string(buf[i].partneridcode) .. ")") or "",
            tradeentryid = ConvertStringTo64Bit(tostring(buf[i].tradeentryid)),
            tradeeventtype = ffi.string(buf[i].tradeeventtype),
            tradeeventtypename = ffi.string(buf[i].tradeeventtypename),
            buyer = buf[i].buyerid,
            seller = buf[i].sellerid,
            ware = ffi.string(buf[i].ware),
            amount = buf[i].amount,
            price = tonumber(buf[i].price) / 100,
            complete = buf[i].complete,
            description = "",
        }

        if (entry.buyer ~= 0) and (entry.seller ~= 0) then
            if entry.seller == container then
                entry.description = string.format(ReadText(1001, 7780), ffi.string(C.GetComponentName(entry.seller)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.seller)) .. ")", entry.amount, GetWareData(entry.ware, "name"), ffi.string(C.GetComponentName(entry.buyer)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.buyer)) .. ")", ConvertMoneyString(Helper.round(entry.price, 2), true, true, 0, true) .. " " .. ReadText(1001, 101))
            else
                entry.description = string.format(ReadText(1001, 7770), ffi.string(C.GetComponentName(entry.buyer)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.buyer)) .. ")", entry.amount, GetWareData(entry.ware, "name"), ffi.string(C.GetComponentName(entry.seller)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.seller)) .. ")", ConvertMoneyString(Helper.round(entry.price, 2), true, true, 0, true) .. " " .. ReadText(1001, 101))
            end
        elseif entry.buyer ~= 0 then
            entry.description = string.format(ReadText(1001, 7772), ffi.string(C.GetComponentName(entry.buyer)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.buyer)) .. ")", entry.amount, GetWareData(entry.ware, "name"), ConvertMoneyString(Helper.round(entry.price, 2), true, true, 0, true) .. " " .. ReadText(1001, 101))
        elseif entry.seller ~= 0 then
            entry.description = string.format(ReadText(1001, 7771), ffi.string(C.GetComponentName(entry.seller)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.seller)) .. ")", entry.amount, GetWareData(entry.ware, "name"), ConvertMoneyString(Helper.round(entry.price, 2), true, true, 0, true) .. " " .. ReadText(1001, 101))
        elseif entry.ware ~= "" then
            entry.description = entry.amount .. ReadText(1001, 42) .. " " .. GetWareData(entry.ware, "name") .. " - " .. ConvertMoneyString(entry.price, false, true, 0, true) .. " " .. ReadText(1001, 101)
        end
        if entry.partner ~= 0 then
            entry.partnername = ffi.string(C.GetComponentName(entry.partner)) .. " (" .. ffi.string(C.GetObjectIDCode(entry.partner)) .. ")"
            entry.destroyedpartner = not C.IsComponentOperational(entry.partner)
        else
            entry.destroyedpartner = entry.partnername ~= ""
        end
        if entry.eventtype == "trade" then
            if entry.seller and (entry.seller == container) then
                entry.eventtypename = ReadText(1001, 7781)
            elseif entry.buyer and (entry.buyer == container) then
                entry.eventtypename = ReadText(1001, 7782)
            end
        elseif entry.eventtype == "sellship" then
            if entry.partnername ~= "" then
                entry.eventtypename = ReadText(1001, 7783)
            else
                entry.eventtypename = entry.eventtypename .. ReadText(1001, 120) .. " " .. entry.partnername
                entry.partnername = ""
            end
        end

        entry.passedtime = Helper.getPassedTime(entry.time)
        table.insert(data, entry)
    end

    table.sort(data, function(a,b) return a.time > b.time end) -- reverse order, from the most recent to the oldest

    return table.move(data, 1, maxEntries, 1, {}) -- return only the first maxEntries elements
end

return output