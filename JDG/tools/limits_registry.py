#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — LIMITS REGISTRY (GLM52 P16)
# Centralny rejestr limitów podatkowych — jeden punkt prawdy (ADR-002):
# monitor przekroczenia (95% = NEAR), limit radar (prognoza przekroczenia).
# Progi zgodne z thresholds.jdg / kampanią GLM52 (P02-P15).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

from datetime import date

# ── Rejestr limitów (klucz → {wartość, jednostka, podstawa prawna}) ───────────
LIMITS = {
    "vat_113":            {"value": 200_000, "unit": "PLN", "name": "Limit zwolnienia VAT (art. 113)",
                          "legal_basis": "Art. 113 ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"},
    "pit0_young":         {"value": 85_528,  "unit": "PLN", "name": "Ulga dla młodych PIT-0 (art. 21 ust. 1 pkt 148)",
                          "legal_basis": "Art. 21 ust. 1 pkt 148 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"},
    "tax_scale_threshold":{"value": 120_000, "unit": "PLN", "name": "Próg podatkowy 12%/32% (art. 27)",
                          "legal_basis": "Art. 27 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"},
    "lump_sum_2m_eur":    {"value": 2_000_000, "unit": "EUR", "name": "Limit ryczałtu 2 mln EUR",
                          "legal_basis": "Art. 6 ust. 4 pkt 1 ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"},
    "mpp_15k":            {"value": 15_000,  "unit": "PLN", "name": "Mechanizm podzielonej płatności (art. 108a)",
                          "legal_basis": "Art. 108a ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"},
    "maly_zus_120k":      {"value": 120_000, "unit": "PLN", "name": "Mały ZUS+ limit przychodu (art. 18c ust. 4-5)",
                          "legal_basis": "Art. 18c ustawy z dnia 13 października 1998 r. o systemie ubezpieczeń społecznych (Dz.U. 2025 poz. 345, ze zm.)"},
    "donations_6pct":     {"value": 0.06,    "unit": "PCT", "name": "Darowizny — limit 6% dochodu (art. 26 ust. 1 pkt 9)",
                          "legal_basis": "Art. 26 ust. 1 pkt 9 ustawy z dnia 26 lipca 1991 r. o podatku dochodowym od osób fizycznych (Dz.U. 2024 poz. 1760 ze zm.)"},
    "ksef_sanction":      {"value": 500_000, "unit": "PLN", "name": "Sankcja KSeF (max)",
                          "legal_basis": "Art. 112e ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"},
    "bdo_fine_194":       {"value": 5_000,   "unit": "PLN", "name": "Kara BDO (art. 194 u. o odpadach)",
                          "legal_basis": "Art. 194 ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)"},
    "rodo_fine_max":      {"value": 20_000_000, "unit": "EUR", "name": "Sankcja RODO (art. 83 ust. 5)",
                          "legal_basis": "Art. 83 ust. 5 rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)"},
    "aml_sanction_max":   {"value": 1_000_000, "unit": "PLN", "name": "Sankcja AML (art. 153)",
                          "legal_basis": "Art. 153 ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"},
}

ALERT_RATIO = 0.95  # alert 95% progu (limit radar)


def get_limit(key: str) -> dict:
    lim = LIMITS.get(key)
    if not lim:
        return {"key": key, "error": "nieznany limit"}
    return {"key": key, **lim}


def check_limit(key: str, current_value: float) -> dict:
    """Monitor przekroczenia: BELOW / NEAR (≥95%) / EXCEEDED."""
    lim = LIMITS.get(key)
    if not lim:
        return {"key": key, "error": "nieznany limit"}
    threshold = lim["value"]
    if current_value >= threshold:
        status = "EXCEEDED"
    elif current_value >= threshold * ALERT_RATIO:
        status = "NEAR"
    else:
        status = "BELOW"
    return {
        "key": key,
        "name": lim["name"],
        "limit": threshold,
        "unit": lim["unit"],
        "current": current_value,
        "ratio": round(current_value / threshold, 4),
        "status": status,
        "legal_basis": lim["legal_basis"],
    }


def forecast(key: str, current: float, monthly_rate: float,
             months_ahead: int = 12, as_of: date | None = None) -> dict:
    """Limit radar — prognoza daty przekroczenia przy stałym tempie wzrostu."""
    lim = LIMITS.get(key)
    if not lim:
        return {"key": key, "error": "nieznany limit"}
    threshold = lim["value"]
    if monthly_rate <= 0:
        return {"key": key, "name": lim["name"], "projected_exceedance": None,
                "months_to_exceed": None, "status": "NO_GROWTH"}
    months_to_exceed = int((threshold - current) / monthly_rate) + 1
    as_of = as_of or date.today()
    projected = None
    if months_to_exceed > 0:
        y = as_of.year + (as_of.month - 1 + months_to_exceed) // 12
        m = (as_of.month - 1 + months_to_exceed) % 12 + 1
        projected = date(y, m, 1)
    return {
        "key": key,
        "name": lim["name"],
        "limit": threshold,
        "current": current,
        "monthly_rate": monthly_rate,
        "months_to_exceed": months_to_exceed if months_to_exceed <= months_ahead else None,
        "projected_exceedance": projected.isoformat() if projected and months_to_exceed <= months_ahead else None,
        "legal_basis": lim["legal_basis"],
    }


if __name__ == "__main__":
    import json

    for k in ["vat_113", "tax_scale_threshold", "mpp_15k"]:
        print(json.dumps(check_limit(k, LIMITS[k]["value"] * 0.96), ensure_ascii=False, indent=1))
    print(json.dumps(forecast("vat_113", 150_000, 10_000), ensure_ascii=False, indent=1))
