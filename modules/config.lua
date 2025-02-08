-- TODO: Make it so this can be set by the user using the .env file, or a config file that is loaded at startup, use defaults if not set

local config = {
    promptsDir = hs.spoons.scriptPath() .. "../prompts",
    handleTranscribingScript = hs.spoons.scriptPath() .. "../handle_transcribing.sh",
    handleTranscriptionCleaningScript = hs.spoons.scriptPath() .. "../handle_transcription_cleaning.sh",
    handleRecordingScript = hs.spoons.scriptPath() .. "../handle_recording.sh",
    handlePromptingScript = hs.spoons.scriptPath() .. "../handle_prompting.sh"
}

return config
