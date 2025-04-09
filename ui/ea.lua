local widgets
local helper

local mapMenu

local external = {
    output = {}
};

local request = require("djfhe.http.request")
local method = 'POST'
local apiUrl = "http://" .. host .. ":" .. port .. "/api/data"

local function init ()
    package.path = package.path .. ";extensions/mycu_external_app/ui/?.lua";
    widgets = require("widgets")
    helper = require("helper")

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
    external.fetchData()

    local payload = external.normalizeOutput(external.output)

    request.new(method)
           :setUrl(apiUrl)
           :setBody(payload)
           :send(
            function(response, err)
                if err then
                    --DebugError("Error occured while sending data to External App Server: " .. tostring(err))
                end
            end
    )
end

---
--- Fetch data from widgets
---
function external.fetchData()
    for key, widget in pairs(widgets) do
        local output = require(widget.path) -- this will be cached after first load
        external.output[key] = output.handle()
    end
end

---
--- Normalize output
---
function external.normalizeOutput(value)
    local elementType = type(value)

    if elementType == "cname" or elementType == "userdata" or elementType == "cdata" then
        value = external.removeUnsupportedType(value)
    end

    if elementType == "string" then
        value = external.handleLineBreaks(value)
        value = external.handleColorCodes(value)
        value = helper.handleFactionColors(value)
    end

    if elementType == "table" then
        for k, v in pairs(value) do
            value[k] = external.normalizeOutput(v)
        end
    end

    return value
end

---
--- Remove unsupported JSON types
---
function external.removeUnsupportedType ()

    return nil
end

---
--- Handle color codes
---
function external.handleColorCodes (value)
    value = string.gsub(value, "A", "<span class='grey'>")
    value = string.gsub(value, "B", "<span class='blue'>")
    value = string.gsub(value, "C", "<span class='cyan'>")
    value = string.gsub(value, "G", "<span class='green'>")
    value = string.gsub(value, "M", "<span class='magenta'>")
    value = string.gsub(value, "O", "<span class='unknown'>")
    value = string.gsub(value, "R", "<span class='red'>")
    value = string.gsub(value, "U", "<span class='pale-blue'>")
    value = string.gsub(value, "W", "<span class='white'>")
    value = string.gsub(value, "Y", "<span class='yellow'>")
    value = string.gsub(value, "Z", "<span class='pale-grey'>")
    value = string.gsub(value, "X", "</span>")
    value = string.gsub(value, "", "")

    return value
end

---
--- Handle line breaks
---
function external.handleLineBreaks(value)

    return string.gsub(value, "\r?\n", "<br />")
end

init()