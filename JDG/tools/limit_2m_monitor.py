#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — LIMIT 2M EUR MONITOR (GLM52 P13)
# Monitor limitu przychodów ryczałtu (art. 6 ust. 4 u.z.p.d. — Dz.U. 2025 poz. 234):
# przeliczenie limitu kursem NBP z 1 października poprzedniego roku, alert przy
# 95% limitu, symulacja przekroczenia (przejście na skalę od 1.01 następnego roku).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations
from datetime import date

LIMIT_EUR = 2_000_000
ALERT_PCT = 0.95
REFERENCE_DATE = date(2025, 10, 1)  # kurs NBP z 1.10 poprzedniego roku


def nbp_rate_from_october(reference_date: date = REFERENCE_DATE) -> float:
    """Kurs EUR/PLN — domyślnie referencyjny (4.3); docelowo pobranie z API NBP
    (http://api.nbp.pl/api/exchangerates/rates/a/eur/{date}/)."""
    # Kurs z 1.10.2025: ~4.30 PLN/EUR (wartość referencyjna z thresholds)
    return 4.30


def limit_pln(rate: float | None = None) -> float:
    rate = rate or nbp_rate_from_october()
    return LIMIT_EUR * rate


def monitor(revenue_pln: float, rate: float | None = None,
            revenue_source: str = "narastająco od 1.01") -> dict:
    lim = limit_pln(rate)
    usage = revenue_pln / lim if lim else 0.0
    status = "OK"
    warnings = []
    if usage >= 1.0:
        status = "LIMIT_EXCEEDED"
        warnings.append(
            "Przekroczono limit 2M EUR — utrata prawa do ryczałtu od 1.01 "
            "następnego roku (art. 6 ust. 4 u.z.p.d.); przejście na skalę (art. 9a uPIT)"
        )
    elif usage >= ALERT_PCT:
        status = "ALERT_95"
        warnings.append(
            f"Osiągnięto {usage:.1%} limitu 2M EUR — planuj przejście na skalę "
            "od 1.01 następnego roku"
        )
    return {
        "limit_eur": LIMIT_EUR,
        "limit_pln": round(lim, 2),
        "nbp_rate": rate or nbp_rate_from_october(),
        "revenue_pln": revenue_pln,
        "usage_pct": round(usage * 100, 2),
        "remaining_pln": round(max(lim - revenue_pln, 0), 2),
        "status": status,
        "warnings": warnings,
        "revenue_source": revenue_source,
        "legal_basis": "art. 6 ust. 4 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym "
                       "podatku dochodowym od niektórych przychodów osiąganych przez osoby "
                       "fizyczne (Dz.U. 2025 poz. 234 ze zm.)",
    }


def simulate_exceedance(revenue_pln: float, current_year: int = 2026) -> dict:
    """Symulacja skutków przekroczenia limitu."""
    m = monitor(revenue_pln)
    exceeded = m["status"] == "LIMIT_EXCEEDED"
    return {
        "limit_exceeded": exceeded,
        "current_year": current_year,
        "switch_to_scale_from": (current_year + 1) if exceeded else None,
        "consequences": [
            "Przejście na skalę podatkową (art. 9a ust. 1 uPIT) od 1.01 następnego roku",
            "Konieczność prowadzenia ksiąg (PKPiR) od 1.01 następnego roku",
            "Rozliczenie ryczałtu za rok bieżący wg stawek ryczałtu do dnia przekroczenia",
        ] if exceeded else [],
        "monitor": m,
    }


if __name__ == "__main__":
    import json
    import sys

    rev = float(sys.argv[1]) if len(sys.argv) > 1 else 1_950_000.0
    print(json.dumps(monitor(rev), ensure_ascii=False, indent=1))
    print(json.dumps(simulate_exceedance(rev), ensure_ascii=False, indent=1))
