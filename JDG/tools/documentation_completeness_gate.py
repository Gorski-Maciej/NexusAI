#!/usr/bin/env python3
"""Documentation completeness gate — verifies every spec requirement.

Validates all 7 core docs against the enterprise documentation spec:
README (PWE, glossary, C4, sequence), STRUKTURA (tree, conventions, ERD, tables,
migrations), API (endpoints, curl, rate limiting, error codes), LOGIKA (modules,
algorithms, sequences, debugging), ZGODNOSC (UoR, KSeF, JPK, declarations, audit,
retention), PODRECZNIK (workflow, decision center, integrations), FAQ.
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

BASE_DIR = Path(__file__).resolve().parents[1]
EVIDENCE = BASE_DIR / "bundles" / "documentation_completeness_evidence.json"

# Each requirement: (file, section_title, search_terms[])
REQUIREMENTS: dict[str, list[tuple[str, str, list[str]]]] = {
    "README.md": [
        ("misja", "Misja", ["Misja"]),
        ("status_produktu", "Status", ["Status produktu", "PRODUCTION"]),
        ("kluczowe_funkcje", "Kluczowe funkcje", ["Kluczowe funkcje"]),
        ("pwe", "PWE", ["Problem", "Wartość", "Efekt"]),
        ("uzytkownicy", "Główni użytkownicy", ["Główni użytkownicy"]),
        ("slownik", "Słownik", ["Słownik", "glosariusz"]),
        ("c4_context", "C4 Context", ["mermaid", "Użytkownicy"]),
        ("c4_container", "C4 Container", ["Container"]),
        ("c4_component", "C4 Component", ["Component"]),
        ("warstwy", "Warstwy architektoniczne", ["Domain", "Application", "Infrastructure", "Presentation"]),
        ("wzorce", "Wzorce projektowe", ["First-Match-Wins", "Multi-Pass", "Sharded Router", "Safe Merge"]),
        ("sekwencja_faktura", "Sekwencja faktury", ["sequenceDiagram", "faktura", "decide"]),
        ("sekwencja_decyzja", "Sekwencja decyzji", ["AUTO_POST", "SUGGEST", "ASK_USER"]),
    ],
    "docs/STRUKTURA_PROJEKTU.md": [
        ("drzewo", "Drzewo katalogów", ["Drzewo katalogów", "rules/", "tools/", "migrations/"]),
        ("konwencje_nazewnicze", "Konwencje nazewnicze", ["Konwencje nazewnicze", "rule_id", "snake_case"]),
        ("erd", "ERD", ["erDiagram", "JDG_TAX_THRESHOLDS"]),
        ("tabele", "Opis tabel", ["Opis tabel", "jdg_tax_thresholds", "rule_versions", "jdg_verdict_audit"]),
        ("migracje", "Strategia migracji", ["Strategia migracji", "001_jdg_rule_store", "seed"]),
    ],
    "docs/API_REFERENCJA.md": [
        ("endpointy", "Lista endpointów", ["Lista endpointów", "/jdg/decide", "/jdg/simulate"]),
        ("curl", "Przykłady curl", ["curl", "Authorization: Bearer"]),
        ("rate_limit", "Rate limiting", ["rate limit", "throttling", "429", "Retry-After"]),
        ("kody_bledow", "Kody błędów", ["kod błędu", "400", "409", "422", "500", "503"]),
        ("autoryzacja", "Autoryzacja", ["JWT", "Bearer"]),
    ],
    "docs/LOGIKA_BIZNESOWA.md": [
        ("moduly", "Mapa modułów", ["Mapa modułów", "jdg.main", "jdg.risk", "jdg.routing"]),
        ("algorytmy", "Algorytmy", ["Algorytm", "safe_merge", "evaluate"]),
        ("sekwencje", "Diagramy sekwencji", ["sequenceDiagram", "księgowanie", "decyzja"]),
        ("bledy", "Typowe błędy", ["Typowe błędy", "Rozwiązanie"]),
        ("debug", "Debugowanie", ["debug", "verbose", "log"]),
    ],
    "docs/ZGODNOSC_PRAWNA.md": [
        ("uor", "UoR/IFRS/GAAP", ["UoR", "IFRS", "GAAP"]),
        ("ksef", "KSeF", ["KSeF", "XSD", "XML", "UPO"]),
        ("jpk", "JPK", ["JPK", "JPK_V7", "JPK_KR"]),
        ("deklaracje", "Deklaracje", ["VAT-7", "CIT-8", "PIT-36"]),
        ("sciezka_audytu", "Ścieżka audytu", ["Ścieżka audytu", "merkle", "audit"]),
        ("retencja", "Retencja", ["retencja", "przechowywanie", "5 lat", "RODO"]),
    ],
    "docs/PODRECZNIK_UZYTKOWNIKA.md": [
        ("pierwsze_uruchomienie", "Pierwsze uruchomienie", ["Pierwsze uruchomienie", "kreator", "licencja"]),
        ("role", "Role użytkowników", ["właściciel", "księgowa", "doradca", "RBAC"]),
        ("workflow", "Workflow codzienna praca", ["pobiera faktury", "AUTO_POST", "ASK_USER"]),
        ("centrum_decyzji", "Centrum decyzji", ["Centrum decyzji", "Historia decyzji"]),
        ("raporty", "Raporty", ["Raporty", "eksport", "druk"]),
        ("integracje", "Integracje", ["KSeF", "GUS", "NBP"]),
    ],
    "docs/FAQ.md": [
        ("faq", "FAQ", ["FAQ", "pytanie", "?"]),
    ],
}


def _read(rel: str) -> str:
    try:
        return (BASE_DIR / rel).read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def build_evidence() -> dict[str, Any]:
    results: dict[str, dict[str, Any]] = {}
    total_reqs = 0
    passed_reqs = 0

    for rel, reqs in REQUIREMENTS.items():
        text = _read(rel)
        if not text:
            results[rel] = {"present": False, "requirements": {}, "passed": 0, "total": len(reqs)}
            continue
        req_results = {}
        for req_id, _title, terms in reqs:
            ok = all(term in text for term in terms)
            req_results[req_id] = ok
            total_reqs += 1
            if ok:
                passed_reqs += 1
        results[rel] = {
            "present": True,
            "requirements": req_results,
            "passed": sum(req_results.values()),
            "total": len(reqs),
        }

    all_docs_present = all(r["present"] for r in results.values())
    all_docs_complete = all(r["passed"] == r["total"] for r in results.values())

    status = "WDROZONY_100" if all_docs_present and all_docs_complete else "NIEPELNY"
    return {
        "schema_version": "1.0.0",
        "report": "DOKUMENTACJA_KOMPLETNOSC",
        "status": status,
        "docs": results,
        "summary": {
            "docs_total": len(REQUIREMENTS),
            "docs_present": sum(1 for r in results.values() if r["present"]),
            "requirements_total": total_reqs,
            "requirements_passed": passed_reqs,
        },
        "generated_at": datetime.now(timezone.utc).isoformat(),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Documentation completeness gate")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    evidence = build_evidence()
    if args.write:
        EVIDENCE.parent.mkdir(parents=True, exist_ok=True)
        EVIDENCE.write_text(json.dumps(evidence, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"✅ Evidence: {EVIDENCE.name} ({evidence['status']})")

    if args.json:
        print(json.dumps(evidence, ensure_ascii=False, indent=2))
    else:
        s = evidence["summary"]
        print(f"DOKUMENTACJA: {evidence['status']} ({s['requirements_passed']}/{s['requirements_total']} wymagań)")
        for rel, r in evidence["docs"].items():
            icon = "✅" if r["present"] and r["passed"] == r["total"] else "⚠️"
            print(f"  {icon} {rel}: {r['passed']}/{r['total']}")
            for req_id, ok in r["requirements"].items():
                if not ok:
                    print(f"      ❌ {req_id}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
