-- ui/layout.lua
-- Layout calculations and responsive logic for LogicTales UI

local Tokens = require("ui.tokens")

local Layout = {}

-- Current scaling state
local state = {
    scale = 1,
    offsetX = 0,
    offsetY = 0,
    safeArea = {x = 0, y = 0, w = Tokens.VIRTUAL_WIDTH, h = Tokens.VIRTUAL_HEIGHT},
    windowWidth = Tokens.VIRTUAL_WIDTH,
    windowHeight = Tokens.VIRTUAL_HEIGHT,
}

-- Initialize layout system
function Layout.init()
    Layout.calculateScale()
end

-- Calculate integer scale factor and centering offset
function Layout.calculateScale()
    state.windowWidth, state.windowHeight = love.graphics.getDimensions()

    -- Calculate scale factors
    local scaleX = state.windowWidth / Tokens.VIRTUAL_WIDTH
    local scaleY = state.windowHeight / Tokens.VIRTUAL_HEIGHT

    -- Use integer scaling for pixel-perfect rendering
    local floatScale = math.min(scaleX, scaleY)
    state.scale = math.max(1, math.floor(floatScale))

    -- If window is smaller than virtual resolution, allow fractional scaling down
    if floatScale < 1 then
        state.scale = floatScale
    end

    -- Calculate centering offset
    local scaledWidth = Tokens.VIRTUAL_WIDTH * state.scale
    local scaledHeight = Tokens.VIRTUAL_HEIGHT * state.scale
    state.offsetX = math.floor((state.windowWidth - scaledWidth) / 2)
    state.offsetY = math.floor((state.windowHeight - scaledHeight) / 2)

    -- Get safe area (for notched displays)
    if love.window.getSafeArea then
        local sx, sy, sw, sh = love.window.getSafeArea()
        state.safeArea = {x = sx, y = sy, w = sw, h = sh}
    end

    return state.scale
end

-- Get current scale
function Layout.getScale()
    return state.scale
end

-- Get centering offset
function Layout.getOffset()
    return state.offsetX, state.offsetY
end

-- Apply transform for rendering at virtual resolution
function Layout.applyTransform()
    love.graphics.translate(state.offsetX, state.offsetY)
    love.graphics.scale(state.scale, state.scale)
end

-- Reset transform
function Layout.resetTransform()
    love.graphics.origin()
end

-- Convert screen coordinates to virtual coordinates
function Layout.screenToVirtual(screenX, screenY)
    local vx = (screenX - state.offsetX) / state.scale
    local vy = (screenY - state.offsetY) / state.scale
    return vx, vy
end

-- Convert virtual coordinates to screen coordinates
function Layout.virtualToScreen(virtualX, virtualY)
    local sx = virtualX * state.scale + state.offsetX
    local sy = virtualY * state.scale + state.offsetY
    return sx, sy
end

-- Check if point is within virtual bounds
function Layout.isInBounds(vx, vy)
    return vx >= 0 and vx <= Tokens.VIRTUAL_WIDTH and
           vy >= 0 and vy <= Tokens.VIRTUAL_HEIGHT
end

-- Get Play mode layout (split left/right)
function Layout.getPlayLayout()
    local L = Tokens.LAYOUT.play
    local w = Tokens.VIRTUAL_WIDTH
    local h = Tokens.VIRTUAL_HEIGHT

    local leftWidth = math.floor(w * L.left_percent)
    local rightWidth = w - leftWidth
    local contentHeight = h - L.status_bar_height

    return {
        -- Left panel (image area)
        leftPanel = {
            x = 0,
            y = 0,
            width = leftWidth,
            height = contentHeight,
            padding = L.panel_padding,
            -- Inner content area
            contentX = L.panel_padding,
            contentY = L.panel_padding,
            contentWidth = leftWidth - L.panel_padding * 2,
            contentHeight = contentHeight - L.panel_padding * 2,
        },

        -- Right panel (question/answers)
        rightPanel = {
            x = leftWidth,
            y = 0,
            width = rightWidth,
            height = contentHeight,
            padding = L.panel_padding + 8, -- Extra padding for kids
            contentX = leftWidth + L.panel_padding + 8,
            contentY = L.panel_padding + 8,
            contentWidth = rightWidth - (L.panel_padding + 8) * 2,
            contentHeight = contentHeight - (L.panel_padding + 8) * 2,
        },

        -- Status bar (bottom)
        statusBar = {
            x = 0,
            y = contentHeight,
            width = w,
            height = L.status_bar_height,
            padding = Tokens.SPACING.sm,
        },

        -- Image card constraints
        imageCard = {
            maxWidth = L.image_max_width,
            maxHeight = L.image_max_height,
            border = L.image_border,
        },

        -- Button layout
        buttons = {
            width = L.button_width,
            height = L.button_height,
            gap = L.button_gap,
        },
    }
end

-- Get Config mode layout (storybook-style: Thumbnails | Preview | Control Deck)
-- Uses window dimensions directly since Create mode doesn't use virtual scaling
function Layout.getConfigLayout()
    local L = Tokens.LAYOUT.config
    local w, h = love.graphics.getDimensions()

    -- Fixed dimensions
    local thumbnailsWidth = 160       -- Left sidebar for page thumbnails
    local controlDeckWidth = 280      -- Right sidebar for control deck
    local dreamItBarHeight = 70       -- Bottom bar for Dream It button
    local margin = 10                 -- Margin between elements

    -- Calculate positions with proper spacing
    local thumbnailsX = margin
    local previewX = thumbnailsX + thumbnailsWidth + margin
    local controlDeckX = w - controlDeckWidth - margin
    local previewWidth = controlDeckX - previewX - margin
    local previewHeight = h - dreamItBarHeight - margin * 2

    -- Story settings header (collapsible, at top of control deck)
    local storySettingsCollapsedHeight = 50
    local storySettingsExpandedHeight = 200

    -- Minimum window width check: if too narrow, reduce sidebar widths
    local minPreviewWidth = 200
    if previewWidth < minPreviewWidth then
        -- Window is too narrow, proportionally reduce sidebar widths
        local availableForSidebars = w - minPreviewWidth - margin * 4
        thumbnailsWidth = math.floor(availableForSidebars * 0.35)
        controlDeckWidth = math.floor(availableForSidebars * 0.65)

        -- Recalculate positions
        thumbnailsX = margin
        previewX = thumbnailsX + thumbnailsWidth + margin
        controlDeckX = w - controlDeckWidth - margin
        previewWidth = controlDeckX - previewX - margin
    end

    return {
        -- Page thumbnails panel (left sidebar)
        thumbnailsPanel = {
            x = thumbnailsX,
            y = margin,
            width = thumbnailsWidth,
            height = h - dreamItBarHeight - margin * 2,
            padding = Tokens.SPACING.xs,
            thumbnailWidth = 120,
            thumbnailHeight = 80,
            thumbnailGap = 8,
        },

        -- Preview panel (center - BIG!)
        previewPanel = {
            x = previewX,
            y = margin,
            width = previewWidth,
            height = previewHeight,
            padding = L.panel_padding,
            -- Calculate scale to fit 800x600 in available space
            scale = math.min(
                (previewWidth - L.panel_padding * 2 - 20) / 800,
                (previewHeight - L.panel_padding * 2 - 50) / 600
            ) * 0.90,
        },

        -- Story settings header (collapsible, top of right sidebar)
        storySettingsHeader = {
            x = controlDeckX,
            y = margin,
            width = controlDeckWidth,
            height = storySettingsCollapsedHeight,
            expandedHeight = storySettingsExpandedHeight,
            collapsedHeight = storySettingsCollapsedHeight,
        },

        -- Control deck panel (right sidebar)
        controlDeckPanel = {
            x = controlDeckX,
            y = margin + storySettingsCollapsedHeight + 5,
            width = controlDeckWidth,
            height = h - dreamItBarHeight - storySettingsCollapsedHeight - margin * 2 - 5,
            padding = L.panel_padding,
        },

        -- Dream It button bar (bottom)
        dreamItBar = {
            x = margin,
            y = h - dreamItBarHeight - margin,
            width = w - margin * 2,
            height = dreamItBarHeight,
            buttonWidth = 250,
            buttonHeight = 50,
        },

        -- Legacy compatibility (kept for any remaining references)
        pagesPanel = {
            x = thumbnailsX,
            y = margin,
            width = thumbnailsWidth,
            height = h - dreamItBarHeight - margin * 2,
            padding = Tokens.SPACING.xs,
        },

        editorPanel = {
            x = controlDeckX,
            y = margin + storySettingsCollapsedHeight + 5,
            width = controlDeckWidth,
            height = h - dreamItBarHeight - storySettingsCollapsedHeight - margin * 2 - 5,
            padding = L.panel_padding,
        },

        -- Status bar (now toast-style, positioned dynamically)
        statusBar = {
            x = margin,
            y = h - dreamItBarHeight - margin - 40,
            width = 400,
            height = 35,
            padding = Tokens.SPACING.sm,
        },
    }
end

-- Get responsive breakpoint status
function Layout.getBreakpoint()
    local w = Tokens.VIRTUAL_WIDTH

    if w < 600 then
        return "mobile"
    elseif w < 900 then
        return "tablet"
    else
        return "desktop"
    end
end

-- Check if we should stack Play mode vertically (for very narrow windows)
function Layout.shouldStackPlayMode()
    -- In practice, we design for 1280x720 minimum, so this rarely triggers
    return state.windowWidth / state.scale < 900
end

-- Center a rect within a container
function Layout.centerIn(containerX, containerY, containerW, containerH, itemW, itemH)
    local x = containerX + math.floor((containerW - itemW) / 2)
    local y = containerY + math.floor((containerH - itemH) / 2)
    return x, y
end

-- Calculate image dimensions maintaining aspect ratio
function Layout.fitImage(imageW, imageH, maxW, maxH)
    local scale = math.min(maxW / imageW, maxH / imageH)
    local newW = math.floor(imageW * scale)
    local newH = math.floor(imageH * scale)
    return newW, newH, scale
end

-- Get virtual dimensions
function Layout.getVirtualSize()
    return Tokens.VIRTUAL_WIDTH, Tokens.VIRTUAL_HEIGHT
end

-- Get window dimensions
function Layout.getWindowSize()
    return state.windowWidth, state.windowHeight
end

return Layout
