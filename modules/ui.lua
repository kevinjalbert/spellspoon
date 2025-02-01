local M = {}

M.recordingIndicator = nil
M.pulseTimer = nil
M.processingTimer = nil

function M:createRecordingIndicator()
    local screen = hs.screen.primaryScreen()
    local frame = screen:frame()

    -- Fixed dimensions for the indicator
    local indicatorWidth = 180
    local indicatorHeight = 60

    -- Center horizontally, keep vertical position near top
    local verticalPadding = 24 + 16  -- menu bar + fixed padding
    local xPosition = (frame.w - indicatorWidth) / 2  -- Center horizontally

    local rect = hs.geometry.rect(
        xPosition,
        verticalPadding,
        indicatorWidth,
        indicatorHeight
    )

    self.recordingIndicator = hs.canvas.new(rect)

    -- Add background with modern styling
    self.recordingIndicator[1] = {
        type = "rectangle",
        action = "fill",
        fillColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.75 },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
    }

    -- Add recording indicator dot
    self.recordingIndicator[2] = {
        type = "circle",
        action = "fill",
        fillColor = { red = 1, green = 0, blue = 0, alpha = 0.75 },
        center = { x = 28, y = indicatorHeight / 2 },
        radius = 8,
    }

    -- Add "Recording ..." text
    self.recordingIndicator[3] = {
        type = "text",
        text = "Recording ...",
        textColor = { white = 1, alpha = 0.9 },
        textFont = "AppleSystemUIFont",
        textSize = 14,
        frame = {
            x = 48,
            y = 10,
            w = 120,
            h = 20
        },
    }

    -- Add counter text below "Recording ..."
    self.recordingIndicator[4] = {
        type = "text",
        text = "00:00",
        textColor = { white = 1, alpha = 0.90 },
        textFont = "AppleSystemUIFont",
        textSize = 14,
        frame = {
            x = 48,
            y = 30,
            w = 120,
            h = 20
        },
    }

    -- Function for pulsing animation for the dot
    local function pulseDot()
        if self.recordingIndicator then
            -- Fade out
            hs.timer.doAfter(0, function()
                if self.recordingIndicator then
                    self.recordingIndicator[2].fillColor.alpha = 0.3
                end
            end)
            -- Fade in
            hs.timer.doAfter(0.8, function()
                if self.recordingIndicator then
                    self.recordingIndicator[2].fillColor.alpha = 0.8
                end
            end)
        end
    end

    -- Start pulsing animation
    pulseDot() -- Initial pulse
    self.pulseTimer = hs.timer.doEvery(1.6, pulseDot)
    self.recordingIndicator:show()
end

function M:setStatus(message, dotColor)
    if self.recordingIndicator then
        -- Update modal to display the message
        self.recordingIndicator[3].text = message

        -- Update dot color if provided
        if dotColor then
            self.recordingIndicator[2].fillColor = dotColor
        end
    end
end

function M:setIndicatorStatus(config)
    -- config = {
    --   dotColor = { red = x, green = x, blue = x, alpha = x },
    --   text = "Status text ...",
    --   showTimer = boolean
    -- }

    if not self.recordingIndicator then
        self:createRecordingIndicator()
    end

    -- Update dot color and text
    self:setStatus(config.text, config.dotColor)

    -- Handle timer
    if self.processingTimer then
        self.processingTimer:stop()
        self.processingTimer = nil
    end

    if config.showTimer then
        self.recordingIndicator[4].text = "00:00" -- Reset timer display
        self.processingStartTime = os.time()
        self.processingTimer = hs.timer.doEvery(1, function()
            if self.recordingIndicator then
                local elapsed = os.time() - self.processingStartTime
                local minutes = math.floor(elapsed / 60)
                local seconds = elapsed % 60
                local timeString = string.format("%02d:%02d", minutes, seconds)
                self.recordingIndicator[4].text = timeString
            end
        end)
    else
        self.recordingIndicator[4].text = ""
    end
end

function M:setRecordingStatus()
    self:setIndicatorStatus({
        dotColor = { red = 1, green = 0, blue = 0, alpha = 0.8 },
        text = "Recording ...",
        showTimer = true
    })
end

function M:setTranscribingStatus()
    self:setIndicatorStatus({
        dotColor = { red = 0, green = 0, blue = 1, alpha = 0.8 },
        text = "Transcribing ...",
        showTimer = true
    })
end

function M:setPromptingStatus()
    self:setIndicatorStatus({
        dotColor = { red = 0, green = 1, blue = 0, alpha = 0.8 },
        text = "Prompting ...",
        showTimer = true
    })
end

function M:updateTimer()
    if self.parent.recording.startTime and self.recordingIndicator then
        local elapsed = os.time() - self.parent.recording.startTime
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        local timeString = string.format("%02d:%02d", minutes, seconds)

        self.recordingIndicator[4].text = timeString
    end
end

function M:cleanup()
    self.logger.d("UI cleanup function called")
    -- Stop all timers
    if self.pulseTimer then
        self.pulseTimer:stop()
        self.pulseTimer = nil
    end
    if self.processingTimer then
        self.processingTimer:stop()
        self.processingTimer = nil
    end

    -- Clean up the indicator
    if self.recordingIndicator then
        self.recordingIndicator:delete()
        self.recordingIndicator = nil
    end
end

return M
