# LogicTales Development Guide

## Prerequisites

- Node.js 18+
- pnpm (`npm install -g pnpm`)
- Love2D (for native game development)
- Rust + Cargo (for Tauri builds)

## Quick Start

```bash
# Install dependencies
pnpm install

# Run everything (backend + React app)
pnpm dev
```

---

## Running Modes

### 1. Backend Only (Hono API with GADK Agents)

```bash
pnpm dev:backend
```

- Runs on `http://localhost:3000`
- Has Google Agent Kit integration (storyteller, researcher, critic, etc.)
- Test endpoint: `curl http://localhost:3000/`

### 2. Native Love2D Game (Full Editor)

```bash
pnpm dev:game
```

- Opens native Love2D window
- **Has full editor** (Tab to switch between Create/Play modes)
- Uses LuaJIT with Slab UI library
- Best for story creation and rapid iteration

### 3. Web Game (Love.js WASM)

```bash
# Build the game first
pnpm build:game

# Start the dev server
pnpm dev

# Open in browser
http://localhost:5174/game/index.html
```

- **Play mode only** (editor disabled - Slab requires LuaJIT)
- Runs in browser via WebAssembly
- Requires COOP/COEP headers (configured in vite.config.ts)

### 4. React + Tauri App (Desktop Shell)

```bash
# Build game assets first
pnpm build:game

# Run Tauri dev mode
pnpm nx tauri:dev app
```

- Tauri v2 desktop wrapper
- React frontend with GameRunner iframe
- **Status: iframe not loading game yet (WIP)**

### 5. Full Stack Development

```bash
pnpm dev
```

Runs in parallel:
- Backend on `http://localhost:3000`
- React app on `http://localhost:5174`

---

## Build Commands

| Command | Description |
|---------|-------------|
| `pnpm build:game` | Compile Love2D → Love.js WASM |
| `pnpm build:app` | Build Tauri distributable |
| `pnpm build` | Build all packages |

---

## Project Structure

```
apps/
  backend/       # Hono API + GADK agents
  game/          # Love2D game (Lua)
  app/           # React + Tauri shell
    public/game/ # Love.js WASM output
tools/
  love-builder/  # Love.js build pipeline
```

---

## Web Mode Limitations

The web (Love.js) version has these limitations:

1. **No editor** - Slab UI requires LuaJIT (`bit`, `ffi` modules)
2. **Play mode only** - Stories must be pre-loaded
3. **512MB memory cap** - Large assets may fail

To enable editor in web mode, replace Slab with [SUIT](https://github.com/vrld/suit) (pure Lua).

See TODO in `apps/game/main.lua` for details.

---

## Troubleshooting

### "SharedArrayBuffer is not defined"
Vite needs COOP/COEP headers. Check `apps/app/vite.config.ts`:
```ts
server: {
  headers: {
    'Cross-Origin-Opener-Policy': 'same-origin',
    'Cross-Origin-Embedder-Policy': 'require-corp',
  },
}
```

### Port 3000 already in use
```bash
# Windows
netstat -ano | findstr :3000
taskkill /PID <pid> /F

# Or use PowerShell
Stop-Process -Id (Get-NetTCPConnection -LocalPort 3000).OwningProcess -Force
```

### Game not loading in iframe
Known issue - game works at `/game/index.html` directly but not in React iframe. WIP.

---

## AI Session Continuation Prompt

```
Continue the Nx monorepo restructure (openspec change: restructure-nx-monorepo).

Current status:
- Love.js game works at http://localhost:5174/game/index.html (play mode only)
- Editor disabled in web mode (Slab requires LuaJIT - see TODO in main.lua)
- Backend synced with GADK (Google Agent Kit) agents

Remaining tasks:
1. Fix React iframe - GameRunner.tsx loads /game/index.html but game doesn't appear
   - Game works when accessed directly, fails in iframe
   - Check if COOP/COEP headers break iframe embedding
2. Test Tauri app with `pnpm nx tauri:dev app`
3. Test full bridge flow: Game → React → Backend → Game
4. Phase 5.2 integration testing

Commands:
- `pnpm dev` - runs backend + React app
- `pnpm build:game` - compiles Love.js WASM to apps/app/public/game/
- `pnpm dev:game` - runs native Love2D (has editor)

Key files modified:
- apps/game/main.lua - IS_WEB conditional, play-only mode
- apps/game/ui/style.lua - conditional Slab loading
- apps/app/vite.config.ts - COOP/COEP headers for SharedArrayBuffer
- tools/love-builder/build.js - Windows-compatible love.js execution
```
