local M = {}

function M:startTranscription(callback)
    self.logger.d("Starting transcription process")
    -- Begin transcription after a short delay
    hs.timer.doAfter(0.25, function()
        local scriptPath = os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_transcription.sh"
        self.logger.d("Running transcription script: " .. scriptPath)

        local transcribeTask = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
            self.logger.d("Transcription script finished with exit code: " .. exitCode)

            if exitCode == 0 and stdOut then
                self.logger.d("Starting post-transcription processing")
                -- Pass transcription output to the shell script for processing
                local handleTask = hs.task.new(os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_post_transcription.sh", function(handleExitCode, handleStdOut, handleStdErr)
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
                handleTask:setInput(stdOut) -- Provide transcription output as input
                handleTask:start()
            else
                self.logger.e("Transcription failed: " .. (stdErr or "unknown error"))
                if callback then
                    callback(nil, stdErr or "unknown error")
                end
            end
        end)
        transcribeTask:start()
    end)
end

return M
