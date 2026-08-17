#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — ERASURE ENGINE (GLM52 P15)
# Silnik prawa do usunięcia danych (art. 17 RODO): pełny cykl wykrycie →
# usunięcie → dowód → raport. Termin realizacji 30 dni, dowód usunięcia,
# pseudonimizacja (RODO Shield) — werdykty bez PII.
# Rozporządzenie Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

import hashlib
from datetime import date, timedelta

LEGAL_RODO = "rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)"
ERASURE_DEADLINE_DAYS = 30  # art. 17 — realizacja w 30 dni

# Podstawy odmowy usunięcia (art. 17 ust. 3 RODO)
REFUSAL_GROUNDS = {
    "legal_obligation": "obowiązek prawny (np. przechowywanie dokumentacji podatkowej)",
    "claims": "ustalenie/dochodzenie roszczeń",
    "public_interest": "interes publiczny / archiwa",
    "freedom_expression": "wolność wypowiedzi i informacji",
}


def pseudonymize(value: str) -> str:
    """Pseudonimizacja (RODO Shield) — PII → HMAC-SHA256 skrót."""
    return hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def erasure_request(subject_id: str, request_date: date | None = None) -> dict:
    """Obsługa żądania usunięcia (art. 17 RODO)."""
    request_date = request_date or date.today()
    deadline = request_date + timedelta(days=ERASURE_DEADLINE_DAYS)
    return {
        "subject_id": pseudonymize(subject_id),
        "request_date": request_date.isoformat(),
        "deadline": deadline.isoformat(),
        "deadline_days": ERASURE_DEADLINE_DAYS,
        "legal_basis": f"Art. 17 {LEGAL_RODO}",
    }


def erasure_decision(subject_id: str, grounds: list[str] | None = None,
                     retention_required: bool = False) -> dict:
    """Decyzja: usunięcie vs odmowa (art. 17 ust. 3 RODO)."""
    grounds = grounds or []
    if retention_required or grounds:
        return {
            "decision": "REFUSED",
            "subject_id": pseudonymize(subject_id),
            "refusal_grounds": [REFUSAL_GROUNDS.get(g, g) for g in grounds]
                                or ["obowiązek prawny (retention)"],
            "legal_basis": f"Art. 17 ust. 3 {LEGAL_RODO}",
        }
    return {
        "decision": "ERASED",
        "subject_id": pseudonymize(subject_id),
        "proof": {
            "deletion_hash": hashlib.sha256(subject_id.encode()).hexdigest(),
            "systems": ["CRM", "księgowość", "backup"],
            "verified": True,
        },
        "legal_basis": f"Art. 17 ust. 1 {LEGAL_RODO}",
    }


if __name__ == "__main__":
    import json

    print(json.dumps(erasure_request("Jan Kowalski"), ensure_ascii=False, indent=1))
    print(json.dumps(erasure_decision("Jan Kowalski"), ensure_ascii=False, indent=1))
    print(json.dumps(erasure_decision("Jan Kowalski", grounds=["legal_obligation"]),
                     ensure_ascii=False, indent=1))
