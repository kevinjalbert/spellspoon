local M = {}

-- Recording state
M.isRecording = false
M.recordingTask = nil
M.recordingTimer = nil
M.startTime = nil
M.escHotkey = nil

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

    -- Clean up escape hotkey
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end

    -- Reset recording state
    self.isRecording = false
    self.startTime = nil
end

function M:stopRecording(interrupted)
    self.logger.d("Stopping recording" .. (interrupted and " (interrupted)" or ""))

    -- Stop the recording task without cleanup
    if self.recordingTask then
        -- Just terminate the task, don't do any cleanup here
        self.recordingTask:terminate()
        self.recordingTask = nil
    end

    -- Stop the timer without cleanup
    if self.recordingTimer then
        self.recordingTimer:stop()
        self.recordingTimer = nil
    end

    if interrupted then
        -- If interrupted, clean up state and UI
        self:cleanup()
        if self.parent and self.parent.ui then
            self.parent.ui:cleanup()
        end
        return
    end

    -- Clean up recording-specific state but keep UI for processing
    self.isRecording = false
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end

    -- Update the modal to "Processing..."
    self.parent.ui:setProcessingStatus()

    -- Begin transcription and handle the result
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
            -- Show the menu with the processed transcript
            -- UI cleanup will happen in the menu module when menu is shown
            self.parent.menu:showMenu(transcript)
        end
    end)
end

function M:startRecording()
    if not self.isRecording then
        -- Start recording
        self.logger.d("Starting recording")
        local scriptPath = os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_recording.sh"
        self.recordingTask = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
            -- Don't do any cleanup here, just log the error if there is one
            if exitCode ~= 0 then
                self.logger.e("Recording failed: " .. (stdErr or "unknown error"))
            end
        end)
        self.recordingTask:start()
        self.isRecording = true

        -- Show recording indicator
        self.parent.ui:createRecordingIndicator()
        self.startTime = os.time()
        self.recordingTimer = hs.timer.doEvery(1, function() self.parent.ui:updateTimer() end)

        -- Bind 'Esc' key to stop recording without transcription
        if self.escHotkey then
            self.escHotkey:delete()
        end
        self.escHotkey = hs.hotkey.bind({}, "escape", function()
            self:stopRecording(true) -- Interrupted
        end)
    else
        -- Stop recording and process transcription
        self:stopRecording(false) -- Not interrupted
    end
end

return M
