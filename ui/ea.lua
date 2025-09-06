local widgets

local mapMenu

local external = {
    maxGroup = 3, -- Maximum number of groups.
    cycleCounter = 0 -- Counter for cycle through groups.
};

local request = require("djfhe.http.request")
local method = 'POST'
local apiUrl = "http://" .. host .. ":" .. port .. "/api/data"

local function init ()
    package.path = package.path .. ";extensions/mycu_external_app/ui/?.lua";
    widgets = require("widgets")

    mapMenu = Helper.getMenu("MapMenu")

    -- Main event
    RegisterEvent("externalapp.getMessages", external.send)

    -- Reputations and Professions mod event triggered after all available guild missions offers are created AFTER the player clicks on the "Connect to the Guild Network" button
    RegisterEvent("kProfs.guildNetwork_onLoaded", external.send)
end

---
--- Send data to external app server
---
function external.send (_, param)
    local payload = external.fetchData()

    request.new(method)
           :setUrl(apiUrl)
           :setBody(payload)
           :send(
            function(response, err)
                if err then
                    DebugError("Error occured while sending data to External App Server: " .. tostring(err))
                end
            end
    )
end

---
--- Fetch data from widgets
---
function external.fetchData()
    local payload = {}
    external.cycleCounter = external.cycleCounter + 1

    -- Determine which group to process (1,2,3 and then repeat)
    local widgetGroupToProcess = external.cycleCounter % external.maxGroup + 1

    for key, widget in pairs(widgets) do
        for _, group in ipairs(widget.groups) do
            -- Process only the widgets that belong to the current group
            if group == widgetGroupToProcess then
                local output = require(widget.path) -- this will be cached after first load
                payload[key] = output.handle()
                break
            end
        end
    end

    return external.removeUnsupportedTypes(payload)
end

---
--- Remove unsupported types
---
function external.removeUnsupportedTypes(value)
    local elementType = type(value)

    if elementType == "cname" or elementType == "userdata" or elementType == "cdata" then
        value = nil
    end

    if elementType == "table" then
        for k, v in pairs(value) do
            value[k] = external.removeUnsupportedTypes(v)
        end
    end

    return value
end

init()