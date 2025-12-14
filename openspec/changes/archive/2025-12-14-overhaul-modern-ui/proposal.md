# Change: Modern UI Overhaul

## Why

The current UI is functional but clunky. For a kids' educational game (ages 6-8), we need:
- Large, forgiving touch targets (48px+ minimum)
- Clear visual hierarchy with card-based design
- Multi-input support (mouse, keyboard, touch, controller)
- Pixel art that stays crisp at any scale
- Modern, engaging aesthetic that appeals to children

## What Changes

### New: UI System (`ui/` module)
- Design tokens (colors, spacing, typography, borders)
- Layout calculations with responsive breakpoints
- 9-slice rendering for scalable card frames
- Unified input manager for all input methods
- Slab style configuration
- Reusable widget wrappers

### Modified: Play Mode
- **BREAKING**: New split left/right layout (55% image / 45% question)
- Image displayed in modern card frame
- Question panel with proper hierarchy
- Status bar at bottom for feedback
- Support for keyboard/controller navigation

### Modified: Config Mode (Creator Studio)
- **BREAKING**: New 3-column layout (pages list | editor | preview)
- Top bar with file operations and settings
- Status bar for generation feedback
- Modernized panel styling with design tokens

### Modified: Window Configuration
- Virtual resolution: 1280×720 (was 1024×768)
- Resizable window with integer scaling
- Safe area support for notched displays

## Architecture

```
ui/
├── tokens.lua        # Design system constants
├── layout.lua        # Layout calculations
├── style.lua         # Slab configuration
├── widgets.lua       # Button, Card, Panel wrappers
├── nineslice.lua     # 9-slice frame rendering
└── input_manager.lua # Unified input handling

screens/
├── play.lua          # Play mode (split layout)
└── config.lua        # Config mode (editor)

components/
├── image_card.lua
├── question_panel.lua
├── page_list.lua
├── page_editor.lua
└── status_bar.lua
```

## Impact

- **New specs**: ui-system
- **Modified specs**: creator-studio
- **Modified files**: conf.lua, main.lua, renderer.lua, editor.lua
- **New files**: 11 new Lua modules in ui/, screens/, components/

## Design Direction

"Bold Kids Blocky" - Zero corner rounding, thick colored borders, 40px gaps, bright playful palette. Minecraft/LEGO-inspired aesthetic that keeps pixel art crisp.
