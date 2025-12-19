## 1. Data Layer
- [x] 1.1 Add `cover_image_path` field to story in `schema.lua`
- [x] 1.2 Update `migrateStory()` to initialize `cover_image_path` for old stories

## 2. Editor - Story Settings
- [x] 2.1 Set `storySettingsExpanded = true` by default in `newStory()`
- [x] 2.2 Add `cover_image_path = ""` to default story structure
- [x] 2.3 Add "Generate Cover" button in `drawStorySettingsHeader()`
- [x] 2.4 Implement cover generation logic (reuse image generation pattern)
- [x] 2.5 Clear `general_image_prompt` after cover generation

## 3. Editor - Pages Panel Gating
- [x] 3.1 Check `cover_image_path` in `drawPageThumbnails()`
- [x] 3.2 If empty: show disabled state with "Generate cover first" message
- [x] 3.3 If set: render Pages panel normally
- [x] 3.4 Disable Add/Remove page buttons when gated

## 4. Play Mode - Story Frame Screen
- [x] 4.1 Add `showingStoryFrame` state to PlayScreen
- [x] 4.2 Create `PlayScreen.drawStoryFrame(story)` function
- [x] 4.3 Draw background with decorations
- [x] 4.4 Draw cover image centered
- [x] 4.5 Draw story title
- [x] 4.6 Draw story topic/description
- [x] 4.7 Draw "Tap anywhere to start" prompt

## 5. Play Mode - Flow Control
- [x] 5.1 In `PlayScreen.enter()`: set `showingStoryFrame = true` if cover exists
- [x] 5.2 Add `schema.hasStoryFrame(story)` helper function
- [x] 5.3 In `drawPlayMode()`: check `showingStoryFrame` state
- [x] 5.4 Call `drawStoryFrame()` instead of page when showing frame
- [x] 5.5 Add `PlayScreen.dismissStoryFrame()` function

## 6. Input Handling
- [x] 6.1 In `love.mousepressed()`: check if showing Story Frame
- [x] 6.2 If showing: call `PlayScreen.dismissStoryFrame()`, proceed to Page 1
- [x] 6.3 Add keyboard support (any key dismisses)

## 7. Testing
- [ ] 7.1 Test new story wizard flow
- [ ] 7.2 Test Generate Cover button
- [ ] 7.3 Test Pages panel gating
- [ ] 7.4 Test Story Frame display in Play mode
- [ ] 7.5 Test tap/click dismissal
- [ ] 7.6 Test old story backwards compatibility
- [ ] 7.7 Test Save/Load with cover_image_path
