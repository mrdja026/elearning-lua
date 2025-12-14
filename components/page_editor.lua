-- components/page_editor.lua
-- Page editor form component for Config mode
-- Works with Slab UI

local Slab = require("libraries.Slab")
local Tokens = require("ui.tokens")

local PageEditor = {}

-- Constants
local OPERATORS = {">", "<", "=", ">=", "<=", "!="}
local QUESTION_TYPES = {"binary", "text", "multi"}
local QUESTION_TYPE_LABELS = {"Binary (True/False)", "Text Answer", "Multi-Question"}

-- Draw the page editor panel
function PageEditor.draw(x, y, width, height, page, state, callbacks)
    callbacks = callbacks or {}
    state = state or {}

    Slab.BeginWindow("PageEditorPanel", {
        Title = "Page Editor",
        X = x,
        Y = y,
        W = width,
        H = height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    if not page then
        Slab.Text("No page selected")
        Slab.EndWindow()
        return
    end

    local inputW = width - 30

    -- Page ID
    Slab.Text("Page ID")
    if Slab.Input("PageId", {Text = tostring(page.id), W = inputW, NumbersOnly = true}) then
        page.id = Slab.GetInputNumber()
    end

    -- Question Text
    Slab.Text("Question Text")
    if Slab.Input("QuestionText", {Text = page.question_text, W = inputW}) then
        page.question_text = Slab.GetInputText()
    end

    -- Hint Text
    Slab.Text("Hint Text")
    if Slab.Input("HintText", {Text = page.hint_text, W = inputW}) then
        page.hint_text = Slab.GetInputText()
    end

    -- Image Path
    Slab.Text("Image Path")
    if Slab.Input("ImagePath", {Text = page.image_path, W = inputW}) then
        page.image_path = Slab.GetInputText()
    end

    Slab.Separator()

    -- AI Image Generation section
    PageEditor.drawImageGenerationSection(page, state, callbacks, inputW)

    Slab.Separator()

    -- Question Type selector
    PageEditor.drawQuestionTypeSection(page, inputW)

    Slab.Separator()

    -- Question type specific options
    if page.question_type == "binary" then
        PageEditor.drawBinaryOptions(page, inputW)
    elseif page.question_type == "text" then
        PageEditor.drawTextOptions(page, inputW)
    elseif page.question_type == "multi" then
        PageEditor.drawMultiOptions(page, inputW)
    end

    Slab.Separator()

    -- Navigation section
    PageEditor.drawNavigationSection(page, state.pages or {}, inputW)

    Slab.EndWindow()
end

-- Draw AI image generation section
function PageEditor.drawImageGenerationSection(page, state, callbacks, inputW)
    Slab.Text("AI Image Generation")

    page.image_description = page.image_description or ""

    Slab.Text("Image Description")
    if Slab.Input("ImageDesc", {Text = page.image_description, W = inputW}) then
        page.image_description = Slab.GetInputText()
    end

    if state.isGenerating then
        Slab.Text("Generating image...")
    else
        if Slab.Button("Generate Image", {W = 150}) then
            if page.image_description ~= "" then
                if callbacks.onGenerateImage then
                    callbacks.onGenerateImage(page)
                end
            else
                if callbacks.onShowMessage then
                    callbacks.onShowMessage("Enter image description first")
                end
            end
        end
    end

    if state.generationError then
        Slab.Text(state.generationError, {Color = {1, 0.3, 0.3, 1}})
    end
end

-- Draw question type selector
function PageEditor.drawQuestionTypeSection(page, inputW)
    Slab.Text("Question Type")

    page.question_type = page.question_type or "binary"
    local typeIndex = 1
    for i, t in ipairs(QUESTION_TYPES) do
        if t == page.question_type then
            typeIndex = i
            break
        end
    end

    if Slab.BeginComboBox("QuestionType", {Selected = QUESTION_TYPE_LABELS[typeIndex], W = inputW}) then
        for i, label in ipairs(QUESTION_TYPE_LABELS) do
            if Slab.TextSelectable(label) then
                page.question_type = QUESTION_TYPES[i]
            end
        end
        Slab.EndComboBox()
    end
end

-- Draw binary question options
function PageEditor.drawBinaryOptions(page, inputW)
    Slab.Text("Logic Configuration")

    local halfW = (inputW - 10) / 2

    -- Variable name
    Slab.Text("Variable Name")
    if Slab.Input("VarName", {Text = page.variable_name or "score", W = halfW}) then
        page.variable_name = Slab.GetInputText()
    end

    -- Variable value
    Slab.Text("Variable Value")
    if Slab.Input("VarValue", {Text = tostring(page.variable_value or 0), W = halfW, NumbersOnly = true}) then
        page.variable_value = Slab.GetInputNumber()
    end

    -- Operator
    local opIndex = 1
    for i, op in ipairs(OPERATORS) do
        if op == page.operator then
            opIndex = i
            break
        end
    end

    Slab.Text("Operator")
    if Slab.BeginComboBox("Operator", {Selected = OPERATORS[opIndex], W = halfW}) then
        for i, op in ipairs(OPERATORS) do
            if Slab.TextSelectable(op) then
                page.operator = op
            end
        end
        Slab.EndComboBox()
    end

    -- Target value
    Slab.Text("Target Value")
    if Slab.Input("TargetValue", {Text = tostring(page.target_value or 0), W = halfW, NumbersOnly = true}) then
        page.target_value = Slab.GetInputNumber()
    end

    Slab.Separator()

    -- Choice labels
    Slab.Text("Choice Labels")

    page.choice_labels = page.choice_labels or {"Yes", "No"}

    Slab.Text("Button 1")
    if Slab.Input("Button1", {Text = page.choice_labels[1], W = halfW}) then
        page.choice_labels[1] = Slab.GetInputText()
    end

    Slab.Text("Button 2")
    if Slab.Input("Button2", {Text = page.choice_labels[2], W = halfW}) then
        page.choice_labels[2] = Slab.GetInputText()
    end
end

-- Draw text question options
function PageEditor.drawTextOptions(page, inputW)
    Slab.Text("Text Answer Configuration")

    page.correct_answer = page.correct_answer or ""

    Slab.Text("Correct Answer")
    if Slab.Input("CorrectAnswer", {Text = page.correct_answer, W = inputW}) then
        page.correct_answer = Slab.GetInputText()
    end
end

-- Draw multi-question options
function PageEditor.drawMultiOptions(page, inputW)
    Slab.Text("Multi-Question Configuration")

    page.questions = page.questions or {}

    local toRemove = nil

    for i, q in ipairs(page.questions) do
        Slab.Text("Question " .. i)

        Slab.Text("Q" .. i .. " Text")
        if Slab.Input("Q" .. i .. "Text", {Text = q.question_text or "", W = inputW - 50}) then
            q.question_text = Slab.GetInputText()
        end

        Slab.Text("Q" .. i .. " Answer")
        if Slab.Input("Q" .. i .. "Answer", {Text = q.correct_answer or "", W = inputW - 50}) then
            q.correct_answer = Slab.GetInputText()
        end

        Slab.SameLine()
        if Slab.Button("X##" .. i, {W = 30}) then
            toRemove = i
        end
    end

    if toRemove then
        table.remove(page.questions, toRemove)
    end

    if Slab.Button("+ Add Question", {W = 120}) then
        table.insert(page.questions, {question_text = "", correct_answer = ""})
    end
end

-- Draw navigation section
function PageEditor.drawNavigationSection(page, pages, inputW)
    Slab.Text("Navigation")

    local halfW = (inputW - 10) / 2

    -- Build destination options
    local destOptions = {"0 (End)"}
    for _, p in ipairs(pages) do
        table.insert(destOptions, tostring(p.id))
    end

    -- True destination
    local trueIdx = 1
    for i, opt in ipairs(destOptions) do
        if tonumber(opt:match("%d+")) == page.true_destination_id then
            trueIdx = i
            break
        end
    end

    Slab.Text("If Correct, go to")
    if Slab.BeginComboBox("TrueDest", {Selected = destOptions[trueIdx], W = halfW}) then
        for i, opt in ipairs(destOptions) do
            if Slab.TextSelectable(opt) then
                page.true_destination_id = tonumber(opt:match("%d+")) or 0
            end
        end
        Slab.EndComboBox()
    end

    -- False destination
    local falseIdx = 1
    for i, opt in ipairs(destOptions) do
        if tonumber(opt:match("%d+")) == page.false_destination_id then
            falseIdx = i
            break
        end
    end

    Slab.Text("If Wrong, go to")
    if Slab.BeginComboBox("FalseDest", {Selected = destOptions[falseIdx], W = halfW}) then
        for i, opt in ipairs(destOptions) do
            if Slab.TextSelectable(opt) then
                page.false_destination_id = tonumber(opt:match("%d+")) or 0
            end
        end
        Slab.EndComboBox()
    end
end

return PageEditor
