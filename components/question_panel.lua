-- components/question_panel.lua
-- Question and answer UI component for Play mode

local Tokens = require("ui.tokens")
local Widgets = require("ui.widgets")
local InputManager = require("ui.input_manager")

local QuestionPanel = {}

-- Draw the question panel content
function QuestionPanel.draw(panel, btnLayout, page, gamestate)
    local questionType = page.question_type or "yesno"

    -- Draw question text
    QuestionPanel.drawQuestion(panel, page)

    -- Draw hint if present
    QuestionPanel.drawHint(panel, page)

    -- Draw answer UI based on question type
    if questionType == "yesno" then
        QuestionPanel.drawYesNoAnswers(panel, btnLayout, page)
    elseif questionType == "text" then
        QuestionPanel.drawTextAnswer(panel, page, gamestate)
    elseif questionType == "multi" then
        QuestionPanel.drawMultiAnswers(panel, page, gamestate)
    end
end

-- Draw question text
function QuestionPanel.drawQuestion(panel, page)
    local questionText = page.question_text or ""

    love.graphics.setColor(Tokens.COLORS.text_primary)

    -- Use body_large for questions
    local x = panel.contentX
    local y = panel.contentY + Tokens.SPACING.md
    local maxWidth = panel.contentWidth

    -- Word wrap would be nice here, but for now just print
    -- TODO: Add proper text wrapping
    love.graphics.printf(questionText, x, y, maxWidth, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw hint text
function QuestionPanel.drawHint(panel, page)
    if not page.hint_text or page.hint_text == "" then
        return
    end

    love.graphics.setColor(Tokens.COLORS.text_secondary)

    local x = panel.contentX
    local y = panel.contentY + Tokens.SPACING.md + 50  -- Below question
    local maxWidth = panel.contentWidth

    love.graphics.printf(page.hint_text, x, y, maxWidth, "center")

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw Yes/No choice buttons
function QuestionPanel.drawYesNoAnswers(panel, btnLayout, page)
    local labels = page.choice_labels or {"Yes", "No"}

    local totalW = btnLayout.width * 2 + btnLayout.gap
    local startX = panel.contentX + (panel.contentWidth - totalW) / 2
    local btnY = panel.contentY + panel.contentHeight - btnLayout.height - Tokens.SPACING.lg

    -- Draw Yes button
    local yesHovered = InputManager.isHovered("btn_yes")
    local yesFocused = InputManager.isFocused("btn_yes")
    local yesPressed = InputManager.isPressed("btn_yes")

    Widgets.button(
        startX,
        btnY,
        btnLayout.width,
        btnLayout.height,
        labels[1] or "Yes",
        {
            style = "primary",
            focused = yesFocused,
            pressed = yesPressed,
        }
    )

    -- Draw No button
    local noHovered = InputManager.isHovered("btn_no")
    local noFocused = InputManager.isFocused("btn_no")
    local noPressed = InputManager.isPressed("btn_no")

    Widgets.button(
        startX + btnLayout.width + btnLayout.gap,
        btnY,
        btnLayout.width,
        btnLayout.height,
        labels[2] or "No",
        {
            style = "secondary",
            focused = noFocused,
            pressed = noPressed,
        }
    )
end

-- Draw text answer input
function QuestionPanel.drawTextAnswer(panel, page, gamestate)
    local inputW = math.min(400, panel.contentWidth - Tokens.SPACING.lg * 2)
    local inputH = Tokens.TOUCH.min_target
    local inputX = panel.contentX + (panel.contentWidth - inputW) / 2
    local inputY = panel.contentY + 120

    -- Get current input text
    local currentText = gamestate.getTextInput and gamestate.getTextInput() or ""

    -- Check for errors
    local errors = gamestate.getErrors and gamestate.getErrors() or {}
    local hasError = errors[1] ~= nil

    -- Draw input field
    Widgets.inputField(inputX, inputY, inputW, inputH, currentText, {
        placeholder = "Type your answer...",
        focused = true,  -- Text input is always focused in text mode
    })

    -- Draw error message if present
    if hasError then
        love.graphics.setColor(Tokens.COLORS.error)
        local errorText = "Incorrect! Expected: " .. (page.correct_answer or "?")
        local font = love.graphics.getFont()
        local errorW = font:getWidth(errorText)
        love.graphics.print(errorText, inputX + (inputW - errorW) / 2, inputY + inputH + 10)
    end

    -- Draw submit button
    local btnW = Tokens.TOUCH.primary_button_width
    local btnH = Tokens.TOUCH.primary_button_height
    local btnX = panel.contentX + (panel.contentWidth - btnW) / 2
    local btnY = panel.contentY + panel.contentHeight - btnH - Tokens.SPACING.lg

    local submitFocused = InputManager.isFocused("btn_submit")
    local submitPressed = InputManager.isPressed("btn_submit")

    Widgets.button(btnX, btnY, btnW, btnH, "Submit", {
        style = "success",
        focused = submitFocused,
        pressed = submitPressed,
    })

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw multi-question answers
function QuestionPanel.drawMultiAnswers(panel, page, gamestate)
    local questions = page.questions or {}
    local startY = panel.contentY + 100
    local spacing = 70

    local errors = gamestate.getErrors and gamestate.getErrors() or {}
    local activeInput = gamestate.getActiveInput and gamestate.getActiveInput() or 1

    for i, q in ipairs(questions) do
        local y = startY + (i - 1) * spacing
        local inputW = math.min(300, panel.contentWidth - 100)
        local inputX = panel.contentX + (panel.contentWidth - inputW) / 2

        -- Draw question text
        love.graphics.setColor(Tokens.COLORS.text_primary)
        local qText = i .. ". " .. (q.question_text or "")
        love.graphics.printf(qText, panel.contentX, y, panel.contentWidth, "center")

        -- Get answer for this question
        local answer = ""
        if gamestate.getMultiAnswer then
            answer = gamestate.getMultiAnswer(i) or ""
        end

        -- Check for error on this question
        local hasError = false
        local expectedAnswer = ""
        for _, err in ipairs(errors) do
            if err.index == i then
                hasError = true
                expectedAnswer = err.expected or ""
                break
            end
        end

        -- Draw input field
        local isActive = activeInput == i
        Widgets.inputField(inputX, y + 22, inputW, 32, answer, {
            placeholder = "Answer...",
            focused = isActive,
        })

        -- Draw error indicator
        if hasError then
            love.graphics.setColor(Tokens.COLORS.error)
            love.graphics.print("Expected: " .. expectedAnswer, inputX, y + 56)
        end
    end

    -- Draw submit button
    if #questions > 0 then
        local btnW = Tokens.TOUCH.primary_button_width
        local btnH = Tokens.TOUCH.primary_button_height
        local btnX = panel.contentX + (panel.contentWidth - btnW) / 2
        local btnY = panel.contentY + panel.contentHeight - btnH - Tokens.SPACING.lg

        local submitFocused = InputManager.isFocused("btn_submit_all")
        local submitPressed = InputManager.isPressed("btn_submit_all")

        Widgets.button(btnX, btnY, btnW, btnH, "Submit All", {
            style = "success",
            focused = submitFocused,
            pressed = submitPressed,
        })
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return QuestionPanel
