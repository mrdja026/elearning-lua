-- AI Story Wizard Module
-- 6-step modal wizard for AI-powered story generation
-- Mirrors the e2eADKFlow.sh interactive flow

local Tokens = require("ui.tokens")

local wizard = {}

-- Text input state for custom input handling
local textInputState = {
    focused = nil,  -- Which input is focused ("topic", "hint1", "hint2", etc.)
    cursorBlink = 0
}

-- Wizard state
local state = {
    isOpen = false,
    step = 1,  -- 1-6: input steps, 7: generating
    data = {
        topic = "",
        artStyle = "pixel",
        targetAge = "8-12",
        pageCount = 3,
        pageHints = {}
    },
    generating = false,
    generationPhase = "",
    generationProgress = { current = 0, total = 0 },
    funnyMessage = "",
    funnyMessageTimer = 0,
    error = nil,
    thread = nil,
    onComplete = nil  -- Callback when generation completes
}

-- Art style options (matches e2eADKFlow.sh)
local ART_STYLES = {"pixel", "fantasy", "cartoon"}
local ART_STYLE_DESCRIPTIONS = {
    pixel = "Pixel art style with retro 8-bit aesthetics",
    fantasy = "Magical fantasy style with rich colors and detail",
    cartoon = "Playful cartoon style with bold outlines"
}

-- Target age options (matches e2eADKFlow.sh)
local TARGET_AGES = {"5-8", "8-12", "13-17", "18+", "all"}
local TARGET_AGE_DESCRIPTIONS = {
    ["5-8"] = "Early readers - simple vocabulary, short sentences",
    ["8-12"] = "Middle grade - more complex topics, longer narratives",
    ["13-17"] = "Young adult - sophisticated themes and language",
    ["18+"] = "Adult - no content restrictions",
    ["all"] = "All ages - family-friendly content"
}

-- Absurd life advice messages (rotates during generation)
local FUNNY_MESSAGES = {
    "Never trust a penguin with your WiFi password",
    "If life gives you lemons, check for hidden cameras",
    "Always keep a spare sock in your pocket. You never know.",
    "The best time to plant a tree was 20 years ago. The second best time is after this story generates.",
    "Remember: dolphins are just wet dogs with degrees",
    "Pro tip: You can't be late if you never show up",
    "Studies show 87% of statistics are made up on the spot",
    "If at first you don't succeed, blame the compiler",
    "Your future self is watching you through memories. Wave hello.",
    "Never make eye contact with a goat. They remember.",
    "Always salt your pasta water. It's the law in Italy.",
    "The moon is just the sun's night shift worker",
    "Never argue with a duck about economics",
    "If you're ever lost, just follow the cats. They know things.",
    "Today's weather: 100% chance of existence",
    "Remember to hydrate. Water is just boneless ice.",
    "The early bird gets the worm, but the second mouse gets the cheese",
    "Always trust your gut, unless it says 'eat the whole pizza'",
    "Time flies like an arrow. Fruit flies like a banana.",
    "Your shoelaces are judging you right now",
    "Somewhere, a squirrel is forgetting where it buried your socks",
    "The WiFi password is hidden in your heart",
    "Never pet a burning dog",
    "If you can dodge a wrench, you can dodge responsibility"
}

local STEP_TITLES = {
    "What's the Topic?",
    "Choose Art Style",
    "Select Target Age",
    "How Many Pages?",
    "Add Page Hints",
    "Review & Generate"
}

local STEP_DESCRIPTIONS = {
    "Enter a topic for your story. This will be used to generate educational content.\nExamples: 'why is the sky blue', 'how computers work', 'basic python programming'",
    "Choose the visual style for your story's images.",
    "Select the age group this story is designed for.",
    "How many pages should your story have? (1-5)",
    "Optionally add hints for each page. These guide the visual metaphors.\nLeave empty for AI-generated suggestions.",
    "Review your choices and generate your story!"
}

function wizard.init()
    state.funnyMessage = FUNNY_MESSAGES[math.random(#FUNNY_MESSAGES)]
end

function wizard.open(onCompleteCallback)
    state.isOpen = true
    state.step = 1
    state.generating = false
    state.generationPhase = ""
    state.error = nil
    state.onComplete = onCompleteCallback

    -- Reset data
    state.data = {
        topic = "",
        artStyle = "pixel",
        targetAge = "8-12",
        pageCount = 3,
        pageHints = {}
    }

    -- Initialize page hints array
    for i = 1, 5 do
        state.data.pageHints[i] = ""
    end
end

function wizard.close()
    state.isOpen = false
    state.generating = false

    -- Stop thread if running
    if state.thread and state.thread:isRunning() then
        local requestChannel = love.thread.getChannel("wizard_request")
        requestChannel:push("quit")
    end
end

function wizard.isOpen()
    return state.isOpen
end

function wizard.isGenerating()
    return state.generating
end

function wizard.update(dt)
    if not state.isOpen then return end

    -- Update cursor blink
    textInputState.cursorBlink = textInputState.cursorBlink + dt
    if textInputState.cursorBlink >= 1 then
        textInputState.cursorBlink = 0
    end

    -- Rotate funny messages during generation
    if state.generating then
        state.funnyMessageTimer = state.funnyMessageTimer + dt
        if state.funnyMessageTimer >= 3 then
            state.funnyMessageTimer = 0
            state.funnyMessage = FUNNY_MESSAGES[math.random(#FUNNY_MESSAGES)]
        end

        -- Check for thread responses
        local responseChannel = love.thread.getChannel("wizard_response")
        local response = responseChannel:pop()

        if response then
            print("[Wizard] Received response type: " .. (response.type or "nil"))

            if response.type == "progress" then
                state.generationPhase = response.phase
                print("[Wizard] Progress: " .. (response.phase or "unknown"))
                if response.current then
                    state.generationProgress.current = response.current
                end
                if response.total then
                    state.generationProgress.total = response.total
                end
            elseif response.type == "error" then
                print("[Wizard] ERROR: " .. (response.message or "unknown"))
                state.generating = false
                state.error = response.message
                state.step = 6  -- Go back to review step
            elseif response.type == "complete" then
                print("[Wizard] Generation complete!")
                if response.story then
                    print("[Wizard] Story title: " .. (response.story.title or "nil"))
                    print("[Wizard] Story pages: " .. (response.story.pages and #response.story.pages or 0))
                end
                state.generating = false
                state.isOpen = false
                if state.onComplete and response.story then
                    print("[Wizard] Calling onComplete callback...")
                    state.onComplete(response.story)
                else
                    print("[Wizard] WARNING: No onComplete callback or no story!")
                end
            end
        end

        -- Check for thread errors
        if state.thread then
            local threadError = state.thread:getError()
            if threadError then
                print("[Wizard] THREAD ERROR: " .. threadError)
                state.generating = false
                state.error = "Thread error: " .. threadError
                state.step = 6
            end
        end
    end
end

function wizard.draw()
    if not state.isOpen then return end

    local winW, winH = love.graphics.getDimensions()
    local dialogW, dialogH = 500, 450
    local dialogX = (winW - dialogW) / 2
    local dialogY = (winH - dialogH) / 2

    -- Draw dark overlay
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, winW, winH)

    -- Draw dialog background
    love.graphics.setColor(0.12, 0.12, 0.15, 1)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogW, dialogH, 10)

    -- Draw dialog border
    love.graphics.setColor(0.4, 0.5, 0.7, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX, dialogY, dialogW, dialogH, 10)
    love.graphics.setLineWidth(1)

    -- Draw title bar
    love.graphics.setColor(0.18, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", dialogX, dialogY, dialogW, 45, 10)

    -- Title
    love.graphics.setColor(0.9, 0.85, 0.7, 1)
    love.graphics.print("AI Story Generator", dialogX + 20, dialogY + 12)

    -- Step indicator (not shown during generation)
    if not state.generating then
        local stepText = string.format("Step %d/6", state.step)
        local font = love.graphics.getFont()
        local stepTextW = font:getWidth(stepText)
        love.graphics.setColor(0.6, 0.6, 0.7, 1)
        love.graphics.print(stepText, dialogX + dialogW - stepTextW - 20, dialogY + 14)
    end

    -- Content area
    local contentX = dialogX + 25
    local contentY = dialogY + 55
    local contentW = dialogW - 50

    if state.generating then
        wizard.drawGeneratingPhase(contentX, contentY, contentW, dialogH - 65)
    else
        wizard.drawInputStep(contentX, contentY, contentW)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function wizard.drawGeneratingPhase(x, y, w, h)
    local centerX = x + w / 2
    local centerY = y + h / 2

    -- Title
    love.graphics.setColor(1, 1, 1, 1)
    local title = "Creating Your Story..."
    local font = love.graphics.getFont()
    local titleW = font:getWidth(title)
    love.graphics.print(title, centerX - titleW / 2, y + 30)

    -- Spinner animation (simple rotating dots)
    local time = love.timer.getTime()
    for i = 0, 7 do
        local angle = (i / 8) * math.pi * 2 + time * 2
        local dotX = centerX + math.cos(angle) * 30
        local dotY = centerY - 40 + math.sin(angle) * 30
        local alpha = 0.3 + 0.7 * ((i / 8 + time * 0.3) % 1)
        love.graphics.setColor(0.5, 0.7, 0.9, alpha)
        love.graphics.circle("fill", dotX, dotY, 5)
    end

    -- Funny message (prominently displayed)
    love.graphics.setColor(0.9, 0.8, 0.5, 1)
    local msgLines = wizard.wrapText('"' .. state.funnyMessage .. '"', w - 40)
    local lineY = centerY + 20
    for _, line in ipairs(msgLines) do
        local lineW = font:getWidth(line)
        love.graphics.print(line, centerX - lineW / 2, lineY)
        lineY = lineY + 20
    end

    -- Phase indicator
    love.graphics.setColor(0.6, 0.6, 0.7, 1)
    local phaseLabels = {
        starting = "Starting session...",
        enhancing = "Enhancing story prompt...",
        cover = "Generating cover image...",
        pages = "Generating page images...",
        downloading = "Downloading images..."
    }
    local phaseText = phaseLabels[state.generationPhase] or "Processing..."

    if state.generationPhase == "pages" or state.generationPhase == "downloading" then
        if state.generationProgress.total > 0 then
            phaseText = phaseText .. string.format(" (%d/%d)",
                state.generationProgress.current,
                state.generationProgress.total)
        end
    end

    local phaseW = font:getWidth(phaseText)
    love.graphics.print(phaseText, centerX - phaseW / 2, y + h - 60)

    -- Non-cancelable notice
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    local notice = "Please wait while your story is being created"
    local noticeW = font:getWidth(notice)
    love.graphics.print(notice, centerX - noticeW / 2, y + h - 35)
end

function wizard.drawInputStep(x, y, w)
    local inputW = w - 20

    -- Step title
    love.graphics.setColor(0.85, 0.8, 0.6, 1)
    love.graphics.print(STEP_TITLES[state.step], x, y)

    -- Step description
    love.graphics.setColor(0.6, 0.6, 0.65, 1)
    local descY = y + 30
    local descLines = wizard.wrapText(STEP_DESCRIPTIONS[state.step], w - 20)
    for _, line in ipairs(descLines) do
        love.graphics.print(line, x, descY)
        descY = descY + 18
    end

    -- Content based on step
    local contentY = descY + 20

    if state.step == 1 then
        wizard.drawTopicInput(x, contentY, inputW)
    elseif state.step == 2 then
        wizard.drawArtStyleSelect(x, contentY, inputW)
    elseif state.step == 3 then
        wizard.drawTargetAgeSelect(x, contentY, inputW)
    elseif state.step == 4 then
        wizard.drawPageCountInput(x, contentY, inputW)
    elseif state.step == 5 then
        wizard.drawPageHintsInput(x, contentY, inputW)
    elseif state.step == 6 then
        wizard.drawReviewSummary(x, contentY, inputW)
    end

    -- Error message
    if state.error then
        love.graphics.setColor(0.9, 0.4, 0.4, 1)
        love.graphics.print("Error: " .. state.error, x, contentY + 210)
    end

    -- Navigation buttons
    wizard.drawNavigationButtons(x, y + 340, w)
end

-- Store clickable areas for input fields
local inputAreas = {}

function wizard.drawTextInput(id, x, y, w, h, text)
    local isFocused = textInputState.focused == id

    -- Background
    if isFocused then
        love.graphics.setColor(0.25, 0.25, 0.3, 1)
    else
        love.graphics.setColor(0.18, 0.18, 0.22, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 4)

    -- Border
    if isFocused then
        love.graphics.setColor(0.5, 0.6, 0.8, 1)
    else
        love.graphics.setColor(0.35, 0.35, 0.4, 1)
    end
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, w, h, 4)
    love.graphics.setLineWidth(1)

    -- Text
    love.graphics.setColor(1, 1, 1, 1)
    local displayText = text
    local font = love.graphics.getFont()
    local textY = y + (h - font:getHeight()) / 2

    -- Truncate text if too long
    while font:getWidth(displayText) > w - 16 and #displayText > 0 do
        displayText = displayText:sub(2)
    end

    love.graphics.print(displayText, x + 8, textY)

    -- Cursor
    if isFocused and textInputState.cursorBlink < 0.5 then
        local cursorX = x + 8 + font:getWidth(displayText)
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", cursorX, y + 5, 2, h - 10)
    end

    -- Store clickable area
    inputAreas[id] = {x = x, y = y, w = w, h = h}
end

function wizard.drawButton(x, y, w, h, label, selected, disabled)
    if disabled then
        love.graphics.setColor(0.2, 0.2, 0.22, 0.5)
    elseif selected then
        love.graphics.setColor(0.3, 0.5, 0.6, 1)
    else
        love.graphics.setColor(0.22, 0.22, 0.28, 1)
    end
    love.graphics.rectangle("fill", x, y, w, h, 4)

    -- Border
    if selected then
        love.graphics.setColor(0.5, 0.7, 0.8, 1)
    else
        love.graphics.setColor(0.35, 0.35, 0.4, 1)
    end
    love.graphics.setLineWidth(selected and 2 or 1)
    love.graphics.rectangle("line", x, y, w, h, 4)
    love.graphics.setLineWidth(1)

    -- Text
    love.graphics.setColor(1, 1, 1, disabled and 0.4 or 1)
    local font = love.graphics.getFont()
    local textW = font:getWidth(label)
    love.graphics.print(label, x + (w - textW) / 2, y + (h - font:getHeight()) / 2)

    return {x = x, y = y, w = w, h = h}
end

function wizard.drawTopicInput(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Enter your topic:", x, y)

    wizard.drawTextInput("topic", x, y + 25, w, 35, state.data.topic)

    -- Validation feedback
    local feedbackY = y + 70
    if #state.data.topic > 0 and #state.data.topic < 3 then
        love.graphics.setColor(0.9, 0.5, 0.4, 1)
        love.graphics.print("Topic must be at least 3 characters", x, feedbackY)
    elseif #state.data.topic >= 3 then
        love.graphics.setColor(0.5, 0.8, 0.5, 1)
        love.graphics.print("Topic is valid!", x, feedbackY)
    end
end

function wizard.drawArtStyleSelect(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Select art style:", x, y)

    local btnY = y + 25
    local btnH = 35
    local btnGap = 8

    inputAreas.artStyles = {}

    for i, style in ipairs(ART_STYLES) do
        local isSelected = state.data.artStyle == style
        local label = style:sub(1, 1):upper() .. style:sub(2)

        local area = wizard.drawButton(x, btnY, w, btnH, label, isSelected, false)
        inputAreas.artStyles[i] = {area = area, style = style}

        -- Description below selected
        if isSelected then
            love.graphics.setColor(0.6, 0.7, 0.8, 1)
            love.graphics.print("  " .. ART_STYLE_DESCRIPTIONS[style], x, btnY + btnH + 2)
            btnY = btnY + 18
        end

        btnY = btnY + btnH + btnGap
    end
end

function wizard.drawTargetAgeSelect(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Select target age group:", x, y)

    local btnY = y + 25
    local btnH = 30
    local btnGap = 5

    inputAreas.targetAges = {}

    for i, age in ipairs(TARGET_AGES) do
        local isSelected = state.data.targetAge == age

        local area = wizard.drawButton(x, btnY, w, btnH, age, isSelected, false)
        inputAreas.targetAges[i] = {area = area, age = age}

        if isSelected then
            love.graphics.setColor(0.6, 0.7, 0.8, 1)
            love.graphics.print("  " .. TARGET_AGE_DESCRIPTIONS[age], x, btnY + btnH + 2)
            btnY = btnY + 16
        end

        btnY = btnY + btnH + btnGap
    end
end

function wizard.drawPageCountInput(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Number of pages (1-5):", x, y)

    local btnW = 50
    local btnH = 45
    local centerX = x + w / 2

    -- Minus button
    local minusArea = wizard.drawButton(centerX - btnW - 40, y + 30, btnW, btnH, "-", false, state.data.pageCount <= 1)
    inputAreas.pageCountMinus = minusArea

    -- Number display
    love.graphics.setColor(0.25, 0.25, 0.3, 1)
    love.graphics.rectangle("fill", centerX - 25, y + 30, 50, btnH, 4)
    love.graphics.setColor(1, 1, 1, 1)
    local font = love.graphics.getFont()
    local numText = tostring(state.data.pageCount)
    love.graphics.print(numText, centerX - font:getWidth(numText) / 2, y + 30 + (btnH - font:getHeight()) / 2)

    -- Plus button
    local plusArea = wizard.drawButton(centerX + 40, y + 30, btnW, btnH, "+", false, state.data.pageCount >= 5)
    inputAreas.pageCountPlus = plusArea

    love.graphics.setColor(0.6, 0.6, 0.65, 1)
    love.graphics.print("Each page will have an AI-generated image", x, y + 95)
end

function wizard.drawPageHintsInput(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Hints for each page (optional):", x, y)

    love.graphics.setColor(0.5, 0.5, 0.55, 1)
    love.graphics.print("Leave empty for AI-generated suggestions", x, y + 18)

    local inputY = y + 45

    for i = 1, state.data.pageCount do
        love.graphics.setColor(0.7, 0.7, 0.75, 1)
        love.graphics.print("Page " .. i .. ":", x, inputY)

        wizard.drawTextInput("hint" .. i, x, inputY + 18, w, 28, state.data.pageHints[i] or "")
        inputY = inputY + 55
    end
end

function wizard.drawReviewSummary(x, y, w)
    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Review your story settings:", x, y)

    local lineY = y + 25

    -- Separator
    love.graphics.setColor(0.4, 0.4, 0.45, 1)
    love.graphics.line(x, lineY, x + w, lineY)
    lineY = lineY + 10

    love.graphics.setColor(0.9, 0.9, 0.95, 1)
    love.graphics.print("Topic: " .. state.data.topic, x, lineY)
    lineY = lineY + 22
    love.graphics.print("Art Style: " .. state.data.artStyle, x, lineY)
    lineY = lineY + 22
    love.graphics.print("Target Age: " .. state.data.targetAge, x, lineY)
    lineY = lineY + 22
    love.graphics.print("Pages: " .. state.data.pageCount, x, lineY)
    lineY = lineY + 30

    -- Separator
    love.graphics.setColor(0.4, 0.4, 0.45, 1)
    love.graphics.line(x, lineY, x + w, lineY)
    lineY = lineY + 10

    love.graphics.setColor(0.8, 0.8, 0.85, 1)
    love.graphics.print("Page Hints:", x, lineY)
    lineY = lineY + 20

    local hasAnyHint = false
    for i = 1, state.data.pageCount do
        local hint = state.data.pageHints[i] or ""
        if hint ~= "" then
            hasAnyHint = true
            love.graphics.setColor(0.7, 0.8, 0.7, 1)
            love.graphics.print("  Page " .. i .. ": " .. hint, x, lineY)
            lineY = lineY + 18
        end
    end

    if not hasAnyHint then
        love.graphics.setColor(0.5, 0.5, 0.55, 1)
        love.graphics.print("  (AI will generate visual metaphors)", x, lineY)
    end
end

function wizard.drawNavigationButtons(x, y, w)
    local btnW = 100
    local btnH = 40
    local btnGap = 20

    -- Back button (disabled on step 1)
    local backX = x
    if state.step > 1 then
        love.graphics.setColor(0.3, 0.3, 0.4, 1)
    else
        love.graphics.setColor(0.2, 0.2, 0.25, 0.5)
    end
    love.graphics.rectangle("fill", backX, y, btnW, btnH, 6)
    love.graphics.setColor(1, 1, 1, state.step > 1 and 1 or 0.4)
    love.graphics.print("Back", backX + 35, y + 12)

    -- Next/Generate button
    local nextX = x + w - btnW
    local isValid = wizard.isCurrentStepValid()

    if state.step == 6 then
        -- Generate button
        if isValid then
            love.graphics.setColor(0.3, 0.6, 0.4, 1)
        else
            love.graphics.setColor(0.2, 0.3, 0.25, 0.5)
        end
        love.graphics.rectangle("fill", nextX, y, btnW, btnH, 6)
        love.graphics.setColor(1, 1, 1, isValid and 1 or 0.4)
        love.graphics.print("Generate", nextX + 22, y + 12)
    else
        -- Next button
        if isValid then
            love.graphics.setColor(0.3, 0.5, 0.7, 1)
        else
            love.graphics.setColor(0.2, 0.25, 0.3, 0.5)
        end
        love.graphics.rectangle("fill", nextX, y, btnW, btnH, 6)
        love.graphics.setColor(1, 1, 1, isValid and 1 or 0.4)
        love.graphics.print("Next", nextX + 35, y + 12)
    end
end

function wizard.isCurrentStepValid()
    if state.step == 1 then
        return #state.data.topic >= 3
    elseif state.step == 2 then
        return state.data.artStyle ~= ""
    elseif state.step == 3 then
        return state.data.targetAge ~= ""
    elseif state.step == 4 then
        return state.data.pageCount >= 1 and state.data.pageCount <= 5
    elseif state.step == 5 then
        return true  -- Hints are optional
    elseif state.step == 6 then
        return wizard.isAllDataValid()
    end
    return true
end

function wizard.isAllDataValid()
    return #state.data.topic >= 3 and
           state.data.artStyle ~= "" and
           state.data.targetAge ~= "" and
           state.data.pageCount >= 1 and
           state.data.pageCount <= 5
end

-- Helper to check if point is in area
local function pointInArea(px, py, area)
    return area and px >= area.x and px <= area.x + area.w and py >= area.y and py <= area.y + area.h
end

function wizard.handleMouseClick(x, y)
    if not state.isOpen or state.generating then return false end

    local winW, winH = love.graphics.getDimensions()
    local dialogW, dialogH = 500, 450
    local dialogX = (winW - dialogW) / 2
    local dialogY = (winH - dialogH) / 2

    -- Check if click is outside dialog (don't close during wizard - it's modal)
    if x < dialogX or x > dialogX + dialogW or y < dialogY or y > dialogY + dialogH then
        return true  -- Consume click but don't close
    end

    -- Button dimensions
    local btnW = 100
    local btnH = 40
    local btnY = dialogY + 395
    local backX = dialogX + 25
    local nextX = dialogX + dialogW - 25 - btnW

    -- Back button click
    if state.step > 1 then
        if x >= backX and x <= backX + btnW and y >= btnY and y <= btnY + btnH then
            state.step = state.step - 1
            state.error = nil
            textInputState.focused = nil
            return true
        end
    end

    -- Next/Generate button click
    if wizard.isCurrentStepValid() then
        if x >= nextX and x <= nextX + btnW and y >= btnY and y <= btnY + btnH then
            if state.step == 6 then
                wizard.startGeneration()
            else
                state.step = state.step + 1
                state.error = nil
                textInputState.focused = nil
            end
            return true
        end
    end

    -- Handle step-specific input clicks
    if state.step == 1 then
        -- Topic input
        if pointInArea(x, y, inputAreas["topic"]) then
            textInputState.focused = "topic"
            return true
        end
    elseif state.step == 2 then
        -- Art style buttons
        if inputAreas.artStyles then
            for _, item in ipairs(inputAreas.artStyles) do
                if pointInArea(x, y, item.area) then
                    state.data.artStyle = item.style
                    return true
                end
            end
        end
    elseif state.step == 3 then
        -- Target age buttons
        if inputAreas.targetAges then
            for _, item in ipairs(inputAreas.targetAges) do
                if pointInArea(x, y, item.area) then
                    state.data.targetAge = item.age
                    return true
                end
            end
        end
    elseif state.step == 4 then
        -- Page count buttons
        if pointInArea(x, y, inputAreas.pageCountMinus) and state.data.pageCount > 1 then
            state.data.pageCount = state.data.pageCount - 1
            return true
        end
        if pointInArea(x, y, inputAreas.pageCountPlus) and state.data.pageCount < 5 then
            state.data.pageCount = state.data.pageCount + 1
            return true
        end
    elseif state.step == 5 then
        -- Page hint inputs
        for i = 1, state.data.pageCount do
            if pointInArea(x, y, inputAreas["hint" .. i]) then
                textInputState.focused = "hint" .. i
                return true
            end
        end
    end

    -- Click elsewhere unfocuses text input
    textInputState.focused = nil

    return true  -- Consume all clicks inside dialog
end

-- Handle keyboard input for text fields
function wizard.keypressed(key)
    if not state.isOpen or state.generating then return false end

    if key == "backspace" and textInputState.focused then
        if textInputState.focused == "topic" then
            state.data.topic = state.data.topic:sub(1, -2)
        elseif textInputState.focused:match("^hint") then
            local idx = tonumber(textInputState.focused:match("hint(%d+)"))
            if idx and state.data.pageHints[idx] then
                state.data.pageHints[idx] = state.data.pageHints[idx]:sub(1, -2)
            end
        end
        return true
    end

    if key == "tab" and textInputState.focused then
        -- Move to next input in hints
        if state.step == 5 then
            local currentIdx = tonumber(textInputState.focused:match("hint(%d+)"))
            if currentIdx then
                local nextIdx = currentIdx + 1
                if nextIdx <= state.data.pageCount then
                    textInputState.focused = "hint" .. nextIdx
                else
                    textInputState.focused = "hint1"
                end
            end
        end
        return true
    end

    if key == "return" or key == "kpenter" then
        if wizard.isCurrentStepValid() and state.step < 6 then
            state.step = state.step + 1
            textInputState.focused = nil
            return true
        elseif state.step == 6 then
            wizard.startGeneration()
            return true
        end
    end

    if key == "escape" then
        textInputState.focused = nil
        return true
    end

    return false
end

-- Handle text input for focused fields
function wizard.textinput(text)
    if not state.isOpen or state.generating then return false end
    if not textInputState.focused then return false end

    if textInputState.focused == "topic" then
        state.data.topic = state.data.topic .. text
        return true
    elseif textInputState.focused:match("^hint") then
        local idx = tonumber(textInputState.focused:match("hint(%d+)"))
        if idx then
            state.data.pageHints[idx] = (state.data.pageHints[idx] or "") .. text
            return true
        end
    end

    return false
end

function wizard.startGeneration()
    print("[Wizard] Starting generation...")
    state.generating = true
    state.step = 7
    state.error = nil
    state.generationPhase = "starting"
    state.generationProgress = { current = 0, total = 0 }
    state.funnyMessageTimer = 0
    state.funnyMessage = FUNNY_MESSAGES[math.random(#FUNNY_MESSAGES)]

    -- Prepare hints array (only up to pageCount)
    local hints = {}
    for i = 1, state.data.pageCount do
        hints[i] = state.data.pageHints[i] or ""
    end

    print("[Wizard] Topic: " .. state.data.topic)
    print("[Wizard] Art Style: " .. state.data.artStyle)
    print("[Wizard] Page Count: " .. state.data.pageCount)

    -- Start thread
    print("[Wizard] Creating and starting thread...")
    state.thread = love.thread.newThread("wizard_thread.lua")
    state.thread:start()
    print("[Wizard] Thread started")

    -- Send request
    local requestChannel = love.thread.getChannel("wizard_request")
    requestChannel:push({
        action = "generate",
        data = {
            topic = state.data.topic,
            artStyle = state.data.artStyle,
            targetAge = state.data.targetAge,
            pageCount = state.data.pageCount,
            pageHints = hints
        }
    })
    print("[Wizard] Request pushed to channel")
end

function wizard.wrapText(text, maxWidth)
    local lines = {}
    local font = love.graphics.getFont()

    for line in text:gmatch("[^\n]+") do
        local currentLine = ""
        for word in line:gmatch("%S+") do
            local testLine = currentLine == "" and word or currentLine .. " " .. word
            if font:getWidth(testLine) <= maxWidth then
                currentLine = testLine
            else
                if currentLine ~= "" then
                    table.insert(lines, currentLine)
                end
                currentLine = word
            end
        end
        if currentLine ~= "" then
            table.insert(lines, currentLine)
        end
    end

    return lines
end

return wizard
