local M = {}
local prompt_reader = require("prompt_reader")

function M:processPromptWithTranscript(prompt, transcript, logger, ui)
    logger.d("Processing prompt with transcript")
    local scriptPath = hs.spoons.scriptPath() .. "../process_prompt.sh"

    -- Show prompting UI state
    if ui then
        ui:createRecordingIndicator()
        ui:setPromptingStatus()
    end

    -- Replace the placeholder in the prompt with the transcript
    local fullPrompt = prompt:gsub("{{TRANSCRIPT}}", transcript)

    -- Create a task to process the prompt
    local task = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
        -- Clean up UI after processing is complete
        if ui then
            ui:cleanup()
        end

        if exitCode == 0 and stdOut then
            -- Handle clipboard paste just like in direct mode
            self:handleClipboardPaste(stdOut)
        end
    end)
    task:setInput(fullPrompt)
    task:start()
end

function M:handleClipboardPaste(text)
    hs.pasteboard.setContents(text) -- Store processed transcription in clipboard

    -- Check if there's an active text field before attempting to paste
    local focused = hs.uielement.focusedElement()
    local shouldPaste = false

    if focused then
        local success, role = pcall(function() return focused:role() end)
        if success and role then
            shouldPaste = (role == "AXTextField" or role == "AXTextArea")
        end
    end

    if shouldPaste then
        hs.eventtap.keyStroke({"cmd"}, "v")
    else
        hs.alert.show("Transcription copied to clipboard")
    end
end

return M
