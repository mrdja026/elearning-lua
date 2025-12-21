-- components/image_card.lua
-- Image display card component for Play mode

local Tokens = require("ui.tokens")
local NineSlice = require("ui.nineslice")

local ImageCard = {}

-- Image cache
local imageCache = {}

-- Card panel style
local cardPanel = nil

-- Initialize card panel
local function getCardPanel()
    if not cardPanel then
        cardPanel = NineSlice.createPanel("card")
    end
    return cardPanel
end

-- Load an image with caching
function ImageCard.loadImage(path)
    if not path or path == "" then
        return nil
    end

    -- Check cache first
    if imageCache[path] then
        return imageCache[path]
    end

    -- Try to load the image
    local success, result = pcall(function()
        local img = love.graphics.newImage(path)
        img:setFilter("nearest", "nearest")  -- Pixel-perfect scaling
        return img
    end)

    if success then
        imageCache[path] = result
        return result
    else
        -- Try loading from save directory
        local savePath = love.filesystem.getSaveDirectory() .. "/" .. path
        success, result = pcall(function()
            local img = love.graphics.newImage(path)
            img:setFilter("nearest", "nearest")
            return img
        end)

        if success then
            imageCache[path] = result
            return result
        end
    end

    return nil
end

-- Clear image cache
function ImageCard.clearCache()
    imageCache = {}
end

-- Remove specific image from cache
function ImageCard.invalidateCache(path)
    imageCache[path] = nil
end

-- Draw image card
function ImageCard.draw(x, y, width, height, image, options)
    options = options or {}

    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    local border = options.border or Tokens.BORDERS.thick
    local bgColor = options.bgColor or Tokens.COLORS.surface
    local borderColor = options.borderColor or Tokens.COLORS.surface_elevated

    -- Draw card frame
    local panel = getCardPanel()
    panel:draw(x, y, width, height)

    -- Calculate inner content area
    local innerX = x + border + Tokens.SPACING.xs
    local innerY = y + border + Tokens.SPACING.xs
    local innerW = width - (border + Tokens.SPACING.xs) * 2
    local innerH = height - (border + Tokens.SPACING.xs) * 2

    if image then
        -- Draw the image scaled to fit
        local imgW, imgH = image:getDimensions()

        -- Calculate scale to fit while maintaining aspect ratio
        local scaleX = innerW / imgW
        local scaleY = innerH / imgH
        local scale = math.min(scaleX, scaleY)

        -- Use integer scale for pixel art when scaling up
        if scale > 1 then
            scale = math.floor(scale)
        end

        local drawW = imgW * scale
        local drawH = imgH * scale

        -- Center image in card
        local drawX = innerX + (innerW - drawW) / 2
        local drawY = innerY + (innerH - drawH) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, math.floor(drawX), math.floor(drawY), 0, scale, scale)
    else
        -- Draw placeholder
        love.graphics.setColor(Tokens.COLORS.surface_elevated)
        love.graphics.rectangle("fill", innerX, innerY, innerW, innerH)

        -- Draw placeholder text
        love.graphics.setColor(Tokens.COLORS.text_disabled)
        local font = love.graphics.getFont()
        local text = "[No Image]"
        local textW = font:getWidth(text)
        local textH = font:getHeight()
        local textX = innerX + (innerW - textW) / 2
        local textY = innerY + (innerH - textH) / 2
        love.graphics.print(text, math.floor(textX), math.floor(textY))
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw a mini preview (for editor)
function ImageCard.drawMini(x, y, width, height, image)
    x = math.floor(x)
    y = math.floor(y)

    -- Simple border
    love.graphics.setColor(Tokens.COLORS.surface_elevated)
    love.graphics.rectangle("fill", x, y, width, height)

    local border = 2
    love.graphics.setColor(Tokens.COLORS.surface)
    love.graphics.rectangle("fill", x + border, y + border, width - border * 2, height - border * 2)

    if image then
        local imgW, imgH = image:getDimensions()
        local innerW = width - border * 2 - 4
        local innerH = height - border * 2 - 4

        local scale = math.min(innerW / imgW, innerH / imgH)
        if scale > 1 then scale = math.floor(scale) end

        local drawW = imgW * scale
        local drawH = imgH * scale
        local drawX = x + (width - drawW) / 2
        local drawY = y + (height - drawH) / 2

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, math.floor(drawX), math.floor(drawY), 0, scale, scale)
    else
        love.graphics.setColor(Tokens.COLORS.text_disabled)
        local font = love.graphics.getFont()
        local text = "?"
        local textW = font:getWidth(text)
        love.graphics.print(text, x + (width - textW) / 2, y + height / 2 - 8)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return ImageCard
