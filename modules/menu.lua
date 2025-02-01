local M = {}
local fuzzy_matcher = require("fuzzy_matcher")
local prompt_reader = require("prompt_reader")
local prompt_processor = require("prompt_processor")

-- Menu state
M.menuChoices = {}
M.prompts = {}
M.escHotkey = nil

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
        local promptData = prompt_reader:readPromptFile(promptsDir .. "/" .. file, self.logger)
        if promptData then
            table.insert(self.menuChoices, {
                text = promptData.title,
                subText = ""  -- Empty string for no subtext
            })
            self.prompts[promptData.title] = promptData.prompt
        end
    end
end

function M:cleanup()
    -- Clean up UI
    if self.parent and self.parent.ui then
        self.parent.ui:cleanup()
    end
end

function M:handleClipboardPaste(text)
    if text then
        -- Copy the text to the clipboard
        hs.pasteboard.setContents(text)

        -- Simulate cmd+v to paste
        hs.eventtap.keyStroke({"cmd"}, "v")
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
            prompt_processor:processPromptWithTranscript(promptTemplate, transcript, self.logger, self.parent and self.parent.ui)
        end
    end)

    -- Style the chooser to match the recording indicator
    chooser:bgDark(true)
    chooser:fgColor({ white = 1, alpha = 0.9 })
    chooser:subTextColor({ white = 0.8, alpha = 0.9 })

    -- Configure the chooser with custom fuzzy finding
    chooser:queryChangedCallback(function(query)
        chooser:choices(fuzzy_matcher:filterChoices(self.menuChoices, query))
    end)

    chooser:choices(self.menuChoices)
    chooser:searchSubText(true) -- Enable searching in descriptions
    chooser:width(400) -- Increased width for better readability
    chooser:rows(#self.menuChoices)

    -- Bind escape key to close menu
    self.escHotkey = hs.hotkey.bind({}, "escape", function()
        self.logger.d("Menu escape pressed")
        chooser:hide()
        self.escHotkey:delete()
    end)

    -- Show the menu
    chooser:show()
    self.logger.d("Menu show command issued")
end

return M
