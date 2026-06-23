#!/usr/bin/env bash
# ==============================================================================
#  build_exe.sh — Build NexusAI Single-File Binary (Linux/macOS)
# ==============================================================================
#  This script compiles NexusAI into a single-file executable using Nuitka.
#  Zgodnie z aa3fvcx.txt:
#    - Nuitka kompiluje Python → C → pojedynczy plik binarny
#    - mimalloc statycznie wkompilowany (5-15% mniej RAM)
#    - Wszystkie zależności w jednym pliku
#
#  Usage:
#    ./build_scripts/build_exe.sh                    # Full build
#    ./build_scripts/build_exe.sh --skip-install     # Skip dependency install
#    ./build_scripts/build_exe.sh --nuitka-only      # Only create the .exe
#    ./build_scripts/build_exe.sh --clean            # Clean artifacts first
#    ./build_scripts/build_exe.sh --help             # Show help
#
#  Prerequisites:
#    - Python 3.13+ with pip
#    - Nuitka (installed automatically if missing)
#    - C compiler (GCC on Linux, Xcode CLT on macOS)
#
# ==============================================================================

set -euo pipefail

# ── Python version check ──────────────────────────────────────────────────
# Projekt wymaga Python >= 3.13 (free-threaded 3.13t preferred)
PYTHON=$(command -v python3 || command -v python)
if [ -z "$PYTHON" ]; then
    echo "[ERROR] Python not found! Install Python 3.13+ first."
    echo "  Recommended: https://www.python.org/downloads/"
    exit 1
fi

PY_MAJOR=$("$PYTHON" -c 'import sys; print(sys.version_info.major)')
PY_MINOR=$("$PYTHON" -c 'import sys; print(sys.version_info.minor)')

if [ "$PY_MAJOR" -lt 3 ] || [ "$PY_MINOR" -lt 13 ]; then
    echo "[ERROR] Python 3.13+ required, found: $PY_MAJOR.$PY_MINOR"
    echo "  Current: $("$PYTHON" --version)"
    echo "  Install Python 3.13+: https://www.python.org/downloads/"
    exit 1
fi
echo "  Python: $("$PYTHON" --version)"
echo ""

# ── Configuration ──────────────────────────────────────────────────────────
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
EXE_NAME="NexusAI"

# ── Parse arguments ────────────────────────────────────────────────────────
SKIP_INSTALL=false
NUITKA_ONLY=false
CLEAN_BUILD=false
USE_CLANG=false
USE_ZIG=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-install) SKIP_INSTALL=true; shift ;;
        --nuitka-only)  NUITKA_ONLY=true; shift ;;
        --clean)        CLEAN_BUILD=true; shift ;;
        --use-clang)    USE_CLANG=true; shift ;;
        --use-zig)      USE_ZIG=true; shift ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --skip-install     Skip pip install of dependencies"
            echo "  --nuitka-only      Create only the binary, skip packaging"
            echo "  --clean            Clean build artifacts first"
            echo "  --use-clang        Use Clang instead of GCC (smaller binary, better diagnostics)"
            echo "  --use-zig          Use Zig as linker (faster linking, cross-compilation ready)"
            echo "  --help             Show this help"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "=============================================================================="
echo "        NexusAI -- Nuitka Build Script (Linux/macOS)"
echo "=============================================================================="
echo ""
echo "Project root: $PROJECT_ROOT"
echo ""

# ── Step 0: Clean build artifacts ──────────────────────────────────────────
if $CLEAN_BUILD; then
    echo "[0/5] Cleaning build artifacts..."
    rm -rf "$BUILD_DIR"
    rm -f "$DIST_DIR/$EXE_NAME" "$DIST_DIR/$EXE_NAME.bin"
    rm -rf "$DIST_DIR"/*.build "$DIST_DIR"/*.dist
    rm -rf "$PROJECT_ROOT"/*.build
    echo "  Done."
    echo ""
fi

# ── Step 1: Install dependencies ──────────────────────────────────────────
if ! $SKIP_INSTALL; then
    echo "[1/5] Installing Python dependencies..."

    # pixi zarządza środowiskiem
    # Używamy pip (dostępny w środowisku pixi)
    echo "  Using pip (via pixi environment)..."
    "$PYTHON" -m pip install --upgrade pip
    "$PYTHON" -m pip install nuitka
    "$PYTHON" -m pip install -e "."

    echo "  Done."
    echo ""
else
    echo "[1/5] Skipping dependency installation (--skip-install)."
    echo ""
fi

# ── Step 2: Ensure directories ─────────────────────────────────────────────
echo "[2/5] Ensuring directories..."
mkdir -p "$PROJECT_ROOT/models"
mkdir -p "$PROJECT_ROOT/app_data/databases"
echo "  Done."
echo ""

# ── Step 3: Build Rust module ──────────────────────────────────────────────
echo "[3/5] Building Rust native module (nexus-crypto)..."
cd "$PROJECT_ROOT/nexus_ai/rust"
if command -v cargo &>/dev/null; then
    "$PYTHON" -m maturin develop --release 2>&1 || {
        echo "  [WARN] Rust build failed — check if Rust toolchain is installed"
        echo "  Continuing with Python fallback..."
    }
else
    echo "  [WARN] Rust/Cargo not found — skipping nexus-crypto build"
    echo "  Install Rust: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
fi
cd "$PROJECT_ROOT"
echo "  Done."
echo ""

# ── Step 4: Run Nuitka ─────────────────────────────────────────────────────
echo "[4/5] Running Nuitka (this may take 10-30 minutes)..."
echo "  Compiling Python → C → single binary with mimalloc..."
echo ""
echo "  Using pyproject.toml Nuitka configuration for onefile build."
echo ""

cd "$PROJECT_ROOT"

# Detect platform suffix
case "$(uname -s)" in
    Linux)   EXE_SUFFIX="" ;;
    Darwin)  EXE_SUFFIX="" ;;  # macOS .app or plain binary
    *)       EXE_SUFFIX="" ;;
esac

# ── Detect Nuitka cache ──────────────────────────────────────────────────
echo "  Checking ccache..."
if command -v ccache &>/dev/null; then
    echo "  ccache: FOUND — 10-50× faster rebuilds"
    export CCACHE_DIR="${CCACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/ccache}"
    export CCACHE_MAXSIZE=${CCACHE_MAXSIZE:-5G}
    mkdir -p "$CCACHE_DIR"
else
    echo "  ccache: NOT FOUND — install for faster rebuilds"
    echo "    Linux: apt install ccache"
    echo "    macOS: brew install ccache"
fi

# ── Setup NUITKA_CACHE_DIR ───────────────────────────────────────────────
export NUITKA_CACHE_DIR="${NUITKA_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/nuitka}"
mkdir -p "$NUITKA_CACHE_DIR"
echo "  NUITKA_CACHE_DIR: $NUITKA_CACHE_DIR"
echo ""

# ── Select compiler (Clang vs GCC vs Zig) ────────────────────────────────
NUITKA_EXTRA_FLAGS=""
if $USE_CLANG; then
    if command -v clang &>/dev/null; then
        echo "  Clang: ENABLED — smaller binary, faster compilation, better diagnostics"
        NUITKA_EXTRA_FLAGS="$NUITKA_EXTRA_FLAGS --clang"
    else
        echo "  [WARN] Clang requested but not found. Install: apt install clang"
    fi
fi
if $USE_ZIG; then
    if command -v zig &>/dev/null; then
        echo "  Zig: ENABLED — faster linking, cross-compilation ready"
        NUITKA_EXTRA_FLAGS="$NUITKA_EXTRA_FLAGS --zig"
    else
        echo "  [WARN] Zig requested but not found. Install: https://ziglang.org/download/"
    fi
fi

# ── Run Nuitka ───────────────────────────────────────────────────────────
# Uwaga: flagi poniżej są dopełnieniem konfiguracji z pyproject.toml i main.py
# Główna konfiguracja Nuitka jest w dyrektywach nuitka-project: w main.py
# Dodatkowe flagi poniżej są wymagane tylko gdy pyproject.toml/main.py nie są używane
"$PYTHON" -m nuitka \
    --project-name=nexus-ai \
    --output-dir="$DIST_DIR" \
    --output-name="$EXE_NAME" \
    --lto=yes \
    $NUITKA_EXTRA_FLAGS \
    main.py

NUITKA_EXIT=$?
if [ $NUITKA_EXIT -ne 0 ]; then
    echo "  [ERROR] Nuitka build failed! (exit code: $NUITKA_EXIT)"
    echo "  Check the output above for details."
    echo ""
    echo "  Common issues:"
    echo "  - Missing C compiler (install GCC: apt install build-essential)"
    echo "  - Missing Python development headers (apt install python3-dev)"
    echo "  - Out of memory during compilation (try: export NUITKA_JOBS=2)"
    exit 1
fi

# ── Show ccache stats ────────────────────────────────────────────────────
if command -v ccache &>/dev/null; then
    echo ""
    echo "  ccache statistics:"
    ccache --show-stats 2>&1 | sed 's/^/    /'
fi

echo ""
echo "  Done. Binary: $DIST_DIR/$EXE_NAME"
echo ""

# ── Step 5: Show result ────────────────────────────────────────────────────
echo "[5/5] Build complete!"
echo ""

# Check if binary exists (Nuitka onefile creates a single binary on Linux/macOS too)
OUTPUT_FILE="$DIST_DIR/$EXE_NAME"
if [ -f "$OUTPUT_FILE" ]; then
    FILE_SIZE=$(du -h "$OUTPUT_FILE" 2>/dev/null | cut -f1 || stat -f%z "$OUTPUT_FILE" 2>/dev/null)
    echo "  Output: $OUTPUT_FILE"
    echo "  Size:   $FILE_SIZE"
    echo ""
    echo "  Run: ./$OUTPUT_FILE"
else
    # Nuitka may create .bin on some platforms
    OUTPUT_FILE="$DIST_DIR/$EXE_NAME.bin"
    if [ -f "$OUTPUT_FILE" ]; then
        FILE_SIZE=$(du -h "$OUTPUT_FILE" 2>/dev/null | cut -f1)
        echo "  Output: $OUTPUT_FILE"
        echo "  Size:   $FILE_SIZE"
    else
        echo "  [WARN] Binary not found at expected path."
        echo "  Check $DIST_DIR/ for output files."
    fi
fi

echo ""
echo "  Pamiętaj: Modele AI (~6.9 GB) są pobierane przy pierwszym uruchomieniu."
echo ""
echo "=============================================================================="
echo "                         Build Complete!"
echo "=============================================================================="
