return {
    ---
    --- Handle color codes
    ---
    handleFactionColors = function(value)
        -- remove color codes between #FF and #
        local text = string.gsub(value, "#[Ff][Ff].-#", "")

        return text or value
    end
}