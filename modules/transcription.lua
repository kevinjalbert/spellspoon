local M = {}

function M:startTranscription(callback)
    self.logger.d("Starting transcription process")

    local scriptPath = os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_transcription.sh"
    self.logger.d("Running transcription script: " .. scriptPath)

    -- Load environment from .env file
    local env = {
        PATH = os.getenv("PATH"),
        HOME = os.getenv("HOME"),
        SHELL = os.getenv("SHELL"),
        USER = os.getenv("USER")
    }

    local envFile = io.open(os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/.env", "r")
    if envFile then
        for line in envFile:lines() do
            if not line:match("^%s*#") and line:match("%S") then
                local key, value = line:match("([^=]+)=(.+)")
                if key and value then
                    -- Remove quotes and whitespace
                    key = key:gsub("^%s*(.-)%s*$", "%1")
                    value = value:gsub("^%s*(.-)%s*$", "%1"):gsub('^"(.-)"$', "%1")
                    env[key] = value
                end
            end
        end
        envFile:close()
    else
        self.logger.e("Could not open .env file")
        if callback then
            callback(nil, "Could not open .env file")
        end
        return
    end

    -- Log environment for debugging
    self.logger.d("Environment loaded with WHISTION variables")
    if env.WHISTION_API_KEY then
        self.logger.d("WHISTION_API_KEY is present")
    else
        self.logger.e("WHISTION_API_KEY is missing")
        if callback then
            callback(nil, "WHISTION_API_KEY environment variable must be set")
        end
        return
    end

    local transcribeTask = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
        self.logger.d("Transcription script finished with exit code: " .. exitCode)

        if exitCode == 0 and stdOut then
            self.logger.d("Starting post-transcription processing")
            -- Pass transcription output to the shell script for processing
            local handleTask = hs.task.new(os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/handle_prompting.sh", function(handleExitCode, handleStdOut, handleStdErr)
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
            end, { "-c", stdOut }, env)
            handleTask:setInput(stdOut) -- Provide transcription output as input
            handleTask:start()
        else
            self.logger.e("Transcription failed: " .. (stdErr or "unknown error"))
            if callback then
                callback(nil, stdErr or "unknown error")
            end
        end
    end, {}, env)
    transcribeTask:start()
end

return M
