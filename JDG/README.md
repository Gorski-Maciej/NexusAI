# 🏛️ NexusAI JDG — Moduł Reguł dla Jednoosobowej Działalności Gospodarczej

> **Status:** ENTERPRISE v3.0 | **Reguł:** 633 | **Plików Rego:** 38 | **Pokrycie 38c:** ~81%
> **Data:** 2026-07-13 | **Mapa kanoniczna:** `docs/CANONICAL_COVERAGE.md`

---

## 📊 EXECUTIVE SUMMARY

Moduł JDG to kompletny silnik reguł OPA/Rego dla polskiej jednoosobowej działalności gospodarczej. Pokrywa **wszystkie kluczowe obszary** prawne:
podatki (VAT, PIT, PCC), składki ZUS, księgowość (PKPiR, KŚT, UoR), odpowiedzialność karną skarbową (KKS),
ochronę danych (RODO), obowiązki pracodawcy (MPiPS, PPK) i transakcje transgraniczne.

---

## 🗂️ STRUKTURA KATALOGU

```
JDG/
├── README.md                          # Ten dokument — overview i nawigacja
├── MANIFEST.md                        # Tracker pokrycia reguł vs mapa kanoniczna 38c
├── rules/                             # Reguły Rego (38 plików, 633 reguły)
│   ├── kks.rego                       # 152 — Kodeks Karny Skarbowy (P200-P499)
│   ├── edge_cases.rego                # 114 — VAT/PIT/ZUS edge cases + limity
│   ├── accounting.rego                #  56 — PKPiR, KŚT, UoR, NBP FX, Remanent
│   ├── vat/
│   │   ├── substantive.rego           #  42 — Stawki VAT, zwolnienia, GTU, MPP, WNT
│   │   ├── deductions.rego            #  25 — Odliczenia VAT, korekty, ulga złe długi
│   │   └── procedures.rego            #  17 — Procedury: VAT-23, VAT-25, WIS, OSS/IOSS
│   ├── conflicts.rego                 #  27 — Konflikty międzydomenowe
│   ├── zus.rego                       #  15 — Składki, ulgi, zasiłki chorobowe/macierzyńskie
│   ├── crossborder.rego               #  14 — WNT, WDT, import/export, ViDA, CFC, TP
│   ├── allowances.rego                #  12 — Ulgi podatkowe (B+R, IP Box, termo)
│   ├── pit/
│   │   ├── kup.rego                   #   9 — Koszty uzyskania przychodu
│   │   ├── advances_returns.rego      #   8 — Zaliczki i zeznania roczne
│   │   ├── forms.rego                 #   7 — Formy opodatkowania
│   │   ├── transitions.rego           #   5 — Zmiany formy opodatkowania
│   │   └── exemptions.rego            #   5 — Zwolnienia przedmiotowe PIT
│   ├── temporal.rego                  #   9 — Temporalność reguł (valid_from/to)
│   ├── employer.rego                  #   9 — Obowiązki pracodawcy
│   ├── risk.rego                      #   8 — Fraud detection, risk scoring
│   ├── validation.rego                #   8 — NIP/REGON, ciągłość faktur
│   ├── business.rego                  #   8 — Cykl życia JDG (CEIDG, zawieszenie)
│   ├── environmental.rego             #   8 — BDO, KOBiZE, SUP
│   ├── compliance.rego                #   7 — Biała Lista, MPP, KSeF
│   ├── crossborder.rego (link)        #   7 — (alternatywna ścieżka)
│   ├── corrections.rego               #   6 — Faktury korygujące, storno
│   ├── restructuring.rego             #   7 — Restrukturyzacja, upadłość
│   ├── representation.rego            #   7 — Pełnomocnictwa (UPL-1, PPS-1)
│   ├── local_taxes.rego               #   7 — PCC, podatek od nieruchomości, transport
│   ├── ksef_jpk.rego                  #   6 — KSeF, JPK_V7 struktura
│   ├── retention.rego                 #   6 — Okresy przechowywania dokumentów
│   ├── digital.rego                   #   6 — E-commerce, platformy cyfrowe
│   ├── routing.rego                   #   5 — Routing field confidence
│   ├── liability.rego                 #   5 — Przedawnienia, odpowiedzialność
│   ├── rodo.rego                      #   4 — RODO — rejestr, retencja, breach
│   ├── mpips.rego                     #   4 — FP, FGŚP, PFRON, ZFŚS
│   ├── international.rego             #   4 — WHT, PE, TP
│   └── fallback.rego                  #   1 — Domyślna stawka 23% VAT
├── tests/                             # Testy OPA i Python
│   ├── test_kks.rego                  # Testy jednostkowe KKS
│   ├── test_vat.rego                  # Testy jednostkowe VAT
│   ├── test_pit.rego                  # Testy jednostkowe PIT
│   ├── test_zus.rego                  # Testy jednostkowe ZUS
│   └── test_coverage.py               # Test pokrycia kanonicznego vs 38c
├── docs/                              # Dokumentacja
│   ├── CANONICAL_COVERAGE.md          # Macierz pokrycia ~779 reguł kanonicznych
│   ├── ARCHITECTURE.md                # ADR — decyzje architektoniczne
│   └── UNIFIED_PLAN.md               # Zunifikowany plan wdrożenia
├── tools/                             # Narzędzia developerskie
│   ├── generate_manifest.py           # Auto-generacja MANIFEST.md z plików Rego
│   ├── validate_rules.py              # Linter reguł Rego (hardcoded values, struktura)
│   └── coverage_report.py             # Generator raportu pokrycia
└── bundles/                           # OPA Bundle
    ├── bundle.sh                       # Skrypt budujący bundle .tar.gz
    └── manifest.json                   # Bundle manifest (OPA v0.60+)
```

---

## 📈 METRYKI

| Metryka | Wartość |
|---------|---------|
| **Reguły Rego (matched:true)** | **633** |
| Pliki Rego | **38** |
| Linii kodu Rego | **~13,000** |
| BLOCK_AND_ALERT | **~195** |
| TRIAGE_QUEUE | **~120** |
| Pakiety OPA | **38** |
| Pokrycie mapy kanonicznej 38c (~779) | **~81%** |

### Top 10 pakietów

| # | Pakiet | Reguł | Domena |
|---|--------|:-----:|--------|
| 1 | `kks.rego` | 152 | Kodeks Karny Skarbowy |
| 2 | `edge_cases.rego` | 114 | VAT/PIT/ZUS edge cases |
| 3 | `accounting.rego` | 56 | PKPiR, KŚT, UoR |
| 4 | `vat/substantive.rego` | 42 | Stawki VAT, zwolnienia |
| 5 | `conflicts.rego` | 27 | Konflikty międzydomenowe |
| 6 | `vat/deductions.rego` | 25 | Odliczenia VAT |
| 7 | `vat/procedures.rego` | 17 | Procedury VAT |
| 8 | `zus.rego` | 15 | Składki i zasiłki ZUS |
| 9 | `crossborder.rego` | 14 | Transakcje transgraniczne |
| 10 | `allowances.rego` | 12 | Ulgi podatkowe |

---

## 🏗️ ARCHITEKTURA

### First-Match-Wins else-chain

Każdy plik `.rego` używa deterministycznej ewaluacji `else`-chain:

```rego
default decide := {"matched": false, "rule_id": "...no_match", "priority": 999}

decide := { ... } { condition_1 }       # Pierwsza reguła
else := { ... } { condition_2 }         # Druga reguła
else := { ... } { condition_3 }         # Trzecia reguła...
```

### Standardowy werdykt

Każda reguła zwraca 25 standardowych pól:

```rego
{
    "matched": true,
    "rule_id": "jdg.domena.nazwa_reguly",
    "package": "jdg.domena",
    "priority": NNN,
    "vat_rate": "0.23",              # Stawka VAT (string)
    "rounding_level": "position",    # "position" | "total"
    "gtu_code": "GTU_04",           # Kod GTU (lub "")
    "procedure": "",                 # "VAT_REVERSE_CHARGE" | "IMPORT" | ...
    "pit_form": "",                  # "PIT_SCALE" | "LINEAR" | "LUMP_SUM"
    "pit_rate": "",                  # Stawka PIT
    "kus_qualification": "",        # "deductible_full" | "non_deductible"
    "kus_percent": 0,               # Procent KUP
    "zus_social_base_type": "",     # "STANDARD" | "START_RELIEF" | ...
    "zus_health_rate": "",          # "0.09" | "0.049"
    "_routing": "",                  # "BLOCK_AND_ALERT" | "TRIAGE_QUEUE" | ""
    "_routing_reason": "",          # Czytelny powód routingu
    "_legal_basis": "Art. XX ustawy Y",  # Podstawa prawna
    "_warnings": []                  # Ostrzeżenia diagnostyczne
}
```

### Zasady projektowe

| Zasada | Implementacja |
|--------|---------------|
| **First-Match-Wins** | Rego `else` chain |
| **Zero Hardcoded Values** | `data.thresholds.*` przez OPA Data API |
| **Temporalność** | `valid_from` / `valid_to` + `temporal.rego` |
| **Audytowalność** | `rule_id` + `_legal_basis` w każdym werdykcie |
| **Immutowalność** | `immutable_verdict: true` dla krytycznych reguł (ZUS, zdrowotna) |

---

## 🗺️ MAPA KANONICZNA 38c

Mapa kanoniczna `Plan OPA/38c_JDG_CANONICAL_MAP.md` zawiera **~779 unikalnych reguł**
po deduplikacji dokumentów Docs 22-43. Jest to **źródło prawdy** dla wszystkich ID reguł.

Szczegółowa macierz pokrycia: → [`docs/CANONICAL_COVERAGE.md`](docs/CANONICAL_COVERAGE.md)

### Status wdrożenia wg domeny

| Domena | Cel (38c) | Wdrożono | % |
|--------|:---------:|:--------:|:--:|
| KKS | 230 | 152 | 66% |
| VAT (stawki + odliczenia + procedury) | ~120 | 84 | 70% |
| Edge Cases | ~200 | 114 | 57% |
| Księgowość (PKPiR, KŚT, UoR) | ~70 | 56 | 80% |
| PIT (formy, KUP, zaliczki, zwolnienia) | ~80 | 39 | 49% |
| Konflikty | 27 | 27 | 100% |
| ZUS (składki, zasiłki) | ~35 | 15 | 43% |
| Cross-border | ~25 | 14 | 56% |
| RODO | 4 | 4 | 100% |
| MPiPS | 4 | 4 | 100% |
| PCC/Podatki lokalne | 8 | 7 | 88% |
| Ulgi podatkowe | ~30 | 12 | 40% |
| Pozostałe (compliance, risk, etc.) | ~50 | 105 | 210%* |

> \*Niektóre domeny mają więcej reguł niż plan kanoniczny ze względu na rozszerzenia dodane podczas implementacji.

---

## 🚀 SZYBKI START

### Walidacja reguł

```bash
# Sprawdzenie składni wszystkich reguł
opa check JDG/rules/ -b

# Uruchomienie testów jednostkowych
opa test JDG/tests/ -v
```

### Generacja manifestu

```bash
python JDG/tools/generate_manifest.py
```

### Budowa OPA Bundle

```bash
cd JDG/bundles && bash bundle.sh
```

---

## 📚 POWIĄZANE DOKUMENTY

| Dokument | Opis |
|----------|------|
| `Plan OPA/38c_JDG_CANONICAL_MAP.md` | Mapa kanoniczna ~779 reguł (źródło prawdy) |
| `Plan OPA/41_JDG_MEGA_MATRIX_7000_RULES.md` | Dual-Layer Architecture (horyzont ~7000) |
| `Plan OPA/52_AUDYT_JAKOSCI_REGUL.md` | Audyt jakości reguł |
| `Plan OPA/51_MISSING_GAP_IMPLEMENTATION_PLAN.md` | Plan implementacji braków |
| `NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt` | Master plan strategiczny |

---

*Wygenerowano przez NexusAI JDG Module Engine v3.0 — 2026-07-13*
