# 🛠️ OPA Rego — Developer Guide dla Modułu JDG

> **Status:** v8.0 | **Data:** 2026-08-02
> **Przewodnik po konwencjach, strukturze i workflow dla deweloperów reguł Rego w NexusAI JDG**

---

## 1. Architektura katalogu `JDG/rules/`

```
JDG/rules/
├── main_jdg.rego                    # 🧠 Główny orkiestrator (~55 pakietów, Multi-Pass)
├── *.rego                           # 153+ plików na poziomie głównym (makro-reguły)
├── micro/                           # 106 plików atomowych (per artykuł ustawy)
├── vat/                             # VAT: stawki, odliczenia, procedury
├── pit/                             # PIT: formy, KUP, zaliczki, ulgi
├── zus/                             # ZUS: składki, zasiłki, zdrowotna
├── kks/                             # KKS: grzywny, przedawnienia
├── accounting/                      # PKPiR, amortyzacja, leasing
├── crossborder/                     # WNT/WDT, import, TP, CFC
├── local_taxes/                     # PCC, akcyza, transport, nieruchomości
├── compliance/                      # AML, RODO, BDO
├── business/                        # CEIDG, zawieszenie, sukcesja
└── *_enterprise.rego                # 90 plików Enterprise (S1-S24)
```

**Zasada:** Każdy plik .rego to jeden pakiet OPA z jednym łańcuchem `else`-chain.

---

## 2. Konwencja Rule ID

### Format
```
jdg.<domena>.<kategoria>_<szczegół>
```

### Przykłady
| Rule ID | Znaczenie |
|---------|-----------|
| `jdg.vat.substantive.fuel_pl` | VAT, stawka dla paliwa w PL |
| `jdg.kks.empty_invoice_issued` | KKS, wystawienie pustej faktury |
| `jdg.zus.health_linear` | ZUS, składka zdrowotna liniowy |
| `jdg.edge_cases.vat_breach_mid_year` | Edge case, przekroczenie limitu VAT |

### Zasady nazewnictwa
- **Prefiks:** `jdg.` — wszystkie reguły JDG
- **Domena:** `vat`, `pit`, `zus`, `kks`, `accounting`, `crossborder`, `compliance`, `edge_cases`, itd.
- **Kategoria i szczegół:** snake_case, opisowe
- **No-match fallback:** `<domena>.no_match` (priority 999)

---

## 3. Struktura reguły — Standardowy Werdykt

Każda reguła zwraca obiekt z 25 polami:

```rego
{
    "matched": true,                     # Czy reguła została dopasowana
    "rule_id": "jdg.vat.substantive.fuel_pl",  # Unikalny identyfikator
    "package": "jdg.vat.substantive",    # Pakiet OPA
    "priority": 58,                      # Priorytet (metadane)
    "vat_rate": "0.23",                  # Stawka VAT
    "rounding_level": "position",        # Zaokrąglanie
    "gtu_code": "",                      # Kod GTU
    "procedure": "",                     # Procedura specjalna
    "vat_exemption": "",                 # Typ zwolnienia VAT
    "pit_form": "",                      # Forma opodatkowania PIT
    "pit_rate": "",                      # Stawka PIT
    "pit_bracket": "",                   # Próg podatkowy
    "pit_annual_return_type": "",        # Typ zeznania rocznego
    "kus_qualification": "",             # Kwalifikacja KUP
    "kus_percent": 0,                    # Procent KUP
    "zus_social_base_type": "",          # Typ podstawy ZUS
    "zus_health_rate": "",               # Stawka zdrowotna
    "business_status": "",               # Status działalności
    "ceidg_registration_required": false, # Czy wymagana rejestracja CEIDG
    "_routing": "",                      # BLOCK_AND_ALERT | TRIAGE_QUEUE | ""
    "_routing_reason": "",               # Uzasadnienie routingu
    "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",  # Podstawa prawna
    "_warnings": [],                     # Ostrzeżenia diagnostyczne
}
```

---

## 4. First-Match-Wins else-chain

**Fundamentalna zasada:** Kolejność reguł w pliku = kolejność ewaluacji.

```rego
package jdg.vat.substantive

# Domyślny werdykt (fallback)
default decide := {
    "matched": false,
    "rule_id": "jdg.vat.substantive.no_match",
    "priority": 999,
    ...
}

# Pierwsza reguła — najwyższy priorytet
decide := {
    "matched": true,
    "rule_id": "jdg.vat.substantive.fuel_pl",
    "priority": 58,
    ...
} {
    input.payload.invoice.expense_type == "FUEL"
}

# Druga reguła
else := {
    "matched": true,
    "rule_id": "jdg.vat.substantive.food_pl",
    "priority": 59,
    ...
} {
    input.payload.invoice.expense_type == "FOOD"
}

# Trzecia reguła — itd.
else := {
    ...
} {
    ...
}
```

**Ważne:** Nie można przeplatać helper functions (`:=`) z `else :=` w łańcuchu. Helper functions muszą być PRZED lub PO łańcuchu `else`.

---

## 5. Dodawanie nowej reguły

1. **Znajdź odpowiedni plik** — reguła musi trafić do właściwej domeny (vat/, pit/, zus/, itd.)
2. **Umieść w odpowiednim miejscu w else-chain** — przed regułami o niższym priorytecie, po regułach o wyższym
3. **Nadaj unikalny rule_id** — sprawdź `python JDG/tools/generate_manifest.py --verify` czy nie ma duplikatów
4. **Wypełnij wszystkie 25 pól** — nawet jeśli większość jest pusta
5. **Dodaj `_legal_basis`** — cytat artykułu ustawy
6. **Ustaw `_routing`** — `"BLOCK_AND_ALERT"` dla krytycznych, `"TRIAGE_QUEUE"` dla wymagających weryfikacji, `""` dla automatycznych
7. **Uruchom walidację:**
   ```bash
   python JDG/tools/validate_rules.py --strict
   ```
8. **Zaktualizuj manifest:**
   ```bash
   python JDG/tools/generate_manifest.py
   ```

---

## 6. Walidacja i testowanie

### Walidacja składni
```bash
opa check JDG/rules/ -b
```

### Walidacja reguł (9 walidacji)
```bash
python JDG/tools/validate_rules.py          # Podstawowa
python JDG/tools/validate_rules.py --strict  # Ostrzeżenia jako błędy
python JDG/tools/validate_rules.py --json    # Output JSON
```

### Testy Rego (w przygotowaniu — Faza 4)
```bash
opa test JDG/tests/ -v
```

### Generacja manifestu
```bash
python JDG/tools/generate_manifest.py         # Generuj MANIFEST.md
python JDG/tools/generate_manifest.py --check # Sprawdź czy aktualny
python JDG/tools/generate_manifest.py --verify # Weryfikuj integralność
```

---

## 7. Budowanie i deployment Bundle OPA

```bash
cd JDG/bundles && bash bundle.sh
```

Bundle zachowuje strukturę katalogów (fix v8.0), więc pliki w podkatalogach (micro/, vat/, pit/) są dostępne jako osobne pakiety.

---

## 8. Zasady projektowe

| Zasada | Implementacja |
|--------|---------------|
| **First-Match-Wins** | Rego `else` chain |
| **Zero Hardcoded Values** | `data.thresholds.*` przez OPA Data API |
| **Temporalność** | `valid_from` / `valid_to` + `temporal.rego` |
| **Audytowalność** | `rule_id` + `_legal_basis` w każdym werdykcie |
| **Immutowalność** | `immutable_verdict: true` dla krytycznych reguł |
| **Multi-Pass** | PASS 0-8 + POST-MERGE w orkiestratorze |

---

## 9. Narzędzia deweloperskie

| Narzędzie | Opis |
|-----------|------|
| `generate_manifest.py` | Auto-generuje MANIFEST.md (parser strukturalny v8.0) |
| `validate_rules.py` | 9 walidacji jakości/spójności reguł |
| `generate_coverage_report.py` | Generuje COVERAGE_REPORT.md (v8.0, fix NameError) |
| `lint_rego_rules.py` | Linter składni Rego |
| `isap_crawler.py` | Crawler ISAP do aktualizacji podstaw prawnych |
| `llm_bridge.py` | Bridge do LLM (C2) |

---

*Wygenerowano przez NexusAI Developer Guide Engine v8.0 — 2026-08-02*
*Zastępuje poprzednią wersję (wklejka odpowiedzi LLM o 4 repozytoriach Rego)*
