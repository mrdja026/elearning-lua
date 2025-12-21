-- ui/input_manager.lua
-- Unified input handling for mouse, keyboard, touch, and controller
-- Provides focus management and navigation abstraction

local Layout = require("ui.layout")

local InputManager = {}

-- Navigation directions
local NAV = {
    UP = "up",
    DOWN = "down",
    LEFT = "left",
    RIGHT = "right",
}

-- Focus state
local state = {
    -- List of focusable elements {id, bounds, callbacks, enabled, row, col}
    elements = {},
    -- Currently focused element ID
    focusedId = nil,
    -- Focus index in elements list
    focusIndex = 0,
    -- Input state tracking
    pointerX = 0,
    pointerY = 0,
    pointerPressed = false,
    pointerJustPressed = false,
    pointerJustReleased = false,
    -- Previous frame state
    prevPointerPressed = false,
    -- Touch state
    touchActive = false,
    touchId = nil,
    -- Gamepad state
    gamepadConnected = false,
    gamepad = nil,
}

-- Initialize input manager
function InputManager.init()
    InputManager.clear()
end

-- Clear all registered elements (call when changing screens)
function InputManager.clear()
    state.elements = {}
    state.focusedId = nil
    state.focusIndex = 0
end

-- Register a focusable element
-- @param id: Unique string identifier
-- @param bounds: {x, y, width, height} in virtual coordinates
-- @param callbacks: {onActivate, onFocus, onBlur} functions
-- @param options: {enabled, row, col} for grid navigation
function InputManager.register(id, bounds, callbacks, options)
    options = options or {}

    local element = {
        id = id,
        bounds = bounds,
        callbacks = callbacks or {},
        enabled = options.enabled ~= false,
        row = options.row or 0,
        col = options.col or 0,
    }

    -- Check if already registered, update if so
    for i, el in ipairs(state.elements) do
        if el.id == id then
            state.elements[i] = element
            return
        end
    end

    table.insert(state.elements, element)
end

-- Unregister an element
function InputManager.unregister(id)
    for i, el in ipairs(state.elements) do
        if el.id == id then
            table.remove(state.elements, i)
            if state.focusedId == id then
                state.focusedId = nil
                state.focusIndex = 0
            end
            return
        end
    end
end

-- Enable/disable an element
function InputManager.setEnabled(id, enabled)
    for _, el in ipairs(state.elements) do
        if el.id == id then
            el.enabled = enabled
            if not enabled and state.focusedId == id then
                InputManager.focusNext()
            end
            return
        end
    end
end

-- Update input state (call in love.update)
function InputManager.update(dt)
    -- Store previous state
    state.prevPointerPressed = state.pointerPressed

    -- Update pointer position (mouse or touch)
    local touches = love.touch.getTouches()
    if #touches > 0 then
        state.touchActive = true
        state.touchId = touches[1]
        local tx, ty = love.touch.getPosition(touches[1])
        state.pointerX, state.pointerY = Layout.screenToVirtual(tx, ty)
        state.pointerPressed = true
    else
        state.touchActive = false
        state.touchId = nil
        local mx, my = love.mouse.getPosition()
        state.pointerX, state.pointerY = Layout.screenToVirtual(mx, my)
        state.pointerPressed = love.mouse.isDown(1)
    end

    -- Detect press/release edges
    state.pointerJustPressed = state.pointerPressed and not state.prevPointerPressed
    state.pointerJustReleased = not state.pointerPressed and state.prevPointerPressed

    -- Update gamepad state
    local joysticks = love.joystick.getJoysticks()
    state.gamepadConnected = #joysticks > 0
    if state.gamepadConnected then
        state.gamepad = joysticks[1]
    else
        state.gamepad = nil
    end

    -- Handle pointer clicks on elements
    if state.pointerJustPressed then
        local clickedId = InputManager.getElementAtPoint(state.pointerX, state.pointerY)
        if clickedId then
            InputManager.setFocus(clickedId)
        end
    end

    if state.pointerJustReleased then
        local clickedId = InputManager.getElementAtPoint(state.pointerX, state.pointerY)
        if clickedId and clickedId == state.focusedId then
            InputManager.activate()
        end
    end
end

-- Get element at point (virtual coords)
function InputManager.getElementAtPoint(vx, vy)
    for _, el in ipairs(state.elements) do
        if el.enabled then
            local b = el.bounds
            if vx >= b.x and vx <= b.x + b.width and
               vy >= b.y and vy <= b.y + b.height then
                return el.id
            end
        end
    end
    return nil
end

-- Get element by ID
local function getElementById(id)
    for _, el in ipairs(state.elements) do
        if el.id == id then
            return el
        end
    end
    return nil
end

-- Set focus to specific element
function InputManager.setFocus(id)
    -- Blur current element
    if state.focusedId then
        local oldEl = getElementById(state.focusedId)
        if oldEl and oldEl.callbacks.onBlur then
            oldEl.callbacks.onBlur()
        end
    end

    state.focusedId = id

    -- Find index of new element
    for i, el in ipairs(state.elements) do
        if el.id == id then
            state.focusIndex = i
            break
        end
    end

    -- Focus new element
    if id then
        local newEl = getElementById(id)
        if newEl and newEl.callbacks.onFocus then
            newEl.callbacks.onFocus()
        end
    end
end

-- Focus next enabled element
function InputManager.focusNext()
    if #state.elements == 0 then return end

    local startIndex = state.focusIndex
    local index = startIndex

    repeat
        index = index + 1
        if index > #state.elements then
            index = 1
        end

        if state.elements[index].enabled then
            InputManager.setFocus(state.elements[index].id)
            return
        end
    until index == startIndex
end

-- Focus previous enabled element
function InputManager.focusPrev()
    if #state.elements == 0 then return end

    local startIndex = state.focusIndex
    local index = startIndex

    repeat
        index = index - 1
        if index < 1 then
            index = #state.elements
        end

        if state.elements[index].enabled then
            InputManager.setFocus(state.elements[index].id)
            return
        end
    until index == startIndex
end

-- Navigate focus in direction (for grid layouts)
function InputManager.navigate(direction)
    if direction == NAV.DOWN or direction == NAV.RIGHT then
        InputManager.focusNext()
    elseif direction == NAV.UP or direction == NAV.LEFT then
        InputManager.focusPrev()
    end
end

-- Activate (click/press) the focused element
function InputManager.activate()
    if state.focusedId then
        local el = getElementById(state.focusedId)
        if el and el.enabled and el.callbacks.onActivate then
            el.callbacks.onActivate()
        end
    end
end

-- Check if element is focused
function InputManager.isFocused(id)
    return state.focusedId == id
end

-- Check if element is hovered
function InputManager.isHovered(id)
    local el = getElementById(id)
    if not el or not el.enabled then return false end

    local b = el.bounds
    return state.pointerX >= b.x and state.pointerX <= b.x + b.width and
           state.pointerY >= b.y and state.pointerY <= b.y + b.height
end

-- Check if element is pressed
function InputManager.isPressed(id)
    return InputManager.isHovered(id) and state.pointerPressed
end

-- Get pointer position (virtual coords)
function InputManager.getPointerPosition()
    return state.pointerX, state.pointerY
end

-- Check if pointer is pressed
function InputManager.isPointerPressed()
    return state.pointerPressed
end

-- Check if pointer was just pressed this frame
function InputManager.isPointerJustPressed()
    return state.pointerJustPressed
end

-- Check if pointer was just released this frame
function InputManager.isPointerJustReleased()
    return state.pointerJustReleased
end

-- Check if using touch input
function InputManager.isTouchActive()
    return state.touchActive
end

-- Check if gamepad is connected
function InputManager.isGamepadConnected()
    return state.gamepadConnected
end

-- Get focused element ID
function InputManager.getFocusedId()
    return state.focusedId
end

-- Handle key press (call from love.keypressed)
function InputManager.keypressed(key)
    if key == "up" then
        InputManager.navigate(NAV.UP)
        return true
    elseif key == "down" then
        InputManager.navigate(NAV.DOWN)
        return true
    elseif key == "left" then
        InputManager.navigate(NAV.LEFT)
        return true
    elseif key == "right" then
        InputManager.navigate(NAV.RIGHT)
        return true
    elseif key == "return" or key == "space" then
        InputManager.activate()
        return true
    elseif key == "tab" then
        if love.keyboard.isDown("lshift", "rshift") then
            InputManager.focusPrev()
        else
            InputManager.focusNext()
        end
        return true
    end
    return false
end

-- Handle gamepad button press (call from love.gamepadpressed)
function InputManager.gamepadpressed(joystick, button)
    if button == "dpup" then
        InputManager.navigate(NAV.UP)
        return true
    elseif button == "dpdown" then
        InputManager.navigate(NAV.DOWN)
        return true
    elseif button == "dpleft" then
        InputManager.navigate(NAV.LEFT)
        return true
    elseif button == "dpright" then
        InputManager.navigate(NAV.RIGHT)
        return true
    elseif button == "a" then
        InputManager.activate()
        return true
    elseif button == "b" then
        -- Back/Cancel - could be handled by screens
        return false
    end
    return false
end

-- Auto-focus first element if nothing focused
function InputManager.ensureFocus()
    if not state.focusedId and #state.elements > 0 then
        for _, el in ipairs(state.elements) do
            if el.enabled then
                InputManager.setFocus(el.id)
                return
            end
        end
    end
end

return InputManager
