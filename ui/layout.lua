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

-- Get Config mode layout (3-column editor)
-- Uses window dimensions directly since Create mode doesn't use virtual scaling
function Layout.getConfigLayout()
    local L = Tokens.LAYOUT.config
    local w, h = love.graphics.getDimensions()

    -- Top section heights
    local fileHeight = 60
    local storyHeight = 160  -- Increased for Topic + General Image Prompt fields
    local topAreaHeight = fileHeight + storyHeight + 20  -- 10px margin + 10px gap

    -- Calculate main content area
    local contentY = topAreaHeight
    local statusH = 40
    local contentHeight = h - topAreaHeight - statusH

    -- Panel widths - responsive to window size
    local pagesWidth = math.min(200, math.floor(w * 0.15))
    local previewWidth = math.min(420, math.floor(w * 0.35))
    local editorWidth = w - pagesWidth - previewWidth - 30  -- 30px for margins

    -- Calculate panel positions
    local pagesX = 10
    local editorX = pagesX + pagesWidth + 10
    local previewX = editorX + editorWidth + 10

    return {
        -- File panel (top row)
        filePanel = {
            x = 10,
            y = 10,
            width = editorWidth + pagesWidth,
            height = fileHeight,
        },

        -- Story panel (below file panel)
        storyPanel = {
            x = 10,
            y = 10 + fileHeight + 10,
            width = editorWidth + pagesWidth,
            height = storyHeight,
        },

        -- Pages panel (left sidebar)
        pagesPanel = {
            x = pagesX,
            y = contentY,
            width = pagesWidth,
            height = contentHeight,
            padding = Tokens.SPACING.xs + 4,
            contentX = pagesX + Tokens.SPACING.xs + 4,
            contentY = contentY + Tokens.SPACING.xs + 4,
            contentWidth = pagesWidth - (Tokens.SPACING.xs + 4) * 2,
            contentHeight = contentHeight - (Tokens.SPACING.xs + 4) * 2,
        },

        -- Editor panel (center)
        editorPanel = {
            x = editorX,
            y = contentY,
            width = editorWidth,
            height = contentHeight,
            padding = L.panel_padding,
            contentX = editorX + L.panel_padding,
            contentY = contentY + L.panel_padding,
            contentWidth = editorWidth - L.panel_padding * 2,
            contentHeight = contentHeight - L.panel_padding * 2,
        },

        -- Preview panel (right)
        previewPanel = {
            x = previewX,
            y = contentY,
            width = previewWidth,
            height = contentHeight,
            padding = L.panel_padding,
            scale = L.preview_scale,
            contentX = previewX + L.panel_padding,
            contentY = contentY + L.panel_padding,
            contentWidth = previewWidth - L.panel_padding * 2,
            contentHeight = contentHeight - L.panel_padding * 2,
        },

        -- Status bar (bottom)
        statusBar = {
            x = 0,
            y = h - statusH,
            width = w,
            height = statusH,
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
