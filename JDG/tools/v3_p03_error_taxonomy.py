#!/usr/bin/env python3
"""NexusAI JDG — ERROR TAXONOMY DSL (V3-P03-I12)
=================================================
Deklaratywna taksonomia błędów generująca dokumentację i kody synchronicznie
(P03-AN08). Klient musi programowo rozróżniać błędy: retry-able vs trwały,
tymczasowy vs kontraktowy, degradacja vs walidacja.

  • kody: JDG-<SEVERITY>-<DOMENA>-<NUM> — semantyka zamknięta;
  • atrybuty: retryable, http_status, severity, description, resolution;
  • synchronizacja: dokumentacja (docs/V3_P03_ERROR_TAXONOMY.md) generowana
    z tej samej definicji co kody — jedno źródło prawdy (AP12).
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
OUT_JSON = BASE_DIR / "bundles" / "v3_p03_error_taxonomy.json"
OUT_DOC = BASE_DIR / "docs" / "V3_P03_ERROR_TAXONOMY.md"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


# ── Jedno źródło prawdy: definicja taksonomii ───────────────────────────────
ERRORS = [
    {"code": "JDG-ERROR-VALIDATION-001", "severity": "ERROR", "domain": "validation",
     "http_status": 422, "retryable": False, "temporary": False,
     "description": "Nieprawidłowy identyfikator (NIP/REGON checksum)",
     "resolution": "Popraw identyfikator przed ponownym wysłaniem"},
    {"code": "JDG-ERROR-VALIDATION-002", "severity": "ERROR", "domain": "validation",
     "http_status": 422, "retryable": False, "temporary": False,
     "description": "Niezgodność kwot netto+VAT vs brutto",
     "resolution": "Popraw kwoty faktury"},
    {"code": "JDG-ERROR-VALIDATION-003", "severity": "ERROR", "domain": "validation",
     "http_status": 422, "retryable": False, "temporary": False,
     "description": "Data faktury w przyszłości",
     "resolution": "Popraw datę wystawienia"},
    {"code": "JDG-ERROR-CONTRACT-001", "severity": "ERROR", "domain": "contract",
     "http_status": 500, "retryable": True, "temporary": True,
     "description": "Werdykt niekompletny — naruszenie kontraktu 25-polowego (INV-043)",
     "resolution": "Ponów po aktualizacji bundla; zgłoś do P03-I05 jeśli utrzymuje się"},
    {"code": "JDG-ERROR-CONTRACT-002", "severity": "ERROR", "domain": "contract",
     "http_status": 500, "retryable": True, "temporary": True,
     "description": "Invariant BLOCK w POST-MERGE (INV-001..042)",
     "resolution": "Nie księguj; prześlij werdykt do weryfikacji manualnej"},
    {"code": "JDG-ERROR-DEGRADED-001", "severity": "WARNING", "domain": "degradation",
     "http_status": 200, "retryable": True, "temporary": True,
     "description": "DEGRADED_API — usługa zewnętrzna niedostępna, werdykt TRIAGE",
     "resolution": "Ponów po przywróceniu usługi; werdykt nie księgowany (INV-038)"},
    {"code": "JDG-ERROR-DEGRADED-002", "severity": "WARNING", "domain": "degradation",
     "http_status": 200, "retryable": False, "temporary": False,
     "description": "PARTIAL — brak danych domeny, werdykt wymaga weryfikacji",
     "resolution": "Uzupełnij dane; werdykt nie księgowany"},
    {"code": "JDG-ERROR-BLOCKED-001", "severity": "ERROR", "domain": "risk",
     "http_status": 409, "retryable": False, "temporary": False,
     "description": "BLOCK_AND_ALERT — ryzyko fraud/sankcje (risk.rego)",
     "resolution": "Eskalacja do weryfikacji manualnej; nigdy AUTO_POST"},
    {"code": "JDG-ERROR-AUTH-001", "severity": "ERROR", "domain": "auth",
     "http_status": 401, "retryable": False, "temporary": False,
     "description": "Brak/nieprawidłowa autoryzacja",
     "resolution": "Popraw token"},
    {"code": "JDG-ERROR-TIMEOUT-001", "severity": "ERROR", "domain": "infra",
     "http_status": 504, "retryable": True, "temporary": True,
     "description": "Przekroczono budżet latencji ewaluacji",
     "resolution": "Ponów z backoff; alarm do P37 (pass_duration_ms)"},
]

RETRYABLE = [e["code"] for e in ERRORS if e["retryable"]]
TEMP = [e["code"] for e in ERRORS if e["temporary"]]


def build() -> dict:
    codes = [e["code"] for e in ERRORS]
    duplicates = [c for c in set(codes) if codes.count(c) > 1]
    return {
        "innovation": "V3-P03-I12",
        "name": "Error Taxonomy DSL — kody + dokumentacja synchronicznie (P03-AN08)",
        "generated_at": now(),
        "errors": ERRORS,
        "error_count": len(ERRORS),
        "retryable_codes": RETRYABLE,
        "temporary_codes": TEMP,
        "semantics": {
            "retryable": "klient może ponowić z backoff (tymczasowe) — NIGDY dla BLOCK",
            "http_status": "mapowanie na protokół — programowe rozróżnienie",
            "severity": "ERROR vs WARNING (degradacja to WARNING z pełnym kontraktem)",
        },
        "gate": {
            "pass": len(duplicates) == 0 and len(codes) == len(ERRORS),
            "rule": "kody unikalne; taksonomia deklaratywna — dokumentacja generowana "
                    "z definicji (jedno źródło prawdy, AP12); wiąże P41 (API)",
        },
        "note": "docs/V3_P03_ERROR_TAXONOMY.md generowany z tej samej definicji co bundle — "
                "zmiana kodu wymaga zmiany definicji (I05 analogia dla błędów).",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Error Taxonomy DSL (V3-P03-I12)")
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--gate", action="store_true")
    args = ap.parse_args()

    data = build()
    if args.write:
        OUT_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
        # Dokumentacja generowana z definicji (synchronizacja kody↔docs).
        lines = ["# V3-P03 ERROR TAXONOMY (generowane z tools/v3_p03_error_taxonomy.py)",
                 "",
                 "| Kod | Severity | Domen | HTTP | Retryable | Tymczasowy | Opis |",
                 "|---|---|---|---|---|---|---|"]
        for e in ERRORS:
            lines.append(f"| {e['code']} | {e['severity']} | {e['domain']} | "
                         f"{e['http_status']} | {e['retryable']} | {e['temporary']} | "
                         f"{e['description']} |")
        lines += ["", f"*Retryable: {', '.join(RETRYABLE)}*", "",
                  "Semantyka: retryable = ponów z backoff (NIGDY dla BLOCK); "
                  "degradacja = WARNING z pełnym kontraktem (I10)."]
        OUT_DOC.write_text("\n".join(lines) + "\n", encoding="utf-8")
        print(f"Zapisano {OUT_JSON.relative_to(BASE_DIR)} + {OUT_DOC.relative_to(BASE_DIR)}")
    if args.json:
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print(f"V3-P03-I12 Error Taxonomy: errors={data['error_count']} "
              f"retryable={len(data['retryable_codes'])} gate_pass={data['gate']['pass']}")
    if args.gate and not data["gate"]["pass"]:
        print("FAIL: duplikaty kodów błędów")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())