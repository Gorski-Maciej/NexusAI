#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I02 EXEMPTION MATRIX COMPLETE
===================================================
Pełna macierz zwolnień art. 43 (lit. a-z) z warunkami parametryzowanymi i
testami. Sprawdza: czy zwolnienia przedmiotowe art. 43 mają reguły, czy ich
warunki są parametryzowane (data.thresholds) i czy istnieją testy zwolnień.

Usage:
  python tools/v3_p12_exemption_matrix.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    # Reguły VAT (macro + micro + enterprise) — tylko pliki VAT, nie PIT
    vat_files = (list(RULES.glob("vat/*.rego")) + list(RULES.glob("micro/vat/*.rego"))
                 + [p for p in RULES.glob("*.rego") if "vat" in p.name])
    vat_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                        for p in vat_files if p.exists())

    # 1. Zwolnienia przedmiotowe: ile wzmianek o "43" z "zwolnien" w plikach VAT
    art43_mentions = len(re.findall(r"(?:art\.?\s*43|43\s*ust\.?\s*1).{0,60}zwolnien|"
                                    r"zwolnien.{0,60}(?:art\.?\s*43|43\s*ust)", vat_hay, re.I))
    # 2. Reguły zwolnień przedmiotowych (rule_id z vat_ i zwolnieniem)
    exemption_rule_ids = re.findall(r'"rule_id"\s*:\s*"jdg\.[^"]*(?:exempt|zwoln|43)[^"]*"',
                                    vat_hay)
    # 3. Warunki parametryzowane (data.thresholds)
    params = json.loads((BUNDLES / "thresholds_data.json").read_text(encoding="utf-8")).get("parameters", {})
    exemption_params = {k: v for k, v in params.items()
                        if "43" in k or "exemption" in k or "zwoln" in k or "80" in str(v)}
    # 4. Testy zwolnień
    tests = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                      for p in (BASE / "tests").glob("*.py"))
    has_exemption_tests = bool(re.search(r"exemption|zwolnien", tests, re.I))
    # 5. Znane obszary art. 43 w regułach (fakty z kodu)
    known_areas = {
        "rolnictwo (43 ust.1 pkt f)": bool(re.search(r"roln", vat_hay, re.I)),
        "finanse/ubezpieczenia (pkt g-h)": bool(re.search(r"ubezpiecz|finans", vat_hay, re.I)),
        "medycyna/leki": bool(re.search(r"lek\b|medycz", vat_hay, re.I)),
        "edukacja": bool(re.search(r"edukac|szkoł", vat_hay, re.I)),
        "nieruchomości (pkt 7/8)": bool(re.search(r"nieruchom|80\s*m2", vat_hay, re.I)),
    }

    checks.append({"name": "art43_rules",
                   "status": "OK" if len(exemption_rule_ids) >= 5 else "FAIL",
                   "detail": f"rule_id zwolnień w plikach VAT: {len(exemption_rule_ids)} "
                             f"(wzmianki art.43+zwolnienie: {art43_mentions})"})
    checks.append({"name": "conditions_as_data",
                   "status": "OK" if exemption_params else "FAIL",
                   "detail": f"warunki zwolnień jako parametry data.thresholds: "
                             f"{exemption_params or 'BRAK'}"})
    checks.append({"name": "exemption_tests",
                   "status": "OK" if has_exemption_tests else "FAIL",
                   "detail": f"testy zwolnień w pytest: {has_exemption_tests}"})

    if len(exemption_rule_ids) < 5 or not exemption_params:
        findings.append({"id": "V3-P12-L02", "severity": "P1",
                         "evidence": f"macierz zwolnień art. 43 niekompletna jako struktura: "
                                     f"{len(exemption_rule_ids)} rule_id zwolnień w plikach VAT "
                                     f"(macro+micro), 0 warunków zwolnień w data.thresholds "
                                     f"(ADR-002/P06) — warunki (limity, powierzchnie, kwoty) "
                                     f"siedzą w treści reguł; testy zwolnień: {has_exemption_tests}; "
                                     f"obszary w regułach: {known_areas}",
                         "fix": "I02: Exemption Matrix — macierz art. 43: zwolnienie → warunki "
                                "jako parametry → reguła → test; brak parametryzacji = "
                                "hardcode do migracji (I01)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I02", "generated_at": now(), "gate": gate,
        "metrics": {"exemption_rule_ids": len(exemption_rule_ids),
                    "art43_mentions": art43_mentions,
                    "exemption_params": exemption_params,
                    "known_areas": known_areas,
                    "exemption_tests": has_exemption_tests},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P06 (parametry), P12→P44, P03 (werdykt)",
                     "rule": "każde zwolnienie art. 43 = wiersz macierzy z parametrami, "
                             "regułą i testem; brak parametryzacji = luka P1"}}
    (BUNDLES / "v3_p12_exemption_matrix.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I02] gate={gate} rule_ids={len(exemption_rule_ids)} params={len(exemption_params)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
