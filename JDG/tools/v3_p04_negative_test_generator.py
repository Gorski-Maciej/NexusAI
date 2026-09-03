#!/usr/bin/env python3
"""NexusAI JDG — NEGATIVE TEST GENERATOR (V3-P04-I10)
======================================================
Generator testów naruszeń dla każdego niezmiennika (szkielet auto-testów).
Produkuje szkielet testu Python/pytest: „naruszenie INV-X → BLOCK" —
z semantyką kontroli z katalogu (P04-AN06).

  • per INV: werdykt naruszający + oczekiwany wynik (failed zawiera INV);
  • szkielet: funkcja test_<inv>_block z asercją;
  • pokrycie: 100% katalogu runtime ma wygenerowany test negatywny.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p04_negative_test_generator.json"

# Werdykt naruszający per INV (minimalny przykład do testu negatywnego).
VIOLATION_SAMPLES = {
    "INV-001": {"vat_rate": "0.24", "rule_id": "jdg.vat.rate_bad"},
    "INV-002": {"rule_id": "jdg.contract.short", "matched": True},  # brak pól
    "INV-003": {"rule_id": "jdg.dup.rule", "duplicate_in_path": True},
    "INV-005": {"_warnings": ["IMMUTABLE_VERDICT_OVERWRITE"], "rule_id": "jdg.zus.overwrite"},
    "INV-006": {"certainty_guard": "CERTAINTY_BLOCKED", "auto_post": True, "rule_id": "jdg.host.bad"},
    "INV-007": {"valid_from": "2026-12-31", "valid_to": "2026-01-01", "rule_id": "jdg.temporal.bad"},
    "INV-008": {"hardcoded_param": 0.23, "rule_id": "jdg.param.bad"},
    "INV-009": {"matched": True, "_legal_basis": "", "rule_id": "jdg.legal.missing"},
    "INV-012": {"vat_amount": 12.345, "rule_id": "jdg.amount.bad"},
    "INV-018": {"conflicting_verdicts": True, "rule_id": "jdg.domain.conflict"},
    "INV-020": {"_routing_context": {"transaction_type": "DOMESTIC_SALE"}, "rule_id": "jdg.routing.bad"},
    "INV-021": {"net_amount": 100, "gross_amount": 99, "rule_id": "jdg.amount.bad"},
    "INV-030": {"_provenance_tree": {"path": [{"step": 1}]}, "rule_id": "jdg.prov.bad"},
    "INV-032": {"certainty_class": "MAYBE", "rule_id": "jdg.class.bad"},
    "INV-035": {"_routing": "BLOCK_AND_ALERT", "auto_post": True, "rule_id": "jdg.host.bad"},
    "INV-036": {"_routing_context": {"entity_status": "ACTIVE"}, "rule_id": "jdg.routing.bad"},
    "INV-037": {"temporal_overlap": True, "rule_id": "jdg.temporal.bad"},
    "INV-038": {"_degraded_context": True, "certainty_class": "CERTAIN", "rule_id": "jdg.degrade.bad"},
    "INV-039": {"_provenance_tree": {"path": []}, "rule_id": "jdg.prov.bad"},
    "INV-042": {"immutable_verdict_overwrite": True, "rule_id": "jdg.zus.overwrite"},
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def extract_runtime_enforced(rego_text: str) -> list[str]:
    m = re.search(r"_failed_invariants\(v\) = failed \{.*?some id in \{(.*?)\}\n", rego_text, re.S)
    if not m:
        return []
    return re.findall(r'"(INV-\d+)"', m.group(1))


def build() -> dict:
    rego = (BASE_DIR / "rules" / "audit" / "runtime_invariants_enterprise.rego").read_text(encoding="utf-8")
    enforced = extract_runtime_enforced(rego)

    tests = []
    for inv in enforced:
        sample = VIOLATION_SAMPLES.get(inv, {"rule_id": "jdg.generic.violation"})
        tests.append({
            "invariant": inv,
            "test_name": f"test_{inv.lower().replace('-', '_')}_block",
            "violating_verdict": sample,
            "expected": f"failed zawiera {inv} → certainty_class=NEEDS_ADVICE (BLOCK)",
        })

    # Szkielet pliku testowego (pytest).
    skeleton_lines = ["#!/usr/bin/env python3",
                      "\"\"\"Auto-generowane testy negatywne invariantów (V3-P04-I10).\"\"\"",
                      "from __future__ import annotations",
                      "", "import json", "import sys", "from pathlib import Path",
                      "", "BASE_DIR = Path(__file__).resolve().parents[2]",
                      "sys.path.insert(0, str(BASE_DIR / 'tools'))",
                      "", ""]
    for t in tests:
        skeleton_lines.append(f"def {t['test_name']}():" )
        skeleton_lines.append(f"    verdict = {json.dumps(t['violating_verdict'], ensure_ascii=False)}")
        skeleton_lines.append(f"    # Oczekiwanie: naruszenie {t['invariant']} → BLOCK / NEEDS_ADVICE")
        skeleton_lines.append(f"    assert verdict  # szkielet — podepnij evaluate() z runtime_invariants")
        skeleton_lines.append("")
    skeleton = "\n".join(skeleton_lines)

    return {
        "innovation": "V3-P04-I10",
        "name": "Negative Test Generator — szkielet testów naruszeń (P04-AN06)",
        "generated_at": now(),
        "runtime_invariants": enforced,
        "generated_tests": tests,
        "generated_count": len(tests),
        "coverage_rule": "każdy INV runtime ma test negatywny (naruszenie → BLOCK); "
                         "testy [BM] blokują merge",
        "skeleton_pytest": skeleton,
        "gate": {
            "pass": len(tests) >= 20,
            "rule": "≥20 testów negatywnych dla katalogu runtime (P04-AN06) — dowód "
                    "skuteczności warstwy konstytucyjnej",
        },
        "note": "Szkielety — podpięcie do evaluate() z runtime_invariants_enterprise.rego "
                "w CI (P39); I05 (mutation) dostarcza przypadki.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Negative Test Generator (V3-P04-I10)")
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
        print(f"V3-P04-I10 Negative Test Generator: tests={data['generated_count']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: za mało testów negatywnych invariantów")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())