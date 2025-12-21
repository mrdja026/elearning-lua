#!/usr/bin/env node

/**
 * Love.js Build Pipeline
 *
 * This script:
 * 1. Creates a game.love archive from apps/game/
 * 2. Runs love.js to compile to WASM
 * 3. Outputs to apps/app/public/game/
 */

import { execSync } from 'child_process'
import { createWriteStream, mkdirSync, existsSync, rmSync, cpSync, writeFileSync, readFileSync } from 'fs'
import { join, dirname } from 'path'
import { fileURLToPath } from 'url'
import archiver from 'archiver'

const __filename = fileURLToPath(import.meta.url)
const __dirname = dirname(__filename)

const ROOT_DIR = join(__dirname, '..', '..')
const GAME_DIR = join(ROOT_DIR, 'apps', 'game')
const OUTPUT_DIR = join(ROOT_DIR, 'apps', 'app', 'public', 'game')
const TEMP_DIR = join(__dirname, 'temp')
const LOVE_FILE = join(TEMP_DIR, 'game.love')
const INDEX_TEMPLATE = join(__dirname, 'index.html.template')

async function build() {
  console.log('[love-builder] Starting build...')

  // Clean temp and output directories
  if (existsSync(TEMP_DIR)) {
    rmSync(TEMP_DIR, { recursive: true })
  }
  mkdirSync(TEMP_DIR, { recursive: true })

  if (existsSync(OUTPUT_DIR)) {
    rmSync(OUTPUT_DIR, { recursive: true })
  }
  mkdirSync(OUTPUT_DIR, { recursive: true })

  // Create game.love archive
  console.log('[love-builder] Creating game.love archive...')
  await createLoveArchive()

  // Run love.js
  console.log('[love-builder] Compiling with love.js...')
  try {
    // Use node to run love.js directly (avoids Windows .js file association issues)
    const lovejsPath = join(__dirname, 'node_modules', 'love.js', 'index.js')
    execSync(`node "${lovejsPath}" "${LOVE_FILE}" "${OUTPUT_DIR}" -t LogicTales -m 536870912`, {
      stdio: 'inherit',
      cwd: TEMP_DIR,
    })

    // Skip custom template for now - use love.js default
    // if (existsSync(INDEX_TEMPLATE)) {
    //   console.log('[love-builder] Applying custom index.html template...')
    //   const template = readFileSync(INDEX_TEMPLATE, 'utf-8')
    //   writeFileSync(join(OUTPUT_DIR, 'index.html'), template)
    // }
  } catch (error) {
    console.error('[love-builder] love.js compilation failed:', error)
    console.log('[love-builder] Falling back to placeholder...')
    createPlaceholder()
  }

  // Cleanup
  rmSync(TEMP_DIR, { recursive: true })

  console.log('[love-builder] Build complete!')
}

function createLoveArchive() {
  return new Promise((resolve, reject) => {
    const output = createWriteStream(LOVE_FILE)
    const archive = archiver('zip', { zlib: { level: 9 } })

    output.on('close', () => {
      console.log(`[love-builder] Created game.love (${archive.pointer()} bytes)`)
      resolve()
    })

    archive.on('error', (err) => reject(err))

    archive.pipe(output)

    // Add all game files
    archive.directory(GAME_DIR, false)

    archive.finalize()
  })
}

function createPlaceholder() {
  // Create a placeholder index.html when love.js isn't available
  const html = `<!DOCTYPE html>
<html>
<head>
  <title>LogicTales</title>
  <style>
    body {
      margin: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      background: #1a1a2e;
      color: white;
      font-family: sans-serif;
    }
  </style>
</head>
<body>
  <div>
    <h1>LogicTales</h1>
    <p>Love.js build required. Run: npx love.js</p>
  </div>
</body>
</html>`

  writeFileSync(join(OUTPUT_DIR, 'index.html'), html)
}

build().catch((err) => {
  console.error('[love-builder] Build failed:', err)
  process.exit(1)
})
