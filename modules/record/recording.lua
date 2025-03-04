local M = {}

local Logger = require("utils.logger")
local Config = require("utils.config")
local Indicator = require("ui.indicator")
local Transcription = require("transcribe.transcription")
local Menu = require("menu.menu")
local PromptProcessor = require("prompt.prompt_processor")

-- Recording modes
M.RecordingMode = {
    WITH_PROMPT = "with_prompt",          -- Show prompt selection menu
    DEFAULT_PROMPT = "default_prompt",    -- Use first available prompt
    NO_PROMPT = "no_prompt"               -- Direct to clipboard/paste
}

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

    -- Reset recording state
    self.isRecording = false
    self.startTime = nil

    -- Clean up recording indicator
    Indicator:cleanup()

    -- Clean up hotkeys
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end
end

function M:stopRecording(interrupted, mode)
    -- Clean up hotkeys (we used esc to get here)
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end

    Logger.log("debug", "Stopping recording" ..
        (interrupted and " (interrupted)" or "") ..
        (mode and " mode: " .. mode or ""))

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
    Indicator:setTranscribingStatus()

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
            Transcription:startTranscription(function(transcript, error)
                Logger.log("debug", "Transcription callback received: " .. (transcript and "success" or "error: " .. (error or "unknown")))

                if error then
                    Logger.log("error", "Transcription error: " .. error)
                    -- Only clean up UI on error
                    Indicator:cleanup()
                    return
                end

                if transcript then
                    if mode == self.RecordingMode.NO_PROMPT then
                        -- For no-prompt mode, just copy to clipboard and paste
                        Indicator:cleanup()
                        PromptProcessor:handleClipboardPaste(transcript)
                    elseif mode == self.RecordingMode.DEFAULT_PROMPT then
                        -- For default prompt, use the first available prompt
                        Menu:refreshMenuOptions()
                        if #Menu.menuChoices > 0 then
                            local firstPromptScriptPath = Menu.prompts[Menu.menuChoices[1].text]
                            if firstPromptScriptPath then
                                Logger.log("debug", "Using prompt script: " .. firstPromptScriptPath)
                                Indicator:cleanup()
                                PromptProcessor:processPromptWithTranscript(firstPromptScriptPath, transcript)
                            else
                                Logger.log("error", "Failed to get prompt script path for first prompt")
                            end
                        else
                            Logger.log("error", "No prompts available")
                        end
                    else
                        -- Show the menu with the processed transcript
                        Menu:showMenu(transcript)
                    end
                end
            end)
        end
    )
end

function M:startRecording(mode)
    mode = mode or self.RecordingMode.WITH_PROMPT

    if not self.isRecording then
        -- Start recording
        Logger.log("debug", "Starting recording")
        local recordingScript = Config.recordingScript
        Logger.log("debug", "Running recording script: " .. recordingScript)
        self.recordingTask = hs.task.new(recordingScript, function(exitCode, stdOut, stdErr)
            -- Don't do any cleanup here, just log the error if there is one
            if exitCode ~= 0 then
                Logger.log("error", "Recording failed: " .. (stdErr or "unknown error"))
            end
        end)
        self.recordingTask:start()
        self.isRecording = true

        -- Show recording indicator
        Indicator:createIndicator()
        Indicator:setRecordingStatus()

        -- Bind 'Esc' key to stop recording without transcription
        if self.escHotkey then
            self.escHotkey:delete()
        end
        self.escHotkey = hs.hotkey.bind({}, "escape", function()
            self:stopRecording(true) -- Interrupted
        end)
    else
        -- Stop recording and process transcription
        self:stopRecording(false, mode)
    end
end

return M
