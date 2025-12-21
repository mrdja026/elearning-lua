@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   LogicTales - PRODUCTION MODE
echo   (Real API calls - credits will be used!)
echo ============================================
echo.

:: Get the script directory without trailing backslash
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"
set "ENV_FILE=%PROJECT_DIR%\backend\.env"

:: Check if .env file exists
if not exist "%ENV_FILE%" (
    echo [ERROR] .env file not found at: %ENV_FILE%
    echo Please copy .env.example to .env and fill in your API keys.
    goto :error
)

:: Read and check required API keys from .env file
set "MISSING_KEYS="
set "GEMINI_OK=0"
set "STABILITY_OK=0"
set "CLOUDINARY_NAME_OK=0"
set "CLOUDINARY_KEY_OK=0"
set "CLOUDINARY_SECRET_OK=0"

:: Parse .env file
for /f "usebackq tokens=1,* delims==" %%a in ("%ENV_FILE%") do (
    set "key=%%a"
    set "value=%%b"

    :: Skip comments and empty lines
    if "!key:~0,1!" neq "#" (
        if "!key!"=="GEMINI_API_KEY" if defined value if "!value!" neq "" set "GEMINI_OK=1"
        if "!key!"=="STABILITY_API_KEY" if defined value if "!value!" neq "" set "STABILITY_OK=1"
        if "!key!"=="CLOUDINARY_CLOUD_NAME" if defined value if "!value!" neq "" set "CLOUDINARY_NAME_OK=1"
        if "!key!"=="CLOUDINARY_API_KEY" if defined value if "!value!" neq "" set "CLOUDINARY_KEY_OK=1"
        if "!key!"=="CLOUDINARY_API_SECRET" if defined value if "!value!" neq "" set "CLOUDINARY_SECRET_OK=1"
    )
)

:: Check which keys are missing
set "HAS_ERRORS=0"

if "!GEMINI_OK!"=="0" (
    echo [MISSING] GEMINI_API_KEY
    set "HAS_ERRORS=1"
)
if "!STABILITY_OK!"=="0" (
    echo [MISSING] STABILITY_API_KEY
    set "HAS_ERRORS=1"
)
if "!CLOUDINARY_NAME_OK!"=="0" (
    echo [MISSING] CLOUDINARY_CLOUD_NAME
    set "HAS_ERRORS=1"
)
if "!CLOUDINARY_KEY_OK!"=="0" (
    echo [MISSING] CLOUDINARY_API_KEY
    set "HAS_ERRORS=1"
)
if "!CLOUDINARY_SECRET_OK!"=="0" (
    echo [MISSING] CLOUDINARY_API_SECRET
    set "HAS_ERRORS=1"
)

if "!HAS_ERRORS!"=="1" (
    echo.
    echo [ERROR] Missing required API keys in .env file!
    echo Please add the missing keys before running in production mode.
    goto :error
)

echo [OK] All required API keys found!
echo.
echo WARNING: This will use REAL API credits:
echo   - Gemini API (prompt generation)
echo   - Stability AI (image generation)
echo   - Cloudinary (image upload)
echo.

:: Confirmation prompt
set /p "CONFIRM=Are you sure you want to continue? (y/N): "
if /i not "!CONFIRM!"=="y" (
    echo Cancelled.
    goto :end
)

echo.
echo Starting services in PRODUCTION mode...
echo.

:: Start backend in production mode (DEV_MODE=false)
echo Starting backend server (DEV_MODE=false)...
start "LogicTales Backend [PROD]" cmd /k "cd /d %PROJECT_DIR%\backend && set DEV_MODE=false && npm run dev"

:: Wait a moment for backend to start
timeout /t 3 /nobreak >nul

:: Start Love2D game
echo Starting Love2D game...
start "" love %PROJECT_DIR%

echo.
echo ============================================
echo   Both services started in PRODUCTION mode!
echo   - Backend: http://localhost:3000 (LIVE)
echo   - Game: Love2D window
echo ============================================
echo.

goto :end

:error
echo.
echo Press any key to exit...
pause >nul
exit /b 1

:end
echo Press any key to close this window...
pause >nul
