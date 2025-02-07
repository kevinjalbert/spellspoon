local M = {}

function M:startTranscription(callback)
    self.logger.d("Starting transcription process")

    local transcribingScript = self.parent.config.handleTranscribingScript
    self.logger.d("Running transcription script: " .. transcribingScript)

    local transcribingTask = hs.task.new(transcribingScript, function(exitCode, stdOut, stdErr)
        self.logger.d("Transcription script finished with exit code: " .. exitCode)

        if exitCode == 0 and stdOut then
            self.logger.d("Starting post-transcription transcribing")
            -- Pass transcription output to the shell script for processing
            local transcriptionCleaningScript = self.parent.config.handleTranscriptionCleaningScript
            local transcriptionCleaningTask = hs.task.new(transcriptionCleaningScript, function(handleExitCode, handleStdOut, handleStdErr)
                self.logger.d("Post-transcription processing finished with exit code: " .. handleExitCode)

                if handleExitCode == 0 and handleStdOut then
                    self.logger.d("Calling callback with processed transcript")
                    -- Pass the processed transcript back to the caller
                    if callback then
                        callback(handleStdOut)
                    end
                else
                    self.logger.e("Post-transcription handling failed: " .. (handleStdErr or "unknown error"))
                    if callback then
                        callback(nil, handleStdErr or "unknown error")
                    end
                end
            end, { "-c", stdOut })
            transcriptionCleaningTask:setInput(stdOut) -- Provide transcription output as input
            transcriptionCleaningTask:start()
        else
            self.logger.e("Transcription failed: " .. (stdErr or "unknown error"))
            if callback then
                callback(nil, stdErr or "unknown error")
            end
        end
    end, {})
    transcribingTask:start()
end

return M
