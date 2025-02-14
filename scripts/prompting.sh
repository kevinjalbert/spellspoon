#!/bin/bash

source ~/.hammerspoon/Spoons/spellspoon.spoon/.env

# Read input from stdin
input=$(cat)

# Prepare the JSON payload
json=$(/opt/homebrew/bin/jq -n --arg content "$input" --arg model "$AI_MODEL" '{
    model: $model,
    messages: [{role: "user", content: $content}],
    temperature: 0.7
}')

# Make the API request
response=$(curl -s -X POST "$AI_API_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AI_API_KEY" \
    -d "$json")

# Extract and output just the message content
content=$(/opt/homebrew/bin/jq -r '.choices[0].message.content' <<<"$response")
printf "%s" "$content"
