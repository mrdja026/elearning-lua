local json = require("libraries.json")
local Slab = require("libraries.Slab")
local schema = require("schema")
local gamestate = require("gamestate")
local logic = require("logic")
local renderer = require("renderer")
local editor = require("editor")

-- New UI system modules
local Tokens = require("ui.tokens")
local Layout = require("ui.layout")
local Style = require("ui.style")
local InputManager = require("ui.input_manager")
local PlayScreen = require("screens.play")
local Decorations = require("ui.decorations")

local APP_MODE = "create"
local errorMessage = nil

-- Legacy preview constants removed - now using Layout.getConfigLayout()

function love.load()
    -- Set default font
    love.graphics.setNewFont(Tokens.TYPOGRAPHY.body.size)
    love.keyboard.setKeyRepeat(true)

    -- Initialize UI systems
    Layout.init()
    Slab.Initialize({})
    Style.initialize()
    InputManager.init()

    -- Initialize game systems
    gamestate.init()
    editor.init()
    PlayScreen.init()

    -- Set up play screen callbacks
    PlayScreen.setCallbacks({
        onChoice = function(isYes)
            -- Convert boolean to string for logic.processYesNo
            local choice = isYes and "yes" or "no"
            handleChoice(choice)
        end,
        onSubmit = function()
            local page = gamestate.getCurrentPage()
            if page then
                handleSubmit(page)
            end
        end,
    })

    local storyPath = "stories/test_story.json"
    local success, story = loadStory(storyPath)

    if success then
        local valid, err = schema.validateStory(story)
        if valid then
            gamestate.loadStory(story)
        end
    end
end

function loadStory(path)
    local info = love.filesystem.getInfo(path)
    if not info then
        return false, "Story file not found: " .. path
    end

    local content, err = love.filesystem.read(path)
    if not content then
        return false, "Failed to read story: " .. err
    end

    local success, story = pcall(json.decode, content)
    if not success then
        return false, "Failed to parse JSON: " .. story
    end

    return true, story
end

function love.update(dt)
    -- Update input manager (handles pointer/touch abstraction)
    InputManager.update(dt)

    if APP_MODE == "create" then
        Slab.Update(dt)
        editor.update(dt)
    else
        -- Update play screen
        PlayScreen.update(dt, gamestate)
    end
end

function love.resize(w, h)
    -- Recalculate scaling when window is resized
    Layout.calculateScale()
end

function love.draw()
    if APP_MODE == "create" then
        drawCreateMode()
    else
        drawPlayMode()
    end

    drawModeIndicator()
end

function drawCreateMode()
    -- Clear with warm storybook background
    love.graphics.clear(Tokens.COLORS.warm_cream)

    -- Draw decorations BEFORE Slab (they appear behind semi-transparent panels)
    Decorations.draw()

    -- Draw editor panels (queues Slab draw commands)
    editor.draw()

    -- Execute all Slab draw commands
    Slab.Draw()

    -- Draw the center preview panel (on top, but uses layout positioning)
    drawCenterPreview()
end

-- Center preview panel - the main visual focus of the storybook layout
function drawCenterPreview()
    local layout = Layout.getConfigLayout()
    local panel = layout.previewPanel

    local previewX = panel.x
    local previewY = panel.y
    local previewW = panel.width
    local previewH = panel.height
    local previewScale = panel.scale or 0.6

    -- Draw semi-transparent panel background
    love.graphics.setColor(Tokens.COLORS.panel_dark_transparent)
    love.graphics.rectangle("fill", previewX, previewY, previewW, previewH, 8)

    -- Draw header bar
    love.graphics.setColor(0.15, 0.15, 0.20, 0.95)
    love.graphics.rectangle("fill", previewX, previewY, previewW, 30, 8)

    -- Preview label
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Preview", previewX + 15, previewY + 7)

    -- Draw subtle border
    love.graphics.setColor(0.35, 0.35, 0.40, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", previewX, previewY, previewW, previewH, 8)
    love.graphics.setLineWidth(1)

    -- Calculate centering for the preview content
    local contentX = previewX + panel.padding
    local contentY = previewY + 40
    local contentW = previewW - panel.padding * 2
    local contentH = previewH - 50

    -- Center the scaled preview within the content area
    local scaledW = 800 * previewScale
    local scaledH = 600 * previewScale
    local offsetX = (contentW - scaledW) / 2
    local offsetY = (contentH - scaledH) / 2

    love.graphics.push()
    love.graphics.translate(contentX + offsetX, contentY + offsetY)
    love.graphics.scale(previewScale, previewScale)

    local page = editor.getCurrentPage()
    if page then
        drawPreviewPage(page)
    else
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("No page selected", 300, 280)
    end

    love.graphics.pop()
    love.graphics.setColor(1, 1, 1, 1)
end

-- Legacy function name for compatibility
function drawPreviewPanel()
    drawCenterPreview()
end

function drawPreviewPage(page)
    love.graphics.setColor(0.2, 0.2, 0.3)
    love.graphics.rectangle("fill", 0, 0, 800, 600)

    love.graphics.setColor(0.4, 0.4, 0.5)
    love.graphics.rectangle("fill", 100, 50, 600, 300, 10)

    if page.image_path and page.image_path ~= "" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("[" .. page.image_path .. "]", 300, 190)
    else
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("[Image Placeholder]", 320, 190)
    end

    love.graphics.setColor(1, 1, 1)
    local questionText = page.question_text or ""
    local font = love.graphics.getFont()
    local textW = font:getWidth(questionText)
    love.graphics.print(questionText, (800 - textW) / 2, 380)

    if page.hint_text and page.hint_text ~= "" then
        love.graphics.setColor(0.7, 0.7, 0.7)
        local hintW = font:getWidth(page.hint_text)
        love.graphics.print(page.hint_text, (800 - hintW) / 2, 420)
    end

    local questionType = page.question_type or "yesno"

    if questionType == "yesno" then
        local labels = page.choice_labels or {"Yes", "No"}
        local btnW, btnH = 200, 60
        local spacing = 50
        local totalW = btnW * 2 + spacing
        local startX = (800 - totalW) / 2

        for i, label in ipairs(labels) do
            local x = startX + (i - 1) * (btnW + spacing)
            local y = 480

            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", x, y, btnW, btnH, 8)

            love.graphics.setColor(1, 1, 1)
            local labelW = font:getWidth(label)
            love.graphics.print(label, x + (btnW - labelW) / 2, y + 20)
        end

        -- Show correct answer indicator
        local correctText = page.correct_answer_is_yes and "Correct: Yes" or "Correct: No"
        love.graphics.setColor(0.5, 0.7, 0.5)
        love.graphics.print(correctText, 20, 560)

    elseif questionType == "text" then
        local inputX = (800 - 400) / 2
        local inputY = 450

        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", inputX, inputY, 400, 40, 5)
        love.graphics.setColor(0.4, 0.4, 0.5)
        love.graphics.rectangle("line", inputX, inputY, 400, 40, 5)

        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("[Text Input]", inputX + 150, inputY + 10)

        local btnX = (800 - 200) / 2
        love.graphics.setColor(0.3, 0.5, 0.7)
        love.graphics.rectangle("fill", btnX, 510, 200, 50, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Submit", btnX + 75, 525)

        love.graphics.setColor(0.5, 0.7, 0.5)
        love.graphics.print("Answer: " .. (page.correct_answer or "?"), 20, 560)

    elseif questionType == "multi" then
        local questions = page.questions or {}
        local startY = 420

        for i, q in ipairs(questions) do
            local y = startY + (i - 1) * 50
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(i .. ". " .. (q.question_text or ""), 200, y)

            love.graphics.setColor(0.15, 0.15, 0.2)
            love.graphics.rectangle("fill", 200, y + 18, 300, 25, 3)
            love.graphics.setColor(0.4, 0.4, 0.5)
            love.graphics.rectangle("line", 200, y + 18, 300, 25, 3)
        end

        if #questions > 0 then
            local btnY = startY + #questions * 50 + 10
            local btnX = (800 - 200) / 2
            love.graphics.setColor(0.3, 0.5, 0.7)
            love.graphics.rectangle("fill", btnX, btnY, 200, 40, 8)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print("Submit All", btnX + 60, btnY + 10)
        end

        love.graphics.setColor(0.5, 0.7, 0.5)
        love.graphics.print("Questions: " .. #questions, 20, 560)
    end

    -- Show linear navigation info
    love.graphics.setColor(0.7, 0.7, 0.5)
    love.graphics.print("Navigation: Linear (correct=next, wrong=retry)", 450, 560)

    love.graphics.setColor(0.6, 0.8, 0.6)
    love.graphics.print("Type: " .. questionType, 20, 540)
end

function drawPlayMode()
    -- Apply virtual resolution scaling
    Layout.applyTransform()

    if errorMessage then
        PlayScreen.drawError(errorMessage)
        Layout.resetTransform()
        return
    end

    if gamestate.isFinished() then
        PlayScreen.drawFinished(gamestate.getResult())
        Layout.resetTransform()
        return
    end

    local page = gamestate.getCurrentPage()
    if page then
        PlayScreen.draw(gamestate, renderer)
    else
        PlayScreen.drawError("No current page")
    end

    Layout.resetTransform()
end

function drawModeIndicator()
    local modeText = APP_MODE == "create" and "CREATE MODE" or "PLAY MODE"
    local color = APP_MODE == "create" and {0.3, 0.6, 0.9} or {0.3, 0.8, 0.4}

    love.graphics.setColor(color[1], color[2], color[3], 0.9)
    love.graphics.rectangle("fill", love.graphics.getWidth() - 150, love.graphics.getHeight() - 35, 140, 25, 5)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(modeText, love.graphics.getWidth() - 140, love.graphics.getHeight() - 30)

    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("Tab to switch", love.graphics.getWidth() - 150, love.graphics.getHeight() - 55)
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    if APP_MODE == "create" then
        -- Handle custom thumbnail panel clicks (before Slab processes)
        if editor.handleThumbnailClick(x, y) then
            return
        end
        -- Slab handles the rest via its own input system
    elseif APP_MODE == "play" then
        if errorMessage then return end
        if gamestate.isFinished() then return end

        local page = gamestate.getCurrentPage()
        if not page then return end

        local questionType = page.question_type or "yesno"

        if questionType == "yesno" then
            local choice = renderer.getClickedButton(x, y)
            if choice then
                -- Convert true/false to yes/no for yesno processing
                local yesNoChoice = (choice == "true") and "yes" or "no"
                handleChoice(yesNoChoice)
            end
        else
            local clickedInput = renderer.getClickedInput(x, y)
            if clickedInput then
                gamestate.setActiveInput(clickedInput)
                return
            end

            if renderer.getClickedSubmit(x, y, page) then
                handleSubmit(page)
            end
        end
    end
end

function love.keypressed(key)
    if key == "tab" then
        if APP_MODE == "create" then
            APP_MODE = "play"
            -- Clear Slab's focused input to prevent it from capturing keystrokes in play mode
            Slab.SetInputFocus(nil)
            local story = editor.getStory()
            local valid, err = schema.validateStory(story)
            if valid then
                gamestate.loadStory(story)
                errorMessage = nil
                -- Enter play screen and register focusables
                PlayScreen.enter(gamestate)
            else
                errorMessage = "Invalid story: " .. err
            end
        else
            APP_MODE = "create"
            PlayScreen.exit()
        end
        return
    end

    if APP_MODE == "create" then
        editor.keypressed(key)
    else
        if key == "r" then
            restartGame()
        elseif key == "escape" then
            love.event.quit()
        elseif key == "return" then
            local page = gamestate.getCurrentPage()
            if page and (page.question_type == "text" or page.question_type == "multi") then
                handleSubmit(page)
            end
        elseif key == "backspace" then
            handleBackspace()
        end
    end
end

function love.textinput(text)
    if APP_MODE == "create" then
        editor.textinput(text)
    else
        local page = gamestate.getCurrentPage()
        if page then
            local questionType = page.question_type or "binary"
            if questionType == "text" then
                local current = gamestate.getTextInput()
                gamestate.setTextInput(current .. text)
                gamestate.clearErrors()
            elseif questionType == "multi" then
                local activeInput = gamestate.getActiveInput()
                local current = gamestate.getMultiAnswer(activeInput)
                gamestate.setMultiAnswer(activeInput, current .. text)
                gamestate.clearErrors()
            end
        end
    end
end

function handleBackspace()
    local page = gamestate.getCurrentPage()
    if not page then return end

    local questionType = page.question_type or "binary"
    if questionType == "text" then
        local current = gamestate.getTextInput()
        if #current > 0 then
            gamestate.setTextInput(current:sub(1, -2))
        end
    elseif questionType == "multi" then
        local activeInput = gamestate.getActiveInput()
        local current = gamestate.getMultiAnswer(activeInput)
        if #current > 0 then
            gamestate.setMultiAnswer(activeInput, current:sub(1, -2))
        end
    end
end

function handleSubmit(page)
    local questionType = page.question_type or "yesno"

    if questionType == "text" then
        local userAnswer = gamestate.getTextInput()
        local isCorrect, outcome, errors = logic.processTextAnswer(page, userAnswer)

        if isCorrect then
            gamestate.resetInputState()
            -- Linear navigation: advance to next page or finish
            if gamestate.isLastPage() then
                gamestate.setResult("win")
            else
                gamestate.advanceToNextPage()
                -- Re-register focusables for the new page
                if APP_MODE == "play" then
                    PlayScreen.registerFocusables(gamestate)
                end
            end
        else
            gamestate.setErrors(errors)
        end
    elseif questionType == "multi" then
        local userAnswers = gamestate.getMultiAnswers()
        local isCorrect, outcome, errors = logic.processMultiAnswer(page, userAnswers)

        if isCorrect then
            gamestate.resetInputState()
            -- Linear navigation: advance to next page or finish
            if gamestate.isLastPage() then
                gamestate.setResult("win")
            else
                gamestate.advanceToNextPage()
                -- Re-register focusables for the new page
                if APP_MODE == "play" then
                    PlayScreen.registerFocusables(gamestate)
                end
            end
        else
            gamestate.setErrors(errors)
        end
    end
end

function handleChoice(choice)
    local page = gamestate.getCurrentPage()
    if not page then return end

    -- Use yesno evaluation with linear navigation
    local isCorrect, outcome = logic.processYesNo(page, choice)

    if isCorrect then
        gamestate.resetInputState()
        -- Linear navigation: advance to next page or finish
        if gamestate.isLastPage() then
            gamestate.setResult("win")
        else
            gamestate.advanceToNextPage()
            -- Re-register focusables for the new page
            if APP_MODE == "play" then
                PlayScreen.registerFocusables(gamestate)
            end
        end
    end
    -- Wrong answer: stay on current page (retry)
end

function restartGame()
    errorMessage = nil
    local story = gamestate.getStory()
    if story then
        gamestate.loadStory(story)
        -- Re-enter play screen to refresh focusables
        if APP_MODE == "play" then
            PlayScreen.enter(gamestate)
        end
    end
end

-- Gamepad support for controller navigation
function love.gamepadpressed(joystick, button)
    if APP_MODE == "play" then
        InputManager.gamepadpressed(joystick, button)
    end
end

-- Joystick (legacy) support - maps to gamepad
function love.joystickpressed(joystick, button)
    if joystick:isGamepad() then
        -- Handled by gamepadpressed
        return
    end
end
