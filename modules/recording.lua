local M = {}

-- Recording state
M.isRecording = false
M.recordingTask = nil
M.recordingTimer = nil
M.startTime = nil
M.escHotkey = nil

function M:stopRecording(interrupted)
    self.logger.d("Stopping recording" .. (interrupted and " (interrupted)" or ""))

    -- Stop the recording task
    if self.recordingTask then
        self.recordingTask:terminate()
        self.recordingTask = nil
    end

    -- Clean up timer
    if self.recordingTimer then
        self.recordingTimer:stop()
        self.recordingTimer = nil
    end

    if interrupted then
        -- If interrupted, clean up the modal
        if self.parent.ui.recordingIndicator then
            self.parent.ui.recordingIndicator:delete()
            self.parent.ui.recordingIndicator = nil
        end
        self.isRecording = false
        return
    end

    -- Update the modal to "Processing..."
    self.parent.ui:setProcessingStatus()

    -- Begin transcription after a short delay
    self.parent.transcription:startTranscription()

    self.isRecording = false
end

function M:startRecording()
    if not self.isRecording then
        -- Start recording
        self.logger.d("Starting recording")
        self.recordingTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, {
            "-y", "-f", "avfoundation", "-i", ":4", "-ar", "16000", "-ac", "1", "/tmp/recorded_audio.wav"
        })
        self.recordingTask:start()
        self.isRecording = true

        -- Show recording indicator
        self.parent.ui:createRecordingIndicator()
        self.startTime = os.time()
        self.recordingTimer = hs.timer.doEvery(1, function() self.parent.ui:updateTimer() end)

        -- Bind 'Esc' key to stop recording without transcription
        self.escHotkey = hs.hotkey.bind({}, "escape", function()
            self:stopRecording(true) -- Interrupted
            if self.escHotkey then
                self.escHotkey:delete() -- Unbind the Esc key
                self.escHotkey = nil
            end
        end)
    else
        -- Stop recording and process transcription
        self:stopRecording(false) -- Not interrupted
        if self.escHotkey then
            self.escHotkey:delete() -- Unbind the Esc key
            self.escHotkey = nil
        end
    end
end

return M
