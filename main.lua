local json = require("libraries.json")
local Slab = require("libraries.Slab")
local schema = require("schema")
local gamestate = require("gamestate")
local logic = require("logic")
local renderer = require("renderer")
local editor = require("editor")
local wizard = require("wizard")

-- New UI system modules
local Tokens = require("ui.tokens")
local Layout = require("ui.layout")
local Style = require("ui.style")
local InputManager = require("ui.input_manager")
local PlayScreen = require("screens.play")
local Decorations = require("ui.decorations")

local APP_MODE = "create"
local errorMessage = nil

-- Check for --ai flag in command line arguments
local AUTO_AI_WIZARD = false
for i, v in ipairs(arg or {}) do
    if v == "--ai" then
        AUTO_AI_WIZARD = true
        break
    end
end

-- Preview canvas for config mode (renders PlayScreen at virtual resolution)
local previewCanvas = nil

-- Mock gamestate for preview mode (wraps editor's current page)
local previewGamestate = {
    getCurrentPage = function()
        return editor.getCurrentPage()
    end,
    getTextInput = function() return "" end,
    getMultiAnswer = function() return "" end,
    getActiveInput = function() return 1 end,
    getErrors = function() return {} end,
}

function love.load()
    -- Set default font
    love.graphics.setNewFont(Tokens.TYPOGRAPHY.body.size)
    love.keyboard.setKeyRepeat(true)

    -- Create preview canvas at virtual resolution
    previewCanvas = love.graphics.newCanvas(Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Initialize UI systems
    Layout.init()
    Slab.Initialize({})
    Style.initialize()
    InputManager.init()

    -- Initialize game systems
    gamestate.init()
    editor.init({ autoAiWizard = AUTO_AI_WIZARD })
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
        wizard.update(dt)  -- Update wizard thread polling
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

    -- Draw modal dialogs on top of EVERYTHING (highest z-index)
    editor.drawModalDialogs()

    -- Draw wizard on top of everything (highest z-index)
    wizard.draw()
end

-- Center preview panel - shows the story/page image prominently
function drawCenterPreview()
    local layout = Layout.getConfigLayout()
    local panel = layout.previewPanel
    local ImageCard = require("components.image_card")

    local previewX = panel.x
    local previewY = panel.y
    local previewW = panel.width
    local previewH = panel.height

    -- Draw semi-transparent panel background
    love.graphics.setColor(Tokens.COLORS.panel_dark_transparent)
    love.graphics.rectangle("fill", previewX, previewY, previewW, previewH, 8)

    -- Determine what to show: cover or page image
    local story = editor.getStory()
    local page = editor.getCurrentPage()
    local imagePath = nil
    local label = "Image Preview"

    if page then
        imagePath = page.image_path
        label = "Page Image"
    elseif story and story.cover_image_path and story.cover_image_path ~= "" then
        imagePath = story.cover_image_path
        label = "Cover Image"
    end

    -- Draw header bar
    love.graphics.setColor(0.15, 0.15, 0.20, 0.95)
    love.graphics.rectangle("fill", previewX, previewY, previewW, 30, 8)

    -- Preview label
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(label, previewX + 15, previewY + 7)

    -- Draw subtle border
    love.graphics.setColor(0.35, 0.35, 0.40, 0.8)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", previewX, previewY, previewW, previewH, 8)
    love.graphics.setLineWidth(1)

    -- Calculate content area for image
    local contentX = previewX + panel.padding
    local contentY = previewY + 40
    local contentW = previewW - panel.padding * 2
    local contentH = previewH - 50

    -- Load and draw the image
    local image = nil
    if imagePath and imagePath ~= "" then
        image = ImageCard.loadImage(imagePath)
    end

    if image then
        -- Calculate scale to fit image in content area while maintaining aspect ratio
        local imgW, imgH = image:getDimensions()
        local scaleX = contentW / imgW
        local scaleY = contentH / imgH
        local scale = math.min(scaleX, scaleY) * 0.95  -- 95% to leave margin

        local drawW = imgW * scale
        local drawH = imgH * scale
        local drawX = contentX + (contentW - drawW) / 2
        local drawY = contentY + (contentH - drawH) / 2

        -- Draw image background/frame
        love.graphics.setColor(0.1, 0.1, 0.12, 1)
        love.graphics.rectangle("fill", drawX - 4, drawY - 4, drawW + 8, drawH + 8, 4)

        -- Draw the image
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, math.floor(drawX), math.floor(drawY), 0, scale, scale)
    else
        -- No image placeholder
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", contentX, contentY, contentW, contentH, 4)

        love.graphics.setColor(0.5, 0.5, 0.55, 1)
        local text = imagePath and imagePath ~= "" and "Loading image..." or "No image"
        local font = love.graphics.getFont()
        local textW = font:getWidth(text)
        love.graphics.print(text, contentX + (contentW - textW) / 2, contentY + contentH / 2 - 10)
    end
end

function drawPlayMode()
    -- Apply virtual resolution scaling
    Layout.applyTransform()

    if errorMessage then
        PlayScreen.drawError(errorMessage)
        Layout.resetTransform()
        return
    end

    -- Check if showing Story Frame (intro screen)
    if PlayScreen.isShowingStoryFrame() then
        local story = gamestate.getStory()
        if story then
            PlayScreen.drawStoryFrame(story)
        end
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
        -- Handle wizard clicks first (highest priority, blocks all other input)
        if wizard.isOpen() then
            wizard.handleMouseClick(x, y)
            return
        end
        -- Handle dialog clicks first (highest priority)
        if editor.handleLoadSavedDialogClick(x, y) then
            return
        end
        -- Handle custom thumbnail panel clicks (before Slab processes)
        if editor.handleThumbnailClick(x, y) then
            return
        end
        -- Slab handles the rest via its own input system
    elseif APP_MODE == "play" then
        if errorMessage then return end

        -- Handle Story Frame dismissal (tap anywhere to start)
        if PlayScreen.isShowingStoryFrame() then
            PlayScreen.dismissStoryFrame(gamestate)
            return
        end

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
    -- Handle wizard keyboard input first (if open)
    if APP_MODE == "create" and wizard.isOpen() then
        if wizard.keypressed(key) then
            return
        end
    end

    if key == "tab" then
        -- Don't switch modes while wizard is open
        if wizard.isOpen() then
            return
        end

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
        -- Handle Story Frame dismissal (any key except tab)
        if PlayScreen.isShowingStoryFrame() then
            PlayScreen.dismissStoryFrame(gamestate)
            return
        end

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
        -- Handle wizard text input first (if open)
        if wizard.isOpen() and wizard.textinput(text) then
            return
        end
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
