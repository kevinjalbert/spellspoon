--- === Whiston ===
---
--- A simple hotkey to trigger a command.
---
--- Configurable properties (with default values):
---     word = "works"
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

-- Load modules from the Spoon's modules directory
local spoonPath = debug.getinfo(1, "S").source:sub(2):match("(.*/)")
package.path = spoonPath .. "modules/?.lua;" .. package.path

obj.recording = require("recording")
obj.ui = require("ui")
obj.transcription = require("transcription")

-- Set up parent references
obj.recording.parent = obj
obj.ui.parent = obj
obj.transcription.parent = obj

-- Share logger with modules
obj.recording.logger = obj.logger
obj.ui.logger = obj.logger
obj.transcription.logger = obj.logger

function obj:whiston()
    if not self.recording.isRecording then
        self.recording:startRecording()
    else
        self.recording:stopRecording(false)
    end
end

function obj:bindHotkeys(mapping)
    local def = {
        whiston = {{"cmd", "alt", "ctrl"}, "w"}
    }
    if mapping then
        for k,v in pairs(mapping) do
            def[k] = v
        end
    end

    for k,v in pairs(def) do
        if v[1] and v[2] then
            hs.hotkey.bind(v[1], v[2], function() self:whiston() end)
        end
    end
end

return obj
