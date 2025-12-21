# Change: Add Creator Studio AI Wizard

## Why

Currently, users must manually fill in all story fields (topic, questions, hints, image prompts) which is time-consuming and requires creativity. The backend already has a working AI story generation pipeline (`/api/flow-test/*` endpoints), but there's no UI to access it from the LÖVE2D app.

By adding a wizard modal that appears when the story is empty, we can:
1. Guide users through the same 6-step flow as `e2eADKFlow.sh`
2. Generate complete stories with AI-powered images
3. Show engaging "absurd life advice" messages during generation
4. Auto-load the generated story into the editor for review

## What Changes

### Client (creator-studio capability)
- **ADDED** `wizard.lua` - 6-step wizard modal UI with Slab
- **ADDED** `wizard_thread.lua` - HTTP thread for wizard API calls
- **MODIFIED** `editor.lua` - Trigger wizard on empty story, handle wizard completion
- **MODIFIED** `main.lua` - Draw wizard modal on top layer, update wizard thread

### Behavior
- Wizard appears automatically when story is empty (default "New Story" state)
- Non-cancelable during generation (no back/close during API calls)
- Shows rotating absurd life advice messages during generation
- After completion, loads story into editor for review/edit

## Impact

- **Affected specs**: `creator-studio`
- **Affected code**:
  - `wizard.lua` (new)
  - `wizard_thread.lua` (new)
  - `editor.lua` (modify)
  - `main.lua` (modify)

## 6-Step Wizard Flow

Mirrors `backend/e2eADKFlow.sh`:

| Step | Input | Validation |
|------|-------|------------|
| 1 | Topic (text) | Min 3 characters |
| 2 | Art Style (dropdown) | pixel/fantasy/cartoon |
| 3 | Target Age (dropdown) | 5-8/8-12/13-17/18+/all |
| 4 | Page Count (number) | 1-5, default 3 |
| 5 | Per-page Hints (text each) | One hint per page |
| 6 | Review & Confirm | Display summary |

## API Endpoints Used

Sequential calls to existing flow-test routes:
1. `POST /api/flow-test/start` - Create session
2. `POST /api/flow-test/confirm` - Enhance story prompt
3. `POST /api/flow-test/generate-cover` - Generate cover image
4. `POST /api/flow-test/generate-pages` - Generate all page images

## Testing Notes

E2E testing is expensive and low priority. Focus on:
- Manual testing of wizard flow
- DEV_MODE=true for mock API responses
- Verify story loads correctly into editor
