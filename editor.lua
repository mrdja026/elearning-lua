local Slab = require("libraries.Slab")
local json = require("libraries.json")
local schema = require("schema")
local Layout = require("ui.layout")
local Tokens = require("ui.tokens")
local ImageCard = require("components.image_card")
local PlayScreen = require("screens.play")

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
    generatingCover = false,  -- Track if generating cover vs page image
    selectedFileIndex = 1,
    -- Image generation state
    isGenerating = false,
    imageThread = nil,
    generationError = nil,
    -- Storybook UI state
    storySettingsExpanded = false
}

function editor.init()
    editor.newStory()
end

function editor.newStory()
    state.story = {
        title = "New Story",
        topic = "",
        general_image_prompt = "",
        cover_image_path = "",  -- Story Frame cover image
        pages = {
            {
                id = 1,
                image_path = "",
                image_prompt = "",  -- Per-page prompt (overrides story prompt)
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
    state.storySettingsExpanded = true  -- Expanded by default for new stories
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
                if state.generatingCover then
                    -- Cover image generated
                    state.story.cover_image_path = response.data
                    -- NOTE: Keep general_image_prompt - it's used for all page images too!
                    state.storySettingsExpanded = false
                    state.selectedPageIndex = 0
                    editor.showMessage("Cover generated!")
                    print("[Editor] Cover generated, path: " .. response.data)
                else
                    -- Page image generated
                    local page = state.story.pages[state.selectedPageIndex]
                    if page then
                        page.image_path = response.data
                        editor.showMessage("Image generated!")
                    end
                end
                state.generatingCover = false
            else
                state.generationError = response.data
                editor.showMessage("Error: " .. response.data)
                state.generatingCover = false
            end
        end
    end
end

function editor.draw()
    -- New storybook layout: Thumbnails | Preview (center) | Control Deck
    editor.drawPageThumbnails()      -- Left sidebar
    editor.drawPreviewPanel()        -- Center preview (NEW!)
    editor.drawStorySettingsHeader() -- Top of right sidebar (collapsible)
    editor.drawControlDeck()         -- Right sidebar (below story settings)
    editor.drawDreamItButton()       -- Bottom bar

    if state.showLoadDialog then
        editor.drawLoadDialog()
    end

    -- Toast-style message
    if state.message then
        local layout = Layout.getConfigLayout()
        local msgX = layout.previewPanel.x + 20
        local msgY = layout.previewPanel.y + layout.previewPanel.height - 50
        love.graphics.setColor(0.2, 0.6, 0.3, 0.95)
        love.graphics.rectangle("fill", msgX, msgY, 350, 35, 8)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(state.message, msgX + 15, msgY + 9)
    end
end

-- Draw the center preview panel using PlayScreen component
function editor.drawPreviewPanel()
    local layout = Layout.getConfigLayout()
    local panel = layout.previewPanel

    -- Draw panel background
    love.graphics.setColor(Tokens.COLORS.surface)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height, 8)

    -- Draw border
    love.graphics.setColor(Tokens.COLORS.surface_elevated)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", panel.x, panel.y, panel.width, panel.height, 8)
    love.graphics.setLineWidth(1)

    -- Determine display mode based on selection
    local displayMode
    local label

    if state.selectedPageIndex == 0 then
        -- Page-Story selected: show cover in STORY mode
        displayMode = PlayScreen.MODE_STORY
        label = "Story Cover"
    else
        -- Regular page selected: show page in PAGE mode
        displayMode = PlayScreen.MODE_PAGE
        label = "Page " .. state.selectedPageIndex .. " Preview"
    end

    -- Draw label at top
    love.graphics.setColor(Tokens.COLORS.text_secondary)
    local labelX = panel.x + panel.padding
    local labelY = panel.y + 10
    love.graphics.print(label, labelX, labelY)

    -- Calculate preview area bounds (below label)
    local bounds = {
        x = panel.x + panel.padding,
        y = panel.y + 35,
        width = panel.width - panel.padding * 2,
        height = panel.height - 50
    }

    -- Use PlayScreen to render preview with appropriate mode
    if displayMode == PlayScreen.MODE_STORY then
        -- STORY mode: pass the story directly
        PlayScreen.draw(state.story, nil, {
            mode = PlayScreen.MODE_STORY,
            preview = true,
            bounds = bounds
        })
    else
        -- PAGE mode: create a minimal gamestate for preview
        local previewGamestate = {
            getCurrentPage = function()
                return state.story.pages[state.selectedPageIndex]
            end,
            getStory = function()
                return state.story
            end
        }

        -- For PAGE mode in preview, just draw the image (not the full play layout)
        local page = state.story.pages[state.selectedPageIndex]
        local imagePath = page and page.image_path or ""

        -- Draw image preview area
        love.graphics.setColor(Tokens.COLORS.surface_elevated)
        love.graphics.rectangle("fill", bounds.x, bounds.y, bounds.width, bounds.height, 4)

        local image = nil
        if imagePath and imagePath ~= "" then
            image = ImageCard.loadImage(imagePath)
        end

        if image then
            local scaleX = bounds.width / image:getWidth()
            local scaleY = bounds.height / image:getHeight()
            local scale = math.min(scaleX, scaleY)

            local drawW = image:getWidth() * scale
            local drawH = image:getHeight() * scale
            local drawX = bounds.x + (bounds.width - drawW) / 2
            local drawY = bounds.y + (bounds.height - drawH) / 2

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(image, drawX, drawY, 0, scale, scale)
        else
            love.graphics.setColor(Tokens.COLORS.text_disabled)
            local placeholder = imagePath == "" and "[No Image - Generate one!]" or "[Image not found]"
            local font = love.graphics.getFont()
            local textW = font:getWidth(placeholder)
            local textX = bounds.x + (bounds.width - textW) / 2
            local textY = bounds.y + bounds.height / 2 - 8
            love.graphics.print(placeholder, textX, textY)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
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

-- ============================================
-- NEW STORYBOOK LAYOUT PANELS
-- ============================================

-- Page thumbnails panel (left sidebar) - Custom drawn, not Slab
function editor.drawPageThumbnails()
    local layout = Layout.getConfigLayout()
    local panel = layout.thumbnailsPanel

    -- Check if Pages panel should be gated (no cover = pages disabled)
    state.story.cover_image_path = state.story.cover_image_path or ""
    local hasCover = state.story.cover_image_path ~= ""
    -- All stories require cover before pages can be edited (no legacy exception)
    local pagesEnabled = hasCover

    -- Draw panel background
    if pagesEnabled then
        love.graphics.setColor(Tokens.COLORS.panel_dark_transparent)
    else
        love.graphics.setColor(0.15, 0.15, 0.18, 0.8)  -- Darker/grayed out
    end
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, panel.height, 6)

    -- Draw header
    love.graphics.setColor(0.2, 0.2, 0.25, 1)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.width, 30, 6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Pages", panel.x + 10, panel.y + 7)

    -- If pages are gated, show message and return early
    if not pagesEnabled then
        love.graphics.setColor(0.7, 0.7, 0.5, 1)
        local msg1 = "Generate cover"
        local msg2 = "first"
        local font = love.graphics.getFont()
        local msg1W = font:getWidth(msg1)
        local msg2W = font:getWidth(msg2)
        local centerX = panel.x + panel.width / 2
        local centerY = panel.y + panel.height / 2 - 20
        love.graphics.print(msg1, centerX - msg1W / 2, centerY)
        love.graphics.print(msg2, centerX - msg2W / 2, centerY + 20)
        love.graphics.setColor(1, 1, 1, 1)
        return
    end

    -- Thumbnail dimensions
    local thumbW = panel.width - 20
    local thumbH = 60
    local thumbGap = 8
    local startY = panel.y + 40
    local thumbX = panel.x + 10
    local font = love.graphics.getFont()
    local thumbIndex = 0  -- Track visual position

    -- Draw Page-Story thumbnail FIRST if cover exists
    if hasCover then
        local thumbY = startY + thumbIndex * (thumbH + thumbGap)
        local isSelected = (state.selectedPageIndex == 0)

        -- Page-Story has special purple/gold styling
        if isSelected then
            love.graphics.setColor(0.4, 0.3, 0.5, 1)  -- Purple selected
        else
            love.graphics.setColor(0.3, 0.25, 0.35, 1)  -- Purple unselected
        end
        love.graphics.rectangle("fill", thumbX, thumbY, thumbW, thumbH, 4)

        -- Border
        if isSelected then
            love.graphics.setColor(0.7, 0.5, 0.9, 1)  -- Bright purple
        else
            love.graphics.setColor(0.5, 0.4, 0.55, 1)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", thumbX, thumbY, thumbW, thumbH, 4)
        love.graphics.setLineWidth(1)

        -- Label with lock indicator
        love.graphics.setColor(0.9, 0.8, 0.5, 1)  -- Gold text
        local label = "Page-Story"
        local labelW = font:getWidth(label)
        love.graphics.print(label, thumbX + (thumbW - labelW) / 2, thumbY + (thumbH - 16) / 2)

        thumbIndex = thumbIndex + 1
    end

    -- Draw regular page thumbnails
    for i, page in ipairs(state.story.pages) do
        local thumbY = startY + thumbIndex * (thumbH + thumbGap)

        -- Check if thumbnail is visible in panel
        if thumbY + thumbH > panel.y + panel.height - 60 then
            break -- Stop drawing if we run out of space
        end

        -- selectedPageIndex: 0 = Page-Story, >= 1 = regular pages (1-indexed)
        local isSelected = (i == state.selectedPageIndex)

        -- Thumbnail background
        if isSelected then
            love.graphics.setColor(0.3, 0.5, 0.7, 1)
        else
            love.graphics.setColor(0.25, 0.25, 0.3, 1)
        end
        love.graphics.rectangle("fill", thumbX, thumbY, thumbW, thumbH, 4)

        -- Thumbnail border
        if isSelected then
            love.graphics.setColor(0.5, 0.7, 0.9, 1)
        else
            love.graphics.setColor(0.4, 0.4, 0.45, 1)
        end
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", thumbX, thumbY, thumbW, thumbH, 4)
        love.graphics.setLineWidth(1)

        -- Page label centered
        love.graphics.setColor(1, 1, 1, 1)
        local label = "Page " .. page.id
        local labelW = font:getWidth(label)
        love.graphics.print(label, thumbX + (thumbW - labelW) / 2, thumbY + (thumbH - 16) / 2)

        thumbIndex = thumbIndex + 1
    end

    -- Bottom buttons area
    local btnY = panel.y + panel.height - 45
    local btnW = 40
    local btnH = 35
    local btnGap = 5
    local btnX = panel.x + 10

    -- Store button positions for click handling
    state.thumbnailButtons = {
        add = {x = btnX, y = btnY, w = btnW, h = btnH},
        remove = {x = btnX + btnW + btnGap, y = btnY, w = btnW, h = btnH},
        load = {x = btnX + (btnW + btnGap) * 2, y = btnY, w = 50, h = btnH}
    }

    -- Draw + button
    love.graphics.setColor(0.3, 0.5, 0.3, 1)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("+", btnX + 15, btnY + 8)

    -- Draw - button
    btnX = btnX + btnW + btnGap
    love.graphics.setColor(0.5, 0.3, 0.3, 1)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("-", btnX + 15, btnY + 8)

    -- Draw Load button
    btnX = btnX + btnW + btnGap
    love.graphics.setColor(0.3, 0.4, 0.5, 1)
    love.graphics.rectangle("fill", btnX, btnY, 50, btnH, 4)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Load", btnX + 10, btnY + 8)

    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle clicks on custom thumbnail panel
function editor.handleThumbnailClick(x, y)
    local layout = Layout.getConfigLayout()
    local panel = layout.thumbnailsPanel

    -- Check if click is in panel
    if x < panel.x or x > panel.x + panel.width then return false end
    if y < panel.y or y > panel.y + panel.height then return false end

    -- Check if Pages panel is gated (no cover = pages disabled)
    state.story.cover_image_path = state.story.cover_image_path or ""
    local hasCover = state.story.cover_image_path ~= ""
    -- All stories require cover before pages can be edited (no legacy exception)
    local pagesEnabled = hasCover

    if not pagesEnabled then
        editor.showMessage("Generate cover first!")
        return true  -- Consume click but don't do anything
    end

    -- Check thumbnail clicks
    local thumbW = panel.width - 20
    local thumbH = 60
    local thumbGap = 8
    local startY = panel.y + 40
    local thumbX = panel.x + 10
    local thumbIndex = 0

    -- Check Page-Story click first (if cover exists)
    if hasCover then
        local thumbY = startY + thumbIndex * (thumbH + thumbGap)
        if x >= thumbX and x <= thumbX + thumbW and
           y >= thumbY and y <= thumbY + thumbH then
            state.selectedPageIndex = 0  -- Page-Story
            return true
        end
        thumbIndex = thumbIndex + 1
    end

    -- Check regular page clicks
    for i, page in ipairs(state.story.pages) do
        local thumbY = startY + thumbIndex * (thumbH + thumbGap)

        if thumbY + thumbH > panel.y + panel.height - 60 then
            break
        end

        if x >= thumbX and x <= thumbX + thumbW and
           y >= thumbY and y <= thumbY + thumbH then
            state.selectedPageIndex = i  -- Regular page (1-indexed)
            return true
        end
        thumbIndex = thumbIndex + 1
    end

    -- Check button clicks
    if state.thumbnailButtons then
        local btns = state.thumbnailButtons
        if x >= btns.add.x and x <= btns.add.x + btns.add.w and
           y >= btns.add.y and y <= btns.add.y + btns.add.h then
            editor.addPage()
            return true
        end
        if x >= btns.remove.x and x <= btns.remove.x + btns.remove.w and
           y >= btns.remove.y and y <= btns.remove.y + btns.remove.h then
            editor.deletePage()
            return true
        end
        if x >= btns.load.x and x <= btns.load.x + btns.load.w and
           y >= btns.load.y and y <= btns.load.y + btns.load.h then
            state.showLoadDialog = true
            state.availableFiles = editor.getStoryFiles()
            state.selectedFileIndex = 1
            return true
        end
    end

    return false
end

-- Story settings header (collapsible, at top of right sidebar)
function editor.drawStorySettingsHeader()
    local layout = Layout.getConfigLayout()
    local header = layout.storySettingsHeader

    local panelHeight = state.storySettingsExpanded and header.expandedHeight or header.collapsedHeight

    Slab.BeginWindow("StorySettingsHeader", {
        Title = "",
        X = header.x,
        Y = header.y,
        W = header.width,
        H = panelHeight,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false,
        NoOutline = true,
        BgColor = Tokens.COLORS.panel_medium_transparent
    })

    -- Collapsible header button
    local headerIcon = state.storySettingsExpanded and "v" or ">"
    local headerText = headerIcon .. " Story Settings"

    if Slab.Button(headerText, {W = header.width - 20}) then
        state.storySettingsExpanded = not state.storySettingsExpanded
    end

    if state.storySettingsExpanded then
        local inputW = header.width - 30

        Slab.Separator()

        -- File operations row
        if Slab.Button("New", {W = 55}) then
            editor.newStory()
        end
        Slab.SameLine()
        if Slab.Button("Save", {W = 55}) then
            editor.saveStory()
        end
        Slab.SameLine()
        if Slab.Button("Test", {W = 55}) then
            -- Tab key handles this
            editor.showMessage("Press Tab to test play")
        end

        Slab.Separator()

        -- Story Title
        Slab.Text("Title")
        if Slab.Input("StoryTitleNew", {Text = state.story.title, W = inputW}) then
            state.story.title = Slab.GetInputText()
        end

        -- Topic
        state.story.topic = state.story.topic or ""
        Slab.Text("Topic")
        if Slab.Input("StoryTopicNew", {Text = state.story.topic, W = inputW}) then
            state.story.topic = Slab.GetInputText()
        end

        -- General Image Prompt
        state.story.general_image_prompt = state.story.general_image_prompt or ""
        Slab.Text("Image Prompt")
        if Slab.Input("GeneralImagePromptNew", {Text = state.story.general_image_prompt, W = inputW, MultiLine = true, H = 45}) then
            state.story.general_image_prompt = Slab.GetInputText()
        end

        Slab.Separator()

        -- Cover image status and Generate Cover button
        state.story.cover_image_path = state.story.cover_image_path or ""
        local hasCover = state.story.cover_image_path ~= ""
        local hasPrompt = state.story.general_image_prompt and state.story.general_image_prompt ~= ""

        if hasCover then
            Slab.Text("Cover: Generated", {Color = {0.5, 0.8, 0.5, 1}})
        else
            Slab.Text("Cover: Not generated", {Color = {0.8, 0.5, 0.5, 1}})
        end

        -- Generate Cover button
        if state.isGenerating and state.generatingCover then
            Slab.Text("Generating cover...", {Color = {0.8, 0.8, 0.3, 1}})
        else
            if Slab.Button("Generate Cover", {W = inputW, Disabled = not hasPrompt or state.isGenerating}) then
                editor.startCoverGeneration()
            end
            if not hasPrompt then
                Slab.Text("Enter Image Prompt first", {Color = {0.6, 0.6, 0.6, 1}})
            end
        end
    end

    Slab.EndWindow()
end

-- Control deck panel (right sidebar with page editor fields)
function editor.drawControlDeck()
    local layout = Layout.getConfigLayout()
    local panel = layout.controlDeckPanel

    -- Adjust Y position based on story settings expansion
    local header = layout.storySettingsHeader
    local panelY = header.y + (state.storySettingsExpanded and header.expandedHeight or header.collapsedHeight) + 5
    local panelH = layout.dreamItBar.y - panelY - 10

    Slab.BeginWindow("ControlDeck", {
        Title = "Page Editor",
        X = panel.x,
        Y = panelY,
        W = panel.width,
        H = panelH,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false,
        NoOutline = true,
        BgColor = Tokens.COLORS.panel_dark_transparent
    })

    local inputW = panel.width - 30

    -- Check if Page-Story is selected (index 0)
    if state.selectedPageIndex == 0 then
        -- Show Page-Story preview (read-only)
        Slab.Text("Page-Story Preview", {Color = {0.9, 0.8, 0.5, 1}})
        Slab.Separator()

        Slab.Text("Title:")
        Slab.Text(state.story.title or "(no title)", {Color = {0.7, 0.7, 0.8, 1}})

        Slab.Text("Topic:")
        Slab.Text(state.story.topic or "(no topic)", {Color = {0.7, 0.7, 0.8, 1}})

        Slab.Separator()
        Slab.Text("Cover Image:")
        local coverPath = state.story.cover_image_path or ""
        if coverPath ~= "" then
            Slab.Text(coverPath, {Color = {0.6, 0.8, 0.6, 1}})
        else
            Slab.Text("(no cover)", {Color = {0.5, 0.5, 0.5, 1}})
        end

        Slab.Separator()
        Slab.Text("This page cannot be edited.", {Color = {0.6, 0.6, 0.6, 1}})
        Slab.Text("It shows in Play mode as the", {Color = {0.6, 0.6, 0.6, 1}})
        Slab.Text("intro screen before Page 1.", {Color = {0.6, 0.6, 0.6, 1}})

        Slab.EndWindow()
        return
    end

    local page = state.story.pages[state.selectedPageIndex]

    if not page then
        Slab.Text("No page selected")
        Slab.EndWindow()
        return
    end

    -- Question Text
    Slab.Text("Question")
    if Slab.Input("QuestionTextNew", {Text = page.question_text, W = inputW, MultiLine = true, H = 50}) then
        page.question_text = Slab.GetInputText()
    end

    -- Hint Text
    Slab.Text("Hint")
    if Slab.Input("HintTextNew", {Text = page.hint_text, W = inputW}) then
        page.hint_text = Slab.GetInputText()
    end

    Slab.Separator()

    -- Image Generation section
    Slab.Text("Page Image")

    -- Show current image path or placeholder
    local imagePath = page.image_path or ""
    if imagePath ~= "" then
        Slab.Text(imagePath, {Color = {0.6, 0.8, 0.6, 1}})
    else
        Slab.Text("(no image)", {Color = {0.5, 0.5, 0.5, 1}})
    end

    -- Page image prompt (required for page image generation)
    page.image_prompt = page.image_prompt or ""
    Slab.Text("Image Prompt")
    if Slab.Input("PageImagePrompt", {Text = page.image_prompt, W = inputW, H = 40, MultiLine = true}) then
        page.image_prompt = Slab.GetInputText()
    end

    -- Check if page has a prompt
    local hasPagePrompt = page.image_prompt and page.image_prompt ~= ""

    if hasPagePrompt then
        Slab.Text("Ready to generate", {Color = {0.5, 0.8, 0.5, 1}})
    else
        Slab.Text("Enter prompt to generate", {Color = {0.8, 0.6, 0.4, 1}})
    end

    -- Generate Image button (uses page image prompt + question only)
    if state.isGenerating and not state.generatingCover then
        Slab.Text("Generating...", {Color = {0.8, 0.8, 0.3, 1}})
    else
        local hasQuestion = page.question_text and page.question_text ~= ""
        local canGenerate = hasPagePrompt and hasQuestion
        if Slab.Button("Generate Image", {W = inputW, Disabled = not canGenerate or state.isGenerating}) then
            print("[Editor] Generate Image clicked!")
            print("[Editor] Page image prompt: " .. tostring(page.image_prompt))
            print("[Editor] Page question: " .. tostring(page.question_text))
            editor.startImageGeneration(page)
        end
        if not hasPagePrompt then
            Slab.Text("Enter page image prompt", {Color = {0.6, 0.6, 0.6, 1}})
        elseif not hasQuestion then
            Slab.Text("Enter question text", {Color = {0.6, 0.6, 0.6, 1}})
        end
    end

    Slab.Separator()

    -- Question Type dropdown
    Slab.Text("Question Type")
    page.question_type = page.question_type or "yesno"
    local typeIndex = 1
    for i, t in ipairs(QUESTION_TYPES) do
        if t == page.question_type then typeIndex = i break end
    end

    if Slab.BeginComboBox("QuestionTypeNew", {Selected = QUESTION_TYPE_LABELS[typeIndex], W = inputW}) then
        for i, label in ipairs(QUESTION_TYPE_LABELS) do
            if Slab.TextSelectable(label) then
                page.question_type = QUESTION_TYPES[i]
            end
        end
        Slab.EndComboBox()
    end

    Slab.Separator()

    -- Question type specific fields
    local halfW = math.floor((inputW - 10) / 2)

    if page.question_type == "yesno" then
        -- Correct answer checkbox
        if page.correct_answer_is_yes == nil then
            page.correct_answer_is_yes = true
        end
        if Slab.CheckBox(page.correct_answer_is_yes, "Correct = Yes") then
            page.correct_answer_is_yes = not page.correct_answer_is_yes
        end

        -- Button Labels
        page.choice_labels = page.choice_labels or {"Yes", "No"}
        Slab.Text("Button Labels")
        if Slab.Input("YesButtonNew", {Text = page.choice_labels[1], W = halfW}) then
            page.choice_labels[1] = Slab.GetInputText()
        end
        Slab.SameLine()
        if Slab.Input("NoButtonNew", {Text = page.choice_labels[2], W = halfW}) then
            page.choice_labels[2] = Slab.GetInputText()
        end

    elseif page.question_type == "text" then
        page.correct_answer = page.correct_answer or ""
        Slab.Text("Correct Answer")
        if Slab.Input("CorrectAnswerNew", {Text = page.correct_answer, W = inputW}) then
            page.correct_answer = Slab.GetInputText()
        end

    elseif page.question_type == "multi" then
        page.questions = page.questions or {}

        Slab.Text("Sub-Questions (" .. #page.questions .. ")")

        local toRemove = nil
        for i, q in ipairs(page.questions) do
            Slab.Text("Q" .. i)
            if Slab.Input("SubQ" .. i .. "Text", {Text = q.question_text or "", W = inputW - 35}) then
                q.question_text = Slab.GetInputText()
            end
            Slab.SameLine()
            if Slab.Button("X##sub" .. i, {W = 25}) then
                toRemove = i
            end

            if Slab.Input("SubQ" .. i .. "Ans", {Text = q.correct_answer or "", W = inputW}) then
                q.correct_answer = Slab.GetInputText()
            end
        end

        if toRemove then
            table.remove(page.questions, toRemove)
        end

        if Slab.Button("+ Add", {W = 80}) then
            table.insert(page.questions, {question_text = "", correct_answer = ""})
        end
    end

    -- Navigation info
    Slab.Separator()
    Slab.Text("Navigation: Linear")

    state.isDirty = true

    Slab.EndWindow()
end

-- Dream It button bar (bottom)
function editor.drawDreamItButton()
    local layout = Layout.getConfigLayout()
    local bar = layout.dreamItBar

    Slab.BeginWindow("DreamItBar", {
        Title = "",
        X = bar.x,
        Y = bar.y,
        W = bar.width,
        H = bar.height,
        AutoSizeWindow = false,
        AllowMove = false,
        AllowResize = false,
        NoOutline = true,
        BgColor = Tokens.COLORS.panel_medium_transparent
    })

    -- Center the button
    local btnX = (bar.width - bar.buttonWidth) / 2 - 10
    Slab.SetCursorPos(btnX, 10)

    local isGenerating = state.isGenerating
    local btnLabel = isGenerating and "Generating..." or "Dream It!"

    -- Use a custom color for the dream button
    local btnOptions = {
        W = bar.buttonWidth,
        H = bar.buttonHeight,
        Disabled = isGenerating
    }

    if Slab.Button(btnLabel, btnOptions) then
        if state.story.general_image_prompt and state.story.general_image_prompt ~= "" then
            local page = state.story.pages[state.selectedPageIndex]
            if page then
                editor.startImageGeneration(page)
            end
        else
            state.storySettingsExpanded = true
            editor.showMessage("Set Image Prompt in Story Settings first!")
        end
    end

    Slab.EndWindow()
end

-- ============================================
-- END NEW STORYBOOK LAYOUT PANELS
-- ============================================

function editor.addPage()
    local maxId = 0
    for _, page in ipairs(state.story.pages) do
        if page.id > maxId then maxId = page.id end
    end

    local newPage = {
        id = maxId + 1,
        image_path = "",
        image_prompt = "",  -- Per-page prompt (overrides story prompt)
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

    -- All stories now require cover before editing pages (no legacy exception)
    -- Expand story settings if no cover so user can generate one
    if not story.cover_image_path or story.cover_image_path == "" then
        state.storySettingsExpanded = true
    end

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
    print("[Editor] startImageGeneration called")
    if state.isGenerating then
        print("[Editor] Already generating, skipping")
        return
    end

    state.isGenerating = true
    state.generatingCover = false
    state.generationError = nil

    -- Start the image generation thread
    print("[Editor] Starting image thread...")
    state.imageThread = love.thread.newThread("image_thread.lua")
    state.imageThread:start()

    -- Page image uses ONLY page.image_prompt (no story prompt)
    local requestChannel = love.thread.getChannel("image_request")
    local request = {
        url = BACKEND_URL,
        description = page.image_prompt or "",
        question = page.question_text or ""
    }
    print("[Editor] Sending request to backend:")
    print("[Editor]   URL: " .. request.url)
    print("[Editor]   Description: " .. request.description)
    print("[Editor]   Question: " .. request.question)
    requestChannel:push(request)

    editor.showMessage("Generating image...")
end

function editor.startCoverGeneration()
    print("[Editor] startCoverGeneration called")
    if state.isGenerating then
        print("[Editor] Already generating, skipping")
        return
    end

    state.isGenerating = true
    state.generatingCover = true
    state.generationError = nil

    -- Start the image generation thread
    state.imageThread = love.thread.newThread("image_thread.lua")
    state.imageThread:start()

    -- Send the request using story prompt and title
    local requestChannel = love.thread.getChannel("image_request")
    requestChannel:push({
        url = BACKEND_URL,
        description = state.story.general_image_prompt or "",
        question = "Cover image for story: " .. (state.story.title or "Untitled")
    })

    editor.showMessage("Generating cover...")
end

return editor
