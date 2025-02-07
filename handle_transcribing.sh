#!/bin/bash

source .env

# Default values
MODEL_PATH="$HOME/Downloads/ggml-large-v3-turbo-q5_0.bin"
INPUT_FILE="/tmp/recorded_audio.wav"

# Use whisper-cli to transcribe the audio
/opt/homebrew/bin/whisper-cli \
  --no-prints \
  --no-timestamps \
  --model "$MODEL_PATH" \
  -f "$INPUT_FILE"
