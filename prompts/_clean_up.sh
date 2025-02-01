#!/bin/bash
# Clean Up Text

# Read the transcript from stdin
read -r transcript

# Output the full prompt
cat << EOF
Please clean up and polish the following text, fixing any grammar, punctuation, and formatting issues. The text must stay pretty much verbatim:
$transcript
EOF
