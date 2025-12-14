# Change: Fix UI Layout and Dropdown Functionality

## Why

Current UI has visual and functional issues:
- Dropdown menus lack background, making them hard to read
- Dropdown selection is broken - cannot select items
- Window is not fixed size, causing layout issues
- UI elements don't fit properly in the available space

## What Changes

- Set fixed window size to 1024x768
- Fix dropdown click detection and item selection
- Add proper background to dropdown/combobox elements
- Adjust panel sizes and positions to fit within fixed dimensions
- Ensure preview panel and editor panels fit correctly

## Impact

- Affected specs: creator-studio
- Affected code: conf.lua, editor.lua, main.lua, libraries/imgui.lua
