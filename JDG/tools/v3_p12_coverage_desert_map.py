#!/usr/bin/env python3
"""
NexusAI JDG — V3-P12-I07 VAT COVERAGE DESERT MAP
==================================================
Mapa przepisów bez reguł z planem zasiedlenia priorytetyzowanym kwotowo.
Sprawdza: które artykuły VAT (41, 43, 113, 106b, 90, 91, zał. 10/15) mają
reguły, a które są pustynią; istniejące narzędzia pokrycia.

Usage:
  python tools/v3_p12_coverage_desert_map.py
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

# Kluczowe przepisy VAT z Bbb (zakres P12)
ARTICLES = {
    "art. 41 (stawki)": ["41", "stawk"],
    "art. 43 ust. 1 (zwolnienia przedmiotowe)": ["43", "zwolnien"],
    "art. 113 (limit podmiotowy)": ["113", "limit"],
    "art. 106b (faktura)": ["106b", "faktur"],
    "art. 90/91 (korekty/proporcja)": ["90", "91", "proporc"],
    "zał. 10 (obniżone stawki)": ["zal. 10", "załącznik 10", "zalacznik 10", "plan42"],
    "zał. 15 (MPP/GTU)": ["zal. 15", "załącznik 15", "zalacznik 15", "GTU"],
    "art. 44 (rezygnacja ze zwolnienia)": ["44", "rezygn"],
    "art. 86 (odliczenie)": ["86", "odlicz"],
    "art. 119 (marża)": ["119", "marż"],
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def main() -> int:
    checks, findings = [], []
    hay = "\n".join(f.read_text(encoding="utf-8", errors="ignore")
                    for f in RULES.glob("**/*.rego"))
    tools_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                          for p in TOOLS.glob("*.py"))
    docs_hay = "\n".join(p.read_text(encoding="utf-8", errors="ignore")
                         for p in (BASE / "docs").glob("*.md"))

    # 1. Pokrycie artykułów w regułach (pustynie)
    coverage = {}
    for label, keys in ARTICLES.items():
        # szukaj art X lub ust X w legal_basis/_legal_basis
        art = label.split("(")[0].strip().replace("art. ", "")
        found = False
        for pat in (f"art. {art}", f"art. {art} ust", f"Art. {art}", f"\"_legal_basis\": \"Art. {art}"):
            if pat in hay:
                found = True
                break
        # fallback: klucze słowne
        if not found:
            found = any(k.lower() in hay.lower() for k in keys if not k[0].isdigit() or k in ("90", "91"))
        coverage[label] = found
    deserts = [k for k, v in coverage.items() if not v]
    # 2. Narzędzia pokrycia VAT
    cov_tools = sorted(p.name for p in TOOLS.glob("*.py")
                       if any(k in p.name.lower() for k in ("coverage", "gap", "desert", "heatmap")))
    # 3. Dokument mapy pokrycia
    cov_docs = sorted(p.name for p in (BASE / "docs").glob("*.md")
                      if any(k in p.name.upper() for k in ("COVERAGE", "VAT_AUDYT")))
    # 4. Plan zasiedlenia (priorytety kwotowe)
    has_settlement_plan = any(k in docs_hay for k in ("plan", "priorytet")) and bool(cov_docs)

    checks.append({"name": "coverage_matrix",
                   "status": "OK" if not deserts else "FAIL",
                   "detail": f"przepisy bez reguł (pustynie): {deserts or 'BRAK'}"})
    checks.append({"name": "coverage_tools",
                   "status": "OK" if cov_tools else "FAIL",
                   "detail": f"narzędzia mapy pokrycia: {cov_tools or 'BRAK'}"})
    checks.append({"name": "settlement_plan",
                   "status": "OK" if has_settlement_plan else "FAIL",
                   "detail": f"plan zasiedlenia pustyń: {has_settlement_plan}"})

    if deserts:
        findings.append({"id": "V3-P12-L07", "severity": "P1",
                         "evidence": f"pustynie pokrycia VAT: brak reguł dla {deserts} — "
                                     f"przepisy materialne bez implementacji = cicha luka "
                                     f"(decyzja NEEDS_ADVICE nigdy nie powstanie, bo reguła "
                                     f"nie istnieje); brak planu zasiedlenia priorytetyzowanego "
                                     f"kwotowo",
                         "fix": "I07: VAT Coverage Desert Map — mapa przepis→reguła→test ze "
                                "statusem; pustynie z priorytetem kwotowym i planem "
                                "zasiedlenia (heat map)"})

    gate = "PASS" if all(c["status"] == "OK" for c in checks) else "FAIL"
    bundle = {
        "innovation": "V3-P12-I07", "generated_at": now(), "gate": gate,
        "metrics": {"coverage": coverage, "deserts": deserts,
                    "coverage_tools": cov_tools, "coverage_docs": cov_docs,
                    "settlement_plan": has_settlement_plan},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P44, P39, P01 (coverage legal), P12→domeny",
                     "rule": "każdy przepis materialny VAT ma regułę i test; pustynia = "
                             "jawny wpis z priorytetem i planem (nigdy cicha)"}}
    (BUNDLES / "v3_p12_coverage_desert_map.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P12-I07] gate={gate} deserts={deserts or 'BRAK'}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
