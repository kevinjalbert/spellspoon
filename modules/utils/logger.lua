local Logger = {}

local Config = require("utils.config")

function Logger.log(level, message, obj)
    local levels = { debug = 1, info = 2, warn = 3, error = 4 }

    if not levels[level] then level = "debug" end

    if levels[level] >= levels[Config.logLevel] then
        if obj then
            print(string.format("[%s] %s", level:upper(), message), obj)
        else
            print(string.format("[%s] %s", level:upper(), message))
        end
    end
end

return Logger
