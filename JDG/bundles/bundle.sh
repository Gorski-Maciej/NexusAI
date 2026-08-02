#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OPA Bundle Build Script (v8.0 — struktura katalogów)
# Buduje bundle .tar.gz ze wszystkich reguł JDG dla OPA Server.
# Zachowuje strukturę katalogów rules/ aby uniknąć kolizji nazw plików.
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: bash bundle.sh [version]
#   version - opcjonalny tag wersji (domyślnie: data)
# Output: bundles/jdg-bundle-{version}.tar.gz
# ═══════════════════════════════════════════════════════════════════════════════
# FIX v8.0 (R1): Zachowuje strukturę katalogów zamiast płaskiego kopiowania.
#   8 zduplikowanych basename (crossborder, kks, pcc, plan26_detailed,
#   plan45, rodo, transport, p24_innovations_enterprise) powodowało ciche
#   nadpisywanie reguł w bundle. Teraz każdy plik ma unikalną ścieżkę.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JDG_ROOT="$(dirname "$SCRIPT_DIR")"
RULES_DIR="$JDG_ROOT/rules"
BUNDLE_DIR="$SCRIPT_DIR"
VERSION="${1:-$(date +%Y%m%d-%H%M%S)}"
BUNDLE_NAME="jdg-bundle-${VERSION}"
TEMP_DIR="$(mktemp -d)"

echo "📦 Building OPA Bundle: $BUNDLE_NAME"
echo "   Rules dir: $RULES_DIR"

# Kopiuj pliki .rego z zachowaniem struktury katalogów (fix R1)
mkdir -p "$TEMP_DIR/jdg"
cd "$RULES_DIR"
find . -name "*.rego" | while read -r f; do
    # Pomijamy wiodący "./"
    rel="${f#./}"
    target_dir="$TEMP_DIR/jdg/$(dirname "$rel")"
    mkdir -p "$target_dir"
    cp "$f" "$target_dir/"
done
cd "$TEMP_DIR"

# Kopiuj plik metadata
if [ -f "$JDG_ROOT/_metadata_jdg.rego" ]; then
    cp "$JDG_ROOT/_metadata_jdg.rego" "$TEMP_DIR/jdg/"
fi

# Kopiuj manifest
cp "$BUNDLE_DIR/manifest.json" "$TEMP_DIR/.manifest"

# Weryfikacja: sprawdź liczbę plików .rego w bundle vs na dysku
BUNDLE_COUNT=$(find "$TEMP_DIR/jdg" -name "*.rego" | wc -l)
SOURCE_COUNT=$(find "$RULES_DIR" -name "*.rego" | wc -l)
if [ "$BUNDLE_COUNT" -ne "$SOURCE_COUNT" ]; then
    echo "⚠️  OSTRZEŻENIE: Bundle zawiera $BUNDLE_COUNT plików .rego, a źródło $SOURCE_COUNT!"
    echo "   Sprawdź, czy wszystkie pliki zostały skopiowane."
fi

# Utwórz bundle .tar.gz
tar czf "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" -C "$TEMP_DIR" .

# Sprzątanie
rm -rf "$TEMP_DIR"

BUNDLE_SIZE=$(du -h "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" | cut -f1)
echo "✅ Bundle utworzony: $BUNDLE_DIR/${BUNDLE_NAME}.tar.gz"
echo "   Rozmiar: $BUNDLE_SIZE"
echo "   Plików .rego: $BUNDLE_COUNT (źródło: $SOURCE_COUNT)"
if [ "$BUNDLE_COUNT" -ne "$SOURCE_COUNT" ]; then
    echo "   ⚠️  ROZBIEŻNOŚĆ: brakuje $((SOURCE_COUNT - BUNDLE_COUNT)) plików!"
    exit 1
fi
echo ""
echo "🚀 Deployment:"
echo "   curl -X PUT --data-binary @${BUNDLE_NAME}.tar.gz http://opa-server:8181/v1/bundles/jdg"
