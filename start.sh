#!/bin/bash
# ══════════════════════════════════════════════════════════════════════
# NexusAI v7.0 AUDIT — Startup Script
# TigerBeetle Shadow Ledger v7.0 Integration
# ══════════════════════════════════════════════════════════════════════

cd ~/NexusAI

# ── v7.0: Load environment configuration ──────────────────────────
if [ -f .env.v7 ]; then
    export $(grep -v '^#' .env.v7 | grep -v '^$' | xargs)
    echo "[v7.0] Environment loaded from .env.v7"
fi

# ── v7.0: Set defaults for critical services ───────────────────────
export TB_CLUSTER_ID="${TB_CLUSTER_ID:-0}"
export PENDING_TIMEOUT_SECONDS="${PENDING_TIMEOUT_SECONDS:-3600}"
export INTEGRITY_CHECK_INTERVAL_SECONDS="${INTEGRITY_CHECK_INTERVAL_SECONDS:-60}"

# ── Git auto-commit ────────────────────────────────────────────────
git pull origin main
fastcode
git add .
git commit -m "FastCode: auto-commit $(date +'%Y-%m-%d %H:%M')" || true
git push origin main

# ── v7.0: Service startup (uncomment to enable) ────────────────────
# Start TigerBeetle
# pixi run start-tigerbeetle &

# Start NATS (if running locally)
# nats-server -js &

# Start NexusAI API with v7.0 services
# python -c "
# import asyncio
# from nexus_ai.services.nats_wiring import wire_all_services
# asyncio.run(wire_all_services(tb_client, duckdb_conn, nats_client=nats))
# " &

echo "[v7.0] NexusAI v7.0 AUDIT startup complete"
