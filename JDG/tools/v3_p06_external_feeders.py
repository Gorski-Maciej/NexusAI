#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I06 EXTERNAL RATE FEEDERS
==============================================
Rejestr parametrów pochodzących ze źródeł zewnętrznych (minimalne/przeciętne
wynagrodzenie, kursy NBP, wskaźniki) z walidacją i audytem. Lokalizuje wartości
w warstwie danych (thresholds_jdg.rego) i ocenia ścieżkę aktualizacji.

Źródła zewnętrzne są poza sesją → status [NIEZWERYFIKOWANE] (klauzula promptu);
rejestr mediacji do P08/P12.

Usage:
  python tools/v3_p06_external_feeders.py
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"

# Słowa kluczowe parametrów zależnych od źródeł zewnętrznych
EXTERNAL_HINTS = ["minimum_wage", "minimalne", "przecietne", "average", "avg_wage",
                  "kurs", "rate_eur", "eur_pln", "exchange", "nbp", "limit_30",
                  "trzydziestokrotnosc", "wskaznik", "index"]


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    t = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    # przeszukaj wszystkie mapy w poszukiwaniu kluczy zewnętrznych
    external = []
    for p in sorted(RULES.rglob("*.rego")):
        rel = str(p.relative_to(RULES))
        tt = p.read_text(encoding="utf-8")
        for i, line in enumerate(tt.splitlines(), 1):
            low = line.lower()
            if any(h in low for h in EXTERNAL_HINTS):
                m = re.search(r'"([A-Za-z0-9_]+)"\s*:\s*(\-?\d+(?:\.\d+)?)', line)
                if m:
                    external.append({"file": rel, "line": i, "key": m.group(1),
                                     "value": m.group(2), "ctx": line.strip()[:90]})
    # poszukiwanie w thresholds_jdg.rego liściach
    t2 = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    ext_leafs = []
    for k, v in re.findall(r'^\s{4}"([A-Za-z0-9_]+)"\s*:\s*(\-?\d+(?:\.\d+)?)', t2, re.M):
        if any(h in k.lower() for h in EXTERNAL_HINTS):
            ext_leafs.append({"key": k, "value": v})

    checks.append({"name": "external_params_registry",
                   "status": "OK",
                   "detail": f"kandydujące parametry zewnętrzne: {len(ext_leafs)} liści w warstwie "
                             f"danych + {len(external)} trafień w regułach"})
    checks.append({"name": "feeder_path",
                   "status": "FAIL",
                   "detail": "brak mechanizmu feedu (żadnego importera NBP/MRPiPS/ZUS w tools/) — "
                             "wartości wprowadzane ręcznie/systemowo"})
    checks.append({"name": "source_verification",
                   "status": "WARN",
                   "detail": "źródła zewnętrzne [NIEZWERYFIKOWANE] — poza sesją (klauzula promptu)"})

    findings.append({"id": "V3-P06-L11", "severity": "P2",
                     "evidence": f"parametry zależne od źródeł zewnętrznych bez feedera: "
                                 f"{[e['key'] for e in ext_leafs][:10]}... (wartości ręczne, "
                                 f"ryzyko dezaktualizacji)",
                     "fix": "feedery NBP (kursy), MRPiPS (minimalne/przeciętne), ZUS (limity) "
                            "z walidacją zakresu i audytem zmiany (P06-I06 kontrakt), status "
                            "źródła w I09"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I06", "generated_at": now(), "gate": gate,
        "metrics": {"external_leafs": len(ext_leafs), "rule_hits": len(external)},
        "external_leafs": ext_leafs[:20],
        "checks": checks, "findings": findings,
        "contract": {"binding": "P08 (Law Radar — publikacje), P12–P36 domenowe, P37 (metryki "
                                "świeżości), P06-I09 (freshness)",
                     "feeders": {"nbp": "kursy walut (EUR/PLN) — codziennie",
                                 "mrpiPS": "minimalne wynagrodzenie — corocznie (obwieszczenie)",
                                 "zus": "limit 30-krotności, prognozowane przeciętne — corocznie"},
                     "rule": "wartość z feedera bez wpisu audytowego = odrzucenie (fail-closed)"},
    }
    (BUNDLES / "v3_p06_external_feeders.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I06] gate={gate} external_leafs={len(ext_leafs)} "
          f"rule_hits={len(external)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
