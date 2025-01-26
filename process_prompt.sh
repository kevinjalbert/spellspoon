#!/bin/bash
set -x

# Source environment variables from .env file
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
fi

# Read input from stdin
input=$(cat)

# Validate environment variables and set defaults
if [ -z "$WHISTION_API_KEY" ]; then
    echo "Error: WHISTION_API_KEY environment variable must be set" >&2
    exit 1
fi

if [ -z "$WHISTION_API_URL" ]; then
    WHISTION_API_URL="https://api.openai.com/v1/"
fi

if [ -z "$WHISTION_MODEL" ]; then
  echo "Error: WHISTION_MODEL environment variable must be set" >&2
  exit 1
fi

# Prepare the JSON payload
json=$(/opt/homebrew/bin/jq -n --arg content "$input" --arg model "$WHISTION_MODEL" '{
    model: $model,
    messages: [{role: "user", content: $content}],
    temperature: 0.7
}')

# Make the API request
response=$(curl -s -X POST "$WHISTION_API_URL/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $WHISTION_API_KEY" \
    -d "$json")

# Check for API errors
if /opt/homebrew/bin/jq -e .error <<<"$response" >/dev/null; then
    echo "API Error: $(/opt/homebrew/bin/jq -r .error.message <<<"$response")" >&2
    exit 1
fi

# Extract and output just the message content, then trim whitespace
content=$(/opt/homebrew/bin/jq -r '.choices[0].message.content' <<<"$response")
trimmed=$(echo "$content" | tr -d '\r' | awk 'NF { gsub(/^[ \t]+|[ \t]+$/, ""); print }')
printf "%s" "$trimmed"
