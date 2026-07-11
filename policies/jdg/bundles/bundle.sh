#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# bundle.sh — Build OPA bundle for Temporal Bundle Routing (A2)
# ═══════════════════════════════════════════════════════════════════════════════
# Użycie:
#   ./bundle.sh v2026          # zbuduj bundle dla roku 2026
#   ./bundle.sh v2026 --watch  # watch mode (OPA >= v0.60)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

YEAR="${1:-v2026}"
WATCH="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/base"
OVERLAY_DIR="$SCRIPT_DIR/overlays/$YEAR"
OUTPUT_DIR="$SCRIPT_DIR/dist"
BUNDLE_FILE="$OUTPUT_DIR/jdg-$YEAR.tar.gz"

# ── Validate overlay exists ──────────────────────────────────────────────────
if [ ! -d "$OVERLAY_DIR" ]; then
    echo "❌ Overlay $YEAR nie istnieje: $OVERLAY_DIR"
    echo "   Dostępne: $(ls -d overlays/*/ 2>/dev/null | sed 's|overlays/||;s|/||' | tr '\n' ' ')"
    exit 1
fi

# ── Build temp dir ───────────────────────────────────────────────────────────
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

echo "📦 Budowanie bundle JDG dla roku: $YEAR"
echo "   Base: $BASE_DIR"
echo "   Overlay: $OVERLAY_DIR"

# 1. Kopiuj base (symlink → rzeczywiste pliki z policies/jdg/)
REAL_BASE="$(cd "$BASE_DIR/../.." && pwd)"
cp -rL "$REAL_BASE"/*.rego "$TEMP_DIR/" 2>/dev/null || true
cp -rL "$REAL_BASE"/pit "$TEMP_DIR/" 2>/dev/null || true
cp -rL "$REAL_BASE"/vat "$TEMP_DIR/" 2>/dev/null || true
cp "$BASE_DIR/manifest.json" "$TEMP_DIR/.manifest"

# 2. Nałóż overlay (nadpisuje reguły z base) — rekurencyjnie dla podkatalogów
if ls "$OVERLAY_DIR"/*.rego &>/dev/null || [ -d "$OVERLAY_DIR" ]; then
    echo "   Nakładanie overlay..."
    # Kopiuj pliki .rego z katalogu overlay (w tym podkatalogi jak pit/, vat/)
    find "$OVERLAY_DIR" -name '*.rego' -exec cp -f {} "$TEMP_DIR/" \; 2>/dev/null || true
fi
cp "$OVERLAY_DIR/manifest.json" "$TEMP_DIR/.manifest"

# 3. Sprawdź poprawność Rego
echo "   Walidacja OPA..."
if command -v opa &>/dev/null; then
    opa check --strict "$TEMP_DIR" 2>&1 || {
        echo "⚠️  OPA check wykrył ostrzeżenia (kontynuuję)"
    }
else
    echo "   ⚠️  OPA CLI nie znaleziony — pomijanie walidacji"
fi

# 4. Utwórz bundle
mkdir -p "$OUTPUT_DIR"
tar -czf "$BUNDLE_FILE" -C "$TEMP_DIR" .

echo "✅ Bundle gotowy: $BUNDLE_FILE ($(du -h "$BUNDLE_FILE" | cut -f1))"
echo ""
echo "📤 Wgraj przez OPA Bundle API:"
echo "   curl -X PUT http://opa:8181/v1/bundles/jdg/$YEAR \\"
echo "        -H 'Content-Type: application/gzip' \\"
echo "        --data-binary @$BUNDLE_FILE"

if [ "$WATCH" = "--watch" ]; then
    echo ""
    echo "👁️  Watch mode (OPA >= v0.60)..."
    opa build --watch "$TEMP_DIR" -o "$BUNDLE_FILE"
fi
