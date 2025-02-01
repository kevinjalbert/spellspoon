#!/bin/bash
# Summarize Text

# Read the transcript from stdin
read -r transcript

# Output the full prompt
cat << EOF
Create a concise summary of the following text, capturing the main points and key ideas:
$transcript
EOF
