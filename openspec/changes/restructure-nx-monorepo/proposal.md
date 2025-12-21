# Change: Restructure to Nx Monorepo with Tauri v2 Desktop App

## Why

The current project structure has Love2D game files at root level mixed with backend code, making it difficult to manage as a multi-platform application. Adding a desktop wrapper (Tauri v2 + React) requires a clean separation of concerns and a proper monorepo structure.

Additionally, Love.js (Love2D compiled to WASM) does not support `love.thread`, requiring a new async architecture where React handles all I/O operations via postMessage bridge.

## What Changes

### Phase 1: Infrastructure
- Initialize Nx monorepo with `apps/backend`, `apps/game`, `apps/app`
- Move existing files to new structure
- Configure Nx project targets
- Setup React + Vite app

### Phase 2: Tauri Shell
- Initialize Tauri v2 with permissions/capabilities
- Create Love.js build pipeline
- Implement `bridge.lua` postMessage module

### Phase 3: Game Refactoring
- Remove `love.thread` usage from `editor.lua`
- Replace with `bridge.requestImageGeneration()` calls
- **BREAKING**: Delete `image_thread.lua`

### Phase 4: React Integration
- Create GameRunner.tsx iframe component
- Implement API integration (backend + Tauri fs)
- Wire message handling between game and React

### Phase 5: Polish & Testing
- Add root package.json scripts
- Integration testing on Windows + macOS
- Documentation updates

### Phase 6: Speech-to-Text (LOW PRIORITY)
- Voice input for answers - deferred until core port complete

## Impact

- Affected specs: `creator-studio` (threading), `ai-pipeline` (image download)
- Affected code: `editor.lua` (thread creation), `image_thread.lua` (deleted)
- New code: `bridge.lua`, `GameRunner.tsx`, `api.ts`
- New tooling: Nx workspace, Love.js build pipeline, Tauri v2 configuration
