--- === Spellspoon ===
---
--- A macOS tool built using Hammerspoon for Audio Recording and Transcription
---
--- SpellSpoon provides hotkey-driven audio recording, transcription, and prompting functionality.
--- A configurable shell script pipeline is used to handle the recording, transcription, and prompting.
---
--- Features:
--- - Hotkey control for recording.
--- - Customizable shell script pipelines for recording, transcribing, and prompting.
--- - Flexible prompt-based text transformation.
--- - Clipboard and direct pasting support.
--- - Tracks transcription stats (duration, word count, character count).
--- - Customization of scripts allows for custom prompts, transcription, recording, and services used.

--- Configuration:
---
--- local spellspoon = hs.loadSpoon("spellspoon")
--- spellspoon:setConfig({
---     promptsDirectory = "~/.spellspoon/prompts",
---     transcriptionStatsDatabase = "~/.spellspoon/transcription_stats.sqlite",
---     transcribingScript = "~/.spellspoon/handle_transcribing.sh",
---     recordingScript = "~/.spellspoon/handle_recording.sh",
---     promptingScript = "~/.spellspoon/handle_prompting.sh",
---     logLevel = "debug"
--- })
--- spellspoon:bindHotkeys({
---     spellspoon = {{"cmd", "alt", "ctrl", "shift"}, "]"},
---     spellspoonDirect = {{"cmd", "alt", "ctrl", "shift"}, "["},
---     spellspoonMenu = {{"cmd", "alt", "ctrl", "shift"}, "="},
---     toggleStats = {{"cmd", "alt", "ctrl", "shift"}, "-"}
--- })
---
--- Download: https://github.com/kevinjalbert/spellspoon

local M = {}

-- Metadata
M.name = "Spellspoon"
M.version = "1.0"
M.author = "Kevin Jalbert <kevin.j.jalbert@gmail.com>"
M.homepage = "https://github.com/kevinjalbert/spellspoon"
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

function M:recordWithDefaultPrompt()
    Indicator:cleanup()
    if not Recording.isRecording then
        Recording:startRecording(true)  -- Pass true for direct mode
    else
        Recording:stopRecording(false, true)  -- Not interrupted, but direct mode
    end
end

function M:recordWithPromptSelection()
    Indicator:cleanup()
    if not Recording.isRecording then
        Recording:startRecording()
    else
        Recording:stopRecording(false)
    end
end

function M:useSelectedTextWithPromptSelection()
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

function M:showStatsModal()
    StatsModal:toggleStatsModal()
end

function M:bindHotkeys(mapping)
    local def = {
        recordWithDefaultPrompt = {{"cmd", "alt", "ctrl"}, "["},
        recordWithPromptSelection= {{"cmd", "alt", "ctrl"}, "]"},
        useSelectedTextWithPromptSelection = {{"cmd", "alt", "ctrl"}, "="},
        showStatsModal = {{"cmd", "alt", "ctrl"}, "-"}
    }
    if mapping then
        for k,v in pairs(mapping) do
            def[k] = v
        end
    end

    for k,v in pairs(def) do
        if v[1] and v[2] then
            if k == "recordWithDefaultPrompt" then
                hs.hotkey.bind(v[1], v[2], function() self:recordWithDefaultPrompt() end)
            elseif k == "recordWithPromptSelection" then
                hs.hotkey.bind(v[1], v[2], function() self:recordWithPromptSelection() end)
            elseif k == "useSelectedTextWithPromptSelection" then
                hs.hotkey.bind(v[1], v[2], function() self:useSelectedTextWithPromptSelection() end)
            elseif k == "showStatsModal" then
                hs.hotkey.bind(v[1], v[2], function() self:showStatsModal() end)
            end
        end
    end
end

return M
