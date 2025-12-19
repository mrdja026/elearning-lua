-- screens/play.lua
-- Play Mode screen with split left/right layout
-- Left: Image card | Right: Question + Answers

local Tokens = require("ui.tokens")
local Layout = require("ui.layout")
local Widgets = require("ui.widgets")
local InputManager = require("ui.input_manager")
local ImageCard = require("components.image_card")
local QuestionPanel = require("components.question_panel")
local StatusBar = require("components.status_bar")
local schema = require("schema")

local PlayScreen = {}

-- Screen state
local state = {
    initialized = false,
    statusMessage = "",
    statusType = "info",
    statusTimer = 0,
    showingStoryFrame = false,  -- Story Frame intro screen state
}

-- Initialize play screen
function PlayScreen.init()
    state.initialized = true
    state.statusMessage = ""
    state.statusType = "info"
    state.statusTimer = 0
end

-- Enter play screen (called when switching to play mode)
function PlayScreen.enter(gamestate)
    InputManager.clear()
    state.statusMessage = ""
    state.statusType = "info"

    -- Check if story has a Story Frame (cover image)
    local story = gamestate.getStory and gamestate.getStory() or nil
    if story and schema.hasStoryFrame(story) then
        state.showingStoryFrame = true
    else
        state.showingStoryFrame = false
        -- Register answer buttons as focusable only if not showing Story Frame
        PlayScreen.registerFocusables(gamestate)
    end
end

-- Exit play screen
function PlayScreen.exit()
    InputManager.clear()
end

-- Register focusable elements based on current page
function PlayScreen.registerFocusables(gamestate)
    InputManager.clear()

    local page = gamestate.getCurrentPage()
    if not page then return end

    local layout = Layout.getPlayLayout()
    local questionType = page.question_type or "yesno"

    if questionType == "yesno" then
        -- Register Yes/No buttons
        local btnLayout = layout.buttons
        local rightPanel = layout.rightPanel

        local totalW = btnLayout.width * 2 + btnLayout.gap
        local startX = rightPanel.contentX + (rightPanel.contentWidth - totalW) / 2
        local btnY = rightPanel.contentY + rightPanel.contentHeight - btnLayout.height - Tokens.SPACING.lg

        InputManager.register("btn_yes", {
            x = startX,
            y = btnY,
            width = btnLayout.width,
            height = btnLayout.height,
        }, {
            onActivate = function()
                PlayScreen.onChoice(true, gamestate)
            end,
        })

        InputManager.register("btn_no", {
            x = startX + btnLayout.width + btnLayout.gap,
            y = btnY,
            width = btnLayout.width,
            height = btnLayout.height,
        }, {
            onActivate = function()
                PlayScreen.onChoice(false, gamestate)
            end,
        })

        -- Auto-focus first button
        InputManager.setFocus("btn_yes")

    elseif questionType == "text" then
        -- Register submit button
        local rightPanel = layout.rightPanel
        local btnW = Tokens.TOUCH.primary_button_width
        local btnH = Tokens.TOUCH.primary_button_height
        local btnX = rightPanel.contentX + (rightPanel.contentWidth - btnW) / 2
        local btnY = rightPanel.contentY + rightPanel.contentHeight - btnH - Tokens.SPACING.lg

        InputManager.register("btn_submit", {
            x = btnX,
            y = btnY,
            width = btnW,
            height = btnH,
        }, {
            onActivate = function()
                PlayScreen.onSubmit(gamestate)
            end,
        })

    elseif questionType == "multi" then
        -- Register submit button for multi-question
        local rightPanel = layout.rightPanel
        local btnW = Tokens.TOUCH.primary_button_width
        local btnH = Tokens.TOUCH.primary_button_height
        local btnX = rightPanel.contentX + (rightPanel.contentWidth - btnW) / 2
        local btnY = rightPanel.contentY + rightPanel.contentHeight - btnH - Tokens.SPACING.lg

        InputManager.register("btn_submit_all", {
            x = btnX,
            y = btnY,
            width = btnW,
            height = btnH,
        }, {
            onActivate = function()
                PlayScreen.onSubmit(gamestate)
            end,
        })
    end
end

-- Handle choice selection (binary questions)
function PlayScreen.onChoice(isTrue, gamestate)
    -- This will be called by main.lua's handleChoice
    -- We just trigger the callback here
    if PlayScreen.choiceCallback then
        PlayScreen.choiceCallback(isTrue)
    end
end

-- Handle submit (text/multi questions)
function PlayScreen.onSubmit(gamestate)
    if PlayScreen.submitCallback then
        PlayScreen.submitCallback()
    end
end

-- Set callbacks for game logic
function PlayScreen.setCallbacks(callbacks)
    PlayScreen.choiceCallback = callbacks.onChoice
    PlayScreen.submitCallback = callbacks.onSubmit
end

-- Check if currently showing Story Frame
function PlayScreen.isShowingStoryFrame()
    return state.showingStoryFrame
end

-- Dismiss Story Frame and proceed to Page 1
function PlayScreen.dismissStoryFrame(gamestate)
    if state.showingStoryFrame then
        state.showingStoryFrame = false
        -- Register focusables now that we're entering actual gameplay
        PlayScreen.registerFocusables(gamestate)
    end
end

-- Draw Story Frame intro screen
function PlayScreen.drawStoryFrame(story)
    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Draw pixel art decorations (border frame)
    local borderSize = 8
    love.graphics.setColor(0.3, 0.25, 0.4, 1)  -- Purple-ish border
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, borderSize)
    love.graphics.rectangle("fill", 0, Tokens.VIRTUAL_HEIGHT - borderSize, Tokens.VIRTUAL_WIDTH, borderSize)
    love.graphics.rectangle("fill", 0, 0, borderSize, Tokens.VIRTUAL_HEIGHT)
    love.graphics.rectangle("fill", Tokens.VIRTUAL_WIDTH - borderSize, 0, borderSize, Tokens.VIRTUAL_HEIGHT)

    -- Inner decorative frame
    local innerBorder = 4
    local innerOffset = borderSize + 8
    love.graphics.setColor(0.4, 0.35, 0.5, 0.8)
    love.graphics.rectangle("line", innerOffset, innerOffset,
        Tokens.VIRTUAL_WIDTH - innerOffset * 2,
        Tokens.VIRTUAL_HEIGHT - innerOffset * 2)

    -- Cover image (centered, prominent)
    local coverImage = nil
    if story.cover_image_path and story.cover_image_path ~= "" then
        coverImage = ImageCard.loadImage(story.cover_image_path)
    end

    local imgW, imgH = 300, 200
    local imgX = (Tokens.VIRTUAL_WIDTH - imgW) / 2
    local imgY = 120

    -- Draw image card background
    love.graphics.setColor(0.15, 0.15, 0.2, 1)
    love.graphics.rectangle("fill", imgX - 4, imgY - 4, imgW + 8, imgH + 8, 4)

    if coverImage then
        love.graphics.setColor(1, 1, 1, 1)
        local scaleX = imgW / coverImage:getWidth()
        local scaleY = imgH / coverImage:getHeight()
        local scale = math.min(scaleX, scaleY)
        local drawW = coverImage:getWidth() * scale
        local drawH = coverImage:getHeight() * scale
        local drawX = imgX + (imgW - drawW) / 2
        local drawY = imgY + (imgH - drawH) / 2
        love.graphics.draw(coverImage, drawX, drawY, 0, scale, scale)
    else
        -- Placeholder
        love.graphics.setColor(0.2, 0.2, 0.25, 1)
        love.graphics.rectangle("fill", imgX, imgY, imgW, imgH)
        love.graphics.setColor(0.4, 0.4, 0.45, 1)
        local placeholder = "[Cover Image]"
        local font = love.graphics.getFont()
        local placeholderW = font:getWidth(placeholder)
        love.graphics.print(placeholder, imgX + (imgW - placeholderW) / 2, imgY + imgH / 2 - 8)
    end

    -- Story title
    local titleY = imgY + imgH + 40
    love.graphics.setColor(1, 1, 1, 1)
    local title = story.title or "Untitled Story"
    local font = love.graphics.getFont()
    local titleW = font:getWidth(title)
    love.graphics.print(title, (Tokens.VIRTUAL_WIDTH - titleW) / 2, titleY)

    -- Topic/description
    if story.topic and story.topic ~= "" then
        local topicY = titleY + 30
        love.graphics.setColor(0.7, 0.7, 0.8, 1)
        local topicW = font:getWidth(story.topic)
        love.graphics.print(story.topic, (Tokens.VIRTUAL_WIDTH - topicW) / 2, topicY)
    end

    -- "Tap anywhere to start" prompt (pulsing effect would be nice but keeping it simple)
    local promptY = Tokens.VIRTUAL_HEIGHT - 80
    love.graphics.setColor(0.6, 0.7, 0.9, 0.8)
    local prompt = "~ Tap anywhere to start ~"
    local promptW = font:getWidth(prompt)
    love.graphics.print(prompt, (Tokens.VIRTUAL_WIDTH - promptW) / 2, promptY)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Show status message
function PlayScreen.showStatus(message, msgType, duration)
    state.statusMessage = message or ""
    state.statusType = msgType or "info"
    state.statusTimer = duration or 3
end

-- Update play screen
function PlayScreen.update(dt, gamestate)
    -- Update status timer
    if state.statusTimer > 0 then
        state.statusTimer = state.statusTimer - dt
        if state.statusTimer <= 0 then
            state.statusMessage = ""
            state.statusType = "info"
        end
    end

    -- Ensure focus is set
    InputManager.ensureFocus()
end

-- Draw play screen
-- previewMode: if true, buttons are disabled (gray) for config mode preview
function PlayScreen.draw(gamestate, renderer, previewMode)
    local layout = Layout.getPlayLayout()

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Get current page
    local page = gamestate.getCurrentPage()

    -- Draw left panel (image)
    PlayScreen.drawLeftPanel(layout.leftPanel, layout.imageCard, page)

    -- Draw right panel (question + answers)
    PlayScreen.drawRightPanel(layout.rightPanel, layout.buttons, page, gamestate, previewMode)

    -- Draw status bar (hide in preview mode)
    if not previewMode then
        StatusBar.draw(
            layout.statusBar.x,
            layout.statusBar.y,
            layout.statusBar.width,
            layout.statusBar.height,
            state.statusMessage,
            state.statusType
        )
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw left panel with image
function PlayScreen.drawLeftPanel(panel, imageCard, page)
    -- Draw panel background
    Widgets.panel(panel.x, panel.y, panel.width, panel.height, {style = "surface"})

    -- Draw image card
    local image = nil
    if page and page.image_path and page.image_path ~= "" then
        image = ImageCard.loadImage(page.image_path)
    end

    -- Center image card in panel
    local cardW = math.min(imageCard.maxWidth, panel.contentWidth)
    local cardH = math.min(imageCard.maxHeight, panel.contentHeight - Tokens.SPACING.lg)
    local cardX = panel.contentX + (panel.contentWidth - cardW) / 2
    local cardY = panel.contentY + (panel.contentHeight - cardH) / 2

    ImageCard.draw(cardX, cardY, cardW, cardH, image)
end

-- Draw right panel with question and answers
function PlayScreen.drawRightPanel(panel, btnLayout, page, gamestate, previewMode)
    -- Draw panel background
    Widgets.panel(panel.x, panel.y, panel.width, panel.height, {style = "elevated"})

    if not page then
        love.graphics.setColor(Tokens.COLORS.text_disabled)
        love.graphics.print("No page loaded", panel.contentX + 20, panel.contentY + 20)
        return
    end

    -- Draw question panel content
    QuestionPanel.draw(panel, btnLayout, page, gamestate, previewMode)
end

-- Draw finished screen (win/lose)
function PlayScreen.drawFinished(result)
    local layout = Layout.getPlayLayout()

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Draw result card in center
    local cardW = 500
    local cardH = 300
    local cardX = (Tokens.VIRTUAL_WIDTH - cardW) / 2
    local cardY = (Tokens.VIRTUAL_HEIGHT - cardH) / 2 - 50

    -- Choose colors based on result
    local bgColor, textColor, title
    if result == "win" then
        bgColor = Tokens.COLORS.success
        textColor = Tokens.COLORS.text_on_primary
        title = "YOU WIN!"
    else
        bgColor = Tokens.COLORS.error
        textColor = Tokens.COLORS.text_on_primary
        title = "TRY AGAIN"
    end

    -- Draw card with colored border
    love.graphics.setColor(Tokens.darken(bgColor, 0.2))
    love.graphics.rectangle("fill", cardX, cardY, cardW, cardH)

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill",
        cardX + Tokens.BORDERS.thick,
        cardY + Tokens.BORDERS.thick,
        cardW - Tokens.BORDERS.thick * 2,
        cardH - Tokens.BORDERS.thick * 2)

    -- Draw title
    love.graphics.setColor(textColor)
    local font = love.graphics.getFont()
    local titleW = font:getWidth(title)
    love.graphics.print(title, cardX + (cardW - titleW) / 2, cardY + 80)

    -- Draw instruction
    love.graphics.setColor(Tokens.withAlpha(textColor, 0.8))
    local instruction = "Press R to restart or Tab to edit"
    local instrW = font:getWidth(instruction)
    love.graphics.print(instruction, cardX + (cardW - instrW) / 2, cardY + 180)

    -- Draw status bar
    StatusBar.draw(
        layout.statusBar.x,
        layout.statusBar.y,
        layout.statusBar.width,
        layout.statusBar.height,
        "",
        "info"
    )

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw error screen
function PlayScreen.drawError(message)
    local layout = Layout.getPlayLayout()

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Draw error card
    local cardW = 600
    local cardH = 200
    local cardX = (Tokens.VIRTUAL_WIDTH - cardW) / 2
    local cardY = (Tokens.VIRTUAL_HEIGHT - cardH) / 2

    love.graphics.setColor(Tokens.COLORS.error_dark)
    love.graphics.rectangle("fill", cardX, cardY, cardW, cardH)

    love.graphics.setColor(Tokens.COLORS.error)
    love.graphics.rectangle("fill",
        cardX + Tokens.BORDERS.thick,
        cardY + Tokens.BORDERS.thick,
        cardW - Tokens.BORDERS.thick * 2,
        cardH - Tokens.BORDERS.thick * 2)

    love.graphics.setColor(Tokens.COLORS.text_on_primary)
    love.graphics.print("Error", cardX + 30, cardY + 30)
    love.graphics.print(message or "Unknown error", cardX + 30, cardY + 70)
    love.graphics.print("Press Tab to return to editor", cardX + 30, cardY + 130)

    love.graphics.setColor(1, 1, 1, 1)
end

return PlayScreen
