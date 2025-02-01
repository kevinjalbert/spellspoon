local M = {}

function M:processPromptWithTranscript(scriptPath, transcript, logger, ui)
    logger.d("Starting prompt processing")
    logger.d("Transcript content:", transcript)
    logger.d("Using script:", scriptPath)

    local processPromptPath = hs.spoons.scriptPath() .. "../process_prompt.sh"
    logger.d("Process prompt path:", processPromptPath)

    -- Show prompting UI state
    if ui then
        logger.d("Creating UI elements")
        ui:createRecordingIndicator()
        ui:setPromptingStatus()
    end

    -- First execute the prompt script to get the full prompt
    logger.d("Executing prompt script")
    local promptHandle = io.popen("echo '" .. transcript:gsub("'", "'\\''") .. "' | " .. scriptPath .. " 2>/dev/null")
    if not promptHandle then
        logger.w("Failed to execute prompt script: " .. scriptPath)
        if ui then ui:cleanup() end
        return
    end

    local fullPrompt = promptHandle:read("*a")
    promptHandle:close()
    logger.d("Generated prompt:", fullPrompt)

    if not fullPrompt then
        logger.w("Failed to get prompt from script: " .. scriptPath)
        if ui then ui:cleanup() end
        return
    end

    -- Create a task to process the prompt
    logger.d("Creating processing task")
    local task = hs.task.new(processPromptPath, function(exitCode, stdOut, stdErr)
        -- Clean up UI after processing is complete
        if ui then
            logger.d("Cleaning up UI")
            ui:cleanup()
        end

        if exitCode == 0 and stdOut then
            logger.d("Processing successful. Output:", stdOut)
            -- Handle clipboard paste just like in direct mode
            self:handleClipboardPaste(stdOut, logger)
        else
            logger.w("Processing failed with exit code:", exitCode)
            if stdErr then
                logger.w("Error output:", stdErr)
            end
        end
    end)
    task:setInput(fullPrompt)
    task:start()
end

function M:handleClipboardPaste(text, logger)
    if logger then
        logger.d("Handling clipboard paste with text:", text)
    end

    -- Store processed transcription in clipboard
    hs.pasteboard.setContents(text)
    if logger then
        logger.d("Text copied to clipboard")
    end

    -- Check if there's an active text field before attempting to paste
    local focused = hs.uielement.focusedElement()
    local shouldPaste = false

    if focused then
        if logger then
            logger.d("Found focused element")
        end
        local success, role = pcall(function() return focused:role() end)
        if success and role then
            if logger then
                logger.d("Element role:", role)
            end
            shouldPaste = (role == "AXTextField" or role == "AXTextArea")
            if logger then
                logger.d("Should paste:", shouldPaste)
            end
        else
            if logger then
                logger.d("Could not determine element role")
            end
        end
    else
        if logger then
            logger.d("No focused element found")
        end
    end

    if shouldPaste then
        if logger then
            logger.d("Executing paste command")
        end
        hs.eventtap.keyStroke({"cmd"}, "v")
    else
        if logger then
            logger.d("Showing clipboard notification")
        end
        hs.alert.show("Transcription copied to clipboard")
    end
end

return M
