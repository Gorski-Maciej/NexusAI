#!/usr/bin/env python3
"""V3 campaign gate — verifies the 20-part enterprise campaign completion.

Checks:
  1. All 21 prompt files exist (00_PULS_STARTU + 01..20) in prompty_enterprise_v3/.
  2. Registry bundles/enterprise_v3_registry.json is valid JSON with 20-part map.
  3. Every part registered as stan in (wdrozone, zweryfikowane) has its report
     TXT present at raporty_enterprise_v3/NN_NAZWA.txt.
  4. Summary counters are consistent (czesc_wykonanych == len(czesci)).
  5. Final status: WDROZONY_100 when all 20 parts are zweryfikowane.

Uruchomienie:  python3 JDG/tools/v3_campaign_gate.py [--json] [--write]
Test:          pytest -q JDG/tests/auto/test_v3_campaign_gate.py
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
PROMPTS_DIR = BASE_DIR / "prompty_enterprise_v3"
REPORTS_DIR = BASE_DIR / "raporty_enterprise_v3"
REGISTRY = BASE_DIR / "bundles" / "enterprise_v3_registry.json"
EVIDENCE = BASE_DIR / "bundles" / "v3_campaign_gate_evidence.json"

NUM_PARTS = 20
FINAL_STATUS = "WDROZONY_100"


def build_evidence() -> dict[str, Any]:
    checks: dict[str, Any] = {}

    # 1. Prompts present (00 + 01..20)
    prompt_files = sorted(PROMPTS_DIR.glob("*.txt"))
    expected = {f"{n:02d}_" for n in range(0, NUM_PARTS + 1)}
    prompts_have_prefix = {p.name[:3] for p in prompt_files if re.match(r"\d\d_", p.name)}
    checks["prompts_present"] = prompts_have_prefix >= expected

    # 2. Registry valid
    registry = {}
    registry_valid = False
    if REGISTRY.exists():
        try:
            registry = json.loads(REGISTRY.read_text(encoding="utf-8"))
            registry_valid = (
                "mapa_czesci" in registry
                and len(registry["mapa_czesci"]) == NUM_PARTS
                and isinstance(registry.get("czesci"), dict)
            )
        except json.JSONDecodeError:
            registry_valid = False
    checks["registry_valid"] = registry_valid

    parts = registry.get("czesci", {}) if registry_valid else {}
    done_states = {"wdrozone", "zweryfikowane"}

    # 3. reports for completed parts
    missing_reports: list[str] = []
    for num in sorted(parts, key=int):
        blok = parts[num]
        if blok.get("stan") in done_states:
            rep = blok.get("raport_txt", "")
            if not rep or not (BASE_DIR / rep).exists():
                missing_reports.append(f"{num}:{rep}")
    checks["reports_for_completed_present"] = not missing_reports
    checks["missing_reports"] = missing_reports

    # 4. summary consistency
    summary = registry.get("podsumowanie", {}) if registry_valid else {}
    checks["summary_consistent"] = (
        int(summary.get("czesc_wykonanych", 0)) == len(parts)
        and int(summary.get("czesc_do_zrobienia", NUM_PARTS)) == NUM_PARTS
    )

    # 5. final status
    all_verified = len(parts) == NUM_PARTS and all(
        p.get("stan") == "zweryfikowane" for p in parts.values()
    )
    status = FINAL_STATUS if all_verified else "W_TRAKCIE_KAMPANII"

    gates = {
        "prompts_present": checks["prompts_present"],
        "registry_valid": checks["registry_valid"],
        "reports_for_completed_present": checks["reports_for_completed_present"],
        "summary_consistent": checks["summary_consistent"],
        "all_20_parts_zweryfikowane": all_verified,
    }
    passed = sum(1 for v in gates.values() if v)
    return {
        "schema_version": "1.0.0",
        "report": "V3_CAMPAIGN_GATE",
        "status": status,
        "gates": gates,
        "gate_summary": f"{passed}/{len(gates)}",
        "parts_done": len(parts),
        "parts_total": NUM_PARTS,
        "missing_reports": missing_reports,
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="V3 campaign gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
        EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Expectation: {EVIDENCE.name} ({evidence['status']})")

    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        print(f"V3 CAMPAIGN: {evidence['status']} ({evidence['gate_summary']} bramek)")
        for name, ok in evidence["gates"].items():
            icon = "OK" if ok else "FAIL"
            print(f"  [{icon}] {name}")
        if evidence["missing_reports"]:
            print("  brak raportów:", ", ".join(evidence["missing_reports"]))
    return 0 if evidence["status"] == FINAL_STATUS else 1


if __name__ == "__main__":
    sys.exit(main())