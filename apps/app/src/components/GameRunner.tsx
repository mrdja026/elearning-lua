import { useEffect, useRef, useCallback } from 'react'

interface GameRunnerProps {
  gamePath: string
  onGameReady?: () => void
  onGameMessage?: (message: unknown) => void
  sendToGame?: (message: unknown) => void
}

export function GameRunner({
  gamePath,
  onGameReady,
  onGameMessage,
}: GameRunnerProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null)

  // Handle messages from game iframe
  const handleMessage = useCallback((event: MessageEvent) => {
    // Only accept messages from our iframe
    if (iframeRef.current && event.source === iframeRef.current.contentWindow) {
      if (event.data?.type === 'GAME_READY') {
        onGameReady?.()
      } else {
        onGameMessage?.(event.data)
      }
    }
  }, [onGameReady, onGameMessage])

  useEffect(() => {
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleMessage])

  // Expose sendToGame function
  const sendMessage = useCallback((message: unknown) => {
    iframeRef.current?.contentWindow?.postMessage(message, '*')
  }, [])

  // Store sendMessage on window for external access if needed
  useEffect(() => {
    (window as unknown as { sendToGame: typeof sendMessage }).sendToGame = sendMessage
  }, [sendMessage])

  return (
    <iframe
      ref={iframeRef}
      src={gamePath}
      style={{
        width: '100%',
        height: '100%',
        border: 'none',
      }}
      title="LogicTales Game"
      allow="autoplay"
    />
  )
}
