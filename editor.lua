local Slab = require("libraries.Slab")
local json = require("libraries.json")
local schema = require("schema")
local Layout = require("ui.layout")
local Tokens = require("ui.tokens")

local editor = {}

local QUESTION_TYPES = {"yesno", "text", "multi"}
local QUESTION_TYPE_LABELS = {"Yes/No Question", "Text Answer", "Multi-Question"}

local BACKEND_URL = "http://localhost:3000/api/generate-image"

local state = {
    story = {
        title = "New Story",
        initial_variables = {},
        pages = {}
    },
    selectedPageIndex = 1,
    isDirty = false,
    message = nil,
    messageTime = 0,
    showLoadDialog = false,
    availableFiles = {},
    selectedFileIndex = 1,
    -- Image generation state
    isGenerating = false,
    imageThread = nil,
    generationError = nil
}

function editor.init()
    editor.newStory()
end

function editor.newStory()
    state.story = {
        title = "New Story",
        topic = "",
        general_image_prompt = "",
        pages = {
            {
                id = 1,
                image_path = "",
                question_text = "Enter your question here",
                hint_text = "",
                choice_labels = {"Yes", "No"},
                question_type = "yesno",
                correct_answer_is_yes = true,
                correct_answer = "",
                questions = {}
            }
        }
    }
    state.selectedPageIndex = 1
    state.isDirty = false
    state.isGenerating = false
    state.generationError = nil
    editor.showMessage("New story created")
end

function editor.showMessage(msg)
    state.message = msg
    state.messageTime = 3
end

function editor.update(dt)
    if state.messageTime > 0 then
        state.messageTime = state.messageTime - dt
        if state.messageTime <= 0 then
            state.message = nil
        end
    end

    -- Check for image generation response
    if state.isGenerating then
        local responseChannel = love.thread.getChannel("image_response")
        local response = responseChannel:pop()
        if response then
            state.isGenerating = false
            if response.success then
                local page = state.story.pages[state.selectedPageIndex]
                if page then
                    page.image_path = response.data
                    editor.showMessage("Image generated!")
                end
            else
                state.generationError = response.data
                editor.showMessage("Error: " .. response.data)
            end
        end
    end
end

function editor.draw()
    editor.drawFilePanel()
    editor.drawStoryPanel()
    editor.drawPageListPanel()
    editor.drawPageEditorPanel()

    if state.showLoadDialog then
        editor.drawLoadDialog()
    end

    if state.message then
        local winH = love.graphics.getHeight()
        local msgY = winH - 45
        love.graphics.setColor(0.2, 0.6, 0.3, 0.9)
        love.graphics.rectangle("fill", 10, msgY, 400, 30, 5)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(state.message, 20, msgY + 8)
    end
end

function editor.drawFilePanel()
    local layout = Layout.getConfigLayout()

    Slab.BeginWindow("FilePanel", {
        Title = "File",
        X = layout.filePanel.x,
        Y = layout.filePanel.y,
        W = layout.filePanel.width,
        H = layout.filePanel.height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    if Slab.Button("New", {W = 80}) then
        editor.newStory()
    end

    Slab.SameLine()
    if Slab.Button("Load", {W = 80}) then
        state.showLoadDialog = true
        state.availableFiles = editor.getStoryFiles()
        state.selectedFileIndex = 1
    end

    Slab.SameLine()
    if Slab.Button("Save", {W = 80}) then
        editor.saveStory()
    end

    Slab.SameLine()
    if Slab.Button("Test Play (Tab)", {W = 140}) then
        -- Handled in main.lua via Tab key
    end

    Slab.EndWindow()
end

function editor.drawStoryPanel()
    local layout = Layout.getConfigLayout()

    Slab.BeginWindow("StoryPanel", {
        Title = "Story Settings",
        X = layout.storyPanel.x,
        Y = layout.storyPanel.y,
        W = layout.storyPanel.width,
        H = layout.storyPanel.height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    local inputW = layout.storyPanel.width - 30

    Slab.Text("Story Title")
    if Slab.Input("StoryTitle", {Text = state.story.title, W = inputW}) then
        state.story.title = Slab.GetInputText()
    end

    state.story.topic = state.story.topic or ""
    Slab.Text("Topic")
    if Slab.Input("StoryTopic", {Text = state.story.topic, W = inputW}) then
        state.story.topic = Slab.GetInputText()
    end

    state.story.general_image_prompt = state.story.general_image_prompt or ""
    Slab.Text("General Image Prompt")
    if Slab.Input("GeneralImagePrompt", {Text = state.story.general_image_prompt, W = inputW, MultiLine = true, H = 60}) then
        state.story.general_image_prompt = Slab.GetInputText()
    end

    Slab.EndWindow()
end

function editor.drawPageListPanel()
    local layout = Layout.getConfigLayout()

    Slab.BeginWindow("PagesPanel", {
        Title = "Pages",
        X = layout.pagesPanel.x,
        Y = layout.pagesPanel.y,
        W = layout.pagesPanel.width,
        H = layout.pagesPanel.height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    local listH = layout.pagesPanel.height - 100
    Slab.BeginListBox("PageList", {H = listH})
    for i, page in ipairs(state.story.pages) do
        local label = "Page " .. page.id
        Slab.BeginListBoxItem("Page_" .. i, {Selected = (i == state.selectedPageIndex)})
        Slab.Text(label)
        if Slab.IsListBoxItemClicked() then
            state.selectedPageIndex = i
        end
        Slab.EndListBoxItem()
    end
    Slab.EndListBox()

    if Slab.Button("Add Page", {W = 85}) then
        editor.addPage()
    end

    Slab.SameLine()
    if Slab.Button("Delete", {W = 85}) then
        editor.deletePage()
    end

    Slab.EndWindow()
end

function editor.drawPageEditorPanel()
    local layout = Layout.getConfigLayout()

    Slab.BeginWindow("PageEditorPanel", {
        Title = "Page Editor",
        X = layout.editorPanel.x,
        Y = layout.editorPanel.y,
        W = layout.editorPanel.width,
        H = layout.editorPanel.height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    local inputW = layout.editorPanel.width - 30

    local page = state.story.pages[state.selectedPageIndex]
    if not page then
        Slab.Text("No page selected")
        Slab.EndWindow()
        return
    end

    Slab.Text("Page ID")
    if Slab.Input("PageId", {Text = tostring(page.id), W = inputW, NumbersOnly = true}) then
        page.id = Slab.GetInputNumber()
    end

    Slab.Text("Question Text")
    if Slab.Input("QuestionText", {Text = page.question_text, W = inputW}) then
        page.question_text = Slab.GetInputText()
    end

    Slab.Text("Hint Text")
    if Slab.Input("HintText", {Text = page.hint_text, W = inputW}) then
        page.hint_text = Slab.GetInputText()
    end

    Slab.Text("Image Path")
    if Slab.Input("ImagePath", {Text = page.image_path, W = inputW}) then
        page.image_path = Slab.GetInputText()
    end

    Slab.Separator()
    Slab.Text("AI Image Generation")
    Slab.Text("(Uses story-level General Image Prompt)")

    if state.isGenerating then
        Slab.Text("Generating image...")
    else
        if Slab.Button("Generate Image", {W = 150}) then
            if state.story.general_image_prompt and state.story.general_image_prompt ~= "" then
                editor.startImageGeneration(page)
            else
                editor.showMessage("Set General Image Prompt in Story Settings first")
            end
        end
    end

    if state.generationError then
        Slab.Text(state.generationError, {Color = {1, 0.3, 0.3, 1}})
    end

    Slab.Separator()
    Slab.Text("Question Type")

    page.question_type = page.question_type or "yesno"
    local typeIndex = 1
    for i, t in ipairs(QUESTION_TYPES) do
        if t == page.question_type then typeIndex = i break end
    end

    if Slab.BeginComboBox("QuestionType", {Selected = QUESTION_TYPE_LABELS[typeIndex], W = inputW}) then
        for i, label in ipairs(QUESTION_TYPE_LABELS) do
            if Slab.TextSelectable(label) then
                page.question_type = QUESTION_TYPES[i]
            end
        end
        Slab.EndComboBox()
    end

    Slab.Separator()

    local halfW = math.floor((inputW - 10) / 2)

    if page.question_type == "yesno" then
        Slab.Text("Yes/No Configuration")

        -- Correct answer checkbox
        if page.correct_answer_is_yes == nil then
            page.correct_answer_is_yes = true
        end
        if Slab.CheckBox(page.correct_answer_is_yes, "Correct answer is Yes") then
            page.correct_answer_is_yes = not page.correct_answer_is_yes
        end

        Slab.Separator()
        Slab.Text("Button Labels")

        page.choice_labels = page.choice_labels or {"Yes", "No"}

        Slab.Text("Yes Button")
        if Slab.Input("YesButton", {Text = page.choice_labels[1], W = halfW}) then
            page.choice_labels[1] = Slab.GetInputText()
        end

        Slab.Text("No Button")
        if Slab.Input("NoButton", {Text = page.choice_labels[2], W = halfW}) then
            page.choice_labels[2] = Slab.GetInputText()
        end

    elseif page.question_type == "text" then
        Slab.Text("Text Answer Configuration")

        page.correct_answer = page.correct_answer or ""

        Slab.Text("Correct Answer")
        if Slab.Input("CorrectAnswer", {Text = page.correct_answer, W = inputW}) then
            page.correct_answer = Slab.GetInputText()
        end

    elseif page.question_type == "multi" then
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

    Slab.Separator()
    Slab.Text("Navigation")
    Slab.Text("Linear: Correct = next page, Wrong = retry")

    state.isDirty = true

    Slab.EndWindow()
end

function editor.drawLoadDialog()
    local winW, winH = love.graphics.getDimensions()

    Slab.BeginWindow("LoadDialog", {
        Title = "Load Story",
        X = (winW - 300) / 2,
        Y = (winH - 300) / 2,
        W = 300, H = 300,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false
    })

    if #state.availableFiles == 0 then
        Slab.Text("No story files found")
        Slab.Text("in stories/ directory")
    else
        Slab.BeginListBox("FileList", {H = 180})
        for i, f in ipairs(state.availableFiles) do
            Slab.BeginListBoxItem("File_" .. i, {Selected = (i == state.selectedFileIndex)})
            Slab.Text(f)
            if Slab.IsListBoxItemClicked() then
                state.selectedFileIndex = i
            end
            Slab.EndListBoxItem()
        end
        Slab.EndListBox()

        if Slab.Button("Load Selected", {W = 130}) then
            editor.loadStory(state.availableFiles[state.selectedFileIndex])
            state.showLoadDialog = false
        end
    end

    Slab.SameLine()
    if Slab.Button("Cancel", {W = 130}) then
        state.showLoadDialog = false
    end

    Slab.EndWindow()
end

function editor.addPage()
    local maxId = 0
    for _, page in ipairs(state.story.pages) do
        if page.id > maxId then maxId = page.id end
    end

    local newPage = {
        id = maxId + 1,
        image_path = "",
        question_text = "New question",
        hint_text = "",
        choice_labels = {"Yes", "No"},
        question_type = "yesno",
        correct_answer_is_yes = true,
        correct_answer = "",
        questions = {}
    }

    table.insert(state.story.pages, newPage)
    state.selectedPageIndex = #state.story.pages
    state.isDirty = true
    editor.showMessage("Page added")
end

function editor.deletePage()
    if #state.story.pages <= 1 then
        editor.showMessage("Cannot delete last page")
        return
    end

    table.remove(state.story.pages, state.selectedPageIndex)
    if state.selectedPageIndex > #state.story.pages then
        state.selectedPageIndex = #state.story.pages
    end
    state.isDirty = true
    editor.showMessage("Page deleted")
end

function editor.getStoryFiles()
    local files = {}
    local items = love.filesystem.getDirectoryItems("stories")
    for _, item in ipairs(items) do
        if item:match("%.json$") then
            table.insert(files, item)
        end
    end
    return files
end

function editor.saveStory()
    local valid, err = schema.validateStory(state.story)
    if not valid then
        editor.showMessage("Error: " .. err)
        return
    end

    local filename = state.story.title:gsub("%s+", "_"):gsub("[^%w_]", "") .. ".json"
    local path = "stories/" .. filename

    local success, encoded = pcall(json.encode, state.story)
    if not success then
        editor.showMessage("Error encoding JSON")
        return
    end

    local ok, writeErr = love.filesystem.write(path, encoded)
    if ok then
        state.isDirty = false
        editor.showMessage("Saved to " .. filename)
    else
        editor.showMessage("Error saving: " .. (writeErr or "unknown"))
    end
end

function editor.loadStory(filename)
    local path = "stories/" .. filename
    local content, err = love.filesystem.read(path)
    if not content then
        editor.showMessage("Error: " .. err)
        return
    end

    local success, story = pcall(json.decode, content)
    if not success then
        editor.showMessage("Error parsing JSON")
        return
    end

    -- Migrate story from old format to new format
    story = schema.migrateStory(story)

    state.story = story
    state.selectedPageIndex = 1
    state.isDirty = false
    editor.showMessage("Loaded " .. filename)
end

function editor.getStory()
    return state.story
end

function editor.getCurrentPage()
    return state.story.pages[state.selectedPageIndex]
end

function editor.keypressed(key)
    -- Slab handles input automatically
end

function editor.textinput(text)
    -- Slab handles input automatically
end

function editor.startImageGeneration(page)
    if state.isGenerating then
        return
    end

    state.isGenerating = true
    state.generationError = nil

    -- Start the image generation thread
    state.imageThread = love.thread.newThread("image_thread.lua")
    state.imageThread:start()

    -- Send the request using story-level prompt combined with question
    local requestChannel = love.thread.getChannel("image_request")
    requestChannel:push({
        url = BACKEND_URL,
        description = state.story.general_image_prompt or "",
        question = page.question_text
    })

    editor.showMessage("Generating image...")
end

return editor
