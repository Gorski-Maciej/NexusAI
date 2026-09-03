#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I07 SCENARIO VERSIONING
=============================================
Obsługa kilku alternatywnych projektów ustaw jednocześnie (scenariusze:
uchwalone / odrzucone / zmienione) z unieważnianiem nieaktualnych wariantów.
Każdy draft w radarze niesie warianty z własnym predicted_diff i zestawem
reguł SHADOW; zmiana statusu unieważnia konkurencyjne scenariusze.

Usage:
  python tools/v3_p08_scenario_versioning.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    radar = json.loads((BUNDLES / "law_radar.json").read_text(encoding="utf-8"))
    drafts = radar.get("drafts", {})

    with_scenarios = sum(1 for d in drafts.values() if d.get("scenarios"))
    with_invalidation = sum(1 for d in drafts.values() if d.get("supersedes"))
    superseded = sum(1 for d in drafts.values() if d.get("superseded_by"))

    checks.append({"name": "scenario_branches", "status": "OK" if with_scenarios else "FAIL",
                   "detail": f"drafty z wariantami: {with_scenarios}/{len(drafts)}"})
    checks.append({"name": "invalidation", "status": "OK" if (with_invalidation or superseded)
                   else "FAIL",
                   "detail": f"unieważnianie wariantów: supersedes={with_invalidation} "
                             f"superseded_by={superseded}"})

    findings.append({"id": "V3-P08-L07", "severity": "P2",
                     "evidence": "law_radar.json przechowuje tylko status pojedynczego draftu "
                                 "(DRL-0001: status DRAFT_LAW, predicted_diff=null); brak pola "
                                 "scenariuszy ani unieważniania — równoległe projekty "
                                 "alternatywne (np. dwie wersje nowelizacji VAT) nie są "
                                 "rozróżnialne",
                     "fix": "I07 Scenario Versioning: draft→[warianty], status per wariant, "
                            "supersedes/superseded_by, predicted_diff per wariant → SHADOW "
                            "per wariant"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I07", "generated_at": now(), "gate": gate,
        "metrics": {"drafts": len(drafts), "with_scenarios": with_scenarios,
                    "invalidation_links": with_invalidation + superseded},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08-I03 (Pre-Life Shadow per wariant), P08-I08 (repeal w "
                                "wariancie), P05 (okna ważności per wariant)",
                     "rule": "draft z N wariantami → N zestawów SHADOW; uchwalenie wariantu A "
                             "unieważnia B i C z wpisem superseded_by"},
    }
    (BUNDLES / "v3_p08_scenario_versioning.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I07] gate={gate} drafts={len(drafts)} "
          f"scenarios={with_scenarios}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
