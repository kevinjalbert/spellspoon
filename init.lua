--- === Whiston ===
---
--- A Hammerspoon Spoon that provides audio recording and transcription functionality.
---
--- Features:
---  * Start/stop audio recording with a configurable hotkey (default: cmd+alt+ctrl+w)
---  * Automatic transcription of recorded audio
---  * Visual feedback through UI elements during recording
---
--- Usage:
---  * Load and configure the spoon in your Hammerspoon configuration
---  * Use the default hotkey or configure custom bindings
---
--- Example:
---```
---   hs.loadSpoon("Whiston")
---
---   -- Optional: Override default configuration
---   spoon.Whiston:setConfig({
---       promptsDir = "~/whiston/prompts",
---       transcriptionStatsDatabase = "~/whiston/transcription_stats.sqlite",
---       handleTranscribingScript = "~/whiston/handle_transcribing.sh",
---       handleRecordingScript = "~/whiston/handle_recording.sh",
---       handlePromptingScript = "~/whiston/handle_prompting.sh"
---   })
---
---   -- Set up hotkeys (optional)
---   spoon.Whiston:bindHotkeys({
---       whiston = {{"cmd", "alt", "ctrl"}, "w"}  -- Default binding
---       whistonDirect = {{"cmd", "alt", "ctrl"}, "e"}  -- Default binding
---       whistonMenu = {{"cmd", "alt", "ctrl"}, "="}  -- Default binding
---       toggleStats = {{"cmd", "alt", "ctrl"}, "-"}  -- Default binding
---   })
---```
---
--- Download: xxxxx

local M = {}

-- Metadata
M.name = "Whistion"
M.version = "1.0"
M.author = "Kevin Jalbert <kevin.j.jalbert@gmail.com>"
M.homepage = "https://github.com/kevinjalbert/whiston"
M.license = "MIT - https://opensource.org/licenses/MIT"

-- Load modules from the Spoon's modules directory
local spoonPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = spoonPath .. "modules/?.lua;" .. package.path

local Logger = require("utils.logger")

-- Load configuration module first
local Config = require("utils.config")

-- Allow setting configuration before initialization
function M:setConfig(config)
    -- Expand any paths that use ~
    local expandedConfig = {}
    for k, v in pairs(config) do
        if type(v) == "string" and v:match("^~") then
            expandedConfig[k] = v:gsub("^~", os.getenv("HOME"))
        else
            expandedConfig[k] = v
        end
    end

    -- Set the config using the proxy's function directly
    Config.setConfig(expandedConfig)
end

local Recording = require("record.recording")
local Indicator = require("ui.indicator")
local Menu = require("menu.menu")
local StatsModal = require("ui.stats_modal")

function M:whiston()
    Indicator:cleanup()
    if not Recording.isRecording then
        Recording:startRecording()
    else
        Recording:stopRecording(false)
    end
end

function M:whistonDirect()
    Indicator:cleanup()
    if not Recording.isRecording then
        Recording:startRecording(true)  -- Pass true for direct mode
    else
        Recording:stopRecording(false, true)  -- Not interrupted, but direct mode
    end
end

function M:whistonMenu()
    Indicator:cleanup()
    -- Get the currently focused element
    local element = hs.uielement.focusedElement()
    if element then
        -- Get selected text directly from the element
        local selectedText = element:selectedText()
        if selectedText then
            -- Show menu directly with the selected text
            Menu:showMenu(selectedText)
        end
    end
end

function M:toggleStats()
    StatsModal:toggleStatsModal()
end

function M:bindHotkeys(mapping)
    local def = {
        whiston = {{"cmd", "alt", "ctrl"}, "w"},
        whistonDirect = {{"cmd", "alt", "ctrl"}, "e"},
        whistonMenu = {{"cmd", "alt", "ctrl"}, "="},
        toggleStats = {{"cmd", "alt", "ctrl"}, "-"}
    }
    if mapping then
        for k,v in pairs(mapping) do
            def[k] = v
        end
    end

    for k,v in pairs(def) do
        if v[1] and v[2] then
            if k == "whiston" then
                hs.hotkey.bind(v[1], v[2], function() self:whiston() end)
            elseif k == "whistonDirect" then
                hs.hotkey.bind(v[1], v[2], function() self:whistonDirect() end)
            elseif k == "whistonMenu" then
                hs.hotkey.bind(v[1], v[2], function() self:whistonMenu() end)
            elseif k == "toggleStats" then
                hs.hotkey.bind(v[1], v[2], function() self:toggleStats() end)
            end
        end
    end
end

return M
