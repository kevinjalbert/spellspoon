local M = {}

local Logger = require("logger")
local Config = require("config")

-- Function to read prompt title from a script file
-- The expectations of these prompt scripts are:
-- 1. The first line is a shebang line
-- 2. The second line is a comment line with the prompt title
-- 3. The input is the transcript to be processed (as stdin)
-- 4. The output is the full prompt to be used (as stdout)
function M:readPromptFile(filename)
    Logger.log("debug", "Reading prompt file: " .. filename)
    local file = io.open(filename, "r")
    if not file then
        Logger.log("warn", "Failed to open prompt file: " .. filename)
        return nil
    end

    -- Read first two lines
    local shebang = file:read("*line")
    local titleLine = file:read("*line")
    file:close()

    -- Verify it's a shell script and has a title
    if not shebang:match("^#!") or not titleLine or not titleLine:match("^#%s*(.+)") then
        Logger.log("warn", "Invalid prompt file format: " .. filename)
        return nil
    end

    -- Extract title (remove leading # and whitespace)
    local title = titleLine:match("^#%s*(.+)")

    if title then
        Logger.log("debug", "Loaded prompt file " .. filename .. ":\nTitle: " .. title)
        return {
            title = title,
            path = filename  -- Return the path instead of the prompt content
        }
    else
        Logger.log("warn", "Failed to get title from: " .. filename)
        return nil
    end
end

return M
