local M = {}

local Logger = require("logger")
local Config = require("config")

-- Initialize the SQLite database schema
function M:initializeDatabase()
    Logger.log("debug", "Initializing statistics database")

    -- Create the transcriptions table if it doesn't exist
    local create_table_query = [[
        CREATE TABLE IF NOT EXISTS transcriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            characters INTEGER NOT NULL,
            words INTEGER NOT NULL,
            audio_length_seconds REAL NOT NULL
        );
    ]]

    -- Create an index on created_at for faster time-based queries
    local create_index_query = [[
        CREATE INDEX IF NOT EXISTS idx_transcriptions_created_at
        ON transcriptions(created_at);
    ]]

    -- Execute the queries
    if not self:executeQuery(create_table_query) then
        Logger.log("error", "Failed to create transcriptions table")
        return false
    end

    if not self:executeQuery(create_index_query) then
        Logger.log("error", "Failed to create index on created_at")
        return false
    end

    Logger.log("debug", "Successfully initialized statistics database")
    return true
end

-- Helper function to execute SQLite queries
function M:executeQuery(query)
    local db_file = os.getenv("HOME") .. "/.hammerspoon/Spoons/whistion.spoon/transcription_stats.sqlite"
    -- Wrap db_file in single quotes and query in double quotes.
    local command = string.format("/usr/bin/sqlite3 '%s' \"%s\"", db_file, query)

    Logger.log("debug", "Executing SQL query: " .. query)
    Logger.log("debug", "Full command: " .. command)

    local handle = io.popen(command .. " 2>&1")  -- Capture stderr too
    if not handle then
        Logger.log("error", "Failed to execute SQLite command")
        return nil
    end

    local result = handle:read("*a")
    local success, _, code = handle:close()

    if not success then
        Logger.log("error", "Command failed with exit code: " .. (code or "unknown"))
        Logger.log("error", "Error output: " .. result)
        return nil
    end

    if not result or result == "" then
        Logger.log("debug", "Query returned empty result")
        return nil
    end

    Logger.log("debug", "Query result: " .. result)
    return result
end

-- Get stats for a specific time period
function M:getStats(period)
    -- Get the current time in local timezone
    local now = os.time()
    local t = os.date("*t", now)

    -- Compute the start of the current day
    t.hour = 0
    t.min  = 0
    t.sec  = 0
    local startOfDay = os.time(t)
    local startOfDayStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay)

    -- Compute the start of the next day (for the upper boundary)
    local endOfDayStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay + 24*60*60)

    -- Compute the start of the week (last 7 days including today)
    local startOfWeekStr = os.date("%Y-%m-%d %H:%M:%S", startOfDay - 6*24*60*60)

    -- Compute the start of the current month
    local startOfMonthStr = string.format("%04d-%02d-01 00:00:00", t.year, t.month)

    -- Compute the start of the current year
    local startOfYearStr = string.format("%04d-01-01 00:00:00", t.year)

    local timeFilters = {
        daily   = string.format("created_at >= '%s' AND created_at < '%s'", startOfDayStr, endOfDayStr),
        weekly  = string.format("created_at >= '%s' AND created_at < '%s'", startOfWeekStr, endOfDayStr),
        monthly = string.format("created_at >= '%s'", startOfMonthStr),
        yearly  = string.format("created_at >= '%s'", startOfYearStr),
        lifetime = "1=1"
    }

    local query = string.format([[
        SELECT
            COUNT(*) as count,
            COALESCE(SUM(characters), 0) as total_chars,
            COALESCE(SUM(words), 0) as total_words,
            COALESCE(SUM(audio_length_seconds), 0) as total_duration
        FROM transcriptions
        WHERE %s;
    ]], timeFilters[period])

    -- Log the time filter being used
    Logger.log("debug", "Using time filter for " .. period .. ": " .. timeFilters[period])

    local result = self:executeQuery(query)
    if not result then
        Logger.log("error", "Failed to get stats for period: " .. period)
        return {
            count = 0,
            characters = 0,
            words = 0,
            duration = 0
        }
    end

    Logger.log("debug", "Raw stats result for " .. period .. ": " .. result)

    -- Trim any whitespace or newlines from the result
    result = result:gsub("^%s*(.-)%s*$", "%1")

    -- Parse the pipe-separated values
    local count, chars, words, duration = result:match("([^|]+)|([^|]+)|([^|]+)|([^|]+)")
    Logger.log("debug", string.format("Parsed values for %s - count: %s, chars: %s, words: %s, duration: %s",
        period, count or "nil", chars or "nil", words or "nil", duration or "nil"))

    local stats = {
        count = tonumber(count) or 0,
        characters = tonumber(chars) or 0,
        words = tonumber(words) or 0,
        duration = tonumber(duration) or 0
    }

    Logger.log("debug", string.format("Final stats for %s: count=%d, chars=%d, words=%d, duration=%f",
        period, stats.count, stats.characters, stats.words, stats.duration))

    return stats
end

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

return M
