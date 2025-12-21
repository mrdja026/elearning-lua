-- ui/style.lua
-- Configure Slab UI library with design system tokens

local IS_WEB = love.system.getOS() == "Web"
local Slab = nil
if not IS_WEB then
    Slab = require("libraries.Slab")
end
local Tokens = require("ui.tokens")

local Style = {}

-- Convert our color format to Slab's expected format
local function toSlabColor(color)
    return {color[1], color[2], color[3], color[4] or 1}
end

-- Initialize Slab with design tokens (native mode only)
function Style.initialize()
    -- Skip in web mode (Slab not available)
    if not Slab then return end

    -- Get Slab's style table
    local style = Slab.GetStyle()

    -- Window styling
    style.WindowBackgroundColor = toSlabColor(Tokens.COLORS.surface)
    style.WindowTitleBarBackgroundColor = toSlabColor(Tokens.COLORS.surface_elevated)
    style.WindowBorderColor = toSlabColor(Tokens.COLORS.surface_elevated)
    style.WindowRounding = 0  -- Pixel-perfect corners

    -- Button styling
    style.ButtonColor = toSlabColor(Tokens.COLORS.primary)
    style.ButtonHoveredColor = toSlabColor(Tokens.lighten(Tokens.COLORS.primary, 0.1))
    style.ButtonPressedColor = toSlabColor(Tokens.darken(Tokens.COLORS.primary, 0.1))
    style.ButtonTextColor = toSlabColor(Tokens.COLORS.text_on_primary)
    style.ButtonRounding = 0

    -- Input styling
    style.InputBgColor = toSlabColor(Tokens.COLORS.input_bg)
    style.InputBorderColor = toSlabColor(Tokens.COLORS.input_border)
    style.InputTextColor = toSlabColor(Tokens.COLORS.text_primary)
    style.InputBgRounding = 0

    -- Text colors
    style.TextColor = toSlabColor(Tokens.COLORS.text_primary)
    style.TextHoverColor = toSlabColor(Tokens.COLORS.text_primary)

    -- Separator
    style.SeparatorColor = toSlabColor(Tokens.COLORS.surface_elevated)

    -- Combobox / Dropdown
    style.ComboBoxDropDownColor = toSlabColor(Tokens.COLORS.surface_elevated)
    style.ComboBoxDropDownHoveredColor = toSlabColor(Tokens.COLORS.primary)

    -- Listbox
    style.ListBoxBackgroundColor = toSlabColor(Tokens.COLORS.input_bg)
    style.ListBoxItemColor = toSlabColor(Tokens.COLORS.surface)
    style.ListBoxItemHoveredColor = toSlabColor(Tokens.COLORS.primary)
    style.ListBoxItemSelectedColor = toSlabColor(Tokens.COLORS.primary_dark)

    -- Checkbox / Radio
    style.CheckBoxBackgroundColor = toSlabColor(Tokens.COLORS.input_bg)
    style.CheckBoxCheckColor = toSlabColor(Tokens.COLORS.primary)

    -- Scrollbar
    style.ScrollBarBackgroundColor = toSlabColor(Tokens.COLORS.surface)
    style.ScrollBarHandleColor = toSlabColor(Tokens.COLORS.surface_elevated)
    style.ScrollBarHandleHoveredColor = toSlabColor(Tokens.COLORS.primary)

    -- Set default font size
    style.FontSize = Tokens.TYPOGRAPHY.body.size
end

-- Apply style to a specific Slab window
function Style.windowOptions(opts)
    opts = opts or {}
    return {
        Title = opts.title or "",
        X = opts.x,
        Y = opts.y,
        W = opts.width,
        H = opts.height,
        AllowMove = opts.allowMove or false,
        AllowResize = opts.allowResize or false,
        AutoSizeWindow = opts.autoSize or false,
        NoOutline = opts.noOutline or false,
        SizerFilter = opts.sizerFilter,
        Border = opts.border or Tokens.BORDERS.medium,
        BgColor = opts.bgColor and toSlabColor(opts.bgColor) or nil,
        IsOpen = opts.isOpen,
    }
end

-- Style presets for common button types
Style.buttonPresets = {
    primary = {
        W = Tokens.TOUCH.primary_button_width,
        H = Tokens.TOUCH.primary_button_height,
    },
    secondary = {
        W = Tokens.TOUCH.button_min_width,
        H = Tokens.TOUCH.button_min_height,
    },
    small = {
        W = 80,
        H = 36,
    },
    icon = {
        W = Tokens.TOUCH.min_target,
        H = Tokens.TOUCH.min_target,
    },
}

-- Get button options with preset
function Style.buttonOptions(preset, overrides)
    local opts = {}

    -- Apply preset if specified
    if preset and Style.buttonPresets[preset] then
        for k, v in pairs(Style.buttonPresets[preset]) do
            opts[k] = v
        end
    end

    -- Apply overrides
    if overrides then
        for k, v in pairs(overrides) do
            opts[k] = v
        end
    end

    return opts
end

-- Input options with proper sizing for kids
function Style.inputOptions(opts)
    opts = opts or {}
    return {
        Text = opts.text or "",
        W = opts.width or 200,
        H = opts.height or Tokens.TOUCH.min_target,
        NumbersOnly = opts.numbersOnly or false,
        Align = opts.align or "left",
        MultiLine = opts.multiLine or false,
        MultiLineW = opts.multiLineW,
        MultiLineH = opts.multiLineH,
        ReturnOnText = opts.returnOnText or false,
        BgColor = opts.bgColor and toSlabColor(opts.bgColor) or nil,
    }
end

-- Create a styled panel background (for custom drawing)
function Style.drawPanelBackground(x, y, w, h, style)
    style = style or "surface"

    local bgColor, borderColor

    if style == "surface" then
        bgColor = Tokens.COLORS.surface
        borderColor = Tokens.COLORS.surface_elevated
    elseif style == "elevated" then
        bgColor = Tokens.COLORS.surface_elevated
        borderColor = Tokens.COLORS.primary_dark
    elseif style == "background" then
        bgColor = Tokens.COLORS.background
        borderColor = Tokens.COLORS.surface
    else
        bgColor = Tokens.COLORS.surface
        borderColor = Tokens.COLORS.surface_elevated
    end

    local border = Tokens.BORDERS.medium

    -- Draw border
    love.graphics.setColor(borderColor)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Draw fill
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x + border, y + border, w - border * 2, h - border * 2)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a status bar message
function Style.drawStatusBar(x, y, w, h, message, messageType)
    messageType = messageType or "info"

    local bgColor = Tokens.COLORS.surface
    local textColor = Tokens.COLORS.text_secondary
    local iconColor = Tokens.COLORS.text_secondary

    if messageType == "success" then
        textColor = Tokens.COLORS.success
        iconColor = Tokens.COLORS.success
    elseif messageType == "error" then
        textColor = Tokens.COLORS.error
        iconColor = Tokens.COLORS.error
    elseif messageType == "warning" then
        textColor = Tokens.COLORS.warning
        iconColor = Tokens.COLORS.warning
    elseif messageType == "loading" then
        textColor = Tokens.COLORS.text_secondary
    end

    -- Draw background
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h)

    -- Draw top border line
    love.graphics.setColor(Tokens.COLORS.surface_elevated)
    love.graphics.rectangle("fill", x, y, w, 2)

    -- Draw message text (centered)
    if message and message ~= "" then
        love.graphics.setColor(textColor)
        local font = love.graphics.getFont()
        local textW = font:getWidth(message)
        local textH = font:getHeight()
        local textX = x + (w - textW) / 2
        local textY = y + (h - textH) / 2
        love.graphics.print(message, math.floor(textX), math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Style
