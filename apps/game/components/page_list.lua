-- components/page_list.lua
-- Page list sidebar component for Config mode
-- Works with Slab UI

local Slab = require("libraries.Slab")
local Tokens = require("ui.tokens")

local PageList = {}

-- Draw page list panel
function PageList.draw(x, y, width, height, pages, selectedIndex, callbacks)
    callbacks = callbacks or {}

    Slab.BeginWindow("PagesPanel", {
        Title = "Pages",
        X = x,
        Y = y,
        W = width,
        H = height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    -- List box for pages
    local listH = height - 100  -- Leave room for buttons
    Slab.BeginListBox("PageList", {H = listH})

    local newSelectedIndex = selectedIndex

    for i, page in ipairs(pages) do
        local label = "Page " .. page.id
        Slab.BeginListBoxItem("Page_" .. i, {Selected = (i == selectedIndex)})
        Slab.Text(label)
        if Slab.IsListBoxItemClicked() then
            newSelectedIndex = i
            if callbacks.onSelect then
                callbacks.onSelect(i)
            end
        end
        Slab.EndListBoxItem()
    end

    Slab.EndListBox()

    -- Button row
    local btnW = (width - 30) / 2

    if Slab.Button("Add Page", {W = btnW}) then
        if callbacks.onAdd then
            callbacks.onAdd()
        end
    end

    Slab.SameLine()

    if Slab.Button("Delete", {W = btnW}) then
        if callbacks.onDelete then
            callbacks.onDelete()
        end
    end

    Slab.EndWindow()

    return newSelectedIndex
end

-- Draw a standalone page item (for custom rendering)
function PageList.drawPageItem(x, y, width, height, page, isSelected, isFocused)
    x = math.floor(x)
    y = math.floor(y)
    width = math.floor(width)
    height = math.floor(height)

    -- Background
    local bgColor = Tokens.COLORS.surface
    if isSelected then
        bgColor = Tokens.COLORS.primary_dark
    elseif isFocused then
        bgColor = Tokens.COLORS.surface_elevated
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)

    -- Focus ring
    if isFocused then
        love.graphics.setColor(Tokens.COLORS.accent)
        love.graphics.setLineWidth(Tokens.BORDERS.medium)
        love.graphics.rectangle("line", x, y, width, height)
    end

    -- Text
    local textColor = isSelected and Tokens.COLORS.text_on_primary or Tokens.COLORS.text_primary
    love.graphics.setColor(textColor)

    local label = "Page " .. (page.id or "?")
    local font = love.graphics.getFont()
    local textH = font:getHeight()
    local textY = y + (height - textH) / 2

    love.graphics.print(label, x + Tokens.SPACING.sm, math.floor(textY))

    love.graphics.setColor(1, 1, 1, 1)
end

return PageList
