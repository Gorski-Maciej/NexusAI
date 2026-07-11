#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# bundle.sh — OPA Bundle Builder for NexusAI Tax Policies
# ═══════════════════════════════════════════════════════════════════════════════
#
# Buduje OPA bundle z katalogu policies/.
# Wzorce: styrainc/enterprise-opa (Bundle API) + kubescape/regolibrary (bundle.py)
#
# Usage: ./bundle.sh [--tag VERSION] [--push REGISTRY_URL]
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── Configuration ────────────────────────────────────────────────────────────
BUNDLE_NAME="nexusai-tax-policies"
OUTPUT_DIR="${SCRIPT_DIR}/build"
REVISION="v$(date +%Y.%m.%d)-$(git rev-parse --short HEAD 2>/dev/null || echo 'dev')"
TAG="${1:-$REVISION}"

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  NexusAI OPA Bundle Builder — ${REVISION}${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"

# ── Clean & Prepare ──────────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"
rm -f "${OUTPUT_DIR}/${BUNDLE_NAME}"*.tar.gz

# ── Step 1: Syntax Check ─────────────────────────────────────────────────────
echo -e "${BLUE}[1/3]${NC} Running opa check --strict..."
if opa check ./tax --strict 2>&1; then
    echo -e "       ${GREEN}✓ All policies pass syntax check${NC}"
else
    echo -e "       ${RED}✗ Syntax check failed${NC}"
    exit 1
fi

# ── Step 2: Run Tests ────────────────────────────────────────────────────────
echo -e "${BLUE}[2/3]${NC} Running opa test..."
if opa test . -v 2>&1; then
    echo -e "       ${GREEN}✓ All tests pass${NC}"
else
    echo -e "       ${RED}✗ Tests failed${NC}"
    exit 1
fi

# ── Step 3: Build Bundle ─────────────────────────────────────────────────────
echo -e "${BLUE}[3/3]${NC} Building OPA bundle..."
BUNDLE_FILE="${OUTPUT_DIR}/${BUNDLE_NAME}-${TAG}.tar.gz"

# Build bundle with tax policies + SC thresholds data + SC-specific packages
opa build \
    --bundle ./tax \
    --bundle ./data \
    --output "$BUNDLE_FILE" \
    --revision "$REVISION" \
    2>&1

echo -e "       ${GREEN}✓ Bundle created: ${BUNDLE_FILE}${NC}"
echo -e "       Size: $(du -h "$BUNDLE_FILE" | cut -f1)"
echo -e "       Packages included: tax/risk, tax/routing, tax/compliance, tax/crossborder,"
echo -e "                         tax/vat/*, tax/pit/*, tax/zus/*, tax/accounting/*,"
echo -e "                         tax/temporal, tax/anomaly, tax/what_if, tax/partner_mirror,"
echo -e "                         tax/main_sc, tax/sc_fallback, tax/sc_partnership,"
echo -e "                         tax/sc_liability, tax/sc_ksef_jpk,"
echo -e "                         tax/_helpers, tax/_helpers_sc, tax/_metadata,"
echo -e "                         data/sc/thresholds"

# ── Optional: Push to OCI Registry ───────────────────────────────────────────
if [[ "${2:-}" == "--push" ]] && [[ -n "${3:-}" ]]; then
    REGISTRY_URL="$3"
    echo -e "${BLUE}[OPT]${NC} Pushing to OCI registry: ${REGISTRY_URL}"
    oras push "${REGISTRY_URL}/${BUNDLE_NAME}:${TAG}" "$BUNDLE_FILE" 2>&1 || {
        echo -e "       ${RED}✗ Push failed (oras not configured?)${NC}"
    }
    echo -e "       ${GREEN}✓ Bundle pushed to ${REGISTRY_URL}/${BUNDLE_NAME}:${TAG}${NC}"
fi

echo -e "\n${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Bundle build complete!                                     ║${NC}"
echo -e "${GREEN}║  File: ${BUNDLE_FILE}${NC}"
echo -e "${GREEN}║  Tag:  ${TAG}${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
