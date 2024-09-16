local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library
local widgets = require("extensions.mycu_external_app.ui.widgets")
local json = require("extensions.mycu_external_app.ui.dkjson")
local helper = require("extensions.mycu_external_app.ui.helper")

local mapMenu

local external = {
    output = {}
};

local function init ()
    DebugError("ea.lua: INIT")

    -- Main event
    RegisterEvent("externalapp.getMessages", external.getOutput)

    -- Reputations and Professions mod event triggered after all available guild missions offers are created AFTER the player clicks on the "Connect to the Guild Network" button
    RegisterEvent("kProfs.guildNetwork_onLoaded", external.getOutput)

    mapMenu = Lib.Get_Egosoft_Menu("MapMenu")
end

function external.getOutput (_, param)
    external.fetchData()

    AddUITriggeredEvent("eventlog_ui_trigger", "data_feed", external.toJson(external.output))
end

function external.fetchData()
    for key, widget in pairs(widgets) do
        local output = require(widget.path) -- this will be cached after first load
        external.output[key] = output.handle()
    end
end

---
--- Convert output to JSON
---
function external.toJson(obj)
    return json.encode(
            external.normalizeOutput(obj)
    )
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