local Logger = {}

Logger.log_level = "debug"  -- Default log level

function Logger.log(level, message, obj)
    local levels = { debug = 1, info = 2, warn = 3, error = 4 }

    -- Ensure both level and Logger.log_level are valid
    if not levels[level] then level = "error" end
    if not levels[Logger.log_level] then Logger.log_level = "debug" end

    if levels[level] >= levels[Logger.log_level] then
        if obj then
            print(string.format("[%s] %s", level:upper(), message), obj)
        else
            print(string.format("[%s] %s", level:upper(), message))
        end
    end
end

return Logger
