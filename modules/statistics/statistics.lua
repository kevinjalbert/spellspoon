local M = {}

local Logger = require("utils.logger")
local Database = require("data.database")

-- Format duration in HH:MM:SS
function M:formatDuration(seconds)
    Logger.log("debug", "Formatting duration: " .. tostring(seconds) .. " seconds")
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    local formatted = string.format("%02d:%02d:%02d", hours, minutes, secs)
    Logger.log("debug", "Formatted duration: " .. formatted)
    return formatted
end

-- Get time filter for a specific period
function M:getTimeFilter(period)
    -- Get the current time in local timezone
    local now = os.time()
    local t = os.date("*t", now)
    Logger.log("debug", string.format("Getting time filter for period '%s', current time: %s", period, os.date("%Y-%m-%d %H:%M:%S", now)))

    -- Compute the start of the current day
    t.hour = 0
    t.min  = 0
    t.sec  = 0
    local startOfDay = os.time(t)
    local startOfDayStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay)
    Logger.log("debug", "Start of day: " .. startOfDayStr)

    -- Compute the start of the next day (for the upper boundary)
    local endOfDayStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay + 24*60*60)
    Logger.log("debug", "End of day: " .. endOfDayStr)

    -- Compute the start of the week (last 7 days including today)
    local startOfWeekStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay - 6*24*60*60)
    Logger.log("debug", "Start of week: " .. startOfWeekStr)

    -- Compute the start of the current month
    local startOfMonthStr = string.format("%04d-%02d-01 00:00:00", t.year, t.month)
    Logger.log("debug", "Start of month: " .. startOfMonthStr)

    -- Compute the start of the current year
    local startOfYearStr = string.format("%04d-01-01 00:00:00", t.year)
    Logger.log("debug", "Start of year: " .. startOfYearStr)

    local timeFilters = {
        daily   = string.format("created_at >= '%s' AND created_at < '%s'", startOfDayStr, endOfDayStr),
        weekly  = string.format("created_at >= '%s' AND created_at < '%s'", startOfWeekStr, endOfDayStr),
        monthly = string.format("created_at >= '%s'", startOfMonthStr),
        yearly  = string.format("created_at >= '%s'", startOfYearStr),
        lifetime = "1=1"
    }

    local filter = timeFilters[period]
    Logger.log("debug", "Generated time filter: " .. filter)
    return filter
end

-- Get stats for a specific period
function M:getStats(period)
    Logger.log("debug", "Getting stats for period: " .. period)

    local timeFilter = self:getTimeFilter(period)
    Logger.log("debug", "Using time filter: " .. timeFilter)

    local data = Database:getStatsForTimeFilter(timeFilter)
    if not data then
        Logger.log("warning", "No data returned for period: " .. period)
        return {
            count = 0,
            characters = 0,
            words = 0,
            duration = 0
        }
    end

    Logger.log("debug", string.format("Raw data returned: count=%s, chars=%s, words=%s, duration=%s",
        tostring(data.count), tostring(data.characters),
        tostring(data.words), tostring(data.duration)))

    return data
end

-- Get all stats formatted for display
function M:getAllStats()
    Logger.log("debug", "Getting all stats")
    local periods = {"daily", "weekly", "monthly", "yearly", "lifetime"}
    local stats = {}

    for _, period in ipairs(periods) do
        Logger.log("debug", "Getting stats for period: " .. period)
        local data = self:getStats(period)
        stats[period] = {
            transcriptions = data.count,
            characters = data.characters,
            words = data.words,
            duration = self:formatDuration(data.duration)
        }
        Logger.log("debug", string.format("Formatted stats for %s: transcriptions=%d, chars=%d, words=%d, duration=%s",
            period, stats[period].transcriptions, stats[period].characters,
            stats[period].words, stats[period].duration))
    end

    Logger.log("debug", "Returning final stats table")
    return stats
end

-- Proxy method for inserting transcription stats
function M:insertTranscriptionStats(charCount, wordCount, audioLength)
    return Database:insertTranscriptionStats(charCount, wordCount, audioLength)
end

return M
