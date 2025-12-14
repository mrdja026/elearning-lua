-- screens/config.lua
-- Config/Editor Mode screen with 3-column layout
-- Uses Slab for immediate mode GUI

local Slab = require("libraries.Slab")
local Tokens = require("ui.tokens")
local Layout = require("ui.layout")
local Widgets = require("ui.widgets")
local StatusBar = require("components.status_bar")
local PageList = require("components.page_list")
local PageEditor = require("components.page_editor")

local ConfigScreen = {}

-- Screen state
local state = {
    initialized = false,
    statusMessage = "",
    statusType = "info",
    statusTimer = 0,
}

-- Initialize config screen
function ConfigScreen.init()
    state.initialized = true
    state.statusMessage = ""
    state.statusType = "info"
    state.statusTimer = 0
end

-- Enter config screen
function ConfigScreen.enter()
    state.statusMessage = ""
    state.statusType = "info"
end

-- Exit config screen
function ConfigScreen.exit()
    -- Nothing to clean up
end

-- Show status message
function ConfigScreen.showStatus(message, msgType, duration)
    state.statusMessage = message or ""
    state.statusType = msgType or "info"
    state.statusTimer = duration or 3
end

-- Update config screen
function ConfigScreen.update(dt, editor)
    -- Update status timer
    if state.statusTimer > 0 then
        state.statusTimer = state.statusTimer - dt
        if state.statusTimer <= 0 then
            state.statusMessage = ""
            state.statusType = "info"
        end
    end

    -- Forward to editor update
    if editor then
        editor.update(dt)
    end
end

-- Draw config screen (called from main.lua drawCreateMode)
function ConfigScreen.draw(editor)
    local layout = Layout.getConfigLayout()

    -- Draw background
    love.graphics.setColor(Tokens.COLORS.background)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    -- Draw status bar at bottom (window coordinates, not virtual)
    local statusH = 40
    local statusY = love.graphics.getHeight() - statusH
    StatusBar.draw(
        0,
        statusY,
        love.graphics.getWidth(),
        statusH,
        state.statusMessage,
        state.statusType
    )

    love.graphics.setColor(1, 1, 1, 1)
end

-- Draw just the status bar (for use with existing editor)
function ConfigScreen.drawStatusBar()
    local statusH = 40
    local statusY = love.graphics.getHeight() - statusH

    StatusBar.draw(
        0,
        statusY,
        love.graphics.getWidth(),
        statusH,
        state.statusMessage,
        state.statusType
    )
end

-- Get current status
function ConfigScreen.getStatus()
    return state.statusMessage, state.statusType
end

return ConfigScreen
