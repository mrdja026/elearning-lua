import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true, // Fail if port busy (Tauri expects exactly 5173)
    headers: {
      // Required for SharedArrayBuffer (Love.js WASM threading)
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
  build: {
    outDir: 'dist',
    emptyOutDir: true,
  },
  // Required for Tauri
  clearScreen: false,
  envPrefix: ['VITE_', 'TAURI_'],
})
