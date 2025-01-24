#!/bin/bash

# Read input (transcription output) from stdin
input=$(cat)

# Strip ALL leading and trailing whitespace, including newlines, carriage returns, tabs, and spaces
trimmed=$(echo "$input" | tr -d '\r' | awk 'NF { gsub(/^[ \t]+|[ \t]+$/, ""); print }')

# Output the result without adding any newlines
printf "%s" "$trimmed"
