# Design: Nx Monorepo with Tauri v2 Desktop App

## Context

LogicTales is transitioning from a standalone Love2D game with separate backend to a packaged desktop application. The game needs to run in-browser (via Love.js WASM) inside a Tauri v2 + React shell that provides:
- Desktop distribution (Windows, macOS)
- Native capabilities (file system, microphone for speech-to-text)
- Async I/O handling (since Love.js doesn't support `love.thread`)

## Goals / Non-Goals

**Goals:**
- Clean separation: backend, game, app as distinct packages
- Tauri v2 app with camera/microphone permissions
- Love.js pipeline for WASM compilation
- React bridge for async operations (image generation, speech-to-text)
- Preserve native Love2D dev mode for rapid iteration

**Non-Goals:**
- Linux support (webkitgtk lacks WebRTC for speech)
- Mobile apps (future consideration)
- Branching story paths (stays linear per existing specs)

## Decisions

### 1. Monorepo Tool: Nx

**Decision:** Use Nx with `@nx/vite`, `@nx/react` plugins.

**Rationale:** Nx provides:
- Built-in task caching and dependency graph
- First-class Vite/React support
- Custom executor support for Love2D and Tauri

**Alternatives considered:**
- pnpm workspaces: Simpler but lacks build orchestration
- Turborepo: Similar but less mature React tooling

### 2. Async Architecture: PostMessage Bridge

**Decision:** Replace `love.thread` with React postMessage bridge.

**Rationale:** Love.js doesn't support Lua threads. React already needs to handle speech-to-text, so centralizing all async I/O in React simplifies the architecture.

**Message flow:**
```
Game (Lua) --postMessage--> React --fetch--> Hono Backend
Game (Lua) <--postMessage-- React <-------- Response
```

**Alternatives considered:**
- Keep threading in native mode only: Would require maintaining two code paths
- Use Web Workers in Love.js: Not supported by Love.js

### 3. Dual Mode Support

**Decision:** `bridge.lua` has native HTTP fallback for `love .` development.

**Rationale:** Developers need to iterate quickly on game logic without running the full Tauri stack. The bridge module detects environment and uses appropriate transport.

### 4. Tauri v2 Capabilities

**Decision:** Use Tauri v2 capabilities system for permissions.

**Permissions required:**
- `http:default` - Backend API calls
- `fs:allow-app-write/read` - Story file storage
- CSP: `wasm-unsafe-eval` for Love.js

**macOS:** Info.plist entries for microphone access.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Love.js audio limitations | Some sounds may not work | Test audio APIs early, document workarounds |
| Memory cap (536MB) | Large assets may fail | Configure love.js -m flag, optimize assets |
| Speech recognition browser dependency | May not work in all WebViews | Fallback to typed input |
| Two code paths (bridge.lua) | Maintenance overhead | Clear abstraction, good tests |

## Migration Plan

1. **Restructure first** - Move files to new locations
2. **Backend works unchanged** - Just different path
3. **Game works unchanged** - Just different path (native mode)
4. **Add bridge.lua** - New module with native fallback
5. **Refactor editor.lua** - Remove threading, use bridge
6. **Create React app** - GameRunner, api.ts, hooks
7. **Configure Tauri** - Permissions, capabilities
8. **Love.js pipeline** - Build scripts, templates
9. **Integration testing** - Full flow in Tauri

**Rollback:** Git revert if issues arise; no database migrations.

## Open Questions

None - all clarified during planning phase.
