# Design: Creator Studio

## Context

Phase 2 adds a visual story editor. Users need to create stories without writing JSON manually. The editor must integrate with the existing Phase 1 logic engine and renderer.

## Goals / Non-Goals

**Goals:**
- Visual story editing with immediate feedback
- Save/Load stories to JSON files
- Reuse existing renderer for preview
- Simple, discoverable UI

**Non-Goals:**
- AI image generation (Phase 3)
- Cloud publishing (Phase 4-5)
- Undo/Redo system (future enhancement)

## Decisions

### Decision 1: Mode System

**What:** Global application mode switching

**Implementation:**
```lua
local APP_MODE = "play"  -- "play" or "create"

function love.keypressed(key)
    if key == "tab" then
        APP_MODE = (APP_MODE == "play") and "create" or "play"
    end
end
```

### Decision 2: Split-View Layout

**What:** Editor on left (60%), Preview on right (40%)

```
+------------------+-------------+
|   Editor Panel   |   Preview   |
|   (Slab UI)      |  (renderer) |
|                  |             |
|  - Story Title   |  [Image]    |
|  - Page List     |             |
|  - Page Editor   |  Question?  |
|  - Logic Config  |  [Yes] [No] |
+------------------+-------------+
     480px              320px
```

### Decision 3: Editor State

**What:** Separate state from game state

```lua
local editorState = {
    story = {
        title = "New Story",
        initial_variables = {},
        pages = {}
    },
    selectedPageIndex = 1,
    isDirty = false  -- unsaved changes
}
```

### Decision 4: Slab Integration

**What:** Initialize Slab in love.load, update in love.update, draw in love.draw

```lua
local Slab = require("libraries.Slab")

function love.load()
    Slab.Initialize()
end

function love.update(dt)
    if APP_MODE == "create" then
        Slab.Update(dt)
    end
end

function love.draw()
    if APP_MODE == "create" then
        editor.draw()  -- Uses Slab
        -- Draw preview in right panel
    else
        -- Normal game rendering
    end
end
```

## Data Flow

```
User Input
    ↓
Slab UI Widgets
    ↓
editorState.story (modified)
    ↓
schema.validateStory() (on save)
    ↓
json.encode() → love.filesystem.write()

Preview Flow:
editorState.story → renderer.drawPage(currentPage)
```

## File Structure

```
eai-learning/
├── main.lua           # Mode switching, Slab init
├── editor.lua         # Editor UI and state
├── filemanager.lua    # Save/Load utilities
├── renderer.lua       # (existing) Used for preview
├── schema.lua         # (existing) Used for validation
├── libraries/
│   ├── json.lua
│   └── Slab/          # GUI library (multiple files)
└── stories/
    └── *.json
```

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Slab learning curve | Start with basic widgets, expand gradually |
| Preview sync issues | Regenerate preview on any edit |
| Lost work on crash | Auto-save to temp file periodically |
| Large Slab library | Only include required files |

## UI Widget Plan

| Panel | Slab Widgets |
|-------|--------------|
| Story Metadata | Input (title) |
| Page List | ListBox, Button (Add/Delete) |
| Page Editor | Input (question, hint), Input (image_path) |
| Logic Config | ComboBox (operator), Input (variable, values) |
| Navigation | ComboBox (destinations) |
| File Operations | Button (Save, Load, New) |

## Open Questions

- Should preview auto-refresh or require manual refresh button?
- Include confirmation dialog for unsaved changes?
