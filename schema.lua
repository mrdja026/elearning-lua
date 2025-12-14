local schema = {}

local DEFAULT_CHOICE_LABELS = {"Yes", "No"}
local QUESTION_TYPES = {"yesno", "text", "multi"}

function schema.createPage(data)
    return {
        id = data.id,
        image_path = data.image_path or "",
        question_text = data.question_text or "",
        hint_text = data.hint_text or "",
        choice_labels = data.choice_labels or DEFAULT_CHOICE_LABELS,
        question_type = data.question_type or "yesno",
        correct_answer_is_yes = data.correct_answer_is_yes ~= false, -- defaults to true
        correct_answer = data.correct_answer or "",
        questions = data.questions or {}
    }
end

function schema.validatePage(page)
    if not page.id then
        return false, "Page missing required field: id"
    end
    if not page.question_text or page.question_text == "" then
        return false, "Page " .. page.id .. " missing required field: question_text"
    end

    local questionType = page.question_type or "yesno"

    if questionType == "yesno" then
        -- yesno type only needs correct_answer_is_yes boolean (defaults to true)
        -- No additional validation required
    elseif questionType == "text" then
        if not page.correct_answer or page.correct_answer == "" then
            return false, "Page " .. page.id .. " missing required field: correct_answer for text question"
        end
    elseif questionType == "multi" then
        if not page.questions or #page.questions == 0 then
            return false, "Page " .. page.id .. " must have at least one question for multi type"
        end
        for i, q in ipairs(page.questions) do
            if not q.question_text or q.question_text == "" then
                return false, "Page " .. page.id .. " question " .. i .. " missing question_text"
            end
            if not q.correct_answer or q.correct_answer == "" then
                return false, "Page " .. page.id .. " question " .. i .. " missing correct_answer"
            end
        end
    end

    return true
end

function schema.getQuestionTypes()
    return QUESTION_TYPES
end

function schema.validateStory(story)
    if not story.pages or #story.pages == 0 then
        return false, "Story has no pages"
    end

    for _, page in ipairs(story.pages) do
        local valid, err = schema.validatePage(page)
        if not valid then
            return false, err
        end
    end

    -- Linear navigation: pages are traversed in array order, no destination validation needed

    return true
end

-- Migrate stories from old binary format to new yesno format
function schema.migrateStory(story)
    -- Add story-level fields if missing
    story.topic = story.topic or ""
    story.general_image_prompt = story.general_image_prompt or ""

    -- Migrate each page
    for _, page in ipairs(story.pages or {}) do
        -- Convert binary to yesno
        if page.question_type == "binary" or page.question_type == nil then
            page.question_type = "yesno"
            page.correct_answer_is_yes = true -- default: Yes is correct
        end

        -- Ensure correct_answer_is_yes exists for yesno pages
        if page.question_type == "yesno" and page.correct_answer_is_yes == nil then
            page.correct_answer_is_yes = true
        end

        -- Update default choice labels from True/False to Yes/No
        if page.choice_labels then
            if page.choice_labels[1] == "True" then
                page.choice_labels[1] = "Yes"
            end
            if page.choice_labels[2] == "False" then
                page.choice_labels[2] = "No"
            end
        else
            page.choice_labels = {"Yes", "No"}
        end

        -- Remove deprecated fields
        page.variable_name = nil
        page.variable_value = nil
        page.operator = nil
        page.target_value = nil
        page.true_destination_id = nil
        page.false_destination_id = nil
        page.image_description = nil
    end

    return story
end

return schema
