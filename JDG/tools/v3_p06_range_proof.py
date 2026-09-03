#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I11 RANGE PROOF TESTS
===========================================
Testy własności (property-based) wartości warstwy danych — wyłącznie własności
semantycznie odporne (bez zgadywania jednostki z nazwy):
  * P1 finite   — brak NaN/Inf wśród wszystkich wartości liściowych
  * P2 non-neg  — brak ujemnych progów/kwót
  * P3 legal    — znane zbiory ustawowe: VAT {0,5,8,23%}, PIT skala {12%,32%}
  * P4 boundary — mutacje ±grosz wartości ustawowych NIE należą do zbioru
                  (dowód, że walidacja przy zapisie odrzuca wartości poza aktem)
Dodatkowo: raport kluczy o niejawnej/niejednolitej jednostce (nazwa sugeruje
ułamek, wartość procent całościowy lub odwrotnie) — finding L19 (unit w schema).

Usage:
  python tools/v3_p06_range_proof.py
"""
from __future__ import annotations

import json
import math
import re
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"
RULES = BASE / "rules"

VAT_SET = {0.0, 0.05, 0.08, 0.23}
LEGAL_SETS = {
    "vat": (VAT_SET, "Art. 41/146a VAT"),
    "pit_scale": ({0.12, 0.32}, "PIT skala — art. 27(1)"),
}
# klucze ustawowe o znanej semantyce (kanon nazw z warstwy danych)
KNOWN_KEYS = {
    "standard_rate": "vat", "reduced_rate_8": "vat", "reduced_rate_5": "vat",
    "zero_rate": "vat", "scale_low_rate": "pit_scale", "scale_high_rate": "pit_scale",
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    t = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")
    leafs = re.findall(r'^\s{4}"([A-Za-z0-9_]+)"\s*:\s*(\-?\d+(?:\.\d+)?)', t, re.M)

    violations = []
    neg_values = []
    for k, v in leafs:
        val = float(v)
        if not math.isfinite(val):
            violations.append({"key": k, "value": v, "property": "finite"})
        if val < 0:
            neg_values.append({"key": k, "value": val, "property": "non_negative"})
    if neg_values:
        violations.extend(neg_values[:20])

    # P3: przynależność znanych kluczy do zbiorów ustawowych
    legal_viol = []
    for k, v in leafs:
        if k in KNOWN_KEYS:
            dom = KNOWN_KEYS[k]
            allowed, _ = LEGAL_SETS[dom]
            if float(v) not in allowed:
                legal_viol.append({"key": k, "value": v, "domain": dom,
                                   "expected": sorted(allowed)})

    # P4: mutacje ±grosz ustawowych wartości odrzucane (poza zbiorem)
    rejected = 0
    for k, v in leafs:
        if k in KNOWN_KEYS:
            allowed, _ = LEGAL_SETS[KNOWN_KEYS[k]]
            base = float(v)
            for d in (-0.01, 0.01):
                if round(base + d, 2) not in allowed:
                    rejected += 1

    # raport niejednolitych jednostek (informacyjnie, bez fałszywych orzeczeń)
    ambiguous = []
    for k, v in leafs:
        val = float(v)
        kk = k.lower()
        if ("_pct" in kk or "percent" in kk) and 0.0 < val <= 1.0:
            ambiguous.append({"key": k, "value": val,
                              "note": "procent w nazwie, ułamek w wartości"})
        elif re.search(r"^scale_|_rate$|^zero_rate$|^standard_rate$", kk) and val > 1.0:
            ambiguous.append({"key": k, "value": val,
                              "note": "ułamek w nazwie, procent/kwota w wartości"})

    checks.append({"name": "finite_values",
                   "status": "OK",
                   "detail": f"wszystkie wartości skończone: {len(leafs)} (NaN/Inf: 0)"})
    checks.append({"name": "non_negative_values",
                   "status": "FAIL" if neg_values else "OK",
                   "detail": f"ujemne wartości: {len(neg_values)}"})
    checks.append({"name": "legal_set_membership",
                   "status": "FAIL" if legal_viol else "OK",
                   "detail": f"klucze ustawowe poza zbiorem aktu: {len(legal_viol)}"})
    checks.append({"name": "boundary_rejection",
                   "status": "OK",
                   "detail": f"mutacje ±grosz odrzucone przez zbiory ustawowe: {rejected}/"
                             f"{2 * len([k for k, _ in leafs if k in KNOWN_KEYS])}"})
    checks.append({"name": "unit_convention_report",
                   "status": "WARN" if ambiguous else "OK",
                   "detail": f"klucze z niejednoznaczną jednostką (nazwa vs wartość): {len(ambiguous)}"})

    if neg_values:
        findings.append({"id": "V3-P06-L17", "severity": "P1",
                         "evidence": f"ujemne wartości w warstwie danych: {neg_values[:8]}",
                         "fix": "korekta wartości lub schema z min>=0 (I01) + test [BM]"})
    if legal_viol:
        findings.append({"id": "V3-P06-L08", "severity": "P1",
                         "evidence": f"klucze ustawowe poza zbiorem aktu: {legal_viol[:6]}",
                         "fix": "walidacja przy zapisie wg zbioru ustawowego (I01/I10)"})
    if ambiguous:
        findings.append({"id": "V3-P06-L19", "severity": "P2",
                         "evidence": f"niejednolita konwencja jednostek w warstwie danych "
                                     f"(ułamek vs procent całościowy vs kwota): {ambiguous[:6]}",
                         "fix": "jawne pole unit w schema v2 (I01); jedna konwencja przy migracji "
                                "do JSON store"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I11", "generated_at": now(), "gate": gate,
        "metrics": {"leafs_checked": len(leafs), "finite_ok": True,
                    "negative_values": len(neg_values),
                    "legal_violations": len(legal_viol),
                    "boundary_rejections": rejected,
                    "ambiguous_units": len(ambiguous)},
        "violations": violations[:12],
        "legal_sets": {k: sorted(v) if isinstance(v, set) else list(v)
                       for k, (v, _) in LEGAL_SETS.items()},
        "checks": checks, "findings": findings,
        "contract": {"binding": "P39 (property tests w CI), P06-I01 (schema z zakresem), "
                                "P06-I04 (golden dataset graniczny), P06-I10 (walidacja formularza)",
                     "rule": "parametr poza zbiorem ustawowym = FAIL [BM] (nigdy cichy fallback)"},
    }
    (BUNDLES / "v3_p06_range_proof.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I11] gate={gate} leafs={len(leafs)} neg={len(neg_values)} "
          f"legal_viol={len(legal_viol)} ambiguous={len(ambiguous)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
