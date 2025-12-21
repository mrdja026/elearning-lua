import { useState, useCallback, useRef } from 'react'
import { generateImage, saveStory, loadStory, listStories } from '../api/api'

interface PendingRequest {
  resolve: (value: unknown) => void
  reject: (reason: unknown) => void
}

type GameMessageType =
  | 'GENERATE_IMAGE'
  | 'SAVE_STORY'
  | 'LOAD_STORY'
  | 'LIST_STORIES'
  | 'GAME_READY'

interface GameMessage {
  type: GameMessageType
  requestId: string
  payload?: unknown
}

interface ImageGenerationPayload {
  description: string
  question: string
}

interface SaveStoryPayload {
  filename: string
  data: string
}

interface LoadStoryPayload {
  filename: string
}

export function useGameBridge() {
  const [isReady, setIsReady] = useState(false)
  const pendingRequests = useRef<Map<string, PendingRequest>>(new Map())

  const sendToGame = useCallback((message: unknown) => {
    const sendMessage = (window as unknown as { sendToGame?: (msg: unknown) => void }).sendToGame
    if (sendMessage) {
      sendMessage(message)
    }
  }, [])

  const handleGameMessage = useCallback(async (message: unknown) => {
    const msg = message as GameMessage
    if (!msg || typeof msg !== 'object' || !('type' in msg)) {
      console.warn('[useGameBridge] Invalid message format:', message)
      return
    }

    const { type, requestId, payload } = msg

    try {
      let result: unknown

      switch (type) {
        case 'GAME_READY':
          setIsReady(true)
          return

        case 'GENERATE_IMAGE': {
          const imgPayload = payload as ImageGenerationPayload
          result = await generateImage(imgPayload.description, imgPayload.question)
          break
        }

        case 'SAVE_STORY': {
          const savePayload = payload as SaveStoryPayload
          result = await saveStory(savePayload.filename, savePayload.data)
          break
        }

        case 'LOAD_STORY': {
          const loadPayload = payload as LoadStoryPayload
          result = await loadStory(loadPayload.filename)
          break
        }

        case 'LIST_STORIES': {
          result = await listStories()
          break
        }

        default:
          console.warn('[useGameBridge] Unknown message type:', type)
          return
      }

      // Send response back to game
      sendToGame({
        type: `${type}_RESPONSE`,
        requestId,
        success: true,
        payload: result,
      })
    } catch (error) {
      console.error('[useGameBridge] Error handling message:', error)
      sendToGame({
        type: `${type}_RESPONSE`,
        requestId,
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
      })
    }
  }, [sendToGame])

  return {
    isReady,
    sendToGame,
    handleGameMessage,
    pendingRequests: pendingRequests.current,
  }
}
