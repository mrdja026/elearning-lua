# Tasks: Add Interactive Story Wizard

## 1. Prompt Enhancer - Hint-Driven Metaphors

### 1.1 Add Hint-to-Metaphor Function
- [x] 1.1.1 Add `enhanceImagePromptWithHint()` function to `prompt-enhancer.ts`
- [x] 1.1.2 Implement visual metaphor system prompt with 51 few-shot examples
- [x] 1.1.3 Add DEV_MODE mock response support
- [x] 1.1.4 Export new result interface `HintEnhancedPromptResult`

### 1.2 Test Prompt Enhancer
- [x] 1.2.1 Add test route `POST /api/test-hint-prompt`
- [x] 1.2.2 **TEST**: curl test with programming hint
- [x] 1.2.3 **MANUAL**: Confirm visual metaphor is generated

## 2. Image Agent - Hint-Aware Wrapper

### 2.1 Add Hint-Aware Image Generation
- [x] 2.1.1 Add `runImageAgentWithHint()` function to `image-agent.ts`
- [x] 2.1.2 Wire up to `enhanceImagePromptWithHint()`
- [x] 2.1.3 Return `visualMetaphor` field in result

### 2.2 Test Image Agent
- [x] 2.2.1 Add test route `POST /api/test-hint-image`
- [x] 2.2.2 **TEST**: curl test hint-driven image generation
- [x] 2.2.3 **MANUAL**: Verify image shows loop-like visual (race track, circular path)

## 3. Session & Flow Routes Updates

### 3.1 Update Session Type
- [x] 3.1.1 Add `pageCount` and `pageHints` to session interface in `cache.ts`
- [x] 3.1.2 Update `createSession()` to accept new fields
- [x] 3.1.3 Update `WizardSession` type in `types/story.ts`

### 3.2 Update Flow Routes
- [x] 3.2.1 Modify `POST /api/flow-test/start` to accept `pageCount` and `pageHints`
- [x] 3.2.2 Store `pageHints` in session
- [x] 3.2.3 Modify `POST /api/flow-test/generate-pages` to use hints for image generation
- [x] 3.2.4 Generate `pageCount` images instead of fixed 3

### 3.3 Test Flow Routes
- [x] 3.3.1 **TEST**: curl test start with hints
- [x] 3.3.2 **MANUAL**: Confirm session stores hints correctly

## 4. Interactive Shell Script

### 4.1 Rewrite e2eADKFlow.sh
- [x] 4.1.1 Create `ask_with_validation()` helper function
- [x] 4.1.2 Implement Step 1: Topic prompt with validation
- [x] 4.1.3 Implement Step 2: Art style selection with validation
- [x] 4.1.4 Implement Step 3: Target age selection with validation
- [x] 4.1.5 Implement Step 4: Page count input with validation
- [x] 4.1.6 Implement Step 5: Per-page hint collection
- [x] 4.1.7 Implement Step 6: Review and confirmation
- [x] 4.1.8 Update API calls to include `pageCount` and `pageHints`

### 4.2 Test Shell Script
- [x] 4.2.1 **TEST**: Run interactive wizard manually
- [x] 4.2.2 **MANUAL**: Verify generated images match hints

## 5. End-to-End Testing

### 5.1 Full Flow Test
- [x] 5.1.1 **TEST**: Complete wizard flow with programming hints
- [x] 5.1.2 **MANUAL**: Verify all 3 images match their hints visually
- [x] 5.1.3 **MANUAL**: Verify JSON output includes visual metaphors

### 5.2 Edge Cases
- [x] 5.2.1 **TEST**: Single page story
- [x] 5.2.2 **TEST**: 5 page story (maximum)
- [x] 5.2.3 **TEST**: Empty hint falls back to generic prompt
