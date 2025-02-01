local M = {}

-- Fuzzy finding helper function
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

return M
