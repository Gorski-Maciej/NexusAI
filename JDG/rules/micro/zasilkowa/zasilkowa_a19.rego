# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG Policies — Micro Layer: Ustawa zasiłkowa — 10 artykułów → ~100 reguł Micro
# Dual-Layer Architecture: Micro (Deep-Tier) — Atomic legal validation
# Generated: 2026-07-13
# Package: jdg.micro.zasilkowa
# ═══════════════════════════════════════════════════════════════════════════════

package jdg.micro.zasilkowa

import data.jdg.helpers

default decide := {
    "matched": false,
    "rule_id": "jdg.micro.zasilkowa.no_match",
    "package": "jdg.micro.zasilkowa",
    "priority": 999999
}

# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  zasilkowa.a19 — Zasiłek chorobowy (10 reguł)                                    ║
# ║  Legal basis: Ustawa zasiłkowa z 25.06.1999 (Dz.U. 1999 nr 60 poz. 636)                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
