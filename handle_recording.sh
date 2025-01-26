#!/bin/bash

# Default values
SAMPLE_RATE=16000
CHANNELS=1
OUTPUT_FILE="/tmp/recorded_audio.wav"
INPUT_DEVICE=":4"  # Default input device for system audio on macOS
# TODO: Add a way to select the input device, from a env or better with a name

# Use ffmpeg to record system audio
/opt/homebrew/bin/ffmpeg -y \
  -f avfoundation \
  -i "$INPUT_DEVICE" \
  -ar "$SAMPLE_RATE" \
  -ac "$CHANNELS" \
  "$OUTPUT_FILE"
