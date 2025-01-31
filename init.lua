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

-- Options
obj.word = "works"

-- Metadata
obj.name = "Whiston"
obj.version = "1.0"
obj.author = "Kevin Jalbert <kevin.j.jalbert@gmail.com>"
obj.homepage = "https://github.com/kevinjalbert/whiston"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Initialize logger
obj.logger = hs.logger.new('Whiston')
obj.logger.setLogLevel('debug')  -- Set log level to debug to see all logs

-- Load modules from the Spoon's modules directory
local spoonPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = spoonPath .. "modules/?.lua;" .. package.path

obj.recording = require("recording")
obj.ui = require("ui")
obj.transcription = require("transcription")
obj.menu = require("menu")

-- Set up parent references
obj.recording.parent = obj
obj.ui.parent = obj
obj.transcription.parent = obj
obj.menu.parent = obj

-- Share logger with modules
obj.recording.logger = obj.logger
obj.ui.logger = obj.logger
obj.transcription.logger = obj.logger
obj.menu.logger = obj.logger

function obj:whiston()
    if not self.recording.isRecording then
        self.recording:startRecording()
    else
        self.recording:stopRecording(false)
    end
end

function obj:whistonDirect()
    if not self.recording.isRecording then
        self.recording:startRecording(true)  -- Pass true for direct mode
    else
        self.recording:stopRecording(false, true)  -- Not interrupted, but direct mode
    end
end

function obj:bindHotkeys(mapping)
    local def = {
        whiston = {{"cmd", "alt", "ctrl"}, "w"},
        whistonDirect = {{"cmd", "alt", "ctrl"}, "e"}
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
            end
        end
    end
end

return obj
