#!/usr/bin/env python3
"""NexusAI JDG — V3-P51-I05 SEMI-AUTO RULE DRAFTING — weryfikacja generatorów.

Kontrakt K-P50-5: każdy generator reguł wywołuje strażnika duplikatów
(v3_p50_duplication_guard / guard_duplicate) PRZED zapisem. P51 rozszerza
(nie duplikuje): generator gotowy do domknięcia pustyni klasy rule_no_test
musi NADTO rejestrować szkic w karcie pustyni (I03) z wymaganym testem
granicznym — szkic bez testu nie może wejść do produkcji (AP01: szkielety
nie liczą się jako pokrycie). Rozszerzanie, nie duplikacja: istniejące
generatory rozpoznawane po istniejących plikach (generate_missing_rules.py,
parse_plan33_and_generate.py, generate_from_plan50.py, coverage_95_plan.py).
"""
from __future__ import annotations

import re
from pathlib import Path

from v3_p51_common import BASE, TOOLS_DIR, read_json, write_p51_bundle

BUNDLES_DIR = BASE / "bundles"

GENERATORS = [
    ("generate_missing_rules.py", BASE / "generate_missing_rules.py"),
    ("parse_plan33_and_generate.py", TOOLS_DIR / "parse_plan33_and_generate.py"),
    ("generate_from_plan50.py", TOOLS_DIR / "generate_from_plan50.py"),
    ("coverage_95_plan.py", TOOLS_DIR / "coverage_95_plan.py"),
]

GUARD_PATTERNS = [
    re.compile(r"v3_p50_duplication_guard"),
    re.compile(r"guard_duplicate"),
    re.compile(r"semantic_hash_index"),
]


def main() -> int:
    guarded, legacy_stubs, totals = [], [], 0
    for name, path in GENERATORS:
        totals += 1
        txt = path.read_text(encoding="utf-8", errors="replace") \
            if path.exists() else ""
        has_guard = any(p.search(txt) for p in GUARD_PATTERNS)
        # AP01: generator masowo produkujący szkielety { true } bez testów
        legacy_stub_factory = bool(
            re.search(r"\{\s*true\s*\}", txt)) and not has_guard
        if legacy_stub_factory:
            legacy_stubs.append(name)
        guarded.append({
            "generator": name,
            "exists": bool(txt),
            "duplicate_guard_wired": has_guard,
            "legacy_stub_factory": legacy_stub_factory,
            "desert_card_integration": False,  # do podłączenia w P36 (K-P50-5+)
        })
    generators_guarded = sum(1 for g in guarded
                             if g["duplicate_guard_wired"]
                             and not g["legacy_stub_factory"])
    metrics = {
        "analysis": "semi_auto_drafting",
        "routing": "TRIAGE_QUEUE" if legacy_stubs or generators_guarded
                                          < totals else "AUTO_FILE",
        "generators_total": totals,
        "generators_guarded": generators_guarded,
        "legacy_stub_factories": len(legacy_stubs),
        "ap01_risk": bool(legacy_stubs),
    }
    write_p51_bundle("semi_auto_drafting", "V3-P51-I05", metrics, {
        "generators": guarded,
        "contract": "K-P50-5 (guard przed zapisem) + P51-I03 (szkic z testem "
                    "granicznym); szkielet bez testu ≠ pokrycie (AP01).",
    })
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
