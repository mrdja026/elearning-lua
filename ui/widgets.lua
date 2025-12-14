-- ui/widgets.lua
-- Custom widget drawing functions for LogicTales UI
-- These provide a consistent look across Play and Config modes

local Tokens = require("ui.tokens")
local NineSlice = require("ui.nineslice")

local Widgets = {}

-- Cached panel styles
local panelStyles = {}

-- Get or create a panel style
local function getPanelStyle(styleName)
    if not panelStyles[styleName] then
        panelStyles[styleName] = NineSlice.createPanel(styleName)
    end
    return panelStyles[styleName]
end

-- Draw a button
-- Returns true if clicked this frame
function Widgets.button(x, y, width, height, label, options)
    options = options or {}

    local style = options.style or "primary"
    local disabled = options.disabled or false
    local focused = options.focused or false
    local pressed = options.pressed or false

    -- Ensure minimum touch target size
    width = math.max(width, Tokens.TOUCH.min_target)
    height = math.max(height, Tokens.TOUCH.min_target)

    -- Integer positions
    x = math.floor(x)
    y = math.floor(y)

    -- Determine colors based on style
    local bgColor, borderColor, textColor
    if style == "primary" then
        bgColor = Tokens.COLORS.primary
        borderColor = Tokens.COLORS.primary_dark
        textColor = Tokens.COLORS.text_on_primary
    elseif style == "secondary" then
        bgColor = Tokens.COLORS.secondary
        borderColor = Tokens.COLORS.secondary_dark
        textColor = Tokens.COLORS.text_on_secondary
    elseif style == "success" then
        bgColor = Tokens.COLORS.success
        borderColor = Tokens.COLORS.success_dark
        textColor = Tokens.COLORS.text_on_primary
    elseif style == "error" then
        bgColor = Tokens.COLORS.error
        borderColor = Tokens.COLORS.error_dark
        textColor = Tokens.COLORS.text_on_primary
    else
        bgColor = Tokens.COLORS.surface_elevated
        borderColor = Tokens.COLORS.surface
        textColor = Tokens.COLORS.text_primary
    end

    -- Apply state modifiers
    local offsetY = 0
    local shadowOffset = Tokens.ELEVATION.low.offset

    if disabled then
        bgColor = Tokens.withAlpha(bgColor, 0.5)
        borderColor = Tokens.withAlpha(borderColor, 0.5)
        textColor = Tokens.COLORS.text_disabled
        shadowOffset = 0
    elseif pressed then
        bgColor = Tokens.darken(bgColor, 0.1)
        offsetY = 2
        shadowOffset = 0
    elseif focused then
        borderColor = Tokens.COLORS.accent
    end

    -- Check hover
    local mx, my = love.mouse.getPosition()
    -- Note: In actual use, mx/my should be converted from screen to virtual coords
    local hovered = not disabled and
        mx >= x and mx <= x + width and
        my >= y and my <= y + height

    if hovered and not disabled then
        bgColor = Tokens.lighten(bgColor, 0.08)
    end

    -- Draw shadow
    if shadowOffset > 0 then
        love.graphics.setColor(Tokens.COLORS.shadow)
        love.graphics.rectangle("fill",
            x + shadowOffset,
            y + shadowOffset + offsetY,
            width, height)
    end

    -- Draw border
    local border = Tokens.BORDERS.thick
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("fill", x, y + offsetY, width, height)

    -- Draw fill
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill",
        x + border,
        y + border + offsetY,
        width - border * 2,
        height - border * 2)

    -- Draw focus ring
    if focused and not disabled then
        love.graphics.setColor(Tokens.COLORS.accent)
        love.graphics.setLineWidth(Tokens.BORDERS.thin)
        love.graphics.rectangle("line", x - 4, y - 4 + offsetY, width + 8, height + 8)
        love.graphics.setLineWidth(1)
    end

    -- Draw label
    if label then
        love.graphics.setColor(textColor)
        local font = love.graphics.getFont()
        local textW = font:getWidth(label)
        local textH = font:getHeight()
        local textX = x + (width - textW) / 2
        local textY = y + (height - textH) / 2 + offsetY
        love.graphics.print(label, math.floor(textX), math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)

    -- Return click state
    local clicked = hovered and love.mouse.isDown(1)
    return clicked and not disabled
end

-- Draw a card/panel background
function Widgets.panel(x, y, width, height, options)
    options = options or {}
    local style = options.style or "surface"

    local panel = getPanelStyle(style)
    panel:draw(x, y, width, height)
end

-- Draw an image inside a card frame
function Widgets.imageCard(x, y, width, height, image, options)
    options = options or {}
    local border = options.border or Tokens.BORDERS.thick
    local bgColor = options.bgColor or Tokens.COLORS.surface

    x = math.floor(x)
    y = math.floor(y)

    -- Draw card background
    local cardPanel = getPanelStyle("card")
    cardPanel:draw(x, y, width, height)

    -- Draw image if provided
    if image then
        local imgW, imgH = image:getDimensions()

        -- Calculate scaled dimensions to fit inside card (with padding)
        local innerW = width - border * 2 - Tokens.SPACING.sm * 2
        local innerH = height - border * 2 - Tokens.SPACING.sm * 2

        local scale = math.min(innerW / imgW, innerH / imgH)
        -- Use integer scale for pixel art
        if scale > 1 then
            scale = math.floor(scale)
        end

        local drawW = imgW * scale
        local drawH = imgH * scale

        -- Center image in card
        local drawX = x + (width - drawW) / 2
        local drawY = y + (height - drawH) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, math.floor(drawX), math.floor(drawY), 0, scale, scale)
    else
        -- Draw placeholder
        love.graphics.setColor(Tokens.COLORS.text_disabled)
        local font = love.graphics.getFont()
        local text = "[No Image]"
        local textW = font:getWidth(text)
        local textH = font:getHeight()
        local textX = x + (width - textW) / 2
        local textY = y + (height - textH) / 2
        love.graphics.print(text, math.floor(textX), math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw text with styling
function Widgets.text(x, y, text, options)
    options = options or {}
    local style = options.style or "body"
    local color = options.color or Tokens.COLORS.text_primary
    local align = options.align or "left"
    local maxWidth = options.maxWidth

    love.graphics.setColor(color)

    if maxWidth and align ~= "left" then
        local font = love.graphics.getFont()
        local textW = font:getWidth(text)

        if align == "center" then
            x = x + (maxWidth - textW) / 2
        elseif align == "right" then
            x = x + maxWidth - textW
        end
    end

    love.graphics.print(text, math.floor(x), math.floor(y))
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a text input field (visual only - actual input handled by Slab or custom)
function Widgets.inputField(x, y, width, height, text, options)
    options = options or {}
    local focused = options.focused or false
    local placeholder = options.placeholder or ""
    local disabled = options.disabled or false

    x = math.floor(x)
    y = math.floor(y)
    height = math.max(height, Tokens.TOUCH.min_target)

    -- Draw background
    local bgColor = Tokens.COLORS.input_bg
    local borderColor = focused and Tokens.COLORS.input_border_focus or Tokens.COLORS.input_border
    local textColor = disabled and Tokens.COLORS.text_disabled or Tokens.COLORS.text_primary

    if disabled then
        bgColor = Tokens.withAlpha(bgColor, 0.5)
    end

    local border = Tokens.BORDERS.thin

    -- Draw border
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Draw fill
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x + border, y + border, width - border * 2, height - border * 2)

    -- Draw focus ring
    if focused then
        love.graphics.setColor(Tokens.COLORS.accent)
        love.graphics.setLineWidth(Tokens.BORDERS.thin)
        love.graphics.rectangle("line", x - 2, y - 2, width + 4, height + 4)
        love.graphics.setLineWidth(1)
    end

    -- Draw text or placeholder
    local displayText = (text and text ~= "") and text or placeholder
    local displayColor = (text and text ~= "") and textColor or Tokens.COLORS.text_disabled

    love.graphics.setColor(displayColor)
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local textY = y + (height - textH) / 2
    local textX = x + Tokens.SPACING.sm

    -- Clip text to input width
    love.graphics.print(displayText, math.floor(textX), math.floor(textY))

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a progress/loading indicator
function Widgets.spinner(x, y, size, options)
    options = options or {}
    local color = options.color or Tokens.COLORS.primary
    local speed = options.speed or 2

    x = math.floor(x)
    y = math.floor(y)

    -- Simple rotating dots spinner
    local time = love.timer.getTime() * speed
    local dotCount = 8
    local dotSize = size / 8

    for i = 1, dotCount do
        local angle = (i / dotCount) * math.pi * 2 + time
        local alpha = (i / dotCount) * 0.8 + 0.2

        local dx = math.cos(angle) * (size / 2 - dotSize)
        local dy = math.sin(angle) * (size / 2 - dotSize)

        love.graphics.setColor(color[1], color[2], color[3], alpha)
        love.graphics.circle("fill", x + size / 2 + dx, y + size / 2 + dy, dotSize)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a divider line
function Widgets.divider(x, y, width, options)
    options = options or {}
    local color = options.color or Tokens.COLORS.surface_elevated
    local thickness = options.thickness or 2

    love.graphics.setColor(color)
    love.graphics.rectangle("fill", math.floor(x), math.floor(y), width, thickness)
    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw an icon placeholder (for when we add actual icons)
function Widgets.icon(x, y, size, iconName, options)
    options = options or {}
    local color = options.color or Tokens.COLORS.text_primary

    -- For now, just draw a placeholder square
    love.graphics.setColor(color)
    love.graphics.rectangle("line", math.floor(x), math.floor(y), size, size)

    -- Draw first letter of icon name as placeholder
    if iconName and #iconName > 0 then
        local font = love.graphics.getFont()
        local letter = iconName:sub(1, 1):upper()
        local textW = font:getWidth(letter)
        local textH = font:getHeight()
        love.graphics.print(letter,
            math.floor(x + (size - textW) / 2),
            math.floor(y + (size - textH) / 2))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Widgets
