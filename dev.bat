@echo off
echo Starting LogicTales in DEV MODE (no API credits used)
echo.

:: Get the script directory without trailing backslash
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

:: Start backend in dev mode (separate window)
echo Starting backend server...
start "LogicTales Backend" cmd /k "cd /d %PROJECT_DIR%\backend && set DEV_MODE=true && npm run dev"

:: Wait a moment for backend to start
timeout /t 2 /nobreak >nul

:: Start Love2D game
echo Starting Love2D game...
start "" love %PROJECT_DIR%

echo.
echo Both services started!
echo - Backend: http://localhost:3000 (DEV_MODE=true)
echo - Game: Love2D window
echo.
echo Press any key to close this window...
pause >nul
