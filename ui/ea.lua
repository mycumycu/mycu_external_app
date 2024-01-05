local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library
local widgets = require("extensions.mycu_external_app.ui.widgets")
local json = require("extensions.mycu_external_app.ui.dkjson")

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
    DebugError("ea.lua: getOutput BEFORE")
    external.fetchData()
    DebugError("ea.lua: getOutput AFTER")

    AddUITriggeredEvent("eventlog_ui_trigger", "data_feed", external.toJson(external.output))
end

function external.fetchData()
    for key, widget in pairs(widgets) do
        local output = require(widget.path) --this will be cached after first load
        external.output[key] = output.handle()
    end
end

function external.toJson(obj)
    obj = external.removeUnsupportedTypes(obj)

    return json.encode(obj)
end

function external.removeUnsupportedTypes (e)
    if type(e) == "cname" or type(e) == "userdata" or type(e) == "cdata" then
        -- set to nil
        e = nil
    end

    if type(e) == "table" then
        for k, v in pairs(e) do
            e[k] = external.removeUnsupportedTypes(v)
        end
    end

    return e
end

init()