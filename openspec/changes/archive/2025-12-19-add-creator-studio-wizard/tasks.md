# Tasks: Add Creator Studio AI Wizard

## 1. Wizard Thread

### 1.1 Create wizard_thread.lua
- [x] 1.1.1 Create `wizard_thread.lua` with channel setup
- [x] 1.1.2 Implement `POST /api/flow-test/start` call
- [x] 1.1.3 Implement `POST /api/flow-test/confirm` call
- [x] 1.1.4 Implement `POST /api/flow-test/generate-cover` call
- [x] 1.1.5 Implement `POST /api/flow-test/generate-pages` call
- [x] 1.1.6 Implement image download (reuse pattern from image_thread.lua)
- [x] 1.1.7 Implement progress updates via response channel
- [x] 1.1.8 Implement error handling and timeout

## 2. Wizard UI Module

### 2.1 Core Structure
- [x] 2.1.1 Create `wizard.lua` with state table
- [x] 2.1.2 Implement `wizard.init()` function
- [x] 2.1.3 Implement `wizard.update(dt)` for thread polling
- [x] 2.1.4 Implement `wizard.draw()` main render function
- [x] 2.1.5 Implement `wizard.open()` and `wizard.isOpen()` helpers

### 2.2 Step 1: Topic Input
- [x] 2.2.1 Draw topic input with Slab.Input
- [x] 2.2.2 Add validation (min 3 chars)
- [x] 2.2.3 Show description text from e2eADKFlow.sh

### 2.3 Step 2: Art Style
- [x] 2.3.1 Draw art style ComboBox (pixel/fantasy/cartoon)
- [x] 2.3.2 Show style descriptions

### 2.4 Step 3: Target Age
- [x] 2.4.1 Draw target age ComboBox (5-8/8-12/13-17/18+/all)
- [x] 2.4.2 Show age group descriptions

### 2.5 Step 4: Page Count
- [x] 2.5.1 Draw page count input (1-5)
- [x] 2.5.2 Add validation and default value (3)

### 2.6 Step 5: Page Hints
- [x] 2.6.1 Draw hint inputs based on pageCount
- [x] 2.6.2 Show hint examples from design.md
- [x] 2.6.3 Allow empty hints (fallback to generic)

### 2.7 Step 6: Review & Confirm
- [x] 2.7.1 Display summary of all inputs
- [x] 2.7.2 Draw "Generate Story" button
- [x] 2.7.3 Disable Back button during review

### 2.8 Step 7: Generation
- [x] 2.8.1 Draw generation overlay (non-cancelable)
- [x] 2.8.2 Implement spinner/loading animation
- [x] 2.8.3 Display current phase (starting/enhancing/cover/pages)
- [x] 2.8.4 Cycle through funny messages every 3 seconds

### 2.9 Absurd Life Advice
- [x] 2.9.1 Create FUNNY_MESSAGES table (20+ messages)
- [x] 2.9.2 Implement message rotation timer
- [x] 2.9.3 Style messages prominently in center

## 3. Editor Integration

### 3.1 Trigger Wizard
- [x] 3.1.1 Add `state.showWizard` to editor state
- [x] 3.1.2 Check for empty story in `editor.init()`
- [x] 3.1.3 Auto-open wizard when story is default/empty

### 3.2 Handle Completion
- [x] 3.2.1 Implement `editor.onWizardComplete(story)` callback
- [x] 3.2.2 Load story via `schema.migrateStory()`
- [x] 3.2.3 Reset selectedPageIndex and show message
- [x] 3.2.4 Set isDirty = true for save prompt

## 4. Main Loop Integration

### 4.1 Update Loop
- [x] 4.1.1 Add `wizard.update(dt)` call in love.update
- [x] 4.1.2 Ensure wizard updates only in create mode

### 4.2 Draw Loop
- [x] 4.2.1 Add `wizard.draw()` after `editor.drawModalDialogs()`
- [x] 4.2.2 Ensure wizard renders on top layer

## 5. Testing (Low Priority)

> **Note**: E2E testing is expensive. Focus on manual testing.

### 5.1 Manual Testing
- [x] 5.1.1 **MANUAL**: Test 6-step wizard flow
- [x] 5.1.2 **MANUAL**: Verify DEV_MODE mock responses work
- [x] 5.1.3 **MANUAL**: Verify story loads into editor correctly
- [x] 5.1.4 **MANUAL**: Verify funny messages display and rotate
