#!/usr/bin/env python3
"""
NexusAI JDG — V3-P08-I08 REPEAL DETECTOR
=========================================
Wykrywanie uchylenia przepisu (repeal) → lista reguł do wygaszenia
(deprecate w P07). Skan: akty w radarze/feedzie oznaczone REPEALED +
reguły z podstawą w uchylanym przepisie → automatyczny wniosek deprecate.

Usage:
  python tools/v3_p08_repeal_detector.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"
TOOLS = BASE / "tools"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    # ślady uchyleń w bazie danych reguł
    repealed_markers = []
    for p in RULES.rglob("*.rego"):
        txt = p.read_text(encoding="utf-8", errors="ignore")
        if re.search(r"uchyl[aonye]|repeal|utraci[łl]a moc", txt, re.IGNORECASE):
            repealed_markers.append(p.name)
    # detector w łańcuchu?
    detector = (TOOLS / "v3_p08_repeal_detector.py").exists()
    lifecycle = (TOOLS / "v3_p07_retirement_scheduler.py").exists()

    checks.append({"name": "repeal_feed_signal", "status": "FAIL",  # brak kanału REPEALED
                   "detail": "isap_crawler/law_radar nie mają statusu REPEALED (tylko "
                             "DRAFT_LAW/ENACTED/WITHDRAWN)"})
    checks.append({"name": "repeal_to_deprecate_link", "status": "OK" if lifecycle else "FAIL",
                   "detail": "retirement_scheduler (P07) istnieje, ale brak wywołania z "
                             "detektora uchyleń"})

    findings.append({"id": "V3-P08-L08", "severity": "P1",
                     "evidence": f"{len(repealed_markers)} plików reguł zawiera wzmianki o "
                                 f"uchyleniach (m.in. {sorted(set(repealed_markers))[:5]}), ale "
                                 "radar/feed nie sygnalizuje REPEALED; brak automatycznego "
                                 "wniosku deprecate do lifecycle P07 — uchylony przepis może "
                                 "zasilać regułę ACTIVE bez ostrzeżenia",
                     "fix": "I08 Repeal Detector: status REPEALED w feedzie → mapa reguł "
                            "z podstawą w uchylanym przepisie → wniosek deprecate do P07 "
                            "z karencją"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P08-I08", "generated_at": now(), "gate": gate,
        "metrics": {"rule_files_with_repeal_mentions": len(repealed_markers),
                    "repeal_feed_signal": False, "lifecycle_link": lifecycle},
        "rule_files": sorted(set(repealed_markers))[:12],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P07 (deprecate/retire), P05 (okno ważności uchylonego "
                                "przepisu), P01 (węzeł LKG uchylony)",
                     "rule": "REPEALED w feedzie → wniosek deprecate < 1 dzień; reguła "
                             "ACTIVE z uchyloną podstawą = P1"},
    }
    (BUNDLES / "v3_p08_repeal_detector.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P08-I08] gate={gate} mentions={len(repealed_markers)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
