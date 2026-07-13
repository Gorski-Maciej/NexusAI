# 🎯 Zunifikowany Plan Wdrożenia Modułu JDG

> **Scalenie 67 dokumentów Plan OPA w jeden nurt**
> **Data:** 2026-07-13 | **Mapa kanoniczna:** 38c (~779 reguł)

---

## Problem: 5 Konkurujących Strategii

Plan OPA zawiera 67 dokumentów (83,702 linii) z wieloma konkurującymi strategiami:

| # | Dokument | Strategia | Status |
|---|----------|-----------|:------:|
| 1 | `00_PLAN_STRUKTURA.md` | 240 reguł, 13 faz | 📐 Fundament |
| 2 | `24_JDG_COMPLETE_INDEX.md` | 47 reguł ID | 🔴 DEPRECATED |
| 3 | `38c_JDG_CANONICAL_MAP.md` | ~779 reguł | ⭐ ŹRÓDŁO PRAWDY |
| 4 | `41_JDG_MEGA_MATRIX_7000_RULES.md` | ~7000 Micro | 🎯 Horyzont 2027+ |
| 5 | `45_JDG_HYPER_GRANULARITY.md` | ~700 atomowych | 🧪 Eksperyment |

**Decyzja:** 38c (~779) = źródło prawdy. Wszystkie strategie scalone w jeden nurt.

---

## Stan Faktyczny

```
STAN OBECNY:  633 reguł (matched:true) w 38 plikach Rego
CEL:          779 reguł (mapa kanoniczna 38c)
LUKA:         146 regułów
HORYZONT:     7000 regułów Micro (Dual-Layer, 2027+)
```

---

## 3 Fazy Wdrożenia

### Faza A: Domknięcie Krytyczne ✅ (ZREALIZOWANE)

| # | Zadanie | Docelowy plik |
|---|---------|---------------|
| A1 | P189 Temporal Fix (150→90 dni SLIM VAT 3) | `vat/deductions.rego`, `vat/substantive.rego` |
| A2 | Accounting matched:false → matched:true | `accounting.rego` |
| A3 | Edge cases Grupy D (VAT 200k), E (PIT), I (cross-border) — +24 | `edge_cases.rego` |
| A4 | VAT procedury (VAT-23, VAT-25, WIS, SLIM VAT3, sankcja 30%) — +6 | `vat/procedures.rego` |
| A5 | Cross-border (ViDA, ICOW, TP, CFC, WHT, PE) — +7 | `crossborder.rego` |
| **Wynik** | **633 reguł, 38 plików, KKS kompletny (152)** | |

### Faza B: Uzupełnienie Kluczowe (P1) ⬜ — +53 regułów

| # | Zadanie | Reguł | Docelowy plik |
|---|---------|:-----:|---------------|
| B1 | RODO rozszerzenie (zgody marketingowe, monitoring, transfer EOG) | ~8 | `rodo.rego` |
| B2 | MPiPS szczegóły (PPK, świadczenia urlopowe, odprawy) | ~8 | `mpips.rego` |
| B3 | ZUS emerytury/renty długoterminowe | ~6 | `zus.rego` |
| B4 | Edge cases pozostałe (VAT-UE korygowany, odwrotne obciążenie) | ~15 | `edge_cases.rego` |
| B5 | PKPiR weryfikacje szczegółowe (walidacje kolumn 10-19) | ~10 | `accounting.rego` |
| B6 | Podatki lokalne rozszerzenie (PCC, nieruchomości) | ~6 | `local_taxes.rego` |
| **Wynik** | **633 → ~686 regułów (~88% pokrycia 38c)** | **~53** | |

### Faza C: Doszlifowanie Enterprise (P2) ⬜

**Część 1 — Nowe reguły (+93):**

| # | Zadanie | Reguł |
|---|---------|:-----:|
| C1 | Doc 28a Enterprise Accounting (R0372-R0399) | ~28 |
| C2 | Doc 28a Korekty deklaracji (R0420-R0435) | ~16 |
| C3 | Doc 28a Przedawnienia (R0436-R0449) | ~14 |
| C4 | Doc 28a Reprezentacja / Pełnomocnictwa (R0450-R0459) | ~10 |
| C5 | Pozostałe edge cases Doc 28a | ~25 |
| **Wynik** | **~686 → ~779 regułów (~100% pokrycia 38c)** | **+93** |

**Część 2 — Jakość i DevOps:**

| # | Zadanie | Typ |
|---|---------|-----|
| C6 | Testy OPA dla wszystkich pakietów JDG | Testy |
| C7 | Migracja hardcoded → data.thresholds | Refaktoryzacja |
| C8 | CI/CD: walidacja składni Rego w pipeline | DevOps |

---

## Metryki Docelowe

| Etap | Reguł | Przyrost | Pokrycie 38c |
|------|:-----:|:--------:|:------------:|
| **Stan obecny** ✅ | 633 | — | ~81% |
| Po Fazie B | ~686 | +53 | ~88% |
| Po Fazie C | **~779** | +93 | **~100%** |

---

*Wygenerowano przez NexusAI Unified Plan Engine v1.0 — 2026-07-13*
