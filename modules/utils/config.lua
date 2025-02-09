local config = {
    promptsDir = hs.spoons.scriptPath() .. "../../prompts",
    transcriptionStatsDatabase = hs.spoons.scriptPath() .. "../../transcription_stats.sqlite",
    handleTranscribingScript = hs.spoons.scriptPath() .. "../../handle_transcribing.sh",
    handleRecordingScript = hs.spoons.scriptPath() .. "../../handle_recording.sh",
    handlePromptingScript = hs.spoons.scriptPath() .. "../../handle_prompting.sh"
}

return config
