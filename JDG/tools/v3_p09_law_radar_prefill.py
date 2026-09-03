#!/usr/bin/env python3
"""
NexusAI JDG — V3-P09-I08 LAW RADAR PREFILL
===========================================
Deklaracje pre-wypełnione z diffów prawnych (P08): projekt ustawy → diff →
pre-deklaracja, którą prawnik potwierdza, nie pisze od zera. Brak diffu =
brak prefillu (deklaracja ręczna).

Usage:
  python tools/v3_p09_law_radar_prefill.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def prefill_from_diff(diff: dict) -> dict | None:
    """Mapuje diff prawny (schema P08-I02) na pre-deklarację."""
    if not diff or not diff.get("change_type"):
        return None
    return {
        "prefilled": True,
        "change_type": diff.get("change_type"),
        "target": {"kind": "parameter", "key": "<key z recipes>"},
        "legal_basis": {"act": diff.get("act"), "article": diff.get("legal_unit")},
        "source_diff": diff.get("diff_id"),
        "old_text": diff.get("old_text"), "new_text": diff.get("new_text"),
        "effective_from": diff.get("effective_from"),
        "status": "AWAITS_LAWYER_CONFIRM",
    }


def main() -> int:
    checks, findings = [], []
    radar = json.loads((BUNDLES / "law_radar.json").read_text(encoding="utf-8"))
    drafts = radar.get("drafts", {})
    diffs_available = sum(1 for d in drafts.values() if d.get("predicted_diff"))
    # diff schema P08 istnieje?
    diff_schema = (BUNDLES / "v3_p08_legal_diff_schema.json").exists()

    prefill_demo = prefill_from_diff({
        "diff_id": "D-2026-0001", "act": "Ustawa o VAT",
        "legal_unit": "art. 113 ust. 1", "change_type": "AMEND_VALUE",
        "old_text": "1 200 000 EUR", "new_text": "2 000 000 EUR",
        "effective_from": "2027-01-01"})

    checks.append({"name": "diff_source", "status": "FAIL" if not diffs_available else "OK",
                   "detail": f"drafty z predicted_diff: {diffs_available}/{len(drafts)} — brak "
                             "źródła do prefillu"})
    checks.append({"name": "prefill_demo", "status": "OK" if prefill_demo else "FAIL",
                   "detail": "prefill z diffa działa (demo D-2026-0001 → pre-deklaracja)"})
    checks.append({"name": "wired_pipeline", "status": "FAIL",
                   "detail": "brak automatycznego prefillu deklaracji z pipeline'u prawa (P08)"})

    findings.append({"id": "V3-P09-L08", "severity": "P2",
                     "evidence": "law_radar.json zawiera 1 draft (DRL-0001) bez "
                                 "predicted_diff; schema diffu (P08-I02) istnieje, ale żaden "
                                 "krok nie generuje pre-deklaracji z diffa — prawnik pisze "
                                 "deklarację od zera, zamiast potwierdzać prefill",
                     "fix": "I08 Law Radar Prefill: diff (P08) → pre-deklaracja wg recipes "
                            "→ status AWAITS_LAWYER_CONFIRM; potwierdzenie = deklaracja "
                            "oficjalna"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P09-I08", "generated_at": now(), "gate": gate,
        "metrics": {"drafts": len(drafts), "with_diff": diffs_available,
                    "diff_schema_exists": diff_schema},
        "prefill_demo": prefill_demo,
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08 (Law Radar diff), P09-I02 (kompilacja prefillu), "
                                "P01 (LKG)",
                     "rule": "ENACTED z diffem → pre-deklaracja w < 1 dzień; prefill bez "
                             "potwierdzenia prawnika nie wykonuje"}}
    (BUNDLES / "v3_p09_law_radar_prefill.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P09-I08] gate={gate} drafts={len(drafts)} with_diff={diffs_available}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
