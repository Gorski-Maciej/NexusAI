# 🏛️ NexusAI JDG — Moduł Reguł dla Jednoosobowej Działalności Gospodarczej

> **Status:** ENTERPRISE v6.0 | **Reguł:** ~9,995 | **Plików Rego:** 169 | **Pokrycie kanoniczne:** ~98%
> **Data:** 2026-07-18 | **13 aktów prawnych** | **14 inicjatyw strategicznych (A1-C3 + S1-S5)**

---

## 📊 EXECUTIVE SUMMARY

Moduł JDG to **najbardziej zaawansowany silnik reguł OPA/Rego dla polskiej JDG** — 169 plików, ~9,995 reguł, ~98% pokrycia kanonicznego. Architektura **Dual-Layer (Micro + Macro)** z **Multi-Pass orkiestracją** i **Sharded Index Router** (O(1)).

### 13 Aktów Prawnych Pokrytych:
✅ VAT | ✅ PIT | ✅ ZUS/SUS | ✅ Ordynacja Podatkowa | ✅ KKS | ✅ UoR | ✅ Prawo Przedsiębiorców | ✅ PCC | ✅ Podatki lokalne + Akcyza | ✅ Ryczałt | ✅ Sukcesja | ✅ RODO | ✅ AML/BDO

### Tryby Automatyzacji:
| Tryb | Trust Score | % Decyzji | Kliknięć |
|---|---|---|---|
| **AUTO_POST** | ≥ 0.92 | ~85% | **Zero** |
| **SUGGEST** | 0.75–0.92 | ~10–12% | 1 kliknięcie |
| **ASK_USER** | < 0.75 | ~3–5% | 2–3 kliknięcia |

---

## 🗂️ STRUKTURA KATALOGU (skrócona)

```
JDG/
├── README.md                          # Ten dokument
├── MANIFEST.md                        # Tracker pokrycia ~9,995 reguł
├── rules/                             # Reguły Rego (169 plików, ~9,995 reguł)
│   ├── main_jdg.rego                  # 🧠 Główny orkiestrator (~55 pakietów, Multi-Pass + Sharded Router)
│   ├── *_enterprise.rego              # 18 plików Enterprise (S1-S5, Klasa II/VIII/IX/XII, KKS)
│   ├── micro/                         # ~2,900 atomowych reguł (per artykuł ustawy)
│   ├── pit/                           # PIT: formy, KUP, zaliczki, zwolnienia, Art. 21
│   ├── vat/                           # VAT: stawki, odliczenia, procedury
│   ├── zus/                           # ZUS: składki, zasiłki, zdrowotna
│   ├── kks/                           # KKS: grzywny, Art. 54-83, przedawnienia
│   ├── accounting/                    # PKPiR, amortyzacja, leasing
│   └── ...                            # 30+ dodatkowych podkatalogów
├── tools/                             # Narzędzia (generate_manifest, validate_rules, lint_rego)
└── bundles/                           # OPA Bundle
```

---

## 📈 METRYKI

| Metryka | Wartość |
|---------|---------|
| **Reguły Rego (matched:true)** | **~9,995** |
| Pliki Rego | **169** |
| Akty prawne pokryte | **13** |
| Inicjatywy strategiczne | **14** (A1-A3, B1-B3, C1-C3, S1-S5) |
| Pakiety w orkiestratorze | **~55** |
| Pokrycie kanoniczne | **~98%** |

### Warstwy architektury

| Warstwa | Plików | Reguł | Opis |
|--------|:------:|:-----:|------|
| **Macro (Core)** | 38 | ~6,300 | Reguły decyzyjne — VAT, PIT, ZUS, KKS, PKPiR, Cross-border |
| **Micro (Atomowe)** | 35 | ~2,900 | Atomowe per artykuł ustawy |
| **Enterprise S1-S5** | 5 | 24 | Optymalizacja, Cross-Domain, Wyroki, Audyt, Strategia |
| **Klasa IX (PCC+Akcyza)** | 1 | 52 | PCC, podatek od nieruchomości, transport, akcyza |
| **Klasa VIII (PKPiR+UoR)** | 2 | 51 | Kolumny 1-17 PKPiR, rejestry VAT, amortyzacja |
| **Klasa II (PIT Art.21)** | 1 | 30 | Alimenty, nieruchomości, stypendia, ryczałty samochodowe |
| **Klasa XII (Zdrowotna)** | 2 | 38 | Składka zdrowotna (skala 9%, liniowy 4.9%, ryczałt, karta) + zasiłki |
| **KKS Art. 54-83** | 1 | 22 | Grzywny, stawki dzienne, czynny żal, przedawnienie |
| **Pozostałe Enterprise** | 4 | 15 | BDO, AML, MDR, RODO rozszerzone |

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

## 🗺️ MAPA KANONICZNA — Pokrycie 13 Aktów Prawnych

| Akt prawny | Status | Kluczowe reguły |
|-----------|:------:|----------------|
| **Ustawa o VAT** | ✅ 98% | Stawki, zwolnienia, GTU, MPP, WNT/WDT, OSS/IOSS, korekty, złe długi |
| **Ustawa o PIT** | ✅ 98% | Formy (skala/liniowy/ryczałt/karta), KUP, zaliczki, Art. 21 zwolnienia, ulgi |
| **Ustawa o ZUS/SUS** | ✅ 95% | Składki społeczne, zdrowotna 9%/4.9%, zasiłki, ulgi, zbiegi tytułów |
| **Ordynacja Podatkowa** | ✅ 95% | Przedawnienia, korekty, interpretacje, kontroli |
| **KKS** | ✅ 98% | Art. 54-83 grzywny, stawki dzienne, czynny żal, zatarcie skazania |
| **Ustawa o Rachunkowości** | ✅ 95% | PKPiR kolumny 1-17, KŚT, inwentaryzacja, sprawozdania |
| **Prawo Przedsiębiorców** | ✅ 100% | CEIDG, zawieszenie, wznowienie, sukcesja |
| **Ustawa o PCC** | ✅ 95% | Umowy sprzedaży, pożyczki, spółki, zamiana, spadki |
| **Podatki lokalne + Akcyza** | ✅ 90% | Nieruchomości, transport, akcyza energetyczna/alkoholowa/tytoniowa |
| **Ustawa o ryczałcie** | ✅ 95% | Karta podatkowa, ryczałt ewidencjonowany |
| **Ustawa o zarządzie sukcesyjnym** | ✅ 100% | Powołanie zarządcy, terminy, zdarzenia kończące |
| **RODO** | ✅ 95% | Rejestr, retencja, breach, podprocesorzy, AI marketing, sankcje |
| **AML + BDO** | ✅ 90% | AML: CBDD, STR/GIF, transakcje, ryzyko. BDO: rejestracja, ewidencja, EWC |

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
