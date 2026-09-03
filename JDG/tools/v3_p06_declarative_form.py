#!/usr/bin/env python3
"""
NexusAI JDG — V3-P06-I10 DECLARATIVE PARAMETER FORM (V2/F6)
============================================================
Formularz deklaratywnej zmiany parametru: opis ludzki → walidacja (typ, zakres,
zbiór ustawowy, okno czasowe) → wersja (payload do JSON store) → hot-reload.
Krok do P09 (declarative change) — zmiana parametru jako artefakt PR, nie edycja.

Zbiory ustawowe: VAT {0,5,8,23%} (art. 41/146a), ryczałt {3,5.5,8.5,10,12,12.5,
14,15,17%} (LEGAL_RATES P13), PIT skala {12,32%}, stawki ZUS ∈ (0,1).

Usage:
  python tools/v3_p06_declarative_form.py
"""
from __future__ import annotations

import json
from datetime import datetime, timezone
from pathlib import Path

BASE = Path(__file__).resolve().parent.parent
BUNDLES = BASE / "bundles"

LEGAL_SETS = {
    "vat.standard_rate": ([0.0, 0.05, 0.08, 0.23], "Art. 41/146a VAT"),
    "ryczalt.rate": ([0.03, 0.055, 0.085, 0.10, 0.12, 0.125, 0.14, 0.15, 0.17],
                     "Art. 12 ustawy o zryczałtowanym podatku"),
    "pit.scale_low": ([0.12], "PIT skala — próg 12%"),
    "pit.scale_high": ([0.32], "PIT skala — próg 32%"),
}


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def validate(candidate: dict) -> tuple[bool, list[str]]:
    errs = []
    key = candidate.get("key", "")
    value = candidate.get("value")
    if key not in LEGAL_SETS:
        errs.append(f"nieznany klucz {key} (brak w rejestrze ustawowym)")
        return False, errs
    allowed, _ = LEGAL_SETS[key]
    if value not in allowed:
        errs.append(f"value {value} poza ustawowym zbiorem {allowed}")
    if not candidate.get("source_act"):
        errs.append("source_act wymagany (schema v2)")
    if not candidate.get("changed_by"):
        errs.append("changed_by wymagany (audyt)")
    if not candidate.get("valid_from"):
        errs.append("valid_from wymagany (okno temporalne P05)")
    if candidate.get("valid_to") and candidate["valid_to"] < candidate["valid_from"]:
        errs.append("valid_to < valid_from")
    return (len(errs) == 0), errs


def main() -> int:
    checks, findings = [], []

    # kandydat poprawny: stawka VAT 8% od 2027-01-01 (przykład deklaratywny)
    good = {"key": "vat.standard_rate", "value": 0.08, "unit": "pct",
            "valid_from": "2027-01-01", "valid_to": None,
            "source_act": "Art. 41 ustawy o VAT", "article": "41",
            "changed_by": "declarative-form-demo", "scope": "global",
            "human_reason": "obniżona stawka na usługi (przykład)"}
    ok_good, errs_good = validate(good)

    # kandydat niepoprawny: stawka 25% poza zbiorem
    bad = {"key": "vat.standard_rate", "value": 0.25, "unit": "pct",
           "valid_from": "2027-01-01", "valid_to": None,
           "source_act": "Art. 41 ustawy o VAT", "article": "41",
           "changed_by": "declarative-form-demo", "scope": "global"}
    ok_bad, errs_bad = validate(bad)

    checks.append({"name": "valid_candidate_accepted",
                   "status": "OK" if ok_good else "FAIL",
                   "detail": f"kandydat 0.08 VAT: {'PRZYJĘTY' if ok_good else errs_good}"})
    checks.append({"name": "invalid_candidate_rejected",
                   "status": "OK" if not ok_bad else "FAIL",
                   "detail": f"kandydat 0.25 VAT: {'ODRZUCONY' if not ok_bad else 'PRZYJĘTY (BŁĄD)'} "
                             f"— {errs_bad}"})

    gate = "FAIL" if any(c["status"] == "FAIL" for c in checks) else "PASS"
    bundle = {
        "innovation": "V3-P06-I10", "generated_at": now(), "gate": gate,
        "mode": "VALIDATION_DEMO",
        "metrics": {"legal_sets": len(LEGAL_SETS),
                    "valid_candidate_ok": ok_good, "invalid_rejected": not ok_bad},
        "validated_payload": good if ok_good else None,
        "rejected_example": {"candidate": bad, "errors": errs_bad},
        "checks": checks, "findings": [],
        "pipeline": ["opis ludzki", "walidacja zbioru ustawowego", "wersja payload",
                     "PR/rewiew 4-eyes", "hot-reload (I05)", "golden dataset (I04)"],
        "contract": {"binding": "P09 (declarative change — pełny formularz), P06-I08 (rollback), "
                                "P39 (testy przy zmianie), P06-I05 (SLO)"},
    }
    (BUNDLES / "v3_p06_declarative_form.json").write_text(
        json.dumps(bundle, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"[V3-P06-I10] gate={gate} legal_sets={len(LEGAL_SETS)} "
          f"valid_ok={ok_good} invalid_rejected={not ok_bad}")
    return 1 if gate == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
