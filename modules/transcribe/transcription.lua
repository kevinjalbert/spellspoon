local M = {}

local Logger = require("utils.logger")
local Config = require("utils.config")
local Statistics = require("statistics.statistics")

-- Helper function to trim all whitespace
local function trim(s)
    -- Remove leading/trailing whitespace, including newlines, carriage returns, and tabs
    return s:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\r", "")
end

-- Helper function to count words in a string
local function countWords(s)
    local words = 0
    for _ in s:gmatch("%S+") do
        words = words + 1
    end
    return words
end

-- Helper function to log transcription statistics
local function logTranscriptionStats(text)
    local charCount = #text
    local wordCount = countWords(text)

    -- Get audio length from the temporary file
    local audioLength = 0
    local audioFile = io.open("/tmp/recorded_audio.wav", "r")
    if audioFile then
        audioFile:close()
        -- Create a pipe to capture ffprobe output synchronously
        local pipe = io.popen('/opt/homebrew/bin/ffprobe -i /tmp/recorded_audio.wav -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null')
        if pipe then
            local output = pipe:read("*a")
            pipe:close()
            audioLength = tonumber(output) or 0
        end
    end

    Statistics:insertTranscriptionStats(charCount, wordCount, audioLength)
end

function M:startTranscription(callback)
    Logger.log("debug", "Starting transcription process")

    local transcribingScript = Config.handleTranscribingScript
    Logger.log("debug", "Running transcription script: " .. transcribingScript)

    local transcribingTask = hs.task.new(transcribingScript, function(exitCode, stdOut, stdErr)
        Logger.log("debug", "Transcription script finished with exit code: " .. exitCode)

        if exitCode == 0 and stdOut then
            Logger.log("debug", "Processing transcription output")

            -- Process the transcription output inline
            local processedText = trim(stdOut)
            logTranscriptionStats(processedText)

            Logger.log("debug", "Calling callback with processed transcript")
            callback(processedText)
        else
            Logger.log("error", "Transcription failed: " .. (stdErr or "unknown error"))
            callback(nil, stdErr or "unknown error")
        end
    end, {})

    transcribingTask:start()
end

return M
