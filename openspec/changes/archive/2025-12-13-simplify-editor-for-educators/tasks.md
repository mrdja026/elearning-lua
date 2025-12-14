## 1. Data Model
- [x] 1.1 Update `schema.lua` - change QUESTION_TYPES to {"yesno", "text", "multi"}
- [x] 1.2 Update `schema.lua` - simplify validatePage() to remove binary logic validation
- [x] 1.3 Add `migrateStory()` function to convert binary pages to yesno

## 2. Editor UI
- [x] 2.1 Expand Story Settings panel with Topic field in `editor.lua`
- [x] 2.2 Add General Image Prompt field to Story Settings panel
- [x] 2.3 Remove binary logic UI (variable_name, operator, target_value)
- [x] 2.4 Add yesno question type with "Correct answer is Yes" checkbox
- [x] 2.5 Remove navigation destination dropdowns
- [x] 2.6 Update `startImageGeneration()` to use story-level prompt
- [x] 2.7 Update `ui/layout.lua` to increase storyPanel height

## 3. Game Logic
- [x] 3.1 Add `evaluateYesNo()` function to `logic.lua`
- [x] 3.2 Add `advanceToNextPage()` to `gamestate.lua`
- [x] 3.3 Add `isLastPage()` to `gamestate.lua`
- [x] 3.4 Add `getCurrentPageIndex()` to `gamestate.lua`

## 4. Play Mode Integration
- [x] 4.1 Update `handleChoice()` in `main.lua` for linear navigation
- [x] 4.2 Update `handleSubmit()` in `main.lua` for linear navigation
- [x] 4.3 Update `registerFocusables()` in `screens/play.lua` for yesno buttons
- [x] 4.4 Add `drawYesNoAnswers()` to `components/question_panel.lua`

## 5. Migration
- [x] 5.1 Call `migrateStory()` in `editor.loadStory()`
- [x] 5.2 Test migration with existing story files
