# Story Frame Feature

## Summary

Add a "Story Frame" intro screen that displays before Page 1 in Play mode. This creates a wizard-style flow where users must generate a cover image before editing pages.

## Motivation

- Provides a professional "title screen" for each story
- Forces users to think about story-level content (title, topic, cover image) before diving into pages
- Creates a more polished player experience with an intro screen

## User Experience

### Create Mode (Wizard Flow)

1. **New Story Created**
   - Story Settings panel expanded by default
   - Pages panel disabled (grayed out) with message "Generate cover first"

2. **User Fills Story Details**
   - Title (required for display)
   - Topic/Description (optional)
   - Story Image Prompt (for AI generation)

3. **Generate Cover Button**
   - Located in Story Settings panel
   - Generates cover image from story prompt
   - Clears story prompt after generation (prevents accidental re-generation)

4. **Pages Enabled**
   - Once cover is generated, Pages panel becomes active
   - User can now add/edit pages normally

### Play Mode

1. **Story Frame Display** (if cover exists)
   - Full-screen intro with pixel art decorations
   - Cover image centered prominently
   - Story title displayed
   - Topic/description shown below title
   - "Tap anywhere to start" prompt

2. **Dismiss & Play**
   - Click/tap anywhere dismisses Story Frame
   - Proceeds to Page 1 (normal gameplay)

### Backwards Compatibility

- Stories without `cover_image_path` skip Story Frame entirely
- Play mode goes directly to Page 1 (existing behavior)
- No data migration issues - missing field defaults to empty string

## Technical Approach

### Data Model

Add `cover_image_path` field to story schema:

```lua
story = {
    title = "...",
    topic = "...",
    general_image_prompt = "...",
    cover_image_path = "",  -- NEW
    pages = { ... }
}
```

### Key Components

1. **schema.lua** - Add field, update migration
2. **editor.lua** - Wizard flow, Generate Cover button, Pages gating
3. **screens/play.lua** - Story Frame rendering, flow control
4. **main.lua** - Input handling for Story Frame dismissal

## Acceptance Criteria

- [ ] New stories start with Story Settings expanded
- [ ] Pages panel disabled until cover generated
- [ ] "Generate Cover" button works in Story Settings
- [ ] Story Frame displays in Play mode (when cover exists)
- [ ] Tap anywhere dismisses Story Frame
- [ ] Old stories without cover play normally (no Story Frame)
