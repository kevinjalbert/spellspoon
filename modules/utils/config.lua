local Config = {}

-- Default configuration with absolute paths
local defaults = {
    promptsDirectory = hs.spoons.scriptPath() .. "../../prompts",
    transcriptionStatsDatabase = hs.spoons.scriptPath() .. "../../transcription_stats.sqlite",
    transcribingScript = hs.spoons.scriptPath() .. "../../scripts/transcribing.sh",
    recordingScript = hs.spoons.scriptPath() .. "../../scripts/recording.sh",
    promptingScript = hs.spoons.scriptPath() .. "../../scripts/prompting.sh",
    logLevel = "info"
}

-- User configuration (empty by default)
local userConfig = {}

-- Create metatable for Config
local mt = {
    __index = function(_, key)
        -- Always prefer user config over defaults
        return userConfig[key] or defaults[key]
    end
}

setmetatable(Config, mt)

-- Function to set user configuration
function Config.setConfig(config)
    if config then
        -- Clear existing user config
        for k in pairs(userConfig) do
            userConfig[k] = nil
        end
        -- Set new config
        for k, v in pairs(config) do
            userConfig[k] = v
        end
    end
end

return Config
