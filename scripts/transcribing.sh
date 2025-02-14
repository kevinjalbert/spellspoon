#!/bin/bash

source ~/.hammerspoon/Spoons/spellspoon.spoon/.env

INPUT_FILE="/tmp/recorded_audio.wav"

# Example usage with whisper-cli to transcribe the audio
# MODEL_PATH="$HOME/Downloads/ggml-large-v3-turbo-q5_0.bin"
# /opt/homebrew/bin/whisper-cli \
#   --no-prints \
#   --no-timestamps \
#   --model "$MODEL_PATH" \
#   -f "$INPUT_FILE"

# Upload the file for transcription (using an API like OpenAI)
response=$(curl -s -X POST "$AI_API_URL/audio/transcriptions" \
    -H "Authorization: Bearer $AI_API_KEY" \
    -H "Content-Type: multipart/form-data" \
    -F "file=@$INPUT_FILE" \
    -F "model=whisper-1")

# Extract and display the transcription result
transcription=$(echo "$response" | /opt/homebrew/bin/jq -r '.text')
echo "$transcription"
