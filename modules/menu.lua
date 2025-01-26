local M = {}

-- Menu state
M.menuChoices = {
    { text = "Menu Option 1", subText = "Description for option 1" },
    { text = "Menu Option 2", subText = "Description for option 2" },
    { text = "Menu Option 3", subText = "Description for option 3" }
}

M.escHotkey = nil

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
    if self.escHotkey then
        self.escHotkey:delete()
        self.escHotkey = nil
    end
end

function M:showMenu(transcript)
    self.logger.d("Showing menu with transcript")

    -- Create a chooser with our menu options
    local chooser = hs.chooser.new(function(choice)
        self.logger.d("Menu choice made: " .. (choice and choice.text or "cancelled"))
        self:cleanup() -- Clean up menu-specific state

        if not choice then
            -- User cancelled without selection, clean up UI
            self.logger.d("Menu cancelled, cleaning up UI")
            if self.parent and self.parent.ui then
                self.parent.ui:cleanup()
            end
            return
        end

        -- TODO: Handle the selected choice
        self.logger.d("Selected menu option: " .. choice.text)
        -- Here we'll eventually handle different prompt files

        -- Clean up UI before handling the selection
        if self.parent and self.parent.ui then
            self.parent.ui:cleanup()
        end

        -- For now, just paste the transcript after menu selection
        self:handleClipboardPaste(transcript)
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
        self:cleanup()
        -- Clean up the UI since we're cancelling
        if self.parent and self.parent.ui then
            self.parent.ui:cleanup()
        end
    end)

    -- Set callback for when menu is actually shown
    chooser:showCallback(function()
        self.logger.d("Menu actually shown, cleaning up processing UI")
        if self.parent and self.parent.ui then
            self.parent.ui:cleanup()
        end
    end)

    -- Show the menu
    chooser:show()
    self.logger.d("Menu show command issued")
end

-- Function to refresh menu options based on available prompt files
function M:refreshMenuOptions()
    -- TODO: Implement scanning for prompt files and updating menuChoices
    -- For now, we're using static options
end

return M
