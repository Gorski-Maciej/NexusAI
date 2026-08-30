# 🏛️ NexusAI JDG — Policy-as-Code (OPA/Rego)

> **Status:** MIRROR SYNCHRONIZED — ETAP 26 (2026-08-22)  
> **Wersja:** 2026.08 (mirror z `JDG/rules/`, hash-parity 0% drift)  
> **Plik referencyjny:** `JDG/rules/` — źródło prawdy (490 plików, ~11 855 rule_id)  
> **Pliki Rego (mirror):** 52 | **Linii kodu:** ~15 500

---

## 📁 Struktura 30 pakietów

```
policies/jdg/
├── README.md                          — Ten plik
├── main_jdg.rego              100 L   — Orchestrator Multi-Pass
├── _helpers_jdg.rego          110 L   — Helpery (thresholds, FC, MPP)
├── _metadata_jdg.rego         110 L   — Metadane reguł (severity, remediation)
│
│  ╔══════════════════════════════════════════════════════════════╗
│  ║  💚 ZAIMPLEMENTOWANE                                       ║
│  ╚══════════════════════════════════════════════════════════════╝
│
├── allowances.rego            599 L   — 10 ulg podatkowych ✅
│
│  ╔══════════════════════════════════════════════════════════════╗
│  ║  🟡 SZKIELETY (66 L każdy, default decide + wzorzec)      ║
│  ╚══════════════════════════════════════════════════════════════╝
│
├── risk.rego                   66 L   — P0-P9 Fraud, anomalie, GAAR
├── routing.rego                66 L   — P10-P19 Field confidence
├── compliance.rego             66 L   — P20-P157 Biała Lista, MPP, kasy
├── crossborder.rego            66 L   — P40-P49 WNT, WDT, eksport
├── zus.rego                    66 L   — P700-P770 Składki, ulgi ZUS
├── accounting.rego             66 L   — P800-P870 PKPiR, amortyzacja, FX
├── business.rego               66 L   — P900-P939 CEIDG, zawieszenie
├── corrections.rego            66 L   — P1100-P1120 Korekty faktur
├── liability.rego              66 L   — P1150-P1174 Przedawnienia
├── representation.rego         66 L   — P1200-P1212 Pełnomocnictwa
├── local_taxes.rego            66 L   — P1300-P1320 PCC, nieruchomości
├── ksef_jpk.rego               66 L   — P950-P989 KSeF, JPK_V7, JPK_PKPIR
├── international.rego          66 L   — P100-P117 WHT, PE, TP
├── employer.rego               66 L   — P1200e-P1223 Pracodawca
├── environmental.rego          66 L   — P1400-P1407 BDO, KOBiZE
├── restructuring.rego          66 L   — P1500-P1505 Przekształcenie
├── temporal.rego               66 L   — P1600-P1612 RMK, Time-Travel
├── digital.rego                66 L   — P630-P1895 Krypto, AI Act, MDR
├── retention.rego              66 L   — P990-P992 Przechowywanie
├── fallback.rego               66 L   — P1000-P1099 Domyślna 23% + NO_MATCH
│
├── vat/
│   ├── substantive.rego        66 L   — P50-P65 Stawki VAT, GTU, OSS
│   ├── deductions.rego         66 L   — P183-P192 Odliczenia, auta
│   └── procedures.rego         66 L   — Marża, VAT-RR, tax point
│
└── pit/
    ├── forms.rego              66 L   — P500-P539 4 formy opodatkowania
    ├── kup.rego                66 L   — P560-P582 KUP wyłączenia
    ├── advances_returns.rego   66 L   — P540-P559 Zaliczki
    ├── exemptions.rego         66 L   — P580-P588 PIT-0 (młodzi, powrót, 4+, senior)
    └── transitions.rego        66 L   — P590-P599 Zmiana formy
```

---

## 🔗 Architektura Multi-Pass

```
INPUT ──► PASS 0: RISK ──────► PASS 1: ROUTING ──► PASS 2: COMPLIANCE ──►
              │ (BLOCK→abort)      │ (BLOCK→abort)     │
              ▼                    ▼                   ▼
         risk_verdict        routing_verdict     compliance_verdict

         PASS 3: CROSSBORDER ──► PASS 4: VAT ──────► PASS 5: PIT ────────►
              │                    │                    │
              ▼                    ▼                    ▼
         cross_verdict        vat_verdict          pit_verdict

         PASS 6: ALLOWANCES ──► PASS 7: ACCOUNTING ─► PASS 8: RESZTA ─────►
              │                    │                    │
              ▼                    ▼                    ▼
         allowances_verdict  accounting_verdict    misc_verdict

         ► VERDICT MERGER ──► final_verdict
```

`main_jdg.rego` scala wszystkie 29 pakietów przez zagnieżdżone `object.union()` — najniższy priorytet wewnątrz (fallback), najwyższy na zewnątrz (risk).

---

## 📊 Mapa priorytetów

| Priorytet | Pakiet | Plik | Odpowiedzialność | Status |
|:---------:|--------|------|-------------------|:------:|
| P0-P9 | `jdg.risk` | `risk.rego` | Fraud, anomalie, KKS, GAAR, CEIDG | 🟡 |
| P10-P19 | `jdg.routing` | `routing.rego` | Field confidence per forma | 🟡 |
| P20-P157 | `jdg.compliance` | `compliance.rego` | Biała Lista, MPP, kasy, CESOP | 🟡 |
| P40-P49 | `jdg.crossborder` | `crossborder.rego` | WNT, WDT, import, eksport | 🟡 |
| P50-P65 | `jdg.vat.substantive` | `vat/substantive.rego` | Stawki VAT, GTU, OSS | 🟡 |
| P100-P117 | `jdg.international` | `international.rego` | WHT, PE, TP | 🟡 |
| P183-P192 | `jdg.vat.deductions` | `vat/deductions.rego` | Odliczenia, korekty, auta | 🟡 |
| P230-P235 | `jdg.vat.procedures` | `vat/procedures.rego` | Marża, VAT-RR, tax point | 🟡 |
| P500-P539 | `jdg.pit.forms` | `pit/forms.rego` | Skala, liniowy, ryczałt, karta | 🟡 |
| P540-P559 | `jdg.pit.advances` | `pit/advances_returns.rego` | Zaliczki i zeznania | 🟡 |
| P560-P582 | `jdg.pit.kup` | `pit/kup.rego` | KUP — wyłączenia i ograniczenia | 🟡 |
| P580-P588 | `jdg.pit.exemptions` | `pit/exemptions.rego` | PIT-0 (młodzi, powrót, 4+, senior) | 🟡 |
| P590-P599 | `jdg.pit.transitions` | `pit/transitions.rego` | Zmiana formy opodatkowania | 🟡 |
| **P600-P635** | **`jdg.allowances`** | **`allowances.rego`** | **10 ulg podatkowych** | **💚** |
| P700-P770 | `jdg.zus` | `zus.rego` | Składki społeczne, zdrowotne | 🟡 |
| P800-P870 | `jdg.accounting` | `accounting.rego` | PKPiR, amortyzacja, leasing | 🟡 |
| P900-P939 | `jdg.business` | `business.rego` | CEIDG, zawieszenie, sukcesja | 🟡 |
| P950-P989 | `jdg.ksef_jpk` | `ksef_jpk.rego` | KSeF, JPK_V7, JPK_PKPIR | 🟡 |
| P990-P992 | `jdg.retention` | `retention.rego` | Przechowywanie dokumentów | 🟡 |
| P1000-P1099 | `jdg.fallback` | `fallback.rego` | Domyślna 23% + NO_MATCH | 🟡 |
| P1100-P1120 | `jdg.corrections` | `corrections.rego` | Korekty faktur, JPK | 🟡 |
| P1150-P1174 | `jdg.liability` | `liability.rego` | Przedawnienia, odsetki | 🟡 |
| P1200-P1212 | `jdg.representation` | `representation.rego` | Pełnomocnictwa PPS-1 | 🟡 |
| P1200e-P1223 | `jdg.employer` | `employer.rego` | JDG jako pracodawca | 🟡 |
| P1300-P1320 | `jdg.local` | `local_taxes.rego` | PCC, nieruchomości | 🟡 |
| P1400-P1407 | `jdg.environmental` | `environmental.rego` | BDO, KOBiZE | 🟡 |
| P1500-P1505 | `jdg.restructuring` | `restructuring.rego` | Przekształcenie JDG | 🟡 |
| P1600-P1612 | `jdg.temporal` | `temporal.rego` | RMK, Time-Travel | 🟡 |
| P630-P1895 | `jdg.digital` | `digital.rego` | Krypto, AI Act, MDR | 🟡 |

---

## 💚 Szczegóły implementacji: `allowances.rego`

**10 ulg, 11 reguł else-chain, 599 linii, 55 mikro-reguł:**

| Priorytet | Rule ID | Ulga | Podstawa | Mikro-reguły |
|:---------:|---------|------|----------|:------------:|
| P600 | `relief_rd_centrum` | B+R 200% (CBR) | Art. 26e ust. 10 PIT | jdg.pit.a26e.r1-r15 |
| P600 | `relief_rd_standard` | B+R 100% | Art. 26e ust. 1 PIT | jdg.pit.a26e.r1-r15 |
| P605 | `relief_ikze` | IKZE (wpłata >0) | Art. 26 ust. 1 pkt 2b | jdg.pit.a26b.r1-r6 |
| P605_b | `relief_ikze_no_contribution` | IKZE (brak wpłaty) | Art. 26 ust. 1 pkt 2b | jdg.pit.a26b.r1 |
| P608 | `relief_innovative_employees` | Innow. pracownicy | Art. 26eb PIT | jdg.pit.a26eb.r1-r7 |
| P610 | `relief_ip_box` | IP Box 5% | Art. 30ca PIT | jdg.pit.a30ca.r1-r10 |
| P612 | `relief_csr_sponsoring` | CSR/sponsoring | Art. 26ha PIT | jdg.pit.a26ha.r1-r5 |
| P614 | `relief_payment_terminal` | Terminal płatniczy | Art. 26hd PIT | jdg.pit.a26hd.r1-r6 |
| P618 | `relief_bad_debt_pit_creditor` | Złe długi PIT | Art. 26i PIT | jdg.pit.a26i.r1-r7 |
| P620 | `relief_abolition` | Abolicyjna | Art. 27g PIT | jdg.pit.a27g.r1-r6 |
| P622 | `relief_union_dues` | Związki zawodowe | Art. 26 ust. 1 pkt 2c | jdg.pit.a26u1p2c.r1-r5 |
| P630 | `crypto_income_classification` | Krypto 19% | Art. 30b ust. 1 pkt 1 | — |
| P639 | `no_match` | Domyślny fallback | — | — |

### Kluczowe cechy implementacji:

- **First-Match-Wins**: `else` chain gwarantuje deterministyczną kolejność
- **Zero hardcoded values**: limity przez `object.get(input.thresholds.jdg.*)`
- **Helper rules**: `ikze_over_limit_warning(contribution, limit)`, `terminal_limit`
- **Eligibility checks**: `ikze_eligible`, `innovative_employee_eligible`, `abolution_eligible`, `union_dues_eligible`, `bad_debt_pit_eligible`
- **Warning builder**: każda reguła generuje czytelne `_warnings` w języku polskim

---

## 🟡 Postęp implementacji

| Kategoria | Zaimplementowano | Szkielety | Razem |
|-----------|:---:|:---:|:---:|
| Ulgi podatkowe | 💚 1 | — | 1 |
| VAT | — | 🟡 3 | 3 |
| PIT | — | 🟡 5 | 5 |
| ZUS | — | 🟡 1 | 1 |
| Księgowość | — | 🟡 1 | 1 |
| Biznes | — | 🟡 1 | 1 |
| Compliance/Risk | — | 🟡 4 | 4 |
| Cross-border | — | 🟡 2 | 2 |
| KSeF/JPK | — | 🟡 1 | 1 |
| Pozostałe | — | 🟡 8 | 8 |
| Infrastruktura | 💚 3 | — | 3 |
| **RAZEM** | **4** | **28** | **32** |

### Sugerowana kolejność implementacji:

1. 🔴 **`risk.rego`** (P0-P9) — fraud/GAAR, najwyższy priorytet, blokuje łańcuch
2. 🔴 **`routing.rego`** (P10-P19) — field confidence, blokuje przed księgowaniem
3. 🟠 **`zus.rego`** (P700-P770) — składki, ulgi ZUS, 110 reguł gotowych w doc 34
4. 🟠 **`pit/forms.rego`** (P500-P539) — fundament PIT, 4 formy opodatkowania
5. 🟡 **`vat/substantive.rego`** (P50-P65) — stawki VAT, GTU
6. 🟡 **`ksef_jpk.rego`** (P950-P989) — KSeF od 01.02.2026

---

## 📐 Standardowy werdykt JDG

Każda reguła zwraca ten sam ustandaryzowany obiekt (Doc 34, Sekcja 1.2):

```json
{
    "matched": true,
    "rule_id": "jdg.package.rule_name",
    "package": "jdg.package",
    "priority": 600,
    "vat_rate": "",
    "rounding_level": "",
    "gtu_code": "",
    "pit_form": "PIT_SCALE",
    "pit_rate": "0.12",
    "pit_bracket": "LOW",
    "pit_annual_return_type": "PIT-36",
    "kus_qualification": "full",
    "kus_percent": 100,
    "zus_social_base_type": "STANDARD",
    "zus_health_rate": "0.09",
    "business_status": "ACTIVE",
    "ceidg_registration_required": false,
    "relief_type": "R_AND_D",
    "relief_percent": 100,
    "relief_limit": 0,
    "relief_deductible": 0,
    "relief_carry_forward_years": 6,
    "relief_rule_ids": ["jdg.pit.a26e.r1", "..."],
    "_routing": "",
    "_routing_reason": "",
    "_legal_basis": "Art. 26e PIT",
    "_warnings": []
}
```

---

## 🔗 Powiązane dokumenty

| Dokument | Opis |
|----------|------|
| `Plan OPA/34_JDG_DEFINITIVE_REGO_PLAN.md` | Definitywny plan — ~1 200 reguł, architektura, priorytety |
| `Plan OPA/33_JDG_MASSIVE_RULE_CATALOG.md` | Katalog 1 615 mikro-reguł z dekompozycją artykuł po artykule |
| `Plan OPA/00_PLAN_STRUKTURA.md` | Oryginalny plan architektoniczny OPA |
| `policies/tax/` | Legacy reguły podatkowe (CIT+PIT, do migracji na JDG) |

---

> **Built with ❤️ by NexusAI Team** | OPA/Rego | First-Match-Wins | Multi-Pass | Zero Hardcoded
