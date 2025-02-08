local M = {}

local Logger = require("logger")
local Config = require("config")
local UI = require("ui")

function M:processPromptWithTranscript(promptScript, transcript)
    Logger.log("debug", "Starting prompt processing")
    Logger.log("debug", "Transcript content:", transcript)
    Logger.log("debug", "Using prompt script:", promptScript)

    -- Show prompting UI state
    Logger.log("debug", "Creating UI elements")
    UI:createRecordingIndicator()
    UI:setPromptingStatus()

    -- First execute the prompt script to get the full prompt
    Logger.log("debug", "Executing prompt script")
    local promptHandle = io.popen("echo '" .. transcript:gsub("'", "'\\''") .. "' | " .. promptScript .. " 2>/dev/null")
    if not promptHandle then
        Logger.log("warn", "Failed to execute prompt script: " .. promptScript)
        UI:cleanup()
        return
    end

    local fullPrompt = promptHandle:read("*a")
    promptHandle:close()
    Logger.log("debug", "Generated prompt:", fullPrompt)

    if not fullPrompt then
        Logger.log("warn", "Failed to get prompt from script: " .. promptScript)
        UI:cleanup()
        return
    end

    -- Create a task to process the prompt
    local handlePromptingScript = Config.handlePromptingScript
    Logger.log("debug", "Handle prompting script:", handlePromptingScript)
    Logger.log("debug", "Creating processing task")
    local task = hs.task.new(handlePromptingScript, function(exitCode, stdOut, stdErr)
        -- Clean up UI after processing is complete
        Logger.log("debug", "Cleaning up UI")
        UI:cleanup()

        if exitCode == 0 and stdOut then
            Logger.log("debug", "Processing successful. Output:", stdOut)
            -- Handle clipboard paste just like in direct mode
            self:handleClipboardPaste(stdOut)
        else
            Logger.log("warn", "Processing failed with exit code:", exitCode)
            if stdErr then
                Logger.log("warn", "Error output:", stdErr)
            end
        end
    end)
    task:setInput(fullPrompt)
    task:start()
end

function M:handleClipboardPaste(text)
    if logger then
        Logger.log("debug", "Handling clipboard paste with text:", text)
    end

    -- Store processed transcription in clipboard
    hs.pasteboard.setContents(text)
    if logger then
        Logger.log("debug", "Text copied to clipboard")
    end

    -- Check if there's an active text field before attempting to paste
    local focused = hs.uielement.focusedElement()
    local shouldPaste = false

    if focused then
        if logger then
            Logger.log("debug", "Found focused element")
        end
        local success, role = pcall(function() return focused:role() end)
        if success and role then
            if logger then
                Logger.log("debug", "Element role:", role)
            end
            shouldPaste = (role == "AXTextField" or role == "AXTextArea")
            if logger then
                Logger.log("debug", "Should paste:", shouldPaste)
            end
        else
            if logger then
                Logger.log("debug", "Could not determine element role")
            end
        end
    else
        if logger then
            Logger.log("debug", "No focused element found")
        end
    end

    if shouldPaste then
        if logger then
            Logger.log("debug", "Executing paste command")
        end
        hs.eventtap.keyStroke({"cmd"}, "v")
    else
        if logger then
            Logger.log("debug", "Showing clipboard notification")
        end
        hs.alert.show("Transcription copied to clipboard")
    end
end

return M
