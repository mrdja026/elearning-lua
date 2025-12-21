# LogicTales

Educational storytelling game with AI-generated content. Create interactive stories with branching logic, AI-generated images, and voice input.

## Architecture

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|    Love2D Game   |     |   Hono Backend   |     |   Tauri Shell    |
|       (Lua)      |     |   (TypeScript)   |     |     (Rust)       |
|                  |     |                  |     |                  |
+--------+---------+     +--------+---------+     +--------+---------+
         |                        |                        |
         v                        v                        v
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|     Love.js      |     |   Google ADK     |     |   React + Vite   |
|     (WASM)       |     |    (Agents)      |     |   (Frontend)     |
|                  |     |                  |     |                  |
+--------+---------+     +------------------+     +--------+---------+
         |                                                 |
         +-------------------------+-----------------------+
                                   |
                                   v
                          +------------------+
                          |                  |
                          |   Desktop App    |
                          |    (Windows/     |
                          |     macOS)       |
                          |                  |
                          +------------------+
```

## How It Fits Together

```
Native Development:
  love apps/game  -->  Love2D Window (full editor)

Web Build:
  apps/game/*.lua  -->  [love.js]  -->  game.wasm + game.js
                                              |
                                              v
                                    apps/app/public/game/

Desktop App:
  +-------------------------------------------------------+
  |  Tauri (Rust)                                         |
  |  +--------------------------------------------------+ |
  |  |  React (TypeScript)                              | |
  |  |  +---------------------------------------------+ | |
  |  |  |  iframe                                     | | |
  |  |  |  +----------------------------------------+ | | |
  |  |  |  |  Love.js Game (WASM)                   | | | |
  |  |  |  |                                        | | | |
  |  |  |  |  [Play Mode Only - No Editor]          | | | |
  |  |  |  +----------------------------------------+ | | |
  |  |  +---------------------------------------------+ | |
  |  +--------------------------------------------------+ |
  +-------------------------------------------------------+
```

## Communication Flow

```
+-------------+    postMessage    +-------------+    HTTP    +-------------+
|             | ----------------> |             | ---------> |             |
|  Love.js    |                   |   React     |            |   Backend   |
|  Game       | <---------------- |   App       | <--------- |   (Hono)    |
|             |    postMessage    |             |    JSON    |             |
+-------------+                   +-------------+            +-------------+
                                        |
                                        | Tauri API
                                        v
                                  +-------------+
                                  |   Local     |
                                  |   Files     |
                                  |   (fs)      |
                                  +-------------+
```

## Project Structure

```
logictales/
|-- apps/
|   |-- backend/          # Hono API server + Google ADK agents
|   |   |-- src/
|   |   |   |-- agents/   # AI agents (storyteller, researcher, critic)
|   |   |   |-- routes/   # API endpoints
|   |   |   +-- index.ts  # Server entry
|   |   +-- package.json
|   |
|   |-- game/             # Love2D game (Lua)
|   |   |-- main.lua      # Entry point
|   |   |-- editor.lua    # Story editor (native only)
|   |   |-- bridge.lua    # React communication
|   |   |-- screens/      # Game screens
|   |   |-- components/   # UI components
|   |   +-- stories/      # Story files
|   |
|   +-- app/              # React + Tauri desktop shell
|       |-- src/
|       |   |-- components/
|       |   |   +-- GameRunner.tsx
|       |   +-- App.tsx
|       |-- public/
|       |   +-- game/     # Love.js output (generated)
|       +-- src-tauri/    # Tauri config (Rust)
|
|-- tools/
|   +-- love-builder/     # Love.js build pipeline
|
|-- openspec/             # Change specifications
+-- package.json          # Root scripts
```

## Dependencies

### System Requirements

| Dependency | Version | Purpose |
|------------|---------|---------|
| Node.js    | >= 18   | Runtime |
| pnpm       | latest  | Package manager |
| Love2D     | 11.4+   | Native game development |
| Rust       | latest  | Tauri builds |

### Install

```bash
# Install pnpm if needed
npm install -g pnpm

# Install project dependencies
pnpm install
```

## Running

### Quick Start

```bash
# Run backend + React app
pnpm dev
```

### All Modes

| Command | What it does |
|---------|--------------|
| `pnpm dev` | Backend + React app (parallel) |
| `pnpm dev:backend` | Hono API only (port 3000) |
| `pnpm dev:game` | Native Love2D with editor |
| `pnpm dev:tauri` | Desktop app (Tauri + Vite) |
| `pnpm build:game` | Compile Lua to WASM |
| `pnpm build:app` | Build distributable |

### Mode Comparison

```
+------------------+------------------+------------------+
|  Native Love2D   |    Web/Tauri     |     Backend      |
+------------------+------------------+------------------+
|  pnpm dev:game   |  pnpm dev:tauri  |  pnpm dev:backend|
+------------------+------------------+------------------+
|  Full editor     |  Play only       |  API server      |
|  LuaJIT          |  WASM            |  Google ADK      |
|  Slab UI         |  No Slab         |  Image gen       |
|  Fast iteration  |  Desktop app     |  Story gen       |
+------------------+------------------+------------------+
```

## Development Workflow

```
1. Edit story content:
   +-- love apps/game  (native, has editor)

2. Test web build:
   +-- pnpm build:game
   +-- pnpm dev:tauri

3. Test with AI features:
   +-- pnpm dev  (runs backend + app)
```

## Tech Stack

```
Frontend:        Backend:         Desktop:         Game:
+-----------+    +-----------+    +-----------+    +-----------+
| React     |    | Hono      |    | Tauri v2  |    | Love2D    |
| Vite      |    | Google    |    | Rust      |    | Lua       |
| TypeScript|    | ADK       |    | WebView   |    | Love.js   |
+-----------+    +-----------+    +-----------+    +-----------+
```

## Web Mode Limitations

The web (Love.js) version runs in **play mode only**:

- No story editor (Slab UI requires LuaJIT)
- Stories must be pre-loaded
- 512MB memory cap

For story editing, use native Love2D: `pnpm dev:game`

## License

MIT
