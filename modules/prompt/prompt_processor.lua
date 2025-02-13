local M = {}

local Logger = require("utils.logger")
local Config = require("utils.config")
local Indicator = require("ui.indicator")

function M:processPromptWithTranscript(promptScript, transcript)
    Logger.log("debug", "Starting prompt processing")
    Logger.log("debug", "Transcript content:", transcript)
    Logger.log("debug", "Using prompt script:", promptScript)

    -- Show prompting UI state
    Logger.log("debug", "Creating UI elements")
    Indicator:createIndicator()
    Indicator:setPromptingStatus()

    -- First execute the prompt script to get the full prompt
    Logger.log("debug", "Executing prompt script")
    local promptHandle = io.popen("echo '" .. transcript:gsub("'", "'\\''") .. "' | " .. promptScript .. " 2>/dev/null")
    if not promptHandle then
        Logger.log("warn", "Failed to execute prompt script: " .. promptScript)
        Indicator:cleanup()
        return
    end

    local fullPrompt = promptHandle:read("*a")
    promptHandle:close()
    Logger.log("debug", "Generated prompt:", fullPrompt)

    if not fullPrompt then
        Logger.log("warn", "Failed to get prompt from script: " .. promptScript)
        Indicator:cleanup()
        return
    end

    -- Create a task to process the prompt
    local promptingScript = Config.promptingScript
    Logger.log("debug", "Handle prompting script:", promptingScript)
    Logger.log("debug", "Creating processing task")
    local task = hs.task.new(promptingScript, function(exitCode, stdOut, stdErr)
        -- Clean up UI after processing is complete
        Indicator:cleanup()

        if exitCode == 0 and stdOut then
            Logger.log("debug", "Processing successful. Output:", stdOut)
            self:handleClipboardPaste(stdOut)
        else
            Logger.log("warn", "Processing failed with exit code:", exitCode)
            Logger.log("warn", "Error output:", stdErr)
        end
    end)

    task:setInput(fullPrompt)
    task:start()
end

function M:handleClipboardPaste(text)
    Logger.log("debug", "Handling clipboard paste with text:", text)

    -- Store processed transcription in clipboard
    hs.pasteboard.setContents(text)

    -- Check if there's an active text field before attempting to paste
    local focused = hs.uielement.focusedElement()
    local shouldPaste = false

    if focused then
        Logger.log("debug", "Found focused element")
        local success, role = pcall(function() return focused:role() end)
        if success and role then
            Logger.log("debug", "Element role:", role)
            shouldPaste = (role == "AXTextField" or role == "AXTextArea")
            Logger.log("debug", "Should paste:", shouldPaste)
        else
            Logger.log("debug", "Could not determine element role")
        end
    else
        Logger.log("debug", "No focused element found")
    end

    if shouldPaste then
        Logger.log("debug", "Executing paste command")
        hs.eventtap.keyStroke({"cmd"}, "v")
    else
        Logger.log("debug", "Showing clipboard notification")
        hs.alert.show("Transcription copied to clipboard")
    end
end

return M
