# Change: Fix Story Frame Gating and Unify Preview Display

## Why
The story-frame spec has conflicting backwards compatibility rules that undermine the "generate cover first" requirement. Additionally, the play screen component should be reused for both story cover and page image display in the config preview.

## What Changes
- **BREAKING**: Remove backwards compatibility exception that allows old stories to bypass cover gating
- Clarify that Pages panel gating is always enforced for stories without cover
- Add requirement for unified preview display using play screen with `displayMode: "STORY" | "PAGE"`
- Play screen in config preview shows either cover image (STORY mode) or page image (PAGE mode)

## Impact
- Affected specs: story-frame, creator-studio
- Affected code: screens/play.lua, editor.lua (config preview logic)
