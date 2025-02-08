#!/bin/bash

source .env

# Default values
SAMPLE_RATE=16000
CHANNELS=1
OUTPUT_FILE="/tmp/recorded_audio.wav"
INPUT_DEVICE=":default"  # Default input device for system audio on macOS

# Use ffmpeg to record system audio
/opt/homebrew/bin/ffmpeg -y \
  -f avfoundation \
  -i "$INPUT_DEVICE" \
  -ar "$SAMPLE_RATE" \
  -ac "$CHANNELS" \
  "$OUTPUT_FILE"
