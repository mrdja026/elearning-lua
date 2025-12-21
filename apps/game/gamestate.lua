local gamestate = {}

local state = {
    current_page_id = 1,
    variables = {},
    story = nil,
    is_finished = false,
    result = nil,
    text_input = "",
    multi_answers = {},
    errors = {},
    active_input = 1
}

function gamestate.init()
    state.current_page_id = 1
    state.variables = {}
    state.story = nil
    state.is_finished = false
    state.result = nil
    state.text_input = ""
    state.multi_answers = {}
    state.errors = {}
    state.active_input = 1
end

function gamestate.loadStory(story)
    state.story = story
    state.current_page_id = 1
    state.variables = {}
    state.is_finished = false
    state.result = nil
    state.text_input = ""
    state.multi_answers = {}
    state.errors = {}
    state.active_input = 1

    if story.initial_variables then
        for k, v in pairs(story.initial_variables) do
            state.variables[k] = v
        end
    end
end

function gamestate.getCurrentPage()
    if not state.story or not state.story.pages then
        return nil
    end

    for _, page in ipairs(state.story.pages) do
        if page.id == state.current_page_id then
            return page
        end
    end
    return nil
end

function gamestate.setVariable(name, value)
    state.variables[name] = value
end

function gamestate.getVariable(name)
    return state.variables[name]
end

function gamestate.navigateTo(pageId)
    if pageId == nil or pageId == 0 then
        state.is_finished = true
        return
    end
    state.current_page_id = pageId
end

-- Linear navigation functions
function gamestate.getCurrentPageIndex()
    if not state.story or not state.story.pages then
        return 0
    end
    for i, page in ipairs(state.story.pages) do
        if page.id == state.current_page_id then
            return i
        end
    end
    return 0
end

function gamestate.isLastPage()
    if not state.story or not state.story.pages then
        return true
    end
    local index = gamestate.getCurrentPageIndex()
    return index >= #state.story.pages
end

function gamestate.advanceToNextPage()
    if not state.story or not state.story.pages then
        return false
    end

    local currentIndex = gamestate.getCurrentPageIndex()
    if currentIndex >= #state.story.pages then
        -- Already on last page, mark finished with win
        state.is_finished = true
        state.result = "win"
        return false
    end

    -- Move to next page
    local nextPage = state.story.pages[currentIndex + 1]
    if nextPage then
        state.current_page_id = nextPage.id
        return true
    end

    return false
end

function gamestate.setResult(result)
    state.result = result
    state.is_finished = true
end

function gamestate.isFinished()
    return state.is_finished
end

function gamestate.getResult()
    return state.result
end

function gamestate.getStory()
    return state.story
end

function gamestate.setTextInput(text)
    state.text_input = text
end

function gamestate.getTextInput()
    return state.text_input
end

function gamestate.setMultiAnswer(index, text)
    state.multi_answers[index] = text
end

function gamestate.getMultiAnswer(index)
    return state.multi_answers[index] or ""
end

function gamestate.getMultiAnswers()
    return state.multi_answers
end

function gamestate.setErrors(errors)
    state.errors = errors
end

function gamestate.getErrors()
    return state.errors
end

function gamestate.clearErrors()
    state.errors = {}
end

function gamestate.setActiveInput(index)
    state.active_input = index
end

function gamestate.getActiveInput()
    return state.active_input
end

function gamestate.resetInputState()
    state.text_input = ""
    state.multi_answers = {}
    state.errors = {}
    state.active_input = 1
end

return gamestate
