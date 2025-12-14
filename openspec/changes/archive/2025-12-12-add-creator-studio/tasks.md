# Implementation Tasks

## 1. Setup

- [x] 1.1 Add imgui.lua library to `libraries/` (custom immediate-mode GUI)
- [x] 1.2 Update `conf.lua` to enable keyboard repeat for text input

## 2. Core Editor

- [x] 2.1 Create `editor.lua` with imgui initialization
- [x] 2.2 Implement mode switching (Play/Create) in `main.lua`
- [x] 2.3 Create split-view layout (left: editor, right: preview)

## 3. Story Editor UI

- [x] 3.1 Story metadata panel (title input)
- [x] 3.2 Page list panel with add/delete buttons
- [x] 3.3 Page editor panel (question_text, hint_text, image_path)
- [x] 3.4 Logic config panel (operator dropdown, variable_name, values)
- [x] 3.5 Navigation config (true/false destination dropdowns)
- [x] 3.6 Choice labels editor

## 4. File Management

- [x] 4.1 File operations integrated into `editor.lua`
- [x] 4.2 Save story button (writes JSON to love.filesystem)
- [x] 4.3 Load story dialog (lists available .json files)
- [x] 4.4 New story button (creates blank story template)

## 5. Preview Integration

- [x] 5.1 Live preview pane in right panel
- [x] 5.2 Preview updates when editor state changes
- [x] 5.3 Test play button (Tab switches to play mode with current story)
