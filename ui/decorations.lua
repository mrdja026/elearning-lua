-- ui/decorations.lua
-- Procedural pixel-art decorations for storybook theme
-- Drawn BEFORE Slab.Draw() to appear behind semi-transparent panels

local Tokens = require("ui.tokens")

local Decorations = {}

-- Configuration
local config = {
    enabled = true,
    seed = 42,  -- Fixed seed for consistent decoration placement
}

-- Draw a pixel-art style tree (triangular foliage + rectangular trunk)
function Decorations.drawPixelTree(x, y, scale)
    scale = scale or 1
    local trunkW = math.floor(6 * scale)
    local trunkH = math.floor(12 * scale)
    local foliageSize = math.floor(24 * scale)

    -- Draw trunk
    love.graphics.setColor(Tokens.COLORS.deco_tree_trunk)
    love.graphics.rectangle("fill",
        math.floor(x - trunkW / 2),
        math.floor(y),
        trunkW,
        trunkH
    )

    -- Draw foliage layers (3 stacked triangles)
    local colors = {
        Tokens.COLORS.deco_tree_dark,
        Tokens.COLORS.deco_tree_light,
        Tokens.COLORS.deco_tree_dark
    }

    for layer = 1, 3 do
        local layerSize = foliageSize - (layer - 1) * 6 * scale
        local layerY = y - layer * foliageSize * 0.6

        love.graphics.setColor(colors[layer])

        -- Draw triangle as rows of pixels
        local rows = math.floor(layerSize)
        for row = 0, rows do
            local rowWidth = math.floor((row / rows) * layerSize * 2)
            if rowWidth > 0 then
                love.graphics.rectangle("fill",
                    math.floor(x - rowWidth / 2),
                    math.floor(layerY + row),
                    rowWidth,
                    1
                )
            end
        end
    end
end

-- Draw a pixel-art style circle
function Decorations.drawPixelCircle(cx, cy, radius, color)
    love.graphics.setColor(color or Tokens.COLORS.deco_circle)

    -- Draw circle using pixel-by-pixel approach for crisp edges
    local r2 = radius * radius
    for dy = -radius, radius do
        for dx = -radius, radius do
            if dx * dx + dy * dy <= r2 then
                love.graphics.rectangle("fill",
                    math.floor(cx + dx),
                    math.floor(cy + dy),
                    1, 1
                )
            end
        end
    end
end

-- Draw a 4-point star/sparkle
function Decorations.drawStar(x, y, size, color)
    love.graphics.setColor(color or Tokens.COLORS.deco_star)

    local half = math.floor(size / 2)

    -- Horizontal line
    love.graphics.rectangle("fill",
        math.floor(x - half),
        math.floor(y),
        size, 1
    )

    -- Vertical line
    love.graphics.rectangle("fill",
        math.floor(x),
        math.floor(y - half),
        1, size
    )

    -- Center dot (brighter)
    love.graphics.setColor(1, 1, 1, (color and color[4]) or 1)
    love.graphics.rectangle("fill",
        math.floor(x),
        math.floor(y),
        1, 1
    )
end

-- Draw a simple triangle (for additional decorations)
function Decorations.drawTriangle(x, y, size, color, inverted)
    love.graphics.setColor(color or Tokens.COLORS.forest_green)

    local rows = math.floor(size)
    for row = 0, rows do
        local width
        if inverted then
            width = math.floor((1 - row / rows) * size * 2) + 1
        else
            width = math.floor((row / rows) * size * 2) + 1
        end

        local posY = inverted and (y + rows - row) or (y + row)
        love.graphics.rectangle("fill",
            math.floor(x - width / 2),
            math.floor(posY),
            width, 1
        )
    end
end

-- Main decoration draw function - call BEFORE Slab.Draw()
function Decorations.draw()
    if not config.enabled then return end

    local w, h = love.graphics.getDimensions()

    -- Use seeded random for consistent placement
    math.randomseed(config.seed)

    -- Draw trees along left edge (behind thumbnails panel)
    for i = 1, 2 do
        local treeX = 30 + math.random(0, 30)
        local treeY = 150 + i * 200 + math.random(-30, 30)
        local treeScale = 0.8 + math.random() * 0.4
        Decorations.drawPixelTree(treeX, treeY, treeScale)
    end

    -- Draw trees along right edge (behind control deck)
    for i = 1, 2 do
        local treeX = w - 30 - math.random(0, 30)
        local treeY = 200 + i * 180 + math.random(-30, 30)
        local treeScale = 0.7 + math.random() * 0.3
        Decorations.drawPixelTree(treeX, treeY, treeScale)
    end

    -- Scattered stars in background (subtle)
    for i = 1, 12 do
        local starX = 80 + math.random(0, w - 160)
        local starY = 50 + math.random(0, h - 150)
        local starSize = 3 + math.random(0, 4)
        local alpha = 0.3 + math.random() * 0.4
        Decorations.drawStar(starX, starY, starSize,
            {Tokens.COLORS.deco_star[1],
             Tokens.COLORS.deco_star[2],
             Tokens.COLORS.deco_star[3],
             alpha})
    end

    -- Soft circles as ambient decoration
    for i = 1, 6 do
        local circleX = 100 + math.random(0, w - 200)
        local circleY = 100 + math.random(0, h - 200)
        local circleR = 10 + math.random(0, 15)
        local alpha = 0.1 + math.random() * 0.15
        Decorations.drawPixelCircle(circleX, circleY, circleR,
            {Tokens.COLORS.warm_orange[1],
             Tokens.COLORS.warm_orange[2],
             Tokens.COLORS.warm_orange[3],
             alpha})
    end

    -- Small triangles as ground decoration
    for i = 1, 4 do
        local triX = 50 + math.random(0, w - 100)
        local triY = h - 100 - math.random(0, 50)
        local triSize = 8 + math.random(0, 8)
        local alpha = 0.2 + math.random() * 0.2
        Decorations.drawTriangle(triX, triY, triSize,
            {Tokens.COLORS.forest_green[1],
             Tokens.COLORS.forest_green[2],
             Tokens.COLORS.forest_green[3],
             alpha}, false)
    end

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Enable/disable decorations
function Decorations.setEnabled(enabled)
    config.enabled = enabled
end

-- Change seed for different layouts
function Decorations.setSeed(seed)
    config.seed = seed
end

return Decorations
