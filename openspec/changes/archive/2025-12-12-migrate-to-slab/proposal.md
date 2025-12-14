# Change: Migrate Creator Studio to Slab GUI Library

## Why

Per `project.md` and `Full_roadmap.md`, the original architecture specifies **Slab** for the Creator Studio UI. Currently, a custom `imgui.lua` is used. Migrating to Slab provides:
- Built-in file dialogs for story loading/saving
- Color pickers for asset tinting
- Tree views for hierarchical story structure
- Better theming support via Style.lua
- Active community maintenance

## What Changes

- Replace `imgui.lua` with Slab in `editor.lua`
- Update `main.lua` to initialize and draw Slab
- Remove custom `libraries/imgui.lua`
- **BREAKING**: Editor now uses Slab API patterns

## Impact

- Affected specs: creator-studio, libraries
- Affected code: main.lua, editor.lua
- Removed: libraries/imgui.lua
