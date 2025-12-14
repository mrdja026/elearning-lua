## 1. Foundation
- [x] 1.1 Create `ui/tokens.lua` with design tokens (colors, spacing, typography, borders)
- [x] 1.2 Create `ui/layout.lua` with layout calculations and responsive logic
- [x] 1.3 Create `ui/nineslice.lua` for 9-slice card frame rendering
- [x] 1.4 Update `conf.lua` for 1280×720 virtual resolution, resizable window

## 2. Core UI System
- [x] 2.1 Create `ui/style.lua` to configure Slab with design tokens
- [x] 2.2 Create `ui/widgets.lua` with Button, Card, Panel wrapper functions
- [x] 2.3 Create `ui/input_manager.lua` for unified input handling (mouse/touch/keyboard/controller)
- [x] 2.4 Add scaling transform and canvas rendering to `main.lua`

## 3. Play Mode Screen
- [x] 3.1 Create `screens/play.lua` with split left/right layout
- [x] 3.2 Create `components/image_card.lua` for image display
- [x] 3.3 Create `components/question_panel.lua` for question and answer UI
- [x] 3.4 Create `components/status_bar.lua` for status feedback display
- [x] 3.5 Integrate play screen with `main.lua` (scaling, callbacks, page navigation)

## 4. Config Mode Screen
- [x] 4.1 Create `screens/config.lua` with 3-column panel layout
- [x] 4.2 Create `components/page_list.lua` for page sidebar
- [x] 4.3 Create `components/page_editor.lua` for page editing form
- [x] 4.4 Migrate `editor.lua` to use Layout system and design tokens

## 5. Polish and Testing
- [x] 5.1 9-slice fallback rendering implemented (procedural panels, no PNG required)
- [x] 5.2 Focus rings implemented in widgets.lua for buttons and inputs
- [x] 5.3 Touch targets enforce 48px minimum via Tokens.TOUCH.min_target
- [x] 5.4 Controller input handled via InputManager.gamepadpressed()
