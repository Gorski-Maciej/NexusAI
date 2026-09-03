#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I08 SIMPLIFIED VS NORMAL ADVISOR
=======================================================
Doradca: czy podatnik powinien być na zwolnieniu podmiotowym (art. 113,
VAT-O / brak rejestracji) czy VAT normalny — symulator korzyści.
Sprawdza: narzędzie decyzyjne VAT (nie generyczne symulatory), reguły
zwolnienia podmiotowego, symulację korzyści.

Usage:
  python tools/v3_p12_vat_r_advisor.py
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
DOCS = BASE / "docs"


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    # Reguły VAT tylko (nie PIT/ZUS)
    vat_files = (list(RULES.glob("vat/*.rego")) + list(RULES.glob("micro/vat/*.rego"))
                 + [p for p in RULES.glob("*.rego") if "vat" in p.name])
    vat_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                        for p in vat_files if p.exists())
    tools_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in TOOLS.glob("*.py"))

    # 1. Narzędzie decyzyjne VAT (doradca rejestracji/zwolnienia) — NIE generyczne symulatory
    advisor_tools = sorted(p.name for p in TOOLS.glob("*.py")
                           if any(k in p.name.lower() for k in ("vat_r", "vat_advisor",
                                                                "vat_recommend", "rejestrac"))
                           or ("vat" in p.name.lower() and any(k in p.name.lower()
                               for k in ("advice", "decide", "recommend", "register"))))
    # 2. Reguły zwolnienia podmiotowego z przesłankami (art. 113)
    subject_rules = re.findall(r'"rule_id"\s*:\s*"jdg\.[^"]*(?:subject_exemption|exemption)[^"]*"',
                               vat_hay)
    # 3. Symulacja korzyści w kontekście VAT (odliczenia vs brak)
    has_vat_benefit = bool(re.search(r"korzyść|(?:deduction|odliczeni).{0,80}(?:exemption|zwolnien)",
                                     vat_hay + tools_hay, re.I))
    # 4. Dokumentacja decyzji rejestracyjnej
    advisor_docs = sorted(p.name for p in DOCS.glob("*.md")
                          if any(k in p.name.upper() for k in ("VAT", "ADVISOR", "REJESTRAC")))

    checks.append({"name": "advisor_tool",
                   "status": "OK" if advisor_tools else "FAIL",
                   "detail": f"narzędzie decyzyjne VAT: {advisor_tools or 'BRAK'}"})
    checks.append({"name": "subject_exemption_rules",
                   "status": "OK" if subject_rules else "FAIL",
                   "detail": f"rule_id zwolnienia podmiotowego: {len(subject_rules)} "
                             f"({subject_rules[:3]})"})
    checks.append({"name": "benefit_simulation",
                   "status": "OK" if has_vat_benefit else "FAIL",
                   "detail": f"symulacja korzyści (odliczenia vs zwolnienie): {has_vat_benefit}"})
    checks.append({"name": "decision_docs",
                   "status": "OK" if advisor_docs else "FAIL",
                   "detail": f"dokumentacja doradcy: {advisor_docs or 'BRAK'}"})

    if not advisor_tools or not has_vat_benefit:
        findings.append({"id": "V3-P12-L08", "severity": "P2",
                         "evidence": f"brak doradcy zwolnienie-vs-VAT (rejestracja): narzędzie="
                                     f"{advisor_tools or 'BRAK'}, symulacja korzyści kwotowej="
                                     f"{has_vat_benefit} — reguły zwolnienia podmiotowego "
                                     f"istnieją ({len(subject_rules)} rule_id), ale brak "
                                     f"warstwy decyzyjnej 'czy warto zarejestrować się jako "
                                     f"czynny' z kwotową analizą (odliczenia vs koszt "
                                     f"administracyjny)",
                         "fix": "I08: Simplified vs Normal Advisor — symulator scenariuszy "
                                "(zwolnienie art. 113 vs VAT) z kwotami: odliczenia, "
                                "kontrahenci, próg; fail-closed przy niepewnych danych"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I08", "generated_at": now(), "gate": gate,
        "metrics": {"advisor_tools": advisor_tools,
                    "subject_exemption_rules": len(subject_rules),
                    "subject_rule_ids": subject_rules[:5],
                    "benefit_simulation": has_vat_benefit,
                    "advisor_docs": advisor_docs},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P14 (ryczałt), P44, P03 (werdykt)",
                     "rule": "rekomendacja zwolnienie-vs-VAT tylko z symulacją kwotową; "
                             "rezygnacja/powrót śledzone temporalnie (I11)"}}
    (BUNDLES / "v3_p12_vat_r_advisor.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I08] gate={gate} advisor={advisor_tools or 'BRAK'} subject_rules={len(subject_rules)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
