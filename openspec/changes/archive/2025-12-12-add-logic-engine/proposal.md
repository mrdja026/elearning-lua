# Change: Add Logic Engine (Phase 1 - Player Mode)

## Why

The Logic Engine is the foundational system for LogicTales. Without it, nothing else can work - no Creator Studio, no AI integration, no marketplace. It reads story files and lets users play through branching narratives with logic-based decisions.

## What Changes

- **NEW** `schema.lua` - Defines the Page data structure for stories
- **NEW** `gamestate.lua` - Manages current page pointer and game variables
- **NEW** `logic.lua` - Evaluates conditions safely (no `loadstring`)
- **NEW** `renderer.lua` - Draws placeholder image, question text, and choice buttons
- **NEW** `main.lua` - LÖVE entry point wiring everything together
- **NEW** Sample story JSON for testing

## Impact

- Affected specs: Creates new `logic-engine` capability
- Affected code: `src/` directory (new files)
- Dependencies: rxi/json library for JSON parsing
- This establishes the core data structures that all future phases will build upon
