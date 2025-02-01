local M = {}

-- Function to read and parse a prompt file
function M:readPromptFile(filename, logger)
    logger.d("Reading prompt file: " .. filename)
    local file = io.open(filename, "r")
    if not file then
        logger.w("Failed to open prompt file: " .. filename)
        return nil
    end

    local title = file:read("*line")
    local prompt = file:read("*all")
    file:close()

    if title and prompt then
        logger.d("Loaded prompt file " .. filename .. ":\nTitle: " .. title .. "\nPrompt: " .. prompt)
        return {
            title = title,
            prompt = prompt:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
        }
    end
    logger.w("Invalid prompt file format: " .. filename)
    return nil
end

return M
