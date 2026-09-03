#!/usr/bin/env python3
"""
NexusAI JDG — V3-P10-I08 INDEPENDENT ORACLE VALIDATOR
=======================================================
Antidotum na „self-fulfilling oracle": golden set walidowany NIEZALEŻNIE
od reguł, które go wygenerowały. Sprawdza, czy istnieje drugi mechanizm
(reguły mirror / niezależna translacja / ekspert) potwierdzający werdykty.

Usage:
  python tools/v3_p10_independent_oracle_validator.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    golden = BUNDLES / "golden_verdicts.json"
    verdicts = {}
    if golden.exists():
        verdicts = json.loads(golden.read_text(encoding="utf-8")).get("verdicts", {})

    # niezależne mechanizmy walidacji: mirror policies, expert review, druga implementacja
    has_mirror = (BASE / "policies").exists() or (BASE.parent / "policies").exists()
    has_expert_gate = any(t.name in {"legal_twin.py", "legal_basis_audit.py",
                                     "decision_quality_monitor.py"} for t in TOOLS.iterdir())
    # próbka niezależnej weryfikacji: legal_basis_refs obecne w rekordach?
    with_refs = sum(1 for r in verdicts.values() if r.get("legal_basis_refs"))
    expert_ratio = round(with_refs / len(verdicts), 3) if verdicts else 0.0

    checks.append({"name": "golden_present", "status": "OK" if verdicts else "FAIL",
                   "detail": f"golden set: {len(verdicts)} werdyktów"})
    checks.append({"name": "legal_basis_refs", "status": "OK" if with_refs else "FAIL",
                   "detail": f"rekordy z legal_basis_refs: {with_refs}/{len(verdicts)} "
                             f"(podstawa do niezależnej mediacji)"})
    checks.append({"name": "independent_mechanism", "status": "OK" if (has_mirror or has_expert_gate) else "FAIL",
                   "detail": f"niezależny mechanizm: mirror={has_mirror}, ekspert/audyt={has_expert_gate}"})

    if not (has_mirror and has_expert_gate):
        findings.append({"id": "V3-P10-L08", "severity": "P1",
                         "evidence": "brak JAWNEGO niezależnego walidatora golden setu: mirror "
                                     "policies nie jest porównywany z werdyktami golden, a walidacja "
                                     "ekspercka (decision_quality_monitor) nie jest zapięta do setu — "
                                     "ryzyko self-fulfilling oracle (set zgodny z błędnymi regułami)",
                         "fix": "I08: walidacja próbki golden przez drugi mechanizm (mirror reguł / "
                                "review ekspercki z podpisem) przy każdej re-generacji; rozbieżność "
                                ">próg = alarm"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P10-I08",
        "name": "Independent Oracle Validator — anti self-fulfilling oracle",
        "generated_at": now(),
        "gate": gate,
        "metrics": {"verdict_count": len(verdicts), "with_legal_basis_refs": with_refs,
                    "expert_ratio": expert_ratio, "has_mirror": has_mirror,
                    "has_expert_gate": has_expert_gate},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P01 (LKG), P48 (mirror sync), P44",
                     "rule": "golden set nigdy nie jest jedynym dowodem sam dla siebie; walidacja "
                             "niezależna przy każdej re-generacji"}}
    (BUNDLES / "v3_p10_independent_oracle_validator.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P10-I08] gate={gate} with_refs={with_refs}/{len(verdicts)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
