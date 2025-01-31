local M = {}

-- Menu state
M.menuChoices = {}
M.prompts = {}
M.escHotkey = nil

-- Function to read and parse a prompt file
function M:readPromptFile(filename)
    self.logger.d("Reading prompt file: " .. filename)
    local file = io.open(filename, "r")
    if not file then
        self.logger.w("Failed to open prompt file: " .. filename)
        return nil
    end

    local title = file:read("*line")
    local prompt = file:read("*all")
    file:close()

    if title and prompt then
        self.logger.d("Loaded prompt file " .. filename .. ":\nTitle: " .. title .. "\nPrompt: " .. prompt)
        return {
            title = title,
            prompt = prompt:gsub("^%s+", ""):gsub("%s+$", "") -- Trim whitespace
        }
    end
    self.logger.w("Invalid prompt file format: " .. filename)
    return nil
end

-- Function to refresh menu options based on available prompt files
function M:refreshMenuOptions()
    self.menuChoices = {}
    self.prompts = {}

    local promptsDir = hs.spoons.scriptPath() .. "../prompts"
    local iter, dir_obj = hs.fs.dir(promptsDir)
    local files = {}

    -- First collect all filenames
    if iter then
        for file in iter, dir_obj do
            if file:match("%.txt$") then
                table.insert(files, file)
            end
        end
        dir_obj:close()
    end

    -- Sort filenames alphanumerically
    table.sort(files)

    -- Process files in sorted order
    for _, file in ipairs(files) do
        local promptData = self:readPromptFile(promptsDir .. "/" .. file)
        if promptData then
            table.insert(self.menuChoices, {
                text = promptData.title,
                subText = ""  -- Empty string for no subtext
            })
            self.prompts[promptData.title] = promptData.prompt
        end
    end
end

-- Fuzzy finding helper functions
function M:fuzzyMatch(str, pattern)
    -- Convert to lowercase for case-insensitive matching
    str = str:lower()
    pattern = pattern:lower()

    local score = 0
    local currentPos = 1
    local consecutiveMatches = 0
    local lastMatchIndex = 0

    -- Match each character in the pattern
    for i = 1, #pattern do
        local c = pattern:sub(i,i)
        local found = false

        -- Look for the character in the remaining string
        for j = currentPos, #str do
            if str:sub(j,j) == c then
                -- Found a match
                found = true
                currentPos = j + 1

                -- Increase score based on match quality
                if lastMatchIndex and j == lastMatchIndex + 1 then
                    -- Consecutive matches are worth more
                    consecutiveMatches = consecutiveMatches + 1
                    score = score + (consecutiveMatches * 2)
                else
                    consecutiveMatches = 1
                    score = score + 1
                end

                -- Bonus for matching at start of word
                if j == 1 or str:sub(j-1,j-1) == " " then
                    score = score + 3
                end

                lastMatchIndex = j
                break
            end
        end

        if not found then
            return 0
        end
    end

    -- Bonus for matching higher percentage of the string
    score = score * (pattern:len() / str:len())

    return score
end

function M:filterChoices(choices, query)
    if not query or query == "" then
        return choices
    end

    local results = {}
    for _, choice in ipairs(choices) do
        local textScore = self:fuzzyMatch(choice.text, query)
        local subTextScore = self:fuzzyMatch(choice.subText, query)
        local score = math.max(textScore, subTextScore)

        if score > 0 then
            table.insert(results, {
                text = choice.text,
                subText = choice.subText,
                score = score
            })
        end
    end

    -- Sort by score
    table.sort(results, function(a, b) return a.score > b.score end)

    -- Remove scores before returning
    for _, result in ipairs(results) do
        result.score = nil
    end

    return results
end

function M:handleClipboardPaste(text)
    hs.pasteboard.setContents(text) -- Store processed transcription in clipboard

    -- Check if there's an active text field before attempting to paste
    local focused = hs.uielement.focusedElement()
    local shouldPaste = false

    if focused then
        local success, role = pcall(function() return focused:role() end)
        if success and role then
            shouldPaste = (role == "AXTextField" or role == "AXTextArea")
        end
    end

    if shouldPaste then
        hs.eventtap.keyStroke({"cmd"}, "v")
    else
        hs.alert.show("Transcription copied to clipboard")
    end
end

function M:cleanup()
    -- Clean up UI
    if self.parent and self.parent.ui then
        self.parent.ui:cleanup()
    end
end

function M:showMenu(transcript)
    self:refreshMenuOptions() -- Refresh menu options before showing
    self.logger.d("Showing menu with transcript")

    -- Clean up UI immediately when showing menu
    if self.parent and self.parent.ui then
        self.parent.ui:cleanup()
    end

    -- Create a chooser with our menu options
    local chooser = hs.chooser.new(function(choice)
        self.logger.d("Menu choice made: " .. (choice and choice.text or "cancelled"))
        -- Clean up menu-specific state

        if not choice then
            -- User cancelled without selection
            self.logger.d("Menu cancelled")
            return
        end

        -- Get the prompt template and replace the placeholder
        local promptTemplate = self.prompts[choice.text]
        if promptTemplate then
            self.logger.d("Using prompt template: " .. promptTemplate)
            self:processPromptWithTranscript(promptTemplate, transcript)
        end
    end)

    -- Style the chooser to match the recording indicator
    chooser:bgDark(true)
    chooser:fgColor({ white = 1, alpha = 0.9 })
    chooser:subTextColor({ white = 0.8, alpha = 0.9 })

    -- Configure the chooser with custom fuzzy finding
    chooser:queryChangedCallback(function(query)
        chooser:choices(self:filterChoices(self.menuChoices, query))
    end)

    chooser:choices(self.menuChoices)
    chooser:searchSubText(true) -- Enable searching in descriptions
    chooser:width(400) -- Increased width for better readability
    chooser:rows(#self.menuChoices)

    -- Bind escape key to close menu
    self.escHotkey = hs.hotkey.bind({}, "escape", function()
        self.logger.d("Menu escape pressed")
        chooser:hide()
    end)

    -- Show the menu
    chooser:show()
    self.logger.d("Menu show command issued")
end

function M:processPromptWithTranscript(prompt, transcript)
    self.logger.d("Processing prompt with transcript")
    local scriptPath = hs.spoons.scriptPath() .. "../process_prompt.sh"

    -- Show prompting UI state
    if self.parent and self.parent.ui then
        self.parent.ui:createRecordingIndicator()
        self.parent.ui:setPromptingStatus()
    end

    -- Replace the placeholder in the prompt with the transcript
    local fullPrompt = prompt:gsub("{{TRANSCRIPT}}", transcript)

    -- Create a task to process the prompt
    local task = hs.task.new(scriptPath, function(exitCode, stdOut, stdErr)
        -- Clean up UI after processing is complete
        if self.parent and self.parent.ui then
            self.parent.ui:cleanup()
        end

        if exitCode == 0 and stdOut then
            -- Handle clipboard paste just like in direct mode
            self:handleClipboardPaste(stdOut)
        end
    end)
    task:setInput(fullPrompt)
    task:start()
end

return M
