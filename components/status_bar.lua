-- components/status_bar.lua
-- Status bar component for showing messages and loading states

local Tokens = require("ui.tokens")
local Widgets = require("ui.widgets")

local StatusBar = {}

-- Draw status bar
function StatusBar.draw(x, y, width, height, message, msgType)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    msgType = msgType or "info"

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.surface)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw top border
    love.graphics.setColor(Tokens.COLORS.surface_elevated)
    love.graphics.rectangle("fill", x, y, width, 2)

    -- Determine text color based on message type
    local textColor = Tokens.COLORS.text_secondary
    local showSpinner = false

    if msgType == "success" then
        textColor = Tokens.COLORS.success
    elseif msgType == "error" then
        textColor = Tokens.COLORS.error
    elseif msgType == "warning" then
        textColor = Tokens.COLORS.warning
    elseif msgType == "loading" then
        textColor = Tokens.COLORS.text_secondary
        showSpinner = true
    end

    -- Draw message
    if message and message ~= "" then
        local font = love.graphics.getFont()
        local textW = font:getWidth(message)
        local textH = font:getHeight()

        local textX = x + (width - textW) / 2
        local textY = y + (height - textH) / 2

        -- If showing spinner, offset text to make room
        if showSpinner then
            local spinnerSize = 20
            textX = textX + spinnerSize / 2 + 8

            -- Draw spinner
            Widgets.spinner(
                textX - spinnerSize - 16,
                y + (height - spinnerSize) / 2,
                spinnerSize,
                {color = Tokens.COLORS.primary}
            )
        end

        love.graphics.setColor(textColor)
        love.graphics.print(message, math.floor(textX), math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a mini status indicator (for top bar use)
function StatusBar.drawMini(x, y, width, height, message, msgType)
    x = math.floor(x)
    y = math.floor(y)

    msgType = msgType or "info"

    local textColor = Tokens.COLORS.text_secondary
    if msgType == "success" then
        textColor = Tokens.COLORS.success
    elseif msgType == "error" then
        textColor = Tokens.COLORS.error
    elseif msgType == "warning" then
        textColor = Tokens.COLORS.warning
    end

    if message and message ~= "" then
        love.graphics.setColor(textColor)
        local font = love.graphics.getFont()
        local textH = font:getHeight()
        local textY = y + (height - textH) / 2
        love.graphics.print(message, x + 8, math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw generation progress
function StatusBar.drawProgress(x, y, width, height, progress, message)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.surface)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw progress bar background
    local barH = 4
    local barY = y + height - barH - 4
    local barX = x + Tokens.SPACING.lg
    local barW = width - Tokens.SPACING.lg * 2

    love.graphics.setColor(Tokens.COLORS.surface_elevated)
    love.graphics.rectangle("fill", barX, barY, barW, barH)

    -- Draw progress fill
    if progress and progress > 0 then
        love.graphics.setColor(Tokens.COLORS.primary)
        love.graphics.rectangle("fill", barX, barY, barW * math.min(1, progress), barH)
    end

    -- Draw message
    if message and message ~= "" then
        love.graphics.setColor(Tokens.COLORS.text_secondary)
        local font = love.graphics.getFont()
        local textH = font:getHeight()
        local textY = y + (height - barH - textH) / 2 - 2
        love.graphics.printf(message, x, math.floor(textY), width, "center")
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return StatusBar
