#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OPA Bundle Build Script
# Buduje bundle .tar.gz ze wszystkich reguł JDG dla OPA Server
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: bash bundle.sh [version]
#   version - opcjonalny tag wersji (domyślnie: data)
# Output: bundles/jdg-bundle-{version}.tar.gz
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

# Kopiuj wszystkie pliki .rego do katalogu tymczasowego
mkdir -p "$TEMP_DIR/jdg"
find "$RULES_DIR" -name "*.rego" -exec cp {} "$TEMP_DIR/jdg/" \;

# Kopiuj plik metadata
if [ -f "$JDG_ROOT/_metadata_jdg.rego" ]; then
    cp "$JDG_ROOT/_metadata_jdg.rego" "$TEMP_DIR/jdg/"
fi

# Kopiuj manifest
cp "$BUNDLE_DIR/manifest.json" "$TEMP_DIR/.manifest"

# Utwórz bundle .tar.gz
cd "$TEMP_DIR"
tar czf "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" -C "$TEMP_DIR" .

# Sprzątanie
rm -rf "$TEMP_DIR"

echo "✅ Bundle utworzony: $BUNDLE_DIR/${BUNDLE_NAME}.tar.gz"
echo "   Rozmiar: $(du -h "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" | cut -f1)"
echo ""
echo "🚀 Deployment:"
echo "   curl -X PUT --data-binary @${BUNDLE_NAME}.tar.gz http://opa-server:8181/v1/bundles/jdg"
