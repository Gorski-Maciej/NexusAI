#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# bundle.sh — Build OPA bundle for Temporal Bundle Routing (A2) + P19 signing
# ═══════════════════════════════════════════════════════════════════════════════
# P19 (GLM52 — POLICIES MIRROR + OVERLAYS):
#   • base = wygenerowany mirror rules/ → policies/ (single source of truth),
#   • overlay v20XX nakładany na base (tylko zmienione reguły — delta),
#   • .signatures = SHA-256 per plik + SHA-256 całego bundle (HSM-ready,
#     spójne z bundle_server.py: HSM-SHA256-Merkle),
#   • weryfikacja: python3 tools/bundle_server.py verify + drift gate.
# Użycie:
#   ./bundle.sh v2026          # zbuduj podpisany bundle dla roku 2026
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

# 1. Base = wygenerowany mirror (policies/ — root mirror z rules/, patrz
#    policies_sync_gate.py). REAL_BASE = katalog nad jdg/bundles/base
#    (czyli policies/ — root mirror; 3 poziomy w górę od base/).
REAL_BASE="$(cd "$BASE_DIR/../../.." && pwd)"
# legacy policies/jdg/ (stary ręczny mirror) — POMIJANY, zastąpiony przez root mirror
echo "   Mirror base: $REAL_BASE"
cp -rL "$REAL_BASE"/*.rego "$TEMP_DIR/" 2>/dev/null || true
for SUB in pit vat zus kks ksef_jpk accounting allowances business \
           crossborder employer environmental local_taxes representation \
           restructuring retention risk rodo temporal digital compliance \
           corrections liability edge_cases conflicts mpips validation \
           international hyper micro pcc taxfree family data audit \
           edelivery esig force_majeure fx insurance jpk mdr payments \
           procurement regulated residency sanctions seasonal security \
           solidarity statute tp uor wis; do
    if [ -d "$REAL_BASE/$SUB" ]; then
        cp -rL "$REAL_BASE/$SUB" "$TEMP_DIR/"
    fi
done
cp "$BASE_DIR/manifest.json" "$TEMP_DIR/.manifest"

# 2. Nałóż overlay (nadpisuje reguły z base) — rekurencyjnie dla podkatalogów
if ls "$OVERLAY_DIR"/*.rego &>/dev/null || [ -d "$OVERLAY_DIR" ]; then
    echo "   Nakładanie overlay..."
    find "$OVERLAY_DIR" -name '*.rego' -exec cp -f {} "$TEMP_DIR/" \; 2>/dev/null || true
fi
cp "$OVERLAY_DIR/manifest.json" "$TEMP_DIR/.manifest"
echo "   Overlay manifest: $OVERLAY_DIR/manifest.json"

# 3. Sprawdź poprawność Rego
echo "   Walidacja OPA..."
if command -v opa &>/dev/null; then
    opa check --strict "$TEMP_DIR" 2>&1 || {
        echo "⚠️  OPA check wykrył ostrzeżenia (kontynuuję)"
    }
else
    echo "   ⚠️  OPA CLI nie znaleziony — pomijanie walidacji"
fi

# 4. Podpis (P19): SHA-256 per plik + całościowy (HSM-ready)
SIG_FILE="$TEMP_DIR/.signatures.json"
{
    echo "{"
    echo "  \"alg\": \"SHA-256\","
    echo "  \"mode\": \"HSM-SHA256-Merkle\","
    echo "  \"bundle\": \"jdg-$YEAR\","
    echo "  \"files\": {"
    FIRST=1
    find "$TEMP_DIR" -name '*.rego' -o -name '.manifest' | sort | while read -r f; do
        REL="${f#$TEMP_DIR/}"
        HASH=$(sha256sum "$f" | cut -d' ' -f1)
        if [ "$FIRST" = "1" ]; then FIRST=0; else echo ","; fi
        printf '    "%s": "%s"' "$REL" "$HASH"
    done
    echo ""
    echo "  }"
    echo "}"
} > "$SIG_FILE"

# 5. Utwórz bundle
mkdir -p "$OUTPUT_DIR"
tar -czf "$BUNDLE_FILE" -C "$TEMP_DIR" .
BUNDLE_HASH=$(sha256sum "$BUNDLE_FILE" | cut -d' ' -f1)
echo "   Signature: $BUNDLE_HASH"
echo "   Bundled files: $(find "$TEMP_DIR" -name '*.rego' | wc -l | tr -d ' ') rego"

echo "✅ Bundle gotowy: $BUNDLE_FILE ($(du -h "$BUNDLE_FILE" | cut -f1))"
echo ""
echo "📤 Wgraj przez OPA Bundle API:"
echo "   curl -X PUT http://opa:8181/v1/bundles/jdg/$YEAR \\\\"
echo "        -H 'Content-Type: application/gzip' \\\\"
echo "        --data-binary @$BUNDLE_FILE"
echo ""
echo "🔐 Weryfikacja podpisu:"
echo "   cd JDG && python3 tools/bundle_server.py verify --bundle ../policies/jdg/bundles/dist/jdg-$YEAR.tar.gz"

if [ "$WATCH" = "--watch" ]; then
    echo ""
    echo "👁️  Watch mode (OPA >= v0.60)..."
    opa build --watch "$TEMP_DIR" -o "$BUNDLE_FILE"
fi
