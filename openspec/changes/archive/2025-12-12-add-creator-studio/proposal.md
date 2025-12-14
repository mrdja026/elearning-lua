# Change: Add Creator Studio (Phase 2 - Story Editor UI)

## Why

Currently, stories must be created by manually writing JSON files. This requires programming knowledge and is error-prone. The Creator Studio provides a visual interface for creating and editing stories, making LogicTales accessible to non-programmers (teachers, parents, content creators).

## What Changes

- **NEW** `editor.lua` - Slab-based story editor with split-view layout
- **NEW** `filemanager.lua` - Save/Load story utilities
- **NEW** `libraries/Slab/` - Immediate Mode GUI library
- **MODIFIED** `main.lua` - Add mode switching (Play/Create)
- **MODIFIED** `conf.lua` - Enable keyboard repeat for text input

## Impact

- Affected specs: Creates new `creator-studio` capability
- Affected code: `main.lua` (mode system), new editor modules
- Dependencies: Slab GUI library
- This enables visual story creation while reusing Phase 1's renderer for preview
