#!/usr/bin/env python3
# ═══════════════════════════════════════════════════════════════════════════════
# NexusAI JDG — PKWiU CLASSIFIER (GLM52 P13)
# Baza stawek ryczałtu wg PKWiU (art. 12 ust. 1 u.z.p.d. — Dz.U. 2025 poz. 234):
# 3% / 5,5% / 8,5% / 12,5% / 17% / 20% / 25%. Klasyfikator PKD → PKWiU → stawka
# z dowodem (artykuł + sekcja PKWiU) i flagami ryzyka.
# ═══════════════════════════════════════════════════════════════════════════════
from __future__ import annotations

# Domyślne stawki ryczałtu wg art. 12 ust. 1 u.z.p.d.
# (ustawa z 20.11.1998 — Dz.U. 2025 poz. 234 ze zm.)
_LEGAL_RYCZALT = "ustawy z dnia 20 listopada 1998 r. o zryczałtowanym podatku dochodowym od niektórych przychodów osiąganych przez osoby fizyczne (Dz.U. 2025 poz. 234 ze zm.)"

RATES = {
    0.03: f"art. 12 ust. 1 pkt 1 {_LEGAL_RYCZALT} (działalność wytwórcza — przetwórstwo)",
    0.055: f"art. 12 ust. 1 pkt 2 {_LEGAL_RYCZALT} (roboty budowlane)",
    0.085: f"art. 12 ust. 1 pkt 5 lit. a {_LEGAL_RYCZALT} (usługi)",
    0.125: f"art. 12 ust. 1 pkt 4 {_LEGAL_RYCZALT} (wolne zawody)",
    0.17: f"art. 12 ust. 1 pkt 2 lit. a {_LEGAL_RYCZALT} (najem, dzierżawa)",
    0.20: f"art. 12 ust. 1 pkt 3 {_LEGAL_RYCZALT} (działy specjalne produkcji rolnej)",
    0.25: f"art. 12 ust. 1 pkt 5 lit. b {_LEGAL_RYCZALT} (pozostałe usługi)",
}

# PKD → stawka (przybliżona mapka wg klasyfikacji PKWiU 2015)
# Format: (prefix PKD, stawka, opis)
PKD_MAP = [
    ("10", 0.03, "produkcja artykułów spożywczych"),
    ("11", 0.03, "produkcja napojów"),
    ("13", 0.03, "produkcja wyrobów tekstylnych"),
    ("14", 0.03, "produkcja odzieży"),
    ("16", 0.03, "produkcja wyrobów z drewna"),
    ("17", 0.03, "produkcja papieru"),
    ("22", 0.03, "produkcja wyrobów z gumy i tworzyw"),
    ("23", 0.03, "produkcja wyrobów z pozostałych minerałów"),
    ("24", 0.03, "produkcja metali"),
    ("25", 0.03, "produkcja wyrobów z metali"),
    ("26", 0.03, "produkcja komputerów, wyrobów elektronicznych"),
    ("27", 0.03, "produkcja urządzeń elektrycznych"),
    ("28", 0.03, "produkcja maszyn"),
    ("29", 0.03, "produkcja pojazdów"),
    ("31", 0.03, "produkcja mebli"),
    ("32", 0.03, "produkcja pozostałych wyrobów"),
    ("41", 0.055, "roboty budowlane związane ze wznoszeniem budynków"),
    ("42", 0.055, "roboty związane z budową obiektów inżynierii"),
    ("43", 0.055, "roboty budowlane specjalistyczne"),
    ("49", 0.085, "transport lądowy"),
    ("55", 0.085, "zakwaterowanie"),
    ("56", 0.085, "gastronomia"),
    ("62", 0.125, "działalność związana z oprogramowaniem (wolne zawody)" if False else "działalność programistyczna"),
    ("63", 0.085, "działalność usługowa w zakresie informacji"),
    ("68", 0.17, "obsługa rynku nieruchomości (najem)"),
    ("69", 0.125, "działalność prawnicza, rachunkowo-księgowa"),
    ("70", 0.125, "działalność firm centralnych, doradztwo"),
    ("71", 0.125, "działalność architektoniczna i inżynierska"),
    ("72", 0.125, "badania naukowe i prace rozwojowe"),
    ("73", 0.125, "reklama, badanie rynku"),
    ("74", 0.125, "pozostała działalność profesjonalna"),
    ("75", 0.125, "działalność weterynaryjna"),
    ("86", 0.17, "opieka zdrowotna (lekarze)"),
    ("90", 0.085, "działalność twórcza związana z kulturą"),
    ("93", 0.085, "działalność sportowa, rozrywkowa"),
    ("95", 0.085, "naprawa i konserwacja"),
    ("96", 0.085, "pozostała indywidualna działalność usługowa"),
]

# PKWiU 2015 → stawka (bezpośrednio wg sekcji/działów)
PKWIU_MAP = [
    ("10", 0.03, "produkty spożywcze"),
    ("13", 0.03, "wyroby tekstylne"),
    ("23", 0.03, "wyroby z minerałów niemetalicznych"),
    ("25", 0.03, "wyroby metalowe"),
    ("26", 0.03, "komputery i wyroby elektroniczne"),
    ("27", 0.03, "urządzenia elektryczne"),
    ("28", 0.03, "maszyny i urządzenia"),
    ("29", 0.03, "pojazdy samochodowe"),
    ("31", 0.03, "meble"),
    ("41", 0.055, "budynki i roboty budowlane"),
    ("43", 0.055, "roboty budowlane specjalistyczne"),
    ("62", 0.085, "oprogramowanie i doradztwo IT (usługi)"),
    ("68", 0.17, "usługi związane z nieruchomościami"),
    ("69", 0.125, "usługi prawnicze i rachunkowe"),
    ("70", 0.125, "usługi doradcze"),
    ("71", 0.125, "usługi architektoniczne i inżynierskie"),
    ("72", 0.125, "badania i prace rozwojowe"),
    ("73", 0.125, "reklama"),
    ("74", 0.125, "pozostałe usługi profesjonalne"),
    ("75", 0.125, "usługi weterynaryjne"),
    ("86", 0.17, "usługi w zakresie opieki zdrowotnej"),
    ("90", 0.085, "usługi kulturalne i rozrywkowe"),
    ("93", 0.085, "usługi sportowe"),
    ("96", 0.085, "pozostałe usługi indywidualne"),
]


def classify_pkd(pkd: str) -> dict:
    """Klasyfikacja stawki ryczałtu na podstawie kodu PKD."""
    code = str(pkd).strip().split(".")[0]
    for prefix, rate, desc in PKD_MAP:
        if code.startswith(prefix):
            return {
                "pkd": pkd,
                "rate": rate,
                "rate_pct": round(rate * 100, 2),
                "category": desc,
                "legal_basis": RATES[rate],
                "confidence": "high",
            }
    return {
        "pkd": pkd,
        "rate": 0.085,
        "rate_pct": 8.5,
        "category": "usługi (fallback)",
        "legal_basis": RATES[0.085],
        "confidence": "low",
        "warning": "Brak dopasowania PKD — przyjęto stawkę 8,5% (usługi)",
    }


def classify_pkwiu(pkwiu: str) -> dict:
    """Klasyfikacja stawki ryczałtu na podstawie kodu PKWiU 2015."""
    code = str(pkwiu).strip().split(".")[0]
    for prefix, rate, desc in PKWIU_MAP:
        if code.startswith(prefix):
            return {
                "pkwiu": pkwiu,
                "rate": rate,
                "rate_pct": round(rate * 100, 2),
                "category": desc,
                "legal_basis": RATES[rate],
                "confidence": "high",
            }
    return {
        "pkwiu": pkwiu,
        "rate": 0.085,
        "rate_pct": 8.5,
        "category": "usługi (fallback)",
        "legal_basis": RATES[0.085],
        "confidence": "low",
        "warning": "Brak dopasowania PKWiU — przyjęto stawkę 8,5% (usługi)",
    }


def rate_table() -> list[dict]:
    """Pełna tabela stawek z podstawą prawną."""
    return [
        {"rate": rate, "rate_pct": round(rate * 100, 2), "legal_basis": basis}
        for rate, basis in sorted(RATES.items())
    ]


if __name__ == "__main__":
    import json
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "--table":
        print(json.dumps(rate_table(), ensure_ascii=False, indent=1))
    elif len(sys.argv) > 1:
        print(json.dumps(classify_pkwiu(sys.argv[1]), ensure_ascii=False, indent=1))
    else:
        for pkd in ["62.01.Z", "10.71.Z", "41.20.Z", "68.20.Z", "86.10.Z"]:
            print(json.dumps(classify_pkd(pkd), ensure_ascii=False))
