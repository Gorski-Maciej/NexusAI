#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# scripts/aliases.sh — Skróty dla pixi run (odpowiednik shell_alias z mise.toml)
# ═══════════════════════════════════════════════════════════════════════════════
#
# Użycie:
#   source scripts/aliases.sh      # Ładuje wszystkie skróty
#   alias | grep pixi              # Pokaż dostępne skróty
#
# Skróty (zgodne ze starymi aliasami z mise.toml):
#   na  → pixi run start-nats
#   tb  → pixi run start-tigerbeetle
#   dv  → pixi run dev
#   ap  → pixi run api
#   wk  → pixi run worker
#   ts  → pixi run test
#   ta  → pixi run test-all
#   tc  → pixi run test-coverage
#   bd  → pixi run build-all
#   br  → pixi run build-rust
#   bn  → pixi run build-nuitka
#   mg  → pixi run migrate
#   dp  → pixi run deploy
#   dq  → pixi run deploy-quick
#   dc  → pixi run deploy-check
#   st  → pixi run status
#
# ═══════════════════════════════════════════════════════════════════════════════

# ── Service startup ──────────────────────────────────────────────────────────
alias na="pixi run start-nats"
alias tb="pixi run start-tigerbeetle"

# ── Development environment ─────────────────────────────────────────────────
alias dv="pixi run dev"
alias ap="pixi run api"
alias wk="pixi run worker"

# ── Testing ──────────────────────────────────────────────────────────────────
alias ts="pixi run test"
alias ta="pixi run test-all"
alias tc="pixi run test-coverage"

# ── Build ────────────────────────────────────────────────────────────────────
alias bd="pixi run build-all"
alias br="pixi run build-rust"
alias bn="pixi run build-nuitka"

# ── Database migrations ─────────────────────────────────────────────────────
alias mg="pixi run migrate"

# ── Deploy ──────────────────────────────────────────────────────────────────
alias dp="pixi run deploy"
alias dq="pixi run deploy-quick"
alias dc="pixi run deploy-check"
alias st="pixi run status"

echo "✅ Aliases loaded — use 'alias | grep pixi' to see all shortcuts"
