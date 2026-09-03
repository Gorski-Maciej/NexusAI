#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I07 CONTEXTUAL PARAMETER MAPS
==================================================
Parametry kontekstowe (per gmina/PKD/sektor) bez eksplozji liczby kluczy:
spójne przestrzenie nazw namespace.context.code — walidacja istnienia kodu
kontekstu (gmina TERYT, PKD) i obecności wartości domyślnej (fallback).

Ustawa o podatkach i opłatach lokalnych (art. 5 — stawki gminne w granicach
ustawowych) jako przypadek użycia: limit gminny może być parametrem z walidacją
zakresu ustawowego (P06-AN09).

Usage:
  python tools/v3_p06_contextual_maps.py
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
    return datetime.now(timezone.utc).isoformat()


def main() -> int:
    checks, findings = [], []
    t = (RULES / "thresholds_jdg.rego").read_text(encoding="utf-8")

    # istniejące mapy kontekstowe: local_taxes / pcc_local_excise / environmental
    maps = re.findall(r'^([a-z][a-z0-9_]*)\s*:?=\s*\{', t, re.M)
    ctx_maps = sorted(m for m in maps if any(s in m for s in ("local", "gmina", "pcc")))
    # użycia local_taxes w regułach
    uses = {}
    for p in sorted(RULES.rglob("*.rego")):
        tt = p.read_text(encoding="utf-8")
        for m in re.finditer(r"data\.thresholds\.jdg\.([A-Za-z0-9_]+)", tt):
            if m.group(1) in ctx_maps or m.group(1) in ("local_taxes",):
                uses.setdefault(m.group(1), set()).add(str(p.relative_to(RULES)))

    # czy w warstwie danych istnieje klucz z kodem kontekstu (np. "pl.teryt.xxx")
    ctx_keys = re.findall(r'^\s{4}"([A-Za-z0-9_]*(?:teryt|gmina|pkd|kod)[A-Za-z0-9_]*)"', t, re.M)

    checks.append({"name": "contextual_maps_exist",
                   "status": "OK" if ctx_maps else "WARN",
                   "detail": f"mapy kontekstowe w warstwie danych: {ctx_maps or 'BRAK'}"})
    checks.append({"name": "context_codes_validated",
                   "status": "FAIL",
                   "detail": "brak walidacji kodów kontekstu (TERYT/PKD) przy zapisie — schema "
                             "nie zna przestrzeni kontekstu"})
    checks.append({"name": "contextual_references",
                   "status": "OK" if uses else "WARN",
                   "detail": f"referencje do map kontekstowych w regułach: "
                             f"{ {k: len(v) for k, v in uses.items()} or 'BRAK' }"})

    findings.append({"id": "V3-P06-L12", "severity": "P2",
                     "evidence": "schema parametru (I01) nie ma wymiaru kontekstu — brak walidacji "
                                 "kodów TERYT/PKD; stawki gminne (UPOL art. 5) bez modelu "
                                 "namespace.context.code",
                     "fix": "rozszerzenie schema v2 o scope=context + walidacja kodu wg rejestru "
                            "(TERYT/PKD) + wartość domyślna z zakresem ustawowym"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I07", "generated_at": now(), "gate": gate,
        "metrics": {"context_maps": len(ctx_maps), "context_code_keys": len(ctx_keys),
                    "contextual_refs": {k: len(v) for k, v in uses.items()}},
        "checks": checks, "findings": findings,
        "model": {"namespace": "pl.teryt.XXXXXX / pl.pkd.A.BB.C / domain.param",
                  "rule": "klucz kontekstowy bez rekordu w rejestrze kodów = odrzucenie; "
                          "brak wartości dla kodu = fallback do default z zakresem ustawowym"},
        "contract": {"binding": "P12–P36 domenowe (migracja wartości kontekstowych), "
                                "P06-I11 (range proofs), P09 (deklaratywna zmiana)"},
    }
    (BUNDLES / "v3_p06_contextual_maps.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I07] gate={gate} ctx_maps={len(ctx_maps)} ctx_keys={len(ctx_keys)}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
