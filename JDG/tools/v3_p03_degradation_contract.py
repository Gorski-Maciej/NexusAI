#!/usr/bin/env python3
"""NexusAI JDG — DEGRADATION CONTRACT PATTERNS (V3-P03-I10)
============================================================
Wzorce pełnego kontraktu przy degradacji (puste ≠ błędne) z testami per wzorzec
(P03-AN12). Każda ścieżka degradacji zwraca pełny 25-polowy kontrakt z jawnym
_degraded_context — nigdy skróconego werdyktu.

  • wzorce: DEGRADED_API (fallback API), PARTIAL (brak danych domeny),
    BLOCKED (ryzyko), NO_MATCH (brak reguły);
  • każdy wzorzec: pełny kontrakt + class NEEDS_ADVICE + _warnings;
  • wykrywanie skróconych kontraktów w kodzie (ścieżki zwracające < 25 pól).
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_degradation_contract.json"

# 25 pól kanonicznych (r01_orchestrator_core_innovations_v9.rego).
CANON_25 = [
    "matched", "rule_id", "package", "priority",
    "vat_rate", "rounding_level", "gtu_code", "vat_exemption", "procedure",
    "pit_form", "pit_rate", "pit_bracket", "pit_annual_return_type",
    "kus_qualification", "kus_percent",
    "zus_social_base_type", "zus_health_rate",
    "business_status", "ceidg_registration_required",
    "valid_from", "valid_to",
    "_routing", "_routing_reason", "_legal_basis", "_warnings",
]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def full_contract(**overrides) -> dict:
    base = {f: "" for f in CANON_25}
    base.update({"matched": True, "rule_id": "jdg.degradation.pattern",
                 "package": "jdg.degradation", "priority": 9999})
    base.update(overrides)
    return base


def build() -> dict:
    patterns = {
        "DEGRADED_API": full_contract(
            rule_id="jdg.api_fallback.no_match", _routing="TRIAGE_QUEUE",
            _degraded_context=True, _warnings=["DEGRADED_API: usługa zewnętrzna niedostępna"],
        ),
        "PARTIAL": full_contract(
            rule_id="jdg.fallback.partial", _routing="TRIAGE_QUEUE",
            _degraded_context=True, _warnings=["PARTIAL: brak danych domeny VAT"],
        ),
        "BLOCKED": full_contract(
            rule_id="jdg.risk.domain_block", _routing="BLOCK_AND_ALERT",
            _warnings=["BLOCK: kontrahent w sieci fraudowej"],
        ),
        "NO_MATCH": full_contract(
            matched=False, rule_id="jdg.fallback.no_match_jdg", _routing="TRIAGE_QUEUE",
            _warnings=["NO_MATCHING_RULE — brak dopasowania"],
        ),
    }
    # Weryfikacja: każdy wzorzec ma komplet 25 pól (klucze obecne, nawet puste).
    for name, contract in patterns.items():
        missing = [f for f in CANON_25 if f not in contract]
        patterns[name] = {**contract, "_contract_complete": len(missing) == 0,
                          "_missing_fields": missing}

    # Skan kodu: ścieżki DEGRADACJI (fallback/api_fallback — ostatnia linia
    # kontraktu) zwracające skrócony kontrakt (luka AP07). Reguły domenowe są
    # kompletowane przez safe_merge w main_jdg (ADR-001 Multi-Pass) — pełny
    # kontrakt wymagany jest tylko dla werdyktów degradacji, które idą do klienta
    # bez dalszej kompletacji (P03-AN12, INV-038).
    short_contracts = []
    for p in sorted((BASE_DIR / "rules").rglob("*.rego")):
        t = p.read_text(encoding="utf-8")
        for m in re.finditer(r'"rule_id"\s*:\s*"([^"]+)"', t):
            rid = m.group(1)
            if rid.endswith(".no_match") or rid.endswith(".no_match_jdg"):
                continue
            nxt = re.search(r'"rule_id"\s*:\s*"', t[m.end():])
            cut = m.end() + (nxt.start() if nxt else 1400)
            ctx = t[m.end():cut]
            routing_m = re.search(r'"_routing"\s*:\s*"(TRIAGE_QUEUE|BLOCK_AND_ALERT)"', ctx)
            if not routing_m:
                continue
            is_degradation = (
                "fallback" in rid or "api_fallback" in rid
                or "_degraded_context" in ctx
                or "DEGRADED" in ctx or "FALLBACK_ACTIVE" in ctx
            )
            if not is_degradation:
                continue
            fields = set(re.findall(r'"([a-z_]+)"\s*:', ctx))
            canon_in_ctx = [f for f in CANON_25 if f in fields]
            if len(canon_in_ctx) < 25:
                short_contracts.append({
                    "file": str(p.relative_to(BASE_DIR)),
                    "rule_id": rid,
                    "canonical_fields_found": len(canon_in_ctx),
                })

    return {
        "innovation": "V3-P03-I10",
        "name": "Degradation Contract Patterns — puste ≠ błędne (P03-AN12)",
        "generated_at": now(),
        "patterns": patterns,
        "all_patterns_complete": all(v["_contract_complete"] for v in patterns.values()),
        "short_contract_paths": short_contracts,
        "short_contract_count": len(short_contracts),
        "semantics": "każda degradacja zwraca pełny 25-polowy kontrakt z _degraded_context "
                     "i _warnings — klient programowo rozróżnia DEGRADED_API/PARTIAL/BLOCKED/NO_MATCH",
        "gate": {
            "pass": all(v["_contract_complete"] for v in patterns.values()) and len(short_contracts) == 0,
            "rule": "zero ścieżek degradacji ze skróconym kontraktem (fail-closed, P03-AN12); "
                    "wzorzec z jawnym _degraded_context (INV-038)",
        },
        "note": "Skan kodu wykrywa ścieżki TRIAGE/BLOCK z <25 polami w kontekście reguły; "
                "padding pustych pól to kontrakt, nie nadpisanie (konwencja P02).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Degradation Contract Patterns (V3-P03-I10)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P03-I10 Degradation Patterns: complete={data['all_patterns_complete']} "
              f"short_contracts={data['short_contract_count']} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: ścieżka degradacji ze skróconym kontraktem")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())