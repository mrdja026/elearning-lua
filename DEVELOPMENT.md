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
# Build game assets first (only needed once, or after game changes)
pnpm build:game

# Run Tauri dev mode (single command - starts Vite + Tauri)
pnpm dev:tauri
```

- Tauri v2 desktop wrapper
- React frontend with GameRunner iframe
- Game runs in Love.js WASM inside the app
- **Note:** Port 5173 must be free (Vite uses strictPort)

### 5. Full Stack Development

```bash
pnpm dev
```

Runs in parallel:

- Backend on `http://localhost:3000`
- React app on `http://localhost:5174`

---

## Build Commands

| Command           | Description                   |
| ----------------- | ----------------------------- |
| `pnpm build:game` | Compile Love2D → Love.js WASM |
| `pnpm build:app`  | Build Tauri distributable     |
| `pnpm build`      | Build all packages            |

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

Fixed: Ensure the parent div has explicit dimensions:

```tsx
<div style={{ width: '100vw', height: '100vh' }}>
  <GameRunner ... />
</div>
```

And the iframe has `display: block` (prevents inline spacing issues).

---

## AI Session Continuation Prompt

```
Continue the Nx monorepo restructure (openspec change: restructure-nx-monorepo).

Current status:
- Love.js game works at http://localhost:5173/game/ (play mode only)
- I can open game in iframe from tauri shell
- Editor disabled in web mode (Slab requires LuaJIT - see TODO in main.lua)
- Backend synced with GADK (Google Agent Kit) agents
- React iframe fixed (GameRunner.tsx with 100vw/100vh wrapper)
- Tauri app works with `pnpm dev:tauri`

Remaining tasks (Phase 5.2 Integration Testing):
1. Test full bridge flow: Game → React → Backend → Game (5.2.4)
2. Test story save/load via Tauri fs API (5.2.5)
3. Test native Love2D mode with bridge fallback (5.2.6)
4. Build and test Tauri distributable on Windows (5.2.7)
5. Build and test Tauri distributable on macOS (5.2.8)

Documentation tasks:
- Update root README.md with new project structure (5.3.1)
- Document build process for distributables (5.3.3)

Commands:
- `pnpm dev` - runs backend + React app (parallel)
- `pnpm dev:tauri` - runs Tauri app (starts Vite automatically)
- `pnpm build:game` - compiles Love.js WASM to apps/app/public/game/
- `pnpm dev:game` - runs native Love2D (has editor)

Key files:
- apps/game/main.lua - IS_WEB conditional, play-only mode
- apps/game/bridge.lua - PostMessage bridge for React communication
- apps/app/src/App.tsx - GameRunner with message handling
- apps/app/src/components/GameRunner.tsx - Iframe wrapper
- apps/app/vite.config.ts - COOP/COEP headers, strictPort: true
- apps/app/src-tauri/tauri.conf.json - devUrl: localhost:5173

Note: Port 5173 must be free for Tauri dev mode (strictPort enforced).
```
