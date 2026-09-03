#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I03 GTU SEMANTIC CLASSIFIER
===================================================
Klasyfikacja GTU z mapy PKWiU/CN jako dane + NEEDS_ADVICE przy niepewności.
Sprawdza: pokrycie GTU_01..GTU_13 (zał. 15), czy mapa GTU→PKWiU/CN jest daną,
czy reguły zwracają NEEDS_ADVICE przy niejednoznaczności (fail-closed).

Usage:
  python tools/v3_p12_gtu_semantic_classifier.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"

GTU_CODES = [f"GTU_{i:02d}" for i in range(1, 14)]  # GTU_01..GTU_13


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    hay_files = list(RULES.glob("**/*.rego"))
    hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore") for f in hay_files)
    tools_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in (BASE / "tools").glob("*.py"))

    # 1. Pokrycie GTU_01..GTU_13
    covered = {g: (g in hay) for g in GTU_CODES}
    covered_count = sum(covered.values())
    # 2. Mapa GTU→PKWiU/CN jako dane (bundle/json) czy hardcode w rego?
    gtu_data_files = sorted(p.name for p in BUNDLES.glob("*.json")
                            if "gtu" in p.name.lower())
    has_gtu_data = bool(gtu_data_files)
    # 3. Fail-closed: NEEDS_ADVICE przy niejednoznacznej klasyfikacji
    needs_advice = hay.count("NEEDS_ADVICE") + hay.count("needs_advice")
    gtu_needs_advice = bool(re.search(r"gtu.*(needs_advice|manual)", hay, re.I))
    # 4. Czy narzędzie GTU istnieje (auto-klasyfikacja)
    gtu_tools = sorted(p.name for p in (BASE / "tools").glob("*.py")
                       if "gtu" in p.name.lower())

    checks.append({"name": "gtu_coverage",
                   "status": "OK" if covered_count >= 13 else "FAIL",
                   "detail": f"GTU_01..GTU_13 w regułach: {covered_count}/13 "
                             f"(brak: {[g for g, c in covered.items() if not c]})"})
    checks.append({"name": "gtu_map_as_data",
                   "status": "OK" if has_gtu_data else "FAIL",
                   "detail": f"mapa GTU→PKWiU/CN jako dane: {gtu_data_files or 'BRAK'}"})
    checks.append({"name": "fail_closed_classification",
                   "status": "OK" if (needs_advice > 0 and gtu_needs_advice) else "FAIL",
                   "detail": f"NEEDS_ADVICE w regułach GTU: {gtu_needs_advice} (łącznie "
                             f"NEEDS_ADVICE: {needs_advice})"})
    checks.append({"name": "gtu_tooling",
                   "status": "OK" if (gtu_tools or covered_count == 13) else "FAIL",
                   "detail": f"narzędzia GTU: {gtu_tools or 'BRAK — reguły wprost'}"})

    if covered_count < 13:
        findings.append({"id": "V3-P12-L03", "severity": "P1",
                         "evidence": f"pokrycie GTU: {covered_count}/13 kodów w regułach "
                                     f"(brak: {[g for g, c in covered.items() if not c]}); "
                                     f"brak mapy GTU→PKWiU/CN jako danych (bundle) — mapa siedzi "
                                     f"w regułach; klasyfikacja bez NEEDS_ADVICE przy "
                                     f"niejednoznaczności = ryzyko cichego błędnego GTU",
                         "fix": "I03: GTU Semantic Classifier — mapa GTU→PKWiU/CN jako dane "
                                "z wersją; niska pewność klasyfikacji → NEEDS_ADVICE "
                                "(fail-closed)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I03", "generated_at": now(), "gate": gate,
        "metrics": {"gtu_covered": covered_count, "gtu_total": 13,
                    "missing_gtu": [g for g, c in covered.items() if not c],
                    "gtu_data_files": gtu_data_files, "needs_advice_hits": needs_advice,
                    "gtu_tools": gtu_tools},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P16 (JPK/KSeF — pola GTU), P03 (werdykt), P44",
                     "rule": "każdy GTU ma regułę; mapa PKWiU/CN→GTU jako dane; "
                             "niejednoznaczność = NEEDS_ADVICE (nigdy cichy wybór)"}}
    (BUNDLES / "v3_p12_gtu_semantic_classifier.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I03] gate={gate} gtu={covered_count}/13 needs_advice={gtu_needs_advice}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
