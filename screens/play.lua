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

local PlayScreen = {}

-- Screen state
local state = {
    initialized = false,
    statusMessage = "",
    statusType = "info",
    statusTimer = 0,
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

    -- Register answer buttons as focusable
    PlayScreen.registerFocusables(gamestate)
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
function PlayScreen.draw(gamestate, renderer)
    local layout = Layout.getPlayLayout()

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT)

    -- Get current page
    local page = gamestate.getCurrentPage()

    -- Draw left panel (image)
    PlayScreen.drawLeftPanel(layout.leftPanel, layout.imageCard, page)

    -- Draw right panel (question + answers)
    PlayScreen.drawRightPanel(layout.rightPanel, layout.buttons, page, gamestate)

    -- Draw status bar
    StatusBar.draw(
        layout.statusBar.x,
        layout.statusBar.y,
        layout.statusBar.width,
        layout.statusBar.height,
        state.statusMessage,
        state.statusType
    )

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
function PlayScreen.drawRightPanel(panel, btnLayout, page, gamestate)
    -- Draw panel background
    Widgets.panel(panel.x, panel.y, panel.width, panel.height, {style = "elevated"})

    if not page then
        love.graphics.setColor(Tokens.COLORS.text_disabled)
        love.graphics.print("No page loaded", panel.contentX + 20, panel.contentY + 20)
        return
    end

    -- Draw question panel content
    QuestionPanel.draw(panel, btnLayout, page, gamestate)
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
