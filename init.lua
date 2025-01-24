--- === Whiston ===
---
--- A simple hotkey to trigger a command.
---
--- Configurable properties (with default values):
---     word = "works"
---
--- Download: xxxxx

local obj = {}

-- Options
obj.word = "works"

-- Metadata
obj.name = "Whiston"
obj.version = "1.0"
obj.author = "Kevin Jalbert <kevin.j.jalbert@gmail.com>"
obj.homepage = "https://github.com/kevinjalbert/whiston"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Initialize logger
obj.logger = hs.logger.new('Whiston')

-- Recording state
obj.isRecording = false
obj.recordingTask = nil
obj.recordingIndicator = nil
obj.recordingTimer = nil
obj.startTime = nil

function obj:createRecordingIndicator()
    local screen = hs.screen.primaryScreen()
    local frame = screen:frame()

    -- Create a centered rectangle with improved dimensions
    local indicatorWidth = 160
    local indicatorHeight = 44

    local rect = hs.geometry.rect(
        frame.w/2 - indicatorWidth/2,
        frame.h/2 - indicatorHeight/2,
        indicatorWidth,
        indicatorHeight
    )

    self.recordingIndicator = hs.canvas.new(rect)

    -- Add background with modern styling
    self.recordingIndicator[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.85 },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
    }

    -- Add recording indicator dot (centered vertically relative to the text)
    self.recordingIndicator[2] = {
        type = "circle",
        action = "fill",
        fillColor = { red = 1, green = 0, blue = 0, alpha = 0.8 },
        frame = { x = 16, y = 14, w = 8, h = 8 },
    }

    -- Add "Recording ..." text
    self.recordingIndicator[3] = {
        type = "text",
        text = "Recording ...",
        textColor = { white = 1, alpha = 0.9 },
        textFont = "AppleSystemUIFont",
        textSize = 14,
        frame = { x = 32, y = 10, w = 100, h = 20 },
        textAlignment = "left",
    }

    -- Add counter text below "Recording ..."
    self.recordingIndicator[4] = {
        type = "text",
        text = "00:00",
        textColor = { white = 1, alpha = 0.95 },
        textFont = "AppleSystemUIFont",
        textSize = 14,
        frame = { x = 32, y = 30, w = 100, h = 20 },
        textAlignment = "left",
    }

    -- Function for pulsing animation for the dot
    local function pulseDot()
        if self.recordingIndicator then
            -- Fade out
            hs.timer.doAfter(0, function()
                if self.recordingIndicator then
                    self.recordingIndicator[2].fillColor.alpha = 0.3
                end
            end)
            -- Fade in
            hs.timer.doAfter(0.8, function()
                if self.recordingIndicator then
                    self.recordingIndicator[2].fillColor.alpha = 0.8
                end
            end)
        end
    end

    -- Start pulsing animation
    pulseDot() -- Initial pulse
    self.pulseTimer = hs.timer.doEvery(1.6, pulseDot)
end

function obj:stopRecording(interrupted)
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
        if self.recordingIndicator then
            self.recordingIndicator:delete()
            self.recordingIndicator = nil
        end
        self.isRecording = false
        self.startTime = nil
        return
    end

    -- Update the modal to "Processing..."
    self:setProcessingStatus()

    -- Begin transcription after a short delay
    hs.timer.doAfter(0.25, function()
        local transcribeTask = hs.task.new("/opt/homebrew/bin/whisper-cli", function(exitCode, stdOut, stdErr)
            if self.recordingIndicator then
                self.recordingIndicator:delete() -- Clean up the modal after processing
                self.recordingIndicator = nil
            end

            if exitCode == 0 and stdOut then
                -- Pass transcription output to the shell script for processing
                local handleTask = hs.task.new(os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_post_transcription.sh", function(handleExitCode, handleStdOut, handleStdErr)
                    if handleExitCode == 0 and handleStdOut then
                        hs.pasteboard.setContents(handleStdOut) -- Store processed transcription in clipboard
                        hs.eventtap.keyStroke({"cmd"}, "v") -- Trigger a single paste event
                        self.logger.d("Post-transcription handling completed")
                    else
                        self.logger.e("Post-transcription handling failed: " .. (handleStdErr or "unknown error"))
                    end
                end, { "-c", stdOut })
                handleTask:setInput(stdOut) -- Provide transcription output as input
                handleTask:start()
            else
                self.logger.e("Transcription failed: " .. (stdErr or "unknown error"))
            end
        end, {
            "--no-prints", "--no-timestamps",
            "--model", os.getenv("HOME") .. "/Downloads/ggml-large-v3-turbo-q5_0.bin",
            "-f", "/tmp/recorded_audio.wav"
        })
        transcribeTask:start()
    end)

    self.isRecording = false
    self.startTime = nil
end

function obj:setProcessingStatus()
    if self.recordingIndicator then
        -- Update modal to display "Processing..."
        self.recordingIndicator[3].text = "Processing ..."
        self.recordingIndicator[4] = nil -- Remove the timer text
        self.recordingIndicator[2].fillColor = { red = 0, green = 0.5, blue = 1, alpha = 0.8 } -- Change dot color to blue
    end
end

-- Update timer display
function obj:updateTimer()
    if self.startTime and self.recordingIndicator then
        local elapsed = os.time() - self.startTime
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        local timeString = string.format("%02d:%02d", minutes, seconds)

        self.recordingIndicator[4].text = timeString
    end
end

function obj:whiston()
    if not self.isRecording then
        -- Start recording
        self.logger.d("Starting recording")
        self.recordingTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, {
            "-y", "-f", "avfoundation", "-i", ":4", "-ar", "16000", "-ac", "1", "/tmp/recorded_audio.wav"
        })
        self.recordingTask:start()
        self.isRecording = true

        -- Show recording indicator
        self:createRecordingIndicator()
        self.recordingIndicator:show()
        self.startTime = os.time()
        self.recordingTimer = hs.timer.doEvery(1, function() self:updateTimer() end)

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

function obj:bindHotkeys(mapping)
    local def = {
        whiston = {{"cmd", "alt", "ctrl"}, "w"}
    }
    if mapping then
        for k,v in pairs(mapping) do
            def[k] = v
        end
    end

    for k,v in pairs(def) do
        if v[1] and v[2] then
            hs.hotkey.bind(v[1], v[2], function() self:whiston() end)
        end
    end
end

return obj
