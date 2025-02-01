#!/bin/bash
# Convert to Bullet Points

# Read the transcript from stdin
read -r transcript

# Output the full prompt
cat << EOF
Transform the following text into clear, organized bullet points, highlighting the key information and maintaining a logical flow:
$transcript
EOF
