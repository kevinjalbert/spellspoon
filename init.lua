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

-- Whiston
function obj:whiston()
    if not self.isRecording then
        -- Start recording
        self.logger.d("Starting recording")
        self.recordingTask = hs.task.new("/opt/homebrew/bin/ffmpeg", nil, {
            "-y", "-f", "avfoundation", "-i", ":4", "-ar", "16000", "-ac", "1", "/tmp/recorded_audio.wav"
        })
        self.recordingTask:start()
        self.isRecording = true
    else
        -- Stop recording and transcribe
        self.logger.d("Stopping recording and transcribing")
        if self.recordingTask then
            self.recordingTask:terminate()
            self.recordingTask = nil
        end

        hs.timer.doAfter(0.25, function()
            local transcribeTask = hs.task.new("/opt/homebrew/bin/whisper-cli", function(exitCode, stdOut, stdErr)
                if exitCode == 0 and stdOut then
                    hs.pasteboard.setContents(stdOut)
                    hs.eventtap.keyStrokes(stdOut)
                    self.logger.d("Transcription completed")
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
