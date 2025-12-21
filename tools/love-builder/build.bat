@echo off
REM Love.js Build Pipeline for Windows
REM Runs the cross-platform Node.js build script

cd /d "%~dp0"

REM Install dependencies if needed
if not exist "node_modules" (
    echo Installing dependencies...
    call pnpm install
)

REM Run the build
node build.js
