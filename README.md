# Spellspoon

Spellspoon is a Hammerspoon Spoon that enables hotkey-driven audio recording, transcription, and text processing. It
provides an efficient way to transcribe voice input and apply customizable prompts to manipulate text before copying it
to the clipboard or pasting it directly.

## Demo

https://github.com/user-attachments/assets/34420500-bd55-4297-a52c-1321ea521650

## Features

- Hotkey-based recording and transcription.
- Customizable shell script pipelines for recording, transcribing, and prompting.
- Flexible text transformation via prompts.
- Supports clipboard copying and direct pasting.
- Tracks transcription statistics (duration, word count, character count).
- Compatible with local and third-party transcription services.

## Installation

Clone the repository and place the `spellspoon.spoon` directory inside `~/.hammerspoon/Spoons/`:

```sh
git clone https://github.com/kevinjalbert/spellspoon.git ~/.hammerspoon/Spoons/spellspoon.spoon
```

## Configuration

Example setup in Hammerspoon:

```lua
local spellspoon = hs.loadSpoon("spellspoon")

spellspoon:setConfig({
    promptsDirectory = "~/.spellspoon/prompts",
    transcriptionStatsDatabase = "~/.spellspoon/transcription_stats.sqlite",
    transcribingScript = "~/.spellspoon/transcribing.sh",
    recordingScript = "~/.spellspoon/recording.sh",
    promptingScript = "~/.spellspoon/prompting.sh",
    logLevel = "debug"
})

spellspoon:bindHotkeys({
    recordWithDefaultPrompt = {{"cmd", "alt", "ctrl", "shift"}, "["},
    recordWithPromptSelection = {{"cmd", "alt", "ctrl", "shift"}, "]"},
    useSelectedTextWithPromptSelection = {{"cmd", "alt", "ctrl", "shift"}, "="},
    showStatsModal = {{"cmd", "alt", "ctrl", "shift"}, "-"}
})
```

## High-level Overview

![](spellspoon.excalidraw.png)

## Customization

### Prompt Scripts

TODO: Add details

### Operational Scripts

TODO: Add details
