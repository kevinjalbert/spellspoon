local M = {}
local fuzzy_matcher = require("menu.fuzzy_matcher")
local prompt_reader = require("prompt.prompt_reader")
local prompt_processor = require("prompt.prompt_processor")

local Logger = require("utils.logger")
local Config = require("utils.config")
local Indicator = require("ui.indicator")

-- Menu state
M.menuChoices = {}
M.prompts = {}
M.escHotkey = nil

-- Function to refresh menu options based on available prompt files
function M:refreshMenuOptions()
    self.menuChoices = {}
    self.prompts = {}

    local promptsDir = Config.promptsDir
    local iter, dir_obj = hs.fs.dir(promptsDir)
    local files = {}

    -- First collect all filenames
    if iter then
        for file in iter, dir_obj do
            if file:match("%.sh$") then
                table.insert(files, file)
            end
        end
        dir_obj:close()
    end

    -- Sort filenames alphanumerically
    table.sort(files)

    -- Process files in sorted order
    for _, file in ipairs(files) do
        local promptData = prompt_reader:readPromptFile(promptsDir .. "/" .. file)
        if promptData then
            table.insert(self.menuChoices, {
                text = promptData.title,
                subText = ""  -- Empty string for no subtext
            })
            self.prompts[promptData.title] = promptData.path  -- Store the script path instead of prompt content
        end
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
    Logger.log("debug", "Showing menu with transcript")

    -- Clean up recording indicator immediately when showing menu
    Indicator:cleanup()

    -- Create a chooser with our menu options
    local chooser = hs.chooser.new(function(choice)
        Logger.log("debug", "Menu choice made: " .. (choice and choice.text or "cancelled"))

        -- Disable the esckey binding if it is still active
        if self.escHotkey ~=nil then
            self.escHotkey:delete()
            self.escHotkey = nil
        end

        if not choice then
            -- User cancelled without selection
            Logger.log("debug", "Menu cancelled")
            return
        end

        -- Get the prompt script path and process with transcript
        local scriptPath = self.prompts[choice.text]
        if scriptPath then
            Logger.log("debug", "Using prompt script: " .. scriptPath)
            prompt_processor:processPromptWithTranscript(scriptPath, transcript)
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
        Logger.log("debug", "Menu escape pressed")
        chooser:hide()

        if self.escHotkey ~=nil then
            self.escHotkey:delete()
            self.escHotkey = nil
        end
    end)

    -- Show the menu
    chooser:show()
end

return M
