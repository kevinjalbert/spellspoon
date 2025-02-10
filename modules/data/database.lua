local M = {}

local Logger = require("utils.logger")
local Config = require("utils.config")

-- Helper function to execute SQLite queries
function M:executeQuery(query, skipSchemaCheck)
    local sqlite = hs.sqlite3.open(Config.transcriptionStatsDatabase)
    local success = false
    local result = {}
    local stmt

    if not sqlite then
        Logger.log("error", "Failed to open transcription stats database: " .. Config.transcriptionStatsDatabase)
        return nil
    end

    -- Prepare and execute the statement
    success, stmt = pcall(function()
        return sqlite:prepare(query)
    end)

    if not success or not stmt then
        Logger.log("error", "Failed to prepare SQL statement: " .. tostring(stmt))
        sqlite:close()
        return nil
    end

    -- Step through results
    while stmt:step() == hs.sqlite3.ROW do
        local row = stmt:get_values()
        table.insert(result, row)
    end

    stmt:finalize()
    sqlite:close()

    -- For single row results, return just the row
    if #result == 1 then
        return result[1]
    elseif #result == 0 then
        -- For empty results from INSERT/CREATE queries
        return true
    end
    return result
end

-- Helper function to ensure database is ready
function M:ensureDatabase()
    Logger.log("debug", "Ensuring database exists and has correct schema")

    -- Try to open the database
    local sqlite = hs.sqlite3.open(Config.transcriptionStatsDatabase)
    if not sqlite then
        Logger.log("debug", "Database doesn't exist, initializing...")
        return self:initializeDatabase()
    end
    sqlite:close()

    -- Check if the transcriptions table exists
    local check_query = [[
        SELECT COUNT(*) FROM sqlite_master
        WHERE type='table' AND name='transcriptions';
    ]]

    local result = self:executeQuery(check_query, true)
    if not result then
        Logger.log("warning", "Failed to check schema, reinitializing...")
        return self:initializeDatabase()
    end

    -- Convert result to number
    local count = tonumber(result[1])
    Logger.log("debug", "Schema check result: " .. tostring(count))

    -- If count is 0, the table doesn't exist
    if count == 0 then
        Logger.log("debug", "No tables found, initializing database...")
        return self:initializeDatabase()
    end

    return true
end

-- Initialize the SQLite database schema
function M:initializeDatabase()
    Logger.log("debug", "Initializing statistics database")
    Logger.log("debug", "Database path: " .. Config.transcriptionStatsDatabase)

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
    local success = self:executeQuery(create_table_query)
    if not success then
        Logger.log("error", "Failed to create transcriptions table")
        return false
    end

    success = self:executeQuery(create_index_query)
    if not success then
        Logger.log("error", "Failed to create index on created_at")
        return false
    end

    Logger.log("debug", "Successfully initialized statistics database")
    return true
end

function M:insertTranscriptionStats(charCount, wordCount, audioLength)
    -- Ensure database is ready before inserting
    if not self:ensureDatabase() then
        Logger.log("error", "Failed to ensure database is ready")
        return false
    end

    -- Insert stats into SQLite database
    local query = string.format(
        "INSERT INTO transcriptions (created_at, characters, words, audio_length_seconds) VALUES (datetime('now', 'localtime'), %d, %d, %f);",
        charCount, wordCount, audioLength
    )
    return self:executeQuery(query)
end

-- Get stats for a specific time filter
function M:getStatsForTimeFilter(timeFilter)
    -- Ensure database is ready before querying
    if not self:ensureDatabase() then
        Logger.log("error", "Failed to ensure database is ready")
        return nil
    end

    local query = string.format([[
        SELECT
            COUNT(*) as count,
            COALESCE(SUM(characters), 0) as total_chars,
            COALESCE(SUM(words), 0) as total_words,
            COALESCE(SUM(audio_length_seconds), 0) as total_duration
        FROM transcriptions
        WHERE %s;
    ]], timeFilter)

    local result = self:executeQuery(query)
    if not result then
        Logger.log("error", "Failed to get stats")
        return nil
    end

    -- Result should be a table with values in order: count, chars, words, duration
    return {
        count = tonumber(result[1]) or 0,
        characters = tonumber(result[2]) or 0,
        words = tonumber(result[3]) or 0,
        duration = tonumber(result[4]) or 0
    }
end

return M
