#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# scripts/doctor.sh — System diagnostics (przeniesione z mise-tasks/)
# ═══════════════════════════════════════════════════════════════════════════════
# Uruchom bezpośrednio: bash scripts/doctor.sh
# Uwaga: 'pixi run doctor' uruchamia Pythonową wersję (nexus_ai/scripts/doctor.py)
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

echo "🔍 NexusAI — System Diagnostics"
echo "================================="
echo ""

echo "── Environment ──"
echo "  Python:  $(python --version 2>&1)"
echo "  Pixi:    $(pixi --version 2>&1)"
echo "  Project: ${PIXI_PROJECT_ROOT:-$(pwd)}"
echo ""

echo "── Database ──"
if [ -f "app_data/nexus.db" ]; then
    DB_SIZE=$(du -h "app_data/nexus.db" 2>/dev/null | cut -f1)
    echo "  SQLite:  ✅  ($DB_SIZE)"
else
    echo "  SQLite:  ⚠️  not found at app_data/nexus.db"
fi
if [ -f "app_data/analytics.duckdb" ]; then
    echo "  DuckDB:  ✅"
else
    echo "  DuckDB:  ⚠️  not found"
fi
echo ""

echo "── NATS ──"
if command -v nats-server &>/dev/null; then
    echo "  Binary:  ✅  ($(nats-server --version 2>&1))"
else
    echo "  Binary:  ❌  not found"
fi
echo ""

echo "── TigerBeetle ──"
if command -v tigerbeetle &>/dev/null; then
    echo "  Binary:  ✅  ($(tigerbeetle version 2>&1))"
else
    echo "  Binary:  ❌  not found"
fi
echo ""

echo "── AI Models ──"
MODEL_COUNT=$(find models/ -name "*.gguf" 2>/dev/null | wc -l)
if [ "$MODEL_COUNT" -gt 0 ]; then
    echo "  GGUF:    ✅  ($MODEL_COUNT models)"
else
    echo "  GGUF:    ⚠️  no models found (run: pixi run download-models)"
fi
echo ""

echo "── Git ──"
if git rev-parse --git-dir &>/dev/null; then
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo "  Branch:  $BRANCH"
    echo "  Status:  $(git status --short 2>/dev/null | wc -l) changes"
else
    echo "  Git:     ❌  not a git repository"
fi
echo ""

echo "✅ Done."
