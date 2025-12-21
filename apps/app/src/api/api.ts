// API layer for LogicTales app
// Handles communication with backend and Tauri filesystem

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:3001'

/**
 * Generate an image using the AI backend
 */
export async function generateImage(
  description: string,
  question: string
): Promise<{ imageUrl: string }> {
  const response = await fetch(`${BACKEND_URL}/api/generate-image`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ description, question }),
  })

  if (!response.ok) {
    throw new Error(`Failed to generate image: ${response.statusText}`)
  }

  return response.json()
}

/**
 * Save a story to local storage
 * Uses Tauri FS API when available, falls back to localStorage
 */
export async function saveStory(filename: string, data: string): Promise<void> {
  // Check if running in Tauri (Tauri v2 plugin-fs)
  if ('__TAURI__' in window) {
    try {
      const { writeTextFile, BaseDirectory } = await import('@tauri-apps/plugin-fs')
      await writeTextFile(`stories/${filename}`, data, { baseDir: BaseDirectory.AppData })
    } catch {
      // Plugin not available, fall back to localStorage
      const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
      stories[filename] = data
      localStorage.setItem('logictales_stories', JSON.stringify(stories))
    }
  } else {
    // Fallback to localStorage for web development
    const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
    stories[filename] = data
    localStorage.setItem('logictales_stories', JSON.stringify(stories))
  }
}

/**
 * Load a story from local storage
 * Uses Tauri FS API when available, falls back to localStorage
 */
export async function loadStory(filename: string): Promise<string> {
  // Check if running in Tauri (Tauri v2 plugin-fs)
  if ('__TAURI__' in window) {
    try {
      const { readTextFile, BaseDirectory } = await import('@tauri-apps/plugin-fs')
      return await readTextFile(`stories/${filename}`, { baseDir: BaseDirectory.AppData })
    } catch {
      // Plugin not available, fall back to localStorage
      const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
      const story = stories[filename]
      if (!story) {
        throw new Error(`Story not found: ${filename}`)
      }
      return story
    }
  } else {
    // Fallback to localStorage for web development
    const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
    const story = stories[filename]
    if (!story) {
      throw new Error(`Story not found: ${filename}`)
    }
    return story
  }
}

/**
 * List all saved stories
 * Uses Tauri FS API when available, falls back to localStorage
 */
export async function listStories(): Promise<string[]> {
  // Check if running in Tauri (Tauri v2 plugin-fs)
  if ('__TAURI__' in window) {
    try {
      const { readDir, BaseDirectory } = await import('@tauri-apps/plugin-fs')
      const entries = await readDir('stories', { baseDir: BaseDirectory.AppData })
      return entries
        .filter((entry) => entry.name?.endsWith('.json'))
        .map((entry) => entry.name!)
    } catch {
      // Plugin not available or directory doesn't exist yet
      const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
      return Object.keys(stories)
    }
  } else {
    // Fallback to localStorage for web development
    const stories = JSON.parse(localStorage.getItem('logictales_stories') || '{}')
    return Object.keys(stories)
  }
}
