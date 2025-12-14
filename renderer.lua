local renderer = {}

local COLORS = {
    background = {0.2, 0.2, 0.3},
    placeholder = {0.4, 0.4, 0.5},
    text = {1, 1, 1},
    button = {0.3, 0.5, 0.7},
    button_hover = {0.4, 0.6, 0.8},
    button_text = {1, 1, 1},
    hint = {0.7, 0.7, 0.7},
    win = {0.2, 0.7, 0.3},
    lose = {0.7, 0.2, 0.2},
    input_bg = {0.15, 0.15, 0.2},
    input_border = {0.4, 0.4, 0.5},
    input_active = {0.3, 0.5, 0.7},
    error = {0.8, 0.3, 0.3},
    error_bg = {0.3, 0.1, 0.1}
}

local LAYOUT = {
    image_x = 100,
    image_y = 50,
    image_width = 600,
    image_height = 300,
    question_y = 380,
    hint_y = 430,
    button_y = 480,
    button_width = 200,
    button_height = 60,
    button_spacing = 50,
    input_width = 400,
    input_height = 40,
    input_y = 450,
    multi_start_y = 380,
    multi_spacing = 70
}

local loadedImages = {}
local hoveredButton = nil
local hoveredInput = nil
local inputBoxes = {}

function renderer.loadImage(path)
    if loadedImages[path] then
        return loadedImages[path]
    end

    local success, image = pcall(love.graphics.newImage, path)
    if success then
        loadedImages[path] = image
        return image
    end
    return nil
end

function renderer.drawBackground()
    love.graphics.setBackgroundColor(COLORS.background)
end

function renderer.drawImageArea(page)
    local image = nil
    if page.image_path and page.image_path ~= "" then
        image = renderer.loadImage(page.image_path)
    end

    if image then
        local imgW, imgH = image:getDimensions()
        local scaleX = LAYOUT.image_width / imgW
        local scaleY = LAYOUT.image_height / imgH
        local scale = math.min(scaleX, scaleY)
        local drawX = LAYOUT.image_x + (LAYOUT.image_width - imgW * scale) / 2
        local drawY = LAYOUT.image_y + (LAYOUT.image_height - imgH * scale) / 2
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(image, drawX, drawY, 0, scale, scale)
    else
        love.graphics.setColor(COLORS.placeholder)
        love.graphics.rectangle("fill", LAYOUT.image_x, LAYOUT.image_y, LAYOUT.image_width, LAYOUT.image_height, 10)
        love.graphics.setColor(COLORS.text)
        local text = "[Image Placeholder]"
        local font = love.graphics.getFont()
        local textW = font:getWidth(text)
        love.graphics.print(text, LAYOUT.image_x + (LAYOUT.image_width - textW) / 2, LAYOUT.image_y + LAYOUT.image_height / 2 - 10)
    end
end

function renderer.drawQuestion(page)
    love.graphics.setColor(COLORS.text)
    local font = love.graphics.getFont()
    local textW = font:getWidth(page.question_text)
    local screenW = love.graphics.getWidth()
    love.graphics.print(page.question_text, (screenW - textW) / 2, LAYOUT.question_y)

    if page.hint_text and page.hint_text ~= "" then
        love.graphics.setColor(COLORS.hint)
        local hintW = font:getWidth(page.hint_text)
        love.graphics.print(page.hint_text, (screenW - hintW) / 2, LAYOUT.hint_y)
    end
end

function renderer.drawButtons(page)
    local screenW = love.graphics.getWidth()
    local labels = page.choice_labels or {"True", "False"}
    local totalWidth = LAYOUT.button_width * 2 + LAYOUT.button_spacing
    local startX = (screenW - totalWidth) / 2

    for i, label in ipairs(labels) do
        local x = startX + (i - 1) * (LAYOUT.button_width + LAYOUT.button_spacing)
        local y = LAYOUT.button_y

        local isHovered = hoveredButton == i
        love.graphics.setColor(isHovered and COLORS.button_hover or COLORS.button)
        love.graphics.rectangle("fill", x, y, LAYOUT.button_width, LAYOUT.button_height, 8)

        love.graphics.setColor(COLORS.button_text)
        local font = love.graphics.getFont()
        local textW = font:getWidth(label)
        local textH = font:getHeight()
        love.graphics.print(label, x + (LAYOUT.button_width - textW) / 2, y + (LAYOUT.button_height - textH) / 2)
    end
end

function renderer.drawPage(page, gamestate)
    renderer.drawBackground()
    renderer.drawImageArea(page)

    local questionType = page.question_type or "binary"

    if questionType == "binary" then
        renderer.drawQuestion(page)
        renderer.drawButtons(page)
    elseif questionType == "text" then
        renderer.drawTextQuestion(page, gamestate)
    elseif questionType == "multi" then
        renderer.drawMultiQuestion(page, gamestate)
    end
end

function renderer.drawTextQuestion(page, gamestate)
    love.graphics.setColor(COLORS.text)
    local font = love.graphics.getFont()
    local screenW = love.graphics.getWidth()

    local textW = font:getWidth(page.question_text)
    love.graphics.print(page.question_text, (screenW - textW) / 2, LAYOUT.question_y)

    if page.hint_text and page.hint_text ~= "" then
        love.graphics.setColor(COLORS.hint)
        local hintW = font:getWidth(page.hint_text)
        love.graphics.print(page.hint_text, (screenW - hintW) / 2, LAYOUT.question_y + 30)
    end

    local inputX = (screenW - LAYOUT.input_width) / 2
    local inputY = LAYOUT.input_y

    inputBoxes = {{x = inputX, y = inputY, w = LAYOUT.input_width, h = LAYOUT.input_height, index = 1}}

    local isActive = gamestate and gamestate.getActiveInput() == 1
    love.graphics.setColor(COLORS.input_bg)
    love.graphics.rectangle("fill", inputX, inputY, LAYOUT.input_width, LAYOUT.input_height, 5)

    love.graphics.setColor(isActive and COLORS.input_active or COLORS.input_border)
    love.graphics.rectangle("line", inputX, inputY, LAYOUT.input_width, LAYOUT.input_height, 5)

    love.graphics.setColor(COLORS.text)
    local inputText = gamestate and gamestate.getTextInput() or ""
    love.graphics.print(inputText, inputX + 10, inputY + 10)

    if isActive then
        local cursorX = inputX + 10 + font:getWidth(inputText)
        if math.floor(love.timer.getTime() * 2) % 2 == 0 then
            love.graphics.rectangle("fill", cursorX, inputY + 8, 2, 24)
        end
    end

    local errors = gamestate and gamestate.getErrors() or {}
    if #errors > 0 or (type(errors) == "table" and errors.correct_answer) then
        love.graphics.setColor(COLORS.error)
        local errorText = "Incorrect! Expected: " .. (errors.correct_answer or "")
        local errorW = font:getWidth(errorText)
        love.graphics.print(errorText, (screenW - errorW) / 2, inputY + 50)
    end

    local submitX = (screenW - LAYOUT.button_width) / 2
    local submitY = inputY + 100

    local isHovered = hoveredButton == 1
    love.graphics.setColor(isHovered and COLORS.button_hover or COLORS.button)
    love.graphics.rectangle("fill", submitX, submitY, LAYOUT.button_width, LAYOUT.button_height, 8)

    love.graphics.setColor(COLORS.button_text)
    local submitText = "Submit"
    local submitW = font:getWidth(submitText)
    love.graphics.print(submitText, submitX + (LAYOUT.button_width - submitW) / 2, submitY + 20)
end

function renderer.drawMultiQuestion(page, gamestate)
    love.graphics.setColor(COLORS.text)
    local font = love.graphics.getFont()
    local screenW = love.graphics.getWidth()

    local textW = font:getWidth(page.question_text)
    love.graphics.print(page.question_text, (screenW - textW) / 2, LAYOUT.question_y - 40)

    inputBoxes = {}
    local questions = page.questions or {}
    local errors = gamestate and gamestate.getErrors() or {}
    local errorIndices = {}
    for _, err in ipairs(errors) do
        errorIndices[err.question_index] = err
    end

    local startY = LAYOUT.multi_start_y
    local inputX = (screenW - LAYOUT.input_width) / 2

    for i, question in ipairs(questions) do
        local y = startY + (i - 1) * LAYOUT.multi_spacing
        local hasError = errorIndices[i] ~= nil
        local isActive = gamestate and gamestate.getActiveInput() == i

        love.graphics.setColor(hasError and COLORS.error or COLORS.text)
        local qText = i .. ". " .. question.question_text
        love.graphics.print(qText, inputX, y)

        local inputY = y + 22

        table.insert(inputBoxes, {x = inputX, y = inputY, w = LAYOUT.input_width, h = LAYOUT.input_height - 10, index = i})

        love.graphics.setColor(hasError and COLORS.error_bg or COLORS.input_bg)
        love.graphics.rectangle("fill", inputX, inputY, LAYOUT.input_width, LAYOUT.input_height - 10, 5)

        local borderColor = COLORS.input_border
        if hasError then
            borderColor = COLORS.error
        elseif isActive then
            borderColor = COLORS.input_active
        end
        love.graphics.setColor(borderColor)
        love.graphics.rectangle("line", inputX, inputY, LAYOUT.input_width, LAYOUT.input_height - 10, 5)

        love.graphics.setColor(COLORS.text)
        local answerText = gamestate and gamestate.getMultiAnswer(i) or ""
        love.graphics.print(answerText, inputX + 10, inputY + 6)

        if isActive then
            local cursorX = inputX + 10 + font:getWidth(answerText)
            if math.floor(love.timer.getTime() * 2) % 2 == 0 then
                love.graphics.rectangle("fill", cursorX, inputY + 4, 2, 20)
            end
        end

        if hasError then
            love.graphics.setColor(COLORS.error)
            local errText = "Expected: " .. errorIndices[i].correct_answer
            love.graphics.print(errText, inputX + LAYOUT.input_width + 10, inputY + 6)
        end
    end

    local submitY = startY + #questions * LAYOUT.multi_spacing + 10
    local submitX = (screenW - LAYOUT.button_width) / 2

    local isHovered = hoveredButton == 1
    love.graphics.setColor(isHovered and COLORS.button_hover or COLORS.button)
    love.graphics.rectangle("fill", submitX, submitY, LAYOUT.button_width, LAYOUT.button_height, 8)

    love.graphics.setColor(COLORS.button_text)
    local submitText = "Submit All"
    local submitW = font:getWidth(submitText)
    love.graphics.print(submitText, submitX + (LAYOUT.button_width - submitW) / 2, submitY + 20)
end

function renderer.drawFinished(result)
    renderer.drawBackground()

    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()

    local text, color
    if result == "win" then
        text = "You Win!"
        color = COLORS.win
    else
        text = "Game Over"
        color = COLORS.lose
    end

    love.graphics.setColor(color)
    local font = love.graphics.getFont()
    local textW = font:getWidth(text)
    love.graphics.print(text, (screenW - textW) / 2, screenH / 2 - 20)

    love.graphics.setColor(COLORS.hint)
    local restartText = "Press R to restart"
    local restartW = font:getWidth(restartText)
    love.graphics.print(restartText, (screenW - restartW) / 2, screenH / 2 + 20)
end

function renderer.drawError(message)
    renderer.drawBackground()
    love.graphics.setColor(COLORS.lose)
    love.graphics.print("Error: " .. message, 50, 50)
end

function renderer.updateHover(mx, my)
    local screenW = love.graphics.getWidth()
    local totalWidth = LAYOUT.button_width * 2 + LAYOUT.button_spacing
    local startX = (screenW - totalWidth) / 2

    hoveredButton = nil
    for i = 1, 2 do
        local x = startX + (i - 1) * (LAYOUT.button_width + LAYOUT.button_spacing)
        local y = LAYOUT.button_y
        if mx >= x and mx <= x + LAYOUT.button_width and my >= y and my <= y + LAYOUT.button_height then
            hoveredButton = i
            break
        end
    end
end

function renderer.getClickedButton(mx, my)
    local screenW = love.graphics.getWidth()
    local totalWidth = LAYOUT.button_width * 2 + LAYOUT.button_spacing
    local startX = (screenW - totalWidth) / 2

    for i = 1, 2 do
        local x = startX + (i - 1) * (LAYOUT.button_width + LAYOUT.button_spacing)
        local y = LAYOUT.button_y
        if mx >= x and mx <= x + LAYOUT.button_width and my >= y and my <= y + LAYOUT.button_height then
            return i == 1 and "true" or "false"
        end
    end
    return nil
end

function renderer.getClickedInput(mx, my)
    for _, box in ipairs(inputBoxes) do
        if mx >= box.x and mx <= box.x + box.w and my >= box.y and my <= box.y + box.h then
            return box.index
        end
    end
    return nil
end

function renderer.getClickedSubmit(mx, my, page)
    local screenW = love.graphics.getWidth()
    local submitX = (screenW - LAYOUT.button_width) / 2
    local submitY

    local questionType = page.question_type or "binary"
    if questionType == "text" then
        submitY = LAYOUT.input_y + 100
    elseif questionType == "multi" then
        local questions = page.questions or {}
        submitY = LAYOUT.multi_start_y + #questions * LAYOUT.multi_spacing + 10
    else
        return false
    end

    return mx >= submitX and mx <= submitX + LAYOUT.button_width and
           my >= submitY and my <= submitY + LAYOUT.button_height
end

function renderer.updateHoverForQuestion(mx, my, page)
    hoveredButton = nil

    local screenW = love.graphics.getWidth()
    local submitX = (screenW - LAYOUT.button_width) / 2
    local submitY

    local questionType = page.question_type or "binary"
    if questionType == "text" then
        submitY = LAYOUT.input_y + 100
    elseif questionType == "multi" then
        local questions = page.questions or {}
        submitY = LAYOUT.multi_start_y + #questions * LAYOUT.multi_spacing + 10
    else
        return
    end

    if mx >= submitX and mx <= submitX + LAYOUT.button_width and
       my >= submitY and my <= submitY + LAYOUT.button_height then
        hoveredButton = 1
    end
end

return renderer
