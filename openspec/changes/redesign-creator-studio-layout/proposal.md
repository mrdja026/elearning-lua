# Change: Redesign Creator Studio Layout with Storybook Theme

## Why

The current Creator Studio layout prioritizes the editor panel over the preview, making it harder for educators to visualize their stories while creating. A preview-centric design with visual page thumbnails and warm storybook aesthetics will improve the creative experience and make the tool more inviting for non-technical users.

## What Changes

- **BREAKING**: Layout structure changes from `Pages | Editor | Preview` to `Thumbnails | Preview | Control Deck`
- Preview panel moves to center and becomes the dominant visual element
- Page list becomes visual thumbnails with placeholder images
- Editor fields move to right sidebar as "Control Deck"
- Story Settings become a collapsible header in the right sidebar
- New "Dream It" button at bottom for AI image generation
- Procedural pixel-art decorations drawn behind semi-transparent UI panels
- Warm storybook color palette added to design tokens

## Impact

- Affected specs: `creator-studio`, `ui-system`
- Affected code:
  - `ui/layout.lua` - New panel arrangement and calculations
  - `ui/tokens.lua` - New warm color palette
  - `ui/decorations.lua` - NEW module for procedural decorations
  - `editor.lua` - Panel restructure, transparency, collapsible sections
  - `main.lua` - Draw order change for decoration layer
