local ffi = require("ffi")
local C = ffi.C
local Lib = require("extensions.sn_mod_support_apis.lua_interface").Library
local widgets = require("extensions.mycu_external_app.ui.widgets")
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
    external.loadWidgets()

    AddUITriggeredEvent("eventlog_ui_trigger", "data_feed", external.formatOutput(external.output))
end

function external.loadWidgets()
    for key, widget in pairs(widgets) do
        local output = require(widget.path) --this will be cached after first load
        external.output[key] = output.handle()
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
        obj = string.format("%q", obj)
        buffer[#buffer + 1] = obj
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

init()