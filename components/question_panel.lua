-- components/question_panel.lua
-- Question and answer UI component for Play mode

local Tokens = require("ui.tokens")
local Widgets = require("ui.widgets")
local InputManager = require("ui.input_manager")

local QuestionPanel = {}

-- Draw the question panel content
-- previewMode: if true, buttons are disabled for config mode preview
function QuestionPanel.draw(panel, btnLayout, page, gamestate, previewMode)
    local questionType = page.question_type or "yesno"

    -- Draw question text
    QuestionPanel.drawQuestion(panel, page)

    -- Draw hint if present
    QuestionPanel.drawHint(panel, page)

    -- Draw answer UI based on question type
    if questionType == "yesno" then
        QuestionPanel.drawYesNoAnswers(panel, btnLayout, page, previewMode)
    elseif questionType == "text" then
        QuestionPanel.drawTextAnswer(panel, page, gamestate, previewMode)
    elseif questionType == "multi" then
        QuestionPanel.drawMultiAnswers(panel, page, gamestate, previewMode)
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
function QuestionPanel.drawYesNoAnswers(panel, btnLayout, page, previewMode)
    local labels = page.choice_labels or {"Yes", "No"}

    local totalW = btnLayout.width * 2 + btnLayout.gap
    local startX = panel.contentX + (panel.contentWidth - totalW) / 2
    local btnY = panel.contentY + panel.contentHeight - btnLayout.height - Tokens.SPACING.lg

    -- Draw Yes button
    local yesFocused = not previewMode and InputManager.isFocused("btn_yes")
    local yesPressed = not previewMode and InputManager.isPressed("btn_yes")

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
            disabled = previewMode,
        }
    )

    -- Draw No button
    local noFocused = not previewMode and InputManager.isFocused("btn_no")
    local noPressed = not previewMode and InputManager.isPressed("btn_no")

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
            disabled = previewMode,
        }
    )
end

-- Draw text answer input
function QuestionPanel.drawTextAnswer(panel, page, gamestate, previewMode)
    local inputW = math.min(400, panel.contentWidth - Tokens.SPACING.lg * 2)
    local inputH = Tokens.TOUCH.min_target
    local inputX = panel.contentX + (panel.contentWidth - inputW) / 2
    local inputY = panel.contentY + 120

    -- Get current input text (empty in preview mode)
    local currentText = ""
    if not previewMode and gamestate.getTextInput then
        currentText = gamestate.getTextInput() or ""
    end

    -- Check for errors (none in preview mode)
    local hasError = false
    if not previewMode then
        local errors = gamestate.getErrors and gamestate.getErrors() or {}
        hasError = errors[1] ~= nil
    end

    -- Draw input field
    Widgets.inputField(inputX, inputY, inputW, inputH, currentText, {
        placeholder = "Type your answer...",
        focused = not previewMode,
        disabled = previewMode,
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

    local submitFocused = not previewMode and InputManager.isFocused("btn_submit")
    local submitPressed = not previewMode and InputManager.isPressed("btn_submit")

    Widgets.button(btnX, btnY, btnW, btnH, "Submit", {
        style = "success",
        focused = submitFocused,
        pressed = submitPressed,
        disabled = previewMode,
    })

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw multi-question answers
function QuestionPanel.drawMultiAnswers(panel, page, gamestate, previewMode)
    local questions = page.questions or {}
    local startY = panel.contentY + 100
    local spacing = 70

    local errors = {}
    local activeInput = 1
    if not previewMode then
        errors = gamestate.getErrors and gamestate.getErrors() or {}
        activeInput = gamestate.getActiveInput and gamestate.getActiveInput() or 1
    end

    for i, q in ipairs(questions) do
        local y = startY + (i - 1) * spacing
        local inputW = math.min(300, panel.contentWidth - 100)
        local inputX = panel.contentX + (panel.contentWidth - inputW) / 2

        -- Draw question text
        love.graphics.setColor(Tokens.COLORS.text_primary)
        local qText = i .. ". " .. (q.question_text or "")
        love.graphics.printf(qText, panel.contentX, y, panel.contentWidth, "center")

        -- Get answer for this question (empty in preview mode)
        local answer = ""
        if not previewMode and gamestate.getMultiAnswer then
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
        local isActive = not previewMode and activeInput == i
        Widgets.inputField(inputX, y + 22, inputW, 32, answer, {
            placeholder = "Answer...",
            focused = isActive,
            disabled = previewMode,
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

        local submitFocused = not previewMode and InputManager.isFocused("btn_submit_all")
        local submitPressed = not previewMode and InputManager.isPressed("btn_submit_all")

        Widgets.button(btnX, btnY, btnW, btnH, "Submit All", {
            style = "success",
            focused = submitFocused,
            pressed = submitPressed,
            disabled = previewMode,
        })
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return QuestionPanel
