#!/bin/bash

# Read input (transcription output) from stdin
input=$(cat)

# Strip ALL leading and trailing whitespace, including newlines, carriage returns, tabs, and spaces
trimmed=$(echo "$input" | tr -d '\r' | awk 'NF { gsub(/^[ \t]+|[ \t]+$/, ""); print }')

# Log transcription statistics to SQLite database
log_transcription_stats() {
    local trimmed="$1"
    local db_file="transcription_stats.db"

    # Get character and word counts from trimmed output
    local char_count=${#trimmed}
    local word_count=$(echo "$trimmed" | wc -w | tr -d ' ')

    # Get audio length in seconds using ffprobe (default to 0 if not found)
    local audio_length=0
    if [ -f "/tmp/recorded_audio.wav" ]; then
        # Use bc for floating point math and format with 6 decimal places
        audio_length=$(/opt/homebrew/bin/ffprobe -i /tmp/recorded_audio.wav -show_entries format=duration -v quiet -of csv="p=0" 2>/dev/null || echo 0)
    fi

    # Create database and table if they don't exist
    if [ ! -f "$db_file" ]; then
        sqlite3 "$db_file" "CREATE TABLE transcriptions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            characters INTEGER NOT NULL,
            words INTEGER NOT NULL,
            audio_length_seconds REAL NOT NULL
        );"
    fi

    # Insert stats into database
    sqlite3 "$db_file" "INSERT INTO transcriptions (characters, words, audio_length_seconds)
        VALUES ($char_count, $word_count, $audio_length);"
}

# Log the stats for this transcription
log_transcription_stats "$trimmed"

# Output the result without adding any newlines
printf "%s" "$trimmed"
