#!/bin/bash

# Read input (transcription output) from stdin
input=$(cat)

# Strip ALL leading and trailing whitespace, including newlines, carriage returns, tabs, and spaces
trimmed=$(echo "$input" | tr -d '\r' | awk 'NF { gsub(/^[ \t]+|[ \t]+$/, ""); print }')

# Output the result without adding any newlines
printf "%s" "$trimmed"


# TODO:
#I want to measure the number of characters and words that are produced here and I also want to look at the length of the audio recording that would be located in the root temp directory recording.wave.
# I can then store these in some SQLite database or even in just a text file or a JSON file just so that we have some data there. I think it'd be cool to have like a per day kind of values or yeah, probably just per day value. I want to be able to have just general statistics. I think that'd be pretty cool to have. Definitely do some efficiency numbers.

# Testing, testing. Oh, yeah. Well, that's not that great. We need to move that over a bit in the OSX (notifications). And I'll sit on the other side and the left side.
