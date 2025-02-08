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
---   spoon.Whiston:bindHotkeys({
---       whiston = {{"cmd", "alt", "ctrl"}, "w"}  -- Default binding
---   })
---```
---
--- Download: xxxxx

local obj = {}

-- Metadata
obj.name = "Whistion"
obj.version = "1.0"
obj.author = "Kevin Jalbert <kevin.j.jalbert@gmail.com>"
obj.homepage = "https://github.com/kevinjalbert/whiston"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Initialize logger
obj.logger = hs.logger.new('Whistion')
obj.logger.setLogLevel('debug')  -- Set log level to debug to see all logs

-- Load modules from the Spoon's modules directory
local spoonPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = spoonPath .. "modules/?.lua;" .. package.path

obj.recording = require("recording")
obj.ui = require("ui")
obj.transcription = require("transcription")
obj.menu = require("menu")
obj.statistics = require("statistics")

-- Set up parent references
obj.recording.parent = obj
obj.ui.parent = obj
obj.transcription.parent = obj
obj.menu.parent = obj
obj.statistics.parent = obj

-- Share logger with modules
obj.recording.logger = obj.logger
obj.ui.logger = obj.logger
obj.transcription.logger = obj.logger
obj.menu.logger = obj.logger
obj.statistics.logger = obj.logger

function obj:whiston()
    self.ui:cleanup()
    if not self.recording.isRecording then
        self.recording:startRecording()
    else
        self.recording:stopRecording(false)
    end
end

function obj:whistonDirect()
    self.ui:cleanup()
    if not self.recording.isRecording then
        self.recording:startRecording(true)  -- Pass true for direct mode
    else
        self.recording:stopRecording(false, true)  -- Not interrupted, but direct mode
    end
end

function obj:whistonMenu()
    self.ui:cleanup()
    -- Get the currently focused element
    local element = hs.uielement.focusedElement()
    if element then
        -- Get selected text directly from the element
        local selectedText = element:selectedText()
        if selectedText then
            -- Show menu directly with the selected text
            self.menu:showMenu(selectedText)
        end
    end
end

function obj:toggleStats()
    self.ui:toggleStatsModal()
end

function obj:bindHotkeys(mapping)
    local def = {
        whiston = {{"cmd", "alt", "ctrl"}, "w"},
        whistonDirect = {{"cmd", "alt", "ctrl"}, "e"},
        whistonMenu = {{"cmd", "alt", "ctrl", "shift"}, "="},
        toggleStats = {{"cmd", "alt", "ctrl", "shift"}, "-"}
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

return obj
