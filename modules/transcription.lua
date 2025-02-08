local M = {}

local Logger = require("logger")
local Config = require("config")

function M:startTranscription(callback)
    Logger.log("debug", "Starting transcription process")

    local transcribingScript = Config.handleTranscribingScript
    Logger.log("debug", "Running transcription script: " .. transcribingScript)

    local transcribingTask = hs.task.new(transcribingScript, function(exitCode, stdOut, stdErr)
        Logger.log("debug", "Transcription script finished with exit code: " .. exitCode)

        if exitCode == 0 and stdOut then
            Logger.log("debug", "Starting post-transcription transcribing")
            -- Pass transcription output to the shell script for processing
            local transcriptionCleaningScript = Config.handleTranscriptionCleaningScript
            local transcriptionCleaningTask = hs.task.new(transcriptionCleaningScript, function(handleExitCode, handleStdOut, handleStdErr)
                Logger.log("debug", "Post-transcription processing finished with exit code: " .. handleExitCode)

                if handleExitCode == 0 and handleStdOut then
                    Logger.log("debug", "Calling callback with processed transcript")
                    -- Pass the processed transcript back to the caller
                    if callback then
                        callback(handleStdOut)
                    end
                else
                    Logger.log("error", "Post-transcription handling failed: " .. (handleStdErr or "unknown error"))
                    if callback then
                        callback(nil, handleStdErr or "unknown error")
                    end
                end
            end, { "-c", stdOut })
            transcriptionCleaningTask:setInput(stdOut) -- Provide transcription output as input
            transcriptionCleaningTask:start()
        else
            Logger.log("error", "Transcription failed: " .. (stdErr or "unknown error"))
            if callback then
                callback(nil, stdErr or "unknown error")
            end
        end
    end, {})
    transcribingTask:start()
end

return M
