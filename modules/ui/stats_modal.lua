M = {}

local Logger = require("utils.logger")
local Config = require("utils.config")
local Statistics = require("statistics")

M.statsModal = nil

-- Create and show the statistics modal
function M:createStatsModal()

    -- This supports the 'toggling' of the stats modal.
    -- We delete the existing if we call this function again.
    if self.statsModal then
        self.statsModal:delete()
        self.statsModal = nil
        return
    end

    local screen = hs.screen.primaryScreen()
    local frame = screen:frame()

    -- Create a larger modal window
    local modalWidth = 250
    local modalHeight = 625
    local rect = hs.geometry.rect(
        (frame.w - modalWidth) / 2,
        (frame.h - modalHeight) / 2,
        modalWidth,
        modalHeight
    )

    self.statsModal = hs.canvas.new(rect)

    -- Background
    self.statsModal[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.9 },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
    }

    -- Title
    self.statsModal[2] = {
        type = "text",
        text = "Transcription Statistics",
        textColor = { white = 1, alpha = 0.9 },
        textFont = "AppleSystemUIFont",
        textSize = 20,
        frame = {
            x = 20,
            y = 20,
            w = modalWidth - 40,
            h = 30
        }
    }

    -- Get statistics
    local stats = Statistics:getAllStats()
    local y = 70
    local periods = {
        {name = "Today", key = "daily"},
        {name = "This Week", key = "weekly"},
        {name = "This Month", key = "monthly"},
        {name = "This Year", key = "yearly"},
        {name = "Lifetime", key = "lifetime"}
    }

    for i, period in ipairs(periods) do
        -- Period header
        self.statsModal[#self.statsModal + 1] = {
            type = "text",
            text = period.name,
            textColor = { white = 1, alpha = 0.9 },
            textFont = "AppleSystemUIFont",
            textSize = 16,
            frame = {
                x = 20,
                y = y,
                w = modalWidth - 40,
                h = 20
            }
        }

        -- Stats text
        local data = stats[period.key]
        local statsText = string.format(
            "Transcriptions: %d\nCharacters: %d\nWords: %d\nDuration: %s",
            data.transcriptions,
            data.characters,
            data.words,
            data.duration
        )

        self.statsModal[#self.statsModal + 1] = {
            type = "text",
            text = statsText,
            textColor = { white = 1, alpha = 0.7 },
            textFont = "AppleSystemUIFont",
            textSize = 14,
            frame = {
                x = 40,
                y = y + 25,
                w = modalWidth - 60,
                h = 80
            }
        }

        y = y + 110
    end

    self.statsModal:show()
end

-- Toggle statistics modal
function M:toggleStatsModal()
    if self.statsModal then
        self:createStatsModal()  -- This will delete the existing modal
    else
        -- Clean up any existing UI elements first
        self:cleanup()
        self:createStatsModal()  -- This will create a new modal
    end
end

function M:cleanup()
    -- Clean up the stats modal
    if self.statsModal then
        self.statsModal:delete()
        self.statsModal = nil
    end
end

return M
