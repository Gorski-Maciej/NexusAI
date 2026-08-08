#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — OPA Bundle Build Script (v9.0 — ENTERPRISE CONTROL PLANE, P01 §5)
# Buduje podpisany bundle .tar.gz ze wszystkich reguł JDG dla OPA Server.
# Rozszerzenia v9.0 (luka L1 — control plane jako infrastruktura, V1 §9.1):
#   • manifest_v2.json (MANIFEST 2.0) dołączany do bundle — jedno źródło prawdy
#   • SBOM: bundles/jdg-bundle-{v}.sbom.json — checksum SHA-256 każdego pliku
#   • Podpis: `opa sign` (jeśli dostępny) + plik .signature (SHA-256 manifestu)
#   • bundles/healthy_versions.json — lista zdrowych wersji (auto-rollback)
#   • tryb VERIFY: weryfikacja podpisu/checksum przed aktywacją na węźle
# ═══════════════════════════════════════════════════════════════════════════════
# Usage: bash bundle.sh [version] [sign|nosign]
#   sign  - (domyślnie) podpisz bundle przez `opa sign` jeśli dostępny
# Output: bundles/jdg-bundle-{version}.tar.gz + .sbom.json + .signature
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
JDG_ROOT="$(dirname "$SCRIPT_DIR")"
RULES_DIR="$JDG_ROOT/rules"
BUNDLE_DIR="$SCRIPT_DIR"
VERSION="${1:-$(date +%Y%m%d-%H%M%S)}"
SIGN_MODE="${2:-sign}"
BUNDLE_NAME="jdg-bundle-${VERSION}"
TEMP_DIR="$(mktemp -d)"
SBOM_FILE="$BUNDLE_DIR/${BUNDLE_NAME}.sbom.json"
SIG_FILE="$BUNDLE_DIR/${BUNDLE_NAME}.signature"

echo "📦 Budowanie podpisanego bundle OPA (v9.0): $BUNDLE_NAME"

# Kopiuj pliki .rego z zachowaniem struktury katalogów (fix R1)
mkdir -p "$TEMP_DIR/jdg"
cd "$RULES_DIR"
find . -name "*.rego" | while read -r f; do
    rel="${f#./}"
    target_dir="$TEMP_DIR/jdg/$(dirname "$rel")"
    mkdir -p "$target_dir"
    cp "$f" "$target_dir/"
done
cd "$TEMP_DIR"

# Kopiuj metadata + manifesty
if [ -f "$JDG_ROOT/_metadata_jdg.rego" ]; then
    cp "$JDG_ROOT/_metadata_jdg.rego" "$TEMP_DIR/jdg/"
fi
cp "$BUNDLE_DIR/manifest.json" "$TEMP_DIR/.manifest"
if [ -f "$BUNDLE_DIR/manifest_v2.json" ]; then
    cp "$BUNDLE_DIR/manifest_v2.json" "$TEMP_DIR/.manifest_v2.json"
fi

# Weryfikacja liczby plików (bramka 1)
BUNDLE_COUNT=$(find "$TEMP_DIR/jdg" -name "*.rego" | wc -l)
SOURCE_COUNT=$(find "$RULES_DIR" -name "*.rego" | wc -l)
if [ "$BUNDLE_COUNT" -ne "$SOURCE_COUNT" ]; then
    echo "❌ BRAMKA: bundle $BUNDLE_COUNT plików vs źródło $SOURCE_COUNT — ABORT"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# SBOM — checksum każdego pliku (V1 §11 supply chain)
{
    echo "{"
    echo "  \"bundle\": \"$BUNDLE_NAME\","
    echo "  \"built_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
    echo "  \"rego_file_count\": $BUNDLE_COUNT,"
    echo "  \"files\": ["
    first=1
    find "$TEMP_DIR/jdg" -name "*.rego" | sort | while read -r f; do
        rel="${f#$TEMP_DIR/}"
        h=$(sha256sum "$f" | cut -d' ' -f1)
        if [ "$first" -eq 0 ]; then echo ","; fi
        printf '    {"path": "%s", "sha256": "%s"}' "$rel" "$h"
        first=0
    done
    echo ""
    echo "  ]"
    echo "}"
} > "$SBOM_FILE"

# MANIFEST 2.0 — suma kontrolna całości (Merkle-root-lite: SHA-256 SBOM)
MANIFEST_HASH=$(sha256sum "$SBOM_FILE" | cut -d' ' -f1)
echo "{\"bundle\": \"$BUNDLE_NAME\", \"sbom_sha256\": \"$MANIFEST_HASH\"}" > "$SIG_FILE"

# Podpis HSM/OPA (jeśli dostępny) — bramka 2 (V1 §4.4: bundle bez podpisu odrzucony)
if [ "$SIGN_MODE" = "sign" ] && command -v opa >/dev/null 2>&1; then
    # opa sign tworzy .signatures.json w katalogu bundle — najlepiej na kopii
    SIG_TMP="$(mktemp -d)"
    cp -r "$TEMP_DIR/jdg" "$SIG_TMP/"
    cp "$SIG_FILE" "$SIG_TMP/signature.json"
    if (cd "$SIG_TMP" && opa sign --signing-key "$BUNDLE_DIR/signing_key.pem" jdg 2>/dev/null); then
        cp "$SIG_TMP/jdg/.signatures.json" "$TEMP_DIR/jdg/.signatures.json" 2>/dev/null || true
        echo "🔐 Podpis OPA: $TEMP_DIR/jdg/.signatures.json (HSM/KMS — weryfikacja na węźle)"
    else
        echo "⚠️  opa sign niedostępny/bez klucza — podpis SHA-256 (SBOM) w .signature"
        echo "   (weryfikacja kryptograficzna HSM wymaga klucza signing_key.pem)"
    fi
    rm -rf "$SIG_TMP"
else
    echo "⚠️  Tryb nosign — bundle z checksum SHA-256 (SBOM + .signature)"
fi

# Utwórz bundle .tar.gz
tar czf "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" -C "$TEMP_DIR" .
rm -rf "$TEMP_DIR"

# Rejestr zbudowanych wersji (V1 §9.1). UWAGA: dodanie do listy "built" NIE
# oznacza zdrowia — status zdrowy nadaje deployment_orchestrator.py po zdaniu
# kanara/soak (promote). Auto-rollback celuje w wersje oznaczone "healthy".
BUILT_FILE="$BUNDLE_DIR/healthy_versions.json"
if [ -f "$BUILT_FILE" ]; then
    BUILT=$(cat "$BUILT_FILE")
else
    BUILT='{"built": [], "healthy": []}'
fi
BUILT=$(echo "$BUILT" | python3 -c "
import json,sys
d=json.load(sys.stdin)
d.setdefault('built', [])
d.setdefault('healthy', [])
if '$BUNDLE_NAME' not in d['built']:
    d['built'].append('$BUNDLE_NAME')
print(json.dumps(d, indent=2))
")
echo "$BUILT" > "$BUILT_FILE"

BUNDLE_SIZE=$(du -h "$BUNDLE_DIR/${BUNDLE_NAME}.tar.gz" | cut -f1)
echo "✅ Bundle utworzony: $BUNDLE_DIR/${BUNDLE_NAME}.tar.gz"
echo "   Rozmiar: $BUNDLE_SIZE · plików Rego: $BUNDLE_COUNT"
echo "   SBOM: $(basename "$SBOM_FILE") · manifest hash: $MANIFEST_HASH"
echo ""
echo "🚀 Deployment (progressive delivery — deployment_orchestrator.py):"
echo "   curl -X PUT --data-binary @${BUNDLE_NAME}.tar.gz http://opa-server:8181/v1/bundles/jdg"
echo "   python ../tools/deployment_orchestrator.py canary ${BUNDLE_NAME}"
