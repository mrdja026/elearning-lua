local logic = {}

function logic.evaluateCondition(operator, currentValue, targetValue)
    if operator == ">" then
        return currentValue > targetValue
    elseif operator == "<" then
        return currentValue < targetValue
    elseif operator == "=" or operator == "==" then
        return currentValue == targetValue
    elseif operator == ">=" then
        return currentValue >= targetValue
    elseif operator == "<=" then
        return currentValue <= targetValue
    elseif operator == "!=" or operator == "~=" then
        return currentValue ~= targetValue
    end
    return false
end

function logic.evaluateTextAnswer(userAnswer, correctAnswer)
    return userAnswer == correctAnswer
end

function logic.evaluateYesNo(userChoice, correctAnswerIsYes)
    -- userChoice is "yes" or "no" string
    -- correctAnswerIsYes is boolean
    local userSaidYes = (userChoice == "yes")
    return userSaidYes == correctAnswerIsYes
end

function logic.evaluateMultiQuestion(userAnswers, questions)
    local errors = {}
    local allCorrect = true

    for i, question in ipairs(questions) do
        local userAnswer = userAnswers[i] or ""
        if userAnswer ~= question.correct_answer then
            allCorrect = false
            table.insert(errors, {
                question_index = i,
                question_text = question.question_text,
                user_answer = userAnswer,
                correct_answer = question.correct_answer
            })
        end
    end

    return allCorrect, errors
end

function logic.processYesNo(page, userChoice)
    -- userChoice is "yes" or "no"
    local correctAnswerIsYes = page.correct_answer_is_yes ~= false -- default true
    local isCorrect = logic.evaluateYesNo(userChoice, correctAnswerIsYes)

    if isCorrect then
        return true, "correct"
    else
        return false, "incorrect"
    end
end

function logic.processTextAnswer(page, userAnswer)
    local isCorrect = logic.evaluateTextAnswer(userAnswer, page.correct_answer)

    if isCorrect then
        return true, "correct", nil
    else
        return false, "incorrect", {
            user_answer = userAnswer,
            correct_answer = page.correct_answer
        }
    end
end

function logic.processMultiAnswer(page, userAnswers)
    local allCorrect, errors = logic.evaluateMultiQuestion(userAnswers, page.questions)

    if allCorrect then
        return true, "correct", {}
    else
        return false, "incorrect", errors
    end
end

return logic
