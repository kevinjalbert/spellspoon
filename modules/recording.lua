local M = {}
local prompt_processor = require("prompt_processor")
prompt_processor.parent = self

-- Recording state
M.isRecording = false
M.recordingTask = nil
M.recordingTimer = nil
M.startTime = nil
M.escHotkey = nil
M.isDirect = false

function M:cleanup()
    -- Stop recording task if it exists
    if self.recordingTask then
        self.recordingTask:terminate()
        self.recordingTask = nil
    end

    -- Clean up timer
    if self.recordingTimer then
        self.recordingTimer:stop()
        self.recordingTimer = nil
    end

    -- Reset recording state
    self.isRecording = false
    self.startTime = nil

    -- Clean up UI
    if self.parent and self.parent.ui then
        self.parent.ui:cleanup()
    end

    -- Clean up hotkeys
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end
end

function M:stopRecording(interrupted, direct)
    -- Clean up hotkeys (we used esc to get here)
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end

    self.logger.d("Stopping recording" .. (interrupted and " (interrupted)" or "") .. (direct and " (direct)" or ""))

    -- If there's no recording task, nothing to do
    if not self.recordingTask then
        return
    end

    if interrupted then
        -- If interrupted, terminate immediately and clean up
        self.recordingTask:terminate()
        self.recordingTask = nil
        self:cleanup()
        return
    end

    -- Update the modal to "Processing..." immediately
    if self.parent and self.parent.ui then
        self.parent.ui:setTranscribingStatus()
    end

    -- Send SIGTERM to ffmpeg to gracefully stop recording
    self.recordingTask:terminate()

    -- Wait for the recording process to fully complete
    hs.timer.waitUntil(
        -- Check condition
        function()
            -- Check both process completion and file existence
            if self.recordingTask:isRunning() then
                return false
            end
            -- Check if the output file exists and is not empty
            local file = io.open("/tmp/recorded_audio.wav", "rb")
            if not file then
                return false
            end
            -- Read a byte to ensure file is written
            local byte = file:read(1)
            file:close()
            return byte ~= nil
        end,
        -- Callback when condition is met
        function()
            self.recordingTask = nil
            self.isRecording = false

            -- Begin transcription immediately once file is ready
            self.parent.transcription:startTranscription(function(transcript, error)
                self.logger.d("Transcription callback received: " .. (transcript and "success" or "error: " .. (error or "unknown")))

                if error then
                    self.logger.e("Transcription error: " .. error)
                    -- Only clean up UI on error
                    if self.parent and self.parent.ui then
                        self.parent.ui:cleanup()
                    end
                    return
                end

                if transcript then
                    if direct then
                        -- For direct prompting, use the first available prompt
                        self.parent.menu:refreshMenuOptions()
                        if #self.parent.menu.menuChoices > 0 then
                            local firstPromptScriptPath = self.parent.menu.prompts[self.parent.menu.menuChoices[1].text]
                            if firstPromptScriptPath then
                                -- Get the prompt script path and process with transcript
                                if firstPromptScriptPath then
                                    self.logger.d("Using prompt script: " .. firstPromptScriptPath)

                                    if self.parent and self.parent.ui then
                                        self.parent.ui:cleanup()
                                    end

                                    prompt_processor:processPromptWithTranscript(firstPromptScriptPath, transcript, self.logger, self.parent and self.parent.ui, self.parent and self.parent.config)
                                else
                                    self.logger.e("Failed to get prompt script path for first prompt")
                                end
                            end
                        else
                            -- Log error if no prompts are available
                            self.logger.e("No prompts available")
                        end
                    else
                        -- Show the menu with the processed transcript
                        -- UI cleanup will happen in the menu module when menu is shown
                        self.parent.menu:showMenu(transcript)
                    end
                end
            end)
        end
    )
end

function M:startRecording(direct)
    if not self.isRecording then
        -- Start recording
        self.logger.d("Starting recording")
        local recordingScript = self.parent.config.handleRecordingScript
        self.recordingTask = hs.task.new(recordingScript, function(exitCode, stdOut, stdErr)
            -- Don't do any cleanup here, just log the error if there is one
            if exitCode ~= 0 then
                self.logger.e("Recording failed: " .. (stdErr or "unknown error"))
            end
        end)
        self.recordingTask:start()
        self.isRecording = true
        self.isDirect = direct -- Store the direct flag

        -- Show recording indicator
        self.parent.ui:createRecordingIndicator()
        self.parent.ui:setRecordingStatus()

        -- Bind 'Esc' key to stop recording without transcription
        if self.escHotkey then
            self.escHotkey:delete()
        end
        self.escHotkey = hs.hotkey.bind({}, "escape", function()
            self:stopRecording(true) -- Interrupted
        end)
    else
        -- Stop recording and process transcription
        self:stopRecording(false, self.isDirect) -- Pass through the direct flag
    end
end

return M
