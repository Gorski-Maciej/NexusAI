@echo off
REM ============================================================================
REM  build_exe.bat — Build NexusAI Windows Installer
REM ============================================================================
REM  This script automates the complete build pipeline:
REM    1. Install Python dependencies
REM    2. Run PyInstaller to create a single .exe bundle
REM    3. Run NSIS to create the final NexusAI_Setup.exe
REM
REM  Prerequisites:
REM    - Python 3.11+ installed and on PATH
REM    - NSIS 3+ installed at default location, OR set NSIS_PATH
REM    - Optional: UPX compressor (for smaller executables)
REM
REM  Usage:
REM    build_exe.bat                    # Full build
REM    build_exe.bat --skip-install     # Skip dependency installation
REM    build_exe.bat --pyinstaller-only # Only create the .exe, skip NSIS
REM    build_exe.bat --clean           # Clean build artifacts first
REM    build_exe.bat --help            # Show help
REM ============================================================================

setlocal enabledelayedexpansion

REM ── Configuration ──────────────────────────────────────────────────────────
set "PROJECT_ROOT=%~dp0.."
set "BUILD_DIR=%PROJECT_ROOT%\build"
set "DIST_DIR=%PROJECT_ROOT%\dist"
set "EXE_NAME=NexusAI"
set "SETUP_NAME=NexusAI_Setup"
set "NSIS_PATH=C:\Program Files (x86)\NSIS\makensis.exe"

REM ── Parse arguments ────────────────────────────────────────────────────────
set "SKIP_INSTALL="
set "PYINSTALLER_ONLY="
set "CLEAN_BUILD="
set "SHOW_HELP="

:parse_args
if "%~1"=="" goto :done_parse
if /I "%~1"=="--skip-install" set "SKIP_INSTALL=1"
if /I "%~1"=="--pyinstaller-only" set "PYINSTALLER_ONLY=1"
if /I "%~1"=="--clean" set "CLEAN_BUILD=1"
if /I "%~1"=="--help" set "SHOW_HELP=1"
shift
goto :parse_args
:done_parse

if defined SHOW_HELP (
    echo Usage: build_exe.bat [options]
    echo.
    echo Options:
    echo   --skip-install     Skip pip install of dependencies
    echo   --pyinstaller-only Create only the .exe bundle, skip NSIS
    echo   --clean            Clean build artifacts first
    echo   --help             Show this help
    exit /b 0
)

echo.
echo ===========================================================================
echo         NexusAI -- Windows Build Script
echo ===========================================================================
echo.
echo Project root: %PROJECT_ROOT%
echo.

REM ── Step 0: Clean build artifacts ─────────────────────────────────────────
if defined CLEAN_BUILD (
    echo [0/5] Cleaning build artifacts...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
    if exist "%DIST_DIR%\NexusAI" rmdir /s /q "%DIST_DIR%\NexusAI"
    if exist "%DIST_DIR%\%EXE_NAME%.exe" del "%DIST_DIR%\%EXE_NAME%.exe"
    if exist "%DIST_DIR%\%EXE_NAME%_CLI.exe" del "%DIST_DIR%\%EXE_NAME%_CLI.exe"
    if exist "%DIST_DIR%\*.exe" del "%DIST_DIR%\*.exe"
    echo   Done.
    echo.
)

REM ── Step 1: Install dependencies (prefer uv, fallback to pip) ──────────
if not defined SKIP_INSTALL (
    echo [1/5] Installing Python dependencies...
    cd /d "%PROJECT_ROOT%"

    where /q uv 2>nul
    if not errorlevel 1 (
        echo   Using uv (Astral) — 10-100x faster than pip...
        uv pip install --system pyinstaller
        if errorlevel 1 (
            echo   [WARN] uv pip install failed, trying uv tool install...
            uv tool install pyinstaller
        )
        uv pip install --system -e ".[ai,ui]"
        if errorlevel 1 (
            echo   [WARN] Some optional deps failed, installing core only...
            uv pip install --system -e "."
        )
    ) else (
        echo   uv not found, falling back to pip...
        echo   ★ Install uv for faster builds: curl -LsSf https://astral.sh/uv/install.sh ^| sh
        python -m pip install --upgrade pip >nul 2>&1
        python -m pip install pyinstaller >nul 2>&1
        if errorlevel 1 (
            echo   [WARN] pip install failed, trying --user...
            python -m pip install --user pyinstaller
        )
        python -m pip install -e ".[ai,ui]" >nul 2>&1
        if errorlevel 1 (
            echo   [WARN] Some optional deps failed (torch/transformers may be large)
            echo   Installing core deps only...
            python -m pip install -e "." >nul 2>&1
        )
    )

    echo   Done.
    echo.
) else (
    echo [1/5] Skipping dependency installation (--skip-install).
    echo.
)

REM ── Step 2: Generate assets (icons, logos) ────────────────────────────────
echo [2/5] Generating application assets...
if not exist "%PROJECT_ROOT%\assets" mkdir "%PROJECT_ROOT%\assets"

cd /d "%PROJECT_ROOT%"
python tools\generate_assets.py 2>&1
if errorlevel 1 (
    echo   [WARN] Asset generation had issues, continuing with any existing assets...
)
if exist "%PROJECT_ROOT%\assets\nexus.ico" (
    echo   ✓ Application icons ready (nexus.ico)
) else (
    echo   [WARN] nexus.ico not found — PyInstaller will use default icon
)
echo   Done.
echo.

REM ── Step 3: Ensure directories ────────────────────────────────────────────
echo [3/5] Ensuring directories...
if not exist "%PROJECT_ROOT%\models" mkdir "%PROJECT_ROOT%\models"
echo   Done.
echo.

REM ── Step 4: Run PyInstaller ───────────────────────────────────────────────
echo [4/5] Running PyInstaller (this may take several minutes)...
echo   Bundling application into single .exe...

cd /d "%PROJECT_ROOT%"
pyinstaller --clean build_scripts\nexusai.spec 2>&1
if errorlevel 1 (
    echo   [ERROR] PyInstaller build failed!
    echo   Check the output above for details.
    exit /b 1
)
echo   Done. Output: %DIST_DIR%\%EXE_NAME%\
echo.

REM ── Step 4b: Create runtime directories in dist ───────────────────────────
echo [4b/5] Creating runtime directory structure...
if not exist "%DIST_DIR%\%EXE_NAME%\app_data" mkdir "%DIST_DIR%\%EXE_NAME%\app_data"
if not exist "%DIST_DIR%\%EXE_NAME%\app_data\uploads" mkdir "%DIST_DIR%\%EXE_NAME%\app_data\uploads"
if not exist "%DIST_DIR%\%EXE_NAME%\logs" mkdir "%DIST_DIR%\%EXE_NAME%\logs"
echo   Done.
echo.

REM ── Step 5: Run NSIS ──────────────────────────────────────────────────────
if not defined PYINSTALLER_ONLY (
    echo [5/5] Creating Windows Installer with NSIS...

    if exist "%NSIS_PATH%" (
        "%NSIS_PATH%" build_scripts\setup.nsi
        if errorlevel 1 (
            echo   [ERROR] NSIS compilation failed.
            echo   Check build_scripts\setup.nsi for errors.
            exit /b 1
        )
        echo   Done. Installer: %DIST_DIR%\%SETUP_NAME%.exe
    ) else (
        echo   [WARN] NSIS not found at: %NSIS_PATH%
        echo.
        echo   To create the installer manually:
        echo   1. Install NSIS from: https://nsis.sourceforge.io/Download
        echo   2. Right-click build_scripts\setup.nsi -> "Compile NSIS Script"
        echo.
        echo   The .exe bundle is still available at: %DIST_DIR%\%EXE_NAME%\
    )
) else (
    echo [5/5] Skipping NSIS (--pyinstaller-only).
)
echo.

echo ===========================================================================
echo                         Build Complete!
echo ===========================================================================
echo.
echo Output:
if not defined PYINSTALLER_ONLY (
    if exist "%DIST_DIR%\%SETUP_NAME%*.exe" (
        dir /b "%DIST_DIR%\%SETUP_NAME%*.exe" 2>nul
    )
)
echo   Bundle    : %DIST_DIR%\%EXE_NAME%\
echo   Executable: %DIST_DIR%\%EXE_NAME%\%EXE_NAME%.exe
echo.

endlocal
