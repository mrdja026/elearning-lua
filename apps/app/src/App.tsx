import { useCallback } from 'react'
import { GameRunner } from './components/GameRunner'
import { useGameBridge } from './hooks/useGameBridge'

function App() {
  const { sendToGame, handleGameMessage, isReady } = useGameBridge()

  const onGameReady = useCallback(() => {
    console.log('[App] Game is ready')
  }, [])

  const onGameMessage = useCallback((message: unknown) => {
    handleGameMessage(message)
  }, [handleGameMessage])

  return (
    <div style={{ width: '100vw', height: '100vh' }}>
      <GameRunner
        gamePath="/game/index.html"
        onGameReady={onGameReady}
        onGameMessage={onGameMessage}
        sendToGame={sendToGame}
      />
    </div>
  )
}

export default App
