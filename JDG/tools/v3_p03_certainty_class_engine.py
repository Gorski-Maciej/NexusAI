#!/usr/bin/env python3
"""NexusAI JDG — CERTAINTY CLASS ENGINE (V3-P03-I02)
=====================================================
Deterministyczny silnik klasy pewności z zamkniętą listą warunków i testami
granicznymi. Odwzorowuje _classify() z runtime_invariants_enterprise.rego
(F4 V2 §5.2) jako funkcję Python — 1:1 z semantyką Rego.

  • zamknięta lista warunków CERTAIN (P03-AN03): brak naruszeń invariantów +
    brak degradacji + pełna proweniencja (_provenance_tree.path >= 1);
  • CONDITIONAL: wymaga interpretacji (_warnings zawiera REQUIRES_INTERPRETATION);
  • NEEDS_ADVICE: naruszenie invariantu / degradacja / brak reguły / brak dowodu;
  • property test: determinizm (ten sam werdykt = ta sama klasa) + granice.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_certainty_class_engine.json"

CLASSES = ("CERTAIN", "CONDITIONAL", "NEEDS_ADVICE")

# Zamknięta lista warunków CERTAIN (P03-AN03) — każdy musi być spełniony.
CERTAIN_CONDITIONS = {
    "no_invariant_failure": "brak naruszeń invariantów (failed == [])",
    "no_degradation": "brak _degraded_context == true (INV-038)",
    "provenance_present": "_provenance_tree obecne z path >= 1 (INV-039)",
    "legal_basis_present": "_legal_basis niepuste dla decyzji materialnej (I06)",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def classify(verdict: dict) -> dict:
    failed = list(verdict.get("failed", []) or verdict.get("_invariant_failed_ids", []))
    degraded = verdict.get("_degraded_context", False) is True
    prov = verdict.get("_provenance_tree") or {}
    path = prov.get("path") or []
    has_prov = isinstance(path, list) and len(path) >= 1
    warnings = verdict.get("_warnings") or []
    legal = verdict.get("_legal_basis") or ""
    matched = verdict.get("matched", False) is True

    conditions = {
        "no_invariant_failure": len(failed) == 0,
        "no_degradation": not degraded,
        "provenance_present": has_prov,
        "legal_basis_present": bool(legal) or not matched,
    }
    met = [k for k, v in conditions.items() if v]
    unmet = [k for k, v in conditions.items() if not v]

    if not matched:
        cls = "NEEDS_ADVICE"
        reason = "brak dopasowania reguły (no_match) — nigdy CERTAIN"
    elif len(failed) > 0 or degraded:
        cls = "NEEDS_ADVICE"
        reason = f"naruszenie invariantów {failed} lub degradacja" if len(failed) > 0 else "degradacja kontekstu (INV-038)"
    elif "REQUIRES_INTERPRETATION" in warnings:
        cls = "CONDITIONAL"
        reason = "wymaga interpretacji (REQUIRES_INTERPRETATION w _warnings)"
    elif all(conditions.values()):
        cls = "CERTAIN"
        reason = "wszystkie warunki zamkniętej listy spełnione"
    else:
        cls = "CONDITIONAL"
        reason = "fallback: brak pełnego dowodu CERTAIN"

    return {
        "certainty_class": cls,
        "reason": reason,
        "conditions_met": met,
        "conditions_unmet": unmet,
        "deterministic_key": json.dumps({
            "failed": failed, "degraded": degraded,
            "has_prov": has_prov, "warnings": sorted(warnings),
            "matched": matched, "legal": bool(legal),
        }, sort_keys=True),
    }


def build() -> dict:
    # Próbki werdyktów: pełny dowód, degradacja, naruszenie, no_match, interpretacja.
    samples = {
        "full_evidence": {
            "matched": True, "rule_id": "jdg.vat.rate_23", "_legal_basis": "Art. 41 ust. 1 VAT",
            "_provenance_tree": {"path": [{"step": 1}]}, "failed": [],
            "_warnings": [],
        },
        "degraded": {
            "matched": True, "rule_id": "jdg.api_fallback.no_match",
            "_degraded_context": True, "_legal_basis": "fallback",
            "_provenance_tree": {"path": [{"step": 1}]}, "failed": [],
            "_warnings": ["DEGRADED_API"],
        },
        "invariant_failure": {
            "matched": True, "rule_id": "jdg.vat.rate_bad", "_legal_basis": "Art. 41 VAT",
            "_provenance_tree": {"path": [{"step": 1}]},
            "failed": ["INV-001"], "_warnings": [],
        },
        "no_match": {
            "matched": False, "rule_id": "jdg.vat.no_match", "_legal_basis": "",
            "_provenance_tree": None, "failed": [], "_warnings": [],
        },
        "requires_interpretation": {
            "matched": True, "rule_id": "jdg.pit.ipbox", "_legal_basis": "Art. 30ca PIT",
            "_provenance_tree": {"path": [{"step": 1}, {"step": 2}]}, "failed": [],
            "_warnings": ["REQUIRES_INTERPRETATION"],
        },
    }
    classified = {k: classify(v) for k, v in samples.items()}

    # Property test: determinizm — 500 powtórzeń klasyfikacji próbki pełnej.
    import random
    rng = random.Random(20260903)
    det_ok = True
    for _ in range(500):
        v = dict(samples["full_evidence"])
        # losowe zaszumienie pól nieistotnych nie zmienia klasy
        v["_cost_ms"] = rng.random() * 10
        v["evaluation_ms"] = int(rng.random() * 100)
        if classify(v)["certainty_class"] != "CERTAIN":
            det_ok = False
            break

    return {
        "innovation": "V3-P03-I02",
        "name": "Certainty Class Engine — zamknięta lista warunków (F4 V2 §5.2)",
        "generated_at": now(),
        "certain_conditions": CERTAIN_CONDITIONS,
        "closed_list": sorted(CERTAIN_CONDITIONS.keys()),
        "samples_classified": classified,
        "auto_post_rule": "AUTO_POST dozwolony WYŁĄCZNIE dla CERTAIN (I11); "
                          "CONDITIONAL/NEEDS_ADVICE → MANUAL_REVIEW/CERTAINTY_BLOCKED (INV-035)",
        "determinism_property_test": {"trials": 500, "deterministic": det_ok},
        "gate": {
            "pass": det_ok and classified["full_evidence"]["certainty_class"] == "CERTAIN"
                    and classified["no_match"]["certainty_class"] == "NEEDS_ADVICE"
                    and classified["degraded"]["certainty_class"] == "NEEDS_ADVICE",
            "rule": "klasa pewności deterministyczna; CERTAIN tylko przy pełnym łańcuchu "
                    "dowodów; no_match/degradacja/invariant → NEEDS_ADVICE (fail-closed)",
        },
        "note": "Silnik odwzorowuje _classify() z runtime_invariants_enterprise.rego "
                "(CERTAIN/CONDITIONAL/NEEDS_ADVICE) — jedno źródło semantyki, testowalne "
                "deterministycznie; próg AUTO_POST wiąże I11.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Certainty Class Engine (V3-P03-I02)")
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
        print(f"V3-P03-I02 Certainty Class: determinizm={data['determinism_property_test']['deterministic']} "
              f"gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: semantyka klasy pewności niezgodna z fail-closed")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())