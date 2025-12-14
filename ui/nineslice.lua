-- ui/nineslice.lua
-- 9-slice frame rendering for pixel-perfect scalable panels
--
-- 9-slice divides an image into 9 sections:
-- +---+-------+---+
-- | 1 |   2   | 3 |  <- corners (1,3,7,9) never scale
-- +---+-------+---+
-- | 4 |   5   | 6 |  <- edges (2,8) scale horizontally, (4,6) scale vertically
-- +---+-------+---+
-- | 7 |   8   | 9 |  <- center (5) scales both ways
-- +---+-------+---+

local Tokens = require("ui.tokens")

local NineSlice = {}
NineSlice.__index = NineSlice

-- Create a new 9-slice from an image file
-- @param imagePath: Path to the image file
-- @param cornerSize: Size of corner sections (assumes square corners)
-- @param margins: Optional {left, top, right, bottom} for asymmetric slicing
function NineSlice.new(imagePath, cornerSize, margins)
    local self = setmetatable({}, NineSlice)

    -- Load image with nearest-neighbor filtering for crisp pixels
    self.image = love.graphics.newImage(imagePath)
    self.image:setFilter("nearest", "nearest")

    local iw, ih = self.image:getDimensions()
    self.imageWidth = iw
    self.imageHeight = ih

    -- Set up slice dimensions
    if margins then
        self.left = margins.left or cornerSize
        self.top = margins.top or cornerSize
        self.right = margins.right or cornerSize
        self.bottom = margins.bottom or cornerSize
    else
        self.left = cornerSize
        self.top = cornerSize
        self.right = cornerSize
        self.bottom = cornerSize
    end

    -- Calculate center dimensions
    local centerW = iw - self.left - self.right
    local centerH = ih - self.top - self.bottom

    -- Create quads for each section
    self.quads = {
        -- Top row
        topLeft = love.graphics.newQuad(0, 0, self.left, self.top, iw, ih),
        topCenter = love.graphics.newQuad(self.left, 0, centerW, self.top, iw, ih),
        topRight = love.graphics.newQuad(iw - self.right, 0, self.right, self.top, iw, ih),

        -- Middle row
        middleLeft = love.graphics.newQuad(0, self.top, self.left, centerH, iw, ih),
        center = love.graphics.newQuad(self.left, self.top, centerW, centerH, iw, ih),
        middleRight = love.graphics.newQuad(iw - self.right, self.top, self.right, centerH, iw, ih),

        -- Bottom row
        bottomLeft = love.graphics.newQuad(0, ih - self.bottom, self.left, self.bottom, iw, ih),
        bottomCenter = love.graphics.newQuad(self.left, ih - self.bottom, centerW, self.bottom, iw, ih),
        bottomRight = love.graphics.newQuad(iw - self.right, ih - self.bottom, self.right, self.bottom, iw, ih),
    }

    -- Store center dimensions for scaling calculations
    self.centerWidth = centerW
    self.centerHeight = centerH

    return self
end

-- Draw the 9-slice at specified position and size
-- @param x, y: Position (top-left corner)
-- @param width, height: Target size
-- @param color: Optional color tint {r, g, b, a}
function NineSlice:draw(x, y, width, height, color)
    -- Ensure integer positions for pixel-perfect rendering
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    -- Calculate stretched center dimensions
    local stretchW = width - self.left - self.right
    local stretchH = height - self.top - self.bottom

    -- Calculate scale factors for edges and center
    local scaleX = stretchW / self.centerWidth
    local scaleY = stretchH / self.centerHeight

    -- Set color if provided
    if color then
        love.graphics.setColor(color)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Draw corners (no scaling)
    love.graphics.draw(self.image, self.quads.topLeft, x, y)
    love.graphics.draw(self.image, self.quads.topRight, x + width - self.right, y)
    love.graphics.draw(self.image, self.quads.bottomLeft, x, y + height - self.bottom)
    love.graphics.draw(self.image, self.quads.bottomRight, x + width - self.right, y + height - self.bottom)

    -- Draw horizontal edges (scale X only)
    love.graphics.draw(self.image, self.quads.topCenter, x + self.left, y, 0, scaleX, 1)
    love.graphics.draw(self.image, self.quads.bottomCenter, x + self.left, y + height - self.bottom, 0, scaleX, 1)

    -- Draw vertical edges (scale Y only)
    love.graphics.draw(self.image, self.quads.middleLeft, x, y + self.top, 0, 1, scaleY)
    love.graphics.draw(self.image, self.quads.middleRight, x + width - self.right, y + self.top, 0, 1, scaleY)

    -- Draw center (scale both)
    love.graphics.draw(self.image, self.quads.center, x + self.left, y + self.top, 0, scaleX, scaleY)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Get minimum size this 9-slice can be drawn at
function NineSlice:getMinSize()
    return self.left + self.right, self.top + self.bottom
end

-- Create a simple colored panel (no image, just rectangles)
-- This is a fallback when no 9-slice image is available
local SimplePanel = {}
SimplePanel.__index = SimplePanel

function NineSlice.newSimplePanel(borderWidth, borderColor, fillColor, shadowOffset)
    local self = setmetatable({}, SimplePanel)
    self.borderWidth = borderWidth or Tokens.BORDERS.medium
    self.borderColor = borderColor or Tokens.COLORS.surface_elevated
    self.fillColor = fillColor or Tokens.COLORS.surface
    self.shadowOffset = shadowOffset or 0
    self.shadowColor = Tokens.COLORS.shadow
    return self
end

function SimplePanel:draw(x, y, width, height)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    -- Draw shadow (offset rectangle)
    if self.shadowOffset > 0 then
        love.graphics.setColor(self.shadowColor)
        love.graphics.rectangle("fill",
            x + self.shadowOffset,
            y + self.shadowOffset,
            width, height)
    end

    -- Draw border (outer rectangle)
    if self.borderWidth > 0 then
        love.graphics.setColor(self.borderColor)
        love.graphics.rectangle("fill", x, y, width, height)
    end

    -- Draw fill (inner rectangle)
    love.graphics.setColor(self.fillColor)
    love.graphics.rectangle("fill",
        x + self.borderWidth,
        y + self.borderWidth,
        width - self.borderWidth * 2,
        height - self.borderWidth * 2)

    love.graphics.setColor(1, 1, 1, 1)
end

function SimplePanel:getMinSize()
    return self.borderWidth * 2, self.borderWidth * 2
end

-- Factory function to create common panel types
function NineSlice.createPanel(style)
    style = style or "surface"

    if style == "surface" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.medium,
            Tokens.COLORS.surface_elevated,
            Tokens.COLORS.surface,
            0
        )
    elseif style == "elevated" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.medium,
            Tokens.COLORS.primary_dark,
            Tokens.COLORS.surface_elevated,
            Tokens.ELEVATION.medium.offset
        )
    elseif style == "card" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.thick,
            Tokens.COLORS.surface_elevated,
            Tokens.COLORS.surface,
            Tokens.ELEVATION.low.offset
        )
    elseif style == "button" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.thick,
            Tokens.COLORS.primary_dark,
            Tokens.COLORS.primary,
            Tokens.ELEVATION.low.offset
        )
    elseif style == "button_secondary" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.thick,
            Tokens.COLORS.secondary_dark,
            Tokens.COLORS.secondary,
            Tokens.ELEVATION.low.offset
        )
    elseif style == "input" then
        return NineSlice.newSimplePanel(
            Tokens.BORDERS.thin,
            Tokens.COLORS.input_border,
            Tokens.COLORS.input_bg,
            0
        )
    else
        -- Default
        return NineSlice.newSimplePanel()
    end
end

return NineSlice
