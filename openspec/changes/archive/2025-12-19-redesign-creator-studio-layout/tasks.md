## 1. Design Tokens Update
- [x] 1.1 Add warm storybook color palette to `ui/tokens.lua`
- [x] 1.2 Add semi-transparent panel colors for Slab integration
- [x] 1.3 Add decoration-specific colors (tree, star, etc.)

## 2. Layout Restructure
- [x] 2.1 Update `getConfigLayout()` in `ui/layout.lua` with new panel arrangement
- [x] 2.2 Add `thumbnailsPanel` calculation (left, 150px)
- [x] 2.3 Update `previewPanel` to center position (remaining width)
- [x] 2.4 Add `storySettingsHeader` calculation (top-right, collapsible)
- [x] 2.5 Add `controlDeckPanel` calculation (right, 300px)
- [x] 2.6 Add `dreamItBar` calculation (bottom, 70px)
- [x] 2.7 Remove old `editorPanel` references

## 3. Decorations Module
- [x] 3.1 Create `ui/decorations.lua` module
- [x] 3.2 Implement `drawPixelTree(x, y, scale)` function
- [x] 3.3 Implement `drawPixelCircle(cx, cy, radius)` function
- [x] 3.4 Implement `drawStar(x, y, size)` function
- [x] 3.5 Implement seeded random placement in `draw()` function
- [ ] 3.6 Test decoration rendering at various window sizes

## 4. Draw Order Update
- [x] 4.1 Update `drawCreateMode()` in `main.lua` to draw decorations before Slab
- [x] 4.2 Add warm background clear color
- [x] 4.3 Integrate `drawCenterPreview()` function for large centered preview

## 5. Editor Panel Restructure
- [x] 5.1 Create `drawPageThumbnails()` function with visual page cards
- [x] 5.2 Create `drawStorySettingsHeader()` with expand/collapse functionality
- [x] 5.3 Create `drawControlDeck()` with all editor fields in right sidebar
- [x] 5.4 Create `drawDreamItButton()` bottom bar with AI generation trigger
- [x] 5.5 Update `editor.draw()` to call new panel functions
- [x] 5.6 Apply semi-transparent `BgColor` to all Slab windows
- [x] 5.7 Set `NoOutline = true` for seamless appearance

## 6. Center Preview Implementation
- [x] 6.1 Create `drawCenterPreview()` function in `main.lua`
- [x] 6.2 Calculate dynamic scale to fit 800x600 in center area
- [x] 6.3 Add preview border and label
- [x] 6.4 Integrate with `editor.getCurrentPage()`

## 7. Testing
- [ ] 7.1 Test window resize behavior (640x360 to 1920x1080)
- [ ] 7.2 Test all button interactions in new positions
- [ ] 7.3 Test Story Settings expand/collapse
- [ ] 7.4 Test page thumbnail selection
- [ ] 7.5 Test "Dream It" button triggers AI generation
- [ ] 7.6 Test Tab switch to Play mode and back
- [ ] 7.7 Test Save/Load story functionality
