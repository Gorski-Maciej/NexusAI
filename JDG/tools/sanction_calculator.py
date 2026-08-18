#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — SANCTION CALCULATOR (GLM52 P16)
# Kalkulator sankcji łącznych per zdarzenie (VAT 30% art. 112b, KSeF art. 112e,
# KKS stawki dzienne, BDO art. 194, RODO art. 83, AML art. 153) + ścieżki
# minimalizacji (czynny żal — art. 16 KKS, dobrowolne poddanie — art. 17 KKS).
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

LEGAL_KKS = "ustawy z dnia 10 września 1999 r. — Kodeks karny skarbowy (Dz.U. 2025 poz. 678, ze zm.)"
LEGAL_VAT = "ustawy z dnia 11 marca 2004 r. o podatku od towarów i usług (Dz.U. 2024 poz. 1557 ze zm.)"
LEGAL_BDO = "ustawy z dnia 14 grudnia 2012 r. o odpadach (Dz.U. 2025 poz. 321)"
LEGAL_RODO = "rozporządzenia Parlamentu Europejskiego i Rady (UE) 2016/679 (RODO)"
LEGAL_AML = "ustawy z dnia 1 marca 2018 r. o przeciwdziałaniu praniu pieniędzy oraz finansowaniu terroryzmu (Dz.U. 2025 poz. 213)"

# ── Katalog sankcji ───────────────────────────────────────────────────────────
SANCTIONS = {
    "vat_30pct":       {"kind": "pct",   "value": 0.30, "base": "tax_understated",
                       "name": "Sankcja VAT 30% (art. 112b)",
                       "legal_basis": f"Art. 112b {LEGAL_VAT}"},
    "ksef_500k":       {"kind": "fixed", "value": 500_000,
                       "name": "Sankcja KSeF (art. 112e, max)",
                       "legal_basis": f"Art. 112e {LEGAL_VAT}"},
    "kks_daily":       {"kind": "daily", "value": 270.0, "days": 30,
                       "name": "Kara KKS — stawka dzienna (art. 23 § 3, do 30 stawek)",
                       "legal_basis": f"Art. 23 § 3 {LEGAL_KKS}"},
    "bdo_5000":        {"kind": "fixed", "value": 5_000,
                       "name": "Kara BDO (art. 194)",
                       "legal_basis": f"Art. 194 {LEGAL_BDO}"},
    "rodo_20m_eur":    {"kind": "fixed", "value": 20_000_000, "unit": "EUR",
                       "name": "Sankcja RODO (art. 83 ust. 5)",
                       "legal_basis": f"Art. 83 ust. 5 {LEGAL_RODO}"},
    "aml_1m_pln":      {"kind": "fixed", "value": 1_000_000,
                       "name": "Sankcja AML (art. 153)",
                       "legal_basis": f"Art. 153 {LEGAL_AML}"},
}

# Ścieżki minimalizacji (KKS)
MITIGATION = {
    "czynny_żal":       {"pct": 1.0, "name": "Czynny żal (art. 16 KKS) — całkowite wyłączenie",
                         "legal_basis": f"Art. 16 {LEGAL_KKS}"},
    "dobrowolne_poddanie": {"pct": 0.5, "name": "Dobrowolne poddanie odpowiedzialności (art. 17 KKS) — 50%",
                         "legal_basis": f"Art. 17 {LEGAL_KKS}"},
}


def sanction_amount(key: str, tax_understated: float = 0.0) -> dict:
    s = SANCTIONS.get(key)
    if not s:
        return {"key": key, "error": "nieznana sankcja"}
    if s["kind"] == "pct":
        amount = round(tax_understated * s["value"], 2)
    elif s["kind"] == "daily":
        amount = round(s["value"] * s["days"], 2)
    else:
        amount = float(s["value"])
    return {
        "key": key,
        "name": s["name"],
        "amount": amount,
        "unit": s.get("unit", "PLN"),
        "legal_basis": s["legal_basis"],
    }


def calculate(offenses: list[str], tax_understated: float = 0.0,
              mitigation: str | None = None) -> dict:
    """Kalkulator sankcji łącznej per zdarzenie + minimalizacja."""
    items = []
    for o in offenses:
        r = sanction_amount(o, tax_understated)
        if "error" not in r:
            items.append(r)
    total = round(sum(i["amount"] for i in items), 2)

    mitigation_info = None
    if mitigation:
        m = MITIGATION.get(mitigation)
        if m:
            applied = round(total * (1 - m["pct"]), 2)
            mitigation_info = {"name": m["name"], "reduction_pct": (1 - m["pct"]) * 100,
                               "amount_after": applied, "legal_basis": m["legal_basis"]}
            total = applied
    return {
        "offenses": items,
        "total_pln": total,
        "mitigation": mitigation_info,
        "priority_actions": ["czynny żal > dobrowolne poddanie > korekta deklaracji > odwołanie"],
    }


if __name__ == "__main__":
    import json

    r = calculate(["vat_30pct", "bdo_5000", "kks_daily"], tax_understated=100_000)
    print(json.dumps(r, ensure_ascii=False, indent=1))
    print(json.dumps(calculate(["vat_30pct"], tax_understated=100_000,
                               mitigation="dobrowolne_poddanie"), ensure_ascii=False, indent=1))
