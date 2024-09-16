return {
    ---
    --- Handle color codes
    ---
    handleFactionColors = function(value)
        -- remove color codes between #FF and #
        local text = string.match(value, "#[fF][fF][%x]+#(.+)")

        return text or value
    end

}