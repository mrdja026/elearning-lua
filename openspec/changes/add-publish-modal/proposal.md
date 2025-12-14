# Change: Add Publish Modal to Creator Studio

## Why

The Creator Studio UI is already cluttered with editor controls. Adding a publish button inline would add visual noise. A centered modal popup provides a focused, distraction-free publishing flow that doesn't obscure the editor.

## What Changes

### New: Publish Modal Component
- Centered modal overlay with dimmed background
- Title input field (pre-filled from story metadata)
- Story preview/summary
- Cancel and Publish action buttons
- Loading state during API call
- Success/error feedback

### New: Publish Button Trigger
- Small "Publish" button in Creator Studio header/toolbar
- Opens the modal on click

### New: HTTP Integration
- Lua HTTP client to call `POST /api/stories`
- Handle success (show confirmation, close modal)
- Handle errors (display message, allow retry)

## Impact

- **Modified specs**: creator-studio
- **New files**:
  - `components/publish_modal.lua`
  - `lib/http.lua` (or extend existing)
- **Modified files**:
  - `screens/creator.lua` (add publish button + modal integration)
