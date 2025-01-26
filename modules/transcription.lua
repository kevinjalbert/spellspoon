local M = {}

function M:startTranscription()
    -- Begin transcription after a short delay
    hs.timer.doAfter(0.25, function()
        local scriptPath = os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_transcription.sh"
        local transcribeTask = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
            if self.parent.ui.recordingIndicator then
                self.parent.ui.recordingIndicator:delete() -- Clean up the modal after processing
                self.parent.ui.recordingIndicator = nil
            end

            if exitCode == 0 and stdOut then
                -- Pass transcription output to the shell script for processing
                local handleTask = hs.task.new(os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_post_transcription.sh", function(handleExitCode, handleStdOut, handleStdErr)
                    if handleExitCode == 0 and handleStdOut then
                        hs.pasteboard.setContents(handleStdOut) -- Store processed transcription in clipboard

                        -- Check if there's an active text field before attempting to paste
                        local focused = hs.uielement.focusedElement()
                        local shouldPaste = false

                        if focused then
                            local success, role = pcall(function() return focused:role() end)
                            if success and role then
                                shouldPaste = (role == "AXTextField" or role == "AXTextArea")
                            end
                        end

                        if shouldPaste then
                            hs.eventtap.keyStroke({"cmd"}, "v")
                        else
                            hs.alert.show("Transcription copied to clipboard")
                        end
                    else
                        self.logger.e("Post-transcription handling failed: " .. (handleStdErr or "unknown error"))
                    end
                end, { "-c", stdOut })
                handleTask:setInput(stdOut) -- Provide transcription output as input
                handleTask:start()
            else
                self.logger.e("Transcription failed: " .. (stdErr or "unknown error"))
            end
        end)
        transcribeTask:start()
    end)
end

return M
