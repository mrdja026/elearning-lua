# Design: Creator Studio AI Wizard

## Context

The backend has a complete AI story generation pipeline accessible via `/api/flow-test/*` endpoints. The shell script `e2eADKFlow.sh` demonstrates the full flow with interactive prompts. This change brings that same experience into the LÖVE2D app.

### Constraints
- LÖVE2D requires threading for HTTP requests (blocks UI otherwise)
- Slab UI is immediate-mode (must manage state separately)
- Wizard must be non-cancelable during generation (data integrity)
- Images must be downloaded and saved locally

## Goals / Non-Goals

### Goals
- Mirror the 6-step flow from `e2eADKFlow.sh`
- Show engaging messages during generation wait
- Auto-load generated story into editor
- Reuse existing `image_thread.lua` patterns for HTTP

### Non-Goals
- Editing story during generation
- Canceling mid-generation
- Saving partial progress

## Decisions

### Decision 1: Separate Wizard Module

**Choice**: Create `wizard.lua` as standalone module, not embedded in editor.lua

**Why**:
- Cleaner separation of concerns
- Wizard has its own complex state machine (7 states)
- Can be tested/modified independently
- Keeps editor.lua focused on editing

### Decision 2: Dedicated HTTP Thread

**Choice**: Create `wizard_thread.lua` separate from `image_thread.lua`

**Why**:
- Wizard makes sequential API calls (4 endpoints)
- Different request/response format than image generation
- Avoids complicating existing image thread
- Cleaner channel management

### Decision 3: State Machine for Steps

**Choice**: Use step number (1-7) with step 7 being generation phase

```lua
wizard.state = {
    step = 1,        -- 1-6: input steps, 7: generating
    generating = false,
    generationPhase = "", -- "starting", "enhancing", "cover", "pages"
}
```

**Why**:
- Simple numeric progression
- Step 7 clearly separates input from generation
- Generation phases map to API calls

### Decision 4: Absurd Life Advice Messages

**Choice**: Rotate through 20+ funny messages every 3 seconds during generation

**Examples**:
- "Never trust a penguin with your WiFi password"
- "If life gives you lemons, check for hidden cameras"
- "Remember: dolphins are just wet dogs with degrees"
- "Pro tip: You can't be late if you never show up"

**Why**:
- User requested this style specifically
- Makes the wait entertaining
- Similar to Claude Code's loading messages

### Decision 5: Local Image Download

**Choice**: Download images to `images/` directory like `image_thread.lua`

**Flow**:
1. API returns Cloudinary URLs
2. Thread downloads each image
3. Saves to `images/wizard_<timestamp>_<page>.png`
4. Story object uses local paths

**Why**:
- Consistent with existing image handling
- Works offline after generation
- Avoids URL expiration issues

## Wizard Thread Protocol

### Request Channel: `wizard_request`

```lua
{
    action = "generate",
    data = {
        topic = "programming basics",
        artStyle = "pixel",
        targetAge = "8-12",
        pageCount = 3,
        pageHints = {"if statement", "for loop", "variables"}
    }
}
```

### Response Channel: `wizard_response`

Progress updates:
```lua
{ type = "progress", phase = "starting" }
{ type = "progress", phase = "enhancing", character = "Professor Code" }
{ type = "progress", phase = "cover", url = "..." }
{ type = "progress", phase = "pages", current = 1, total = 3 }
```

Final result:
```lua
{
    type = "complete",
    story = { ... }  -- Full story object ready for editor
}
```

Error:
```lua
{ type = "error", message = "Failed to connect" }
```

## UI Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Story Generator                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Step X/6: [Step Title]                                     │
│  ─────────────────────────────────────────                  │
│                                                             │
│  [Step-specific content: input fields, dropdowns, etc.]    │
│                                                             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  [Back]                                          [Next]     │
└─────────────────────────────────────────────────────────────┘
```

Generation phase:
```
┌─────────────────────────────────────────────────────────────┐
│                    Creating Your Story...                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    [Spinner Animation]                      │
│                                                             │
│              "Never argue with a duck about                 │
│                      economics"                             │
│                                                             │
│  ──────────────────────────────────────────                 │
│  Phase: Generating page images (2/3)                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Long generation time (2-5 min) | Engaging messages, progress updates |
| API failure mid-generation | Show error, allow restart wizard |
| User closes app during gen | No mitigation needed (just loses progress) |
| Thread crashes | Error handling, timeout fallback |
