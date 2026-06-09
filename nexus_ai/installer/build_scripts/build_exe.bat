@echo off
REM ============================================================================
REM  build_exe.bat — Build NexusAI Windows Installer (Nuitka)
REM ============================================================================
REM  This script automates the complete build pipeline using Nuitka:
REM    1. Install Python dependencies
REM    2. Run Nuitka to create a single .exe file (z mimalloc)
REM    3. Run Inno Setup to create the final NexusAI_Setup.exe
REM
REM  Zgodnie z aa3fvcx.txt:
REM    - Nuitka kompiluje Python → C → pojedynczy .exe
REM    - mimalloc statycznie wkompilowany (5-15% mniej RAM)
REM    - Wszystkie zależności w jednym pliku
REM
REM  Prerequisites:
REM    - Python 3.13+ installed and on PATH
REM    - Nuitka (pip install nuitka)
REM    - Inno Setup 6+ (for installer, optional)
REM    - Visual Studio Build Tools (Windows) lub GCC (Linux/Mac)
REM
REM  Usage:
REM    build_exe.bat                    # Full build
REM    build_exe.bat --skip-install     # Skip dependency installation
REM    build_exe.bat --nuitka-only      # Only create the .exe, skip Inno Setup
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
set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

REM ── Parse arguments ────────────────────────────────────────────────────────
set "SKIP_INSTALL="
set "NUITKA_ONLY="
set "CLEAN_BUILD="
set "SHOW_HELP="

:parse_args
if "%~1"=="" goto :done_parse
if /I "%~1"=="--skip-install" set "SKIP_INSTALL=1"
if /I "%~1"=="--nuitka-only" set "NUITKA_ONLY=1"
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
    echo   --nuitka-only      Create only the .exe, skip Inno Setup
    echo   --clean            Clean build artifacts first
    echo   --help             Show this help
    exit /b 0
)

echo.
echo ===========================================================================
echo         NexusAI -- Windows Nuitka Build Script
echo ===========================================================================
echo.
echo Project root: %PROJECT_ROOT%
echo.

REM ── Step 0: Clean build artifacts ─────────────────────────────────────────
if defined CLEAN_BUILD (
    echo [0/5] Cleaning build artifacts...
    if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
    if exist "%DIST_DIR%\*.exe" del "%DIST_DIR%\*.exe"
    if exist "%DIST_DIR%\*.build" rmdir /s /q "%DIST_DIR%\*.build"
    if exist "%DIST_DIR%\*.dist" rmdir /s /q "%DIST_DIR%\*.dist"
    if exist "%PROJECT_ROOT%\*.build" rmdir /s /q "%PROJECT_ROOT%\*.build"
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
        uv pip install --system nuitka
        if errorlevel 1 (
            echo   [WARN] uv pip install failed, trying pip...
            python -m pip install nuitka
        )
        uv pip install --system -e ".[ui]"
        if errorlevel 1 (
            echo   [WARN] Some optional deps failed, installing core only...
            uv pip install --system -e "."
        )
    ) else (
        echo   uv not found, falling back to pip...
        python -m pip install --upgrade pip >nul 2>&1
        python -m pip install nuitka >nul 2>&1
        python -m pip install -e "." >nul 2>&1
    )

    echo   Done.
    echo.
) else (
    echo [1/5] Skipping dependency installation (--skip-install).
    echo.
)

REM ── Step 2: Ensure directories ────────────────────────────────────────────
echo [2/5] Ensuring directories...
if not exist "%PROJECT_ROOT%\models" mkdir "%PROJECT_ROOT%\models"
if not exist "%PROJECT_ROOT%\app_data\databases" mkdir "%PROJECT_ROOT%\app_data\databases"
echo   Done.
echo.

REM ── Step 3: Build Rust module (nexus-crypto) ──────────────────────────────
echo [3/5] Building Rust native module (nexus-crypto)...
cd /d "%PROJECT_ROOT%\nexus_ai\rust"
python -m maturin develop --release 2>&1
if errorlevel 1 (
    echo   [WARN] Rust build failed — check if Rust is installed
    echo   Continuing with Python fallback...
)
cd /d "%PROJECT_ROOT%"
echo   Done.
echo.

REM ── Step 4: Run Nuitka ────────────────────────────────────────────────────
echo [4/5] Running Nuitka (this may take 10-30 minutes)...
echo   Compiling Python → C → single .exe with mimalloc...

echo.
echo   Using pyproject.toml Nuitka configuration for onefile build.
echo   To see full config, check [tool.nuitka] section in pyproject.toml.
echo.

cd /d "%PROJECT_ROOT%"
python -m nuitka ^
    --project-name=nexus-ai ^
    --output-dir="%DIST_DIR%" ^
    --output-name="%EXE_NAME%" ^
    main.py

if errorlevel 1 (
    echo   [ERROR] Nuitka build failed!
    echo   Check the output above for details.
    echo.
    echo   Common issues:
    echo   - Visual Studio Build Tools not installed (Windows)
    echo   - Missing C compiler (install MSVC or MinGW)
    echo   - Out of memory during compilation
    exit /b 1
)
echo.
echo   Done. Executable: %DIST_DIR%\%EXE_NAME%.exe
echo.

REM ── Step 5: Run Inno Setup ────────────────────────────────────────────────
if not defined NUITKA_ONLY (
    echo [5/5] Creating Windows Installer with Inno Setup...

    if exist "%INNO_PATH%" (
        "%INNO_PATH%" build_scripts\setup.iss
        if errorlevel 1 (
            echo   [ERROR] Inno Setup compilation failed.
            echo   Check build_scripts\setup.iss for errors.
            exit /b 1
        )
        echo   Done. Installer: %DIST_DIR%\%SETUP_NAME%.exe
    ) else (
        echo   [WARN] Inno Setup not found at: %INNO_PATH%
        echo.
        echo   To create the installer manually:
        echo   1. Install Inno Setup from: https://jrsoftware.org/isdl.php
        echo   2. Right-click build_scripts\setup.iss -> "Compile"
        echo.
        echo   The .exe is still available at: %DIST_DIR%\%EXE_NAME%.exe
    )
) else (
    echo [5/5] Skipping Inno Setup (--nuitka-only).
)
echo.

echo ===========================================================================
echo                         Build Complete!
echo ===========================================================================
echo.
echo Output:
echo   Executable: %DIST_DIR%\%EXE_NAME%.exe
if not defined NUITKA_ONLY (
    if exist "%DIST_DIR%\%SETUP_NAME%.exe" (
        echo   Installer : %DIST_DIR%\%SETUP_NAME%.exe
    )
)
echo.
echo Size:
if exist "%DIST_DIR%\%EXE_NAME%.exe" (
    for %%I in ("%DIST_DIR%\%EXE_NAME%.exe") do echo   %%I: %%~zI bytes
)
echo.

echo   Pamiętaj: Modele AI (~6.9 GB) są pobierane przy pierwszym uruchomieniu.
echo.

endlocal
