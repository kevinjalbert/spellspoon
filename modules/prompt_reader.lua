local M = {}

-- Function to read prompt title from a script file
function M:readPromptFile(filename, logger)
    logger.d("Reading prompt file: " .. filename)
    local file = io.open(filename, "r")
    if not file then
        logger.w("Failed to open prompt file: " .. filename)
        return nil
    end

    -- Read first two lines
    local shebang = file:read("*line")
    local titleLine = file:read("*line")
    file:close()

    -- Verify it's a shell script and has a title
    if not shebang:match("^#!") or not titleLine or not titleLine:match("^#%s*(.+)") then
        logger.w("Invalid prompt file format: " .. filename)
        return nil
    end

    -- Extract title (remove leading # and whitespace)
    local title = titleLine:match("^#%s*(.+)")

    if title then
        logger.d("Loaded prompt file " .. filename .. ":\nTitle: " .. title)
        return {
            title = title,
            path = filename  -- Return the path instead of the prompt content
        }
    end
    logger.w("Failed to get title from: " .. filename)
    return nil
end

return M
