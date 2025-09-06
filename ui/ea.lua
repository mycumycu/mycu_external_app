local widgets

local mapMenu

local external = {};

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
    for key, widget in pairs(widgets) do
        local output = require(widget.path) -- this will be cached after first load
        payload[key] = output.handle()
    end

    return payload
end

init()