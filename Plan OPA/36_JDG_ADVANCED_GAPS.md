# 🔬 JDG Advanced Gaps — Druga Warstwa Analizy Luk ENTERPRISE

> **Status:** ENTERPRISE v2.1 — Głęboka analiza 26 wyspecjalizowanych obszarów
> **Data:** 2026-07-11
> **Bazuje na:** 29 plikach `.rego`, `35_JDG_ENTERPRISE_GAP_ANALYSIS.md`, `20_MASTER_RULES_REFERENCE.md`
> **Pokrycie:** 26 obszarów × szczegółowa analiza CO JUŻ JEST vs CO BRAKUJE
> **Nowe luki:** 174 brakujących reguł w 26 obszarach (137 w 20 obszarach bazowych + 37 w 6 nowych obszarach ENTERPRISE)
> **Kontynuacja numeracji P:** P340–P999 (nie koliduje z P100–P339 z Master Reference oraz P1000–P1617 z implementacji)
> **Uwaga:** P359 celowo pominięty (rezerwa na przyszłe reguły); luki w numeracji wynikają z grupowania tematycznego

---

## 📊 Executive Summary

| Metryka | Wartość |
|---|---|
| **Reguły zaimplementowane (JDG)** | ~355 w 29 plikach |
| **Luki w pierwszej analizie (Doc 35)** | 78 reguł w 15 obszarach |
| **Luki w tej analizie** | **180 reguł** w 26 obszarach |
| **Wspólne / pokrywające się z Doc 35** | ~48 reguł (opisane z cross-referencjami, bez duplikacji) |
| **Nowe, unikalne luki** | **~126 reguł** (89 szczegółowych + 37 w 6 nowych obszarach) |
| **Nowe obszary ENTERPRISE** | 6 (MDR [7], DAC7 [6], ESG [5], Upadłość [6], Siła Wyższa [5], Kasa Fiskalna [8]) |
| **Alignment z nowymi pakietami z Doc 35** | `jdg.validation` (P950+), `jdg.audit` (P970+), `jdg.conflicts` (P900+) |

---

## 🔗 Cross-Reference: Doc 36 → Doc 35

| # | Obszar w Doc 36 | Pokrycie w Doc 35 (§) | Relacja |
|---|---|---|---|
| 1 | Reguły Temporalne | §11 (Progi i Limity Czasowe) | **Rozszerza** — dodaje metadane effective_from/to, okresy przejściowe, minimum wage history |
| 2 | Walidacja Danych | §13 (jdg.validation) | **Implementuje** — rozpisuje pełną listę 9 reguł walidacyjnych z checksumami |
| 3 | Limity i Progi | §11 + rozproszone | **Systematyzuje** — zbiera 10 rozproszonych limitów w jeden spójny katalog |
| 4 | Sankcje i Odsetki | §8 (Przedawnienia) + rozproszone | **Rozszerza** — dodaje konkretne stawki odsetek, sankcje JPK/KSeF/MPP |
| 5 | Scenariusze Wyjątkowe | §15 (Scenariusze Brzegowe) | **Pogłębia** — 7 nowych edge case'ów |
| 6 | Dokumentacja i Retencja | — (brak w 35) | **Nowy obszar** — numeracja faktur, potwierdzenia, podpis elektroniczny |
| 7 | Kontrola i Audyt | §14 (jdg.audit) + §7 (Korekty) | **Rozszerza** — dodaje protokoły, terminy, uprawnienia podczas kontroli |
| 8 | Transakcje Gotówkowe | §14 (audit trace) | **Pogłębia** — agregacja dzienna, GIIF, sankcja 20% |
| 9 | Split Payment (MPP) | część w implementacji (P25) | **Rozszerza** — pełny załącznik 15, rachunek VAT, zwolnienie środków |
| 10 | Biała Lista VAT | część w implementacji (P20-P21) | **Rozszerza** — weryfikacja przed przelewem, bufor 3-dniowy, ZAW-NR |
| 11 | Ulga na Złe Długi | część w implementacji (P60, P184, P571) | **Pogłębia** — 5 szczegółowych mikro-reguł (notyfikacje, odwrócenie, wyłączenia) |
| 12 | Odwrotne Obciążenie | część w implementacji (P40-P41) | **Rozszerza** — załączniki 11/14, podwykonawstwo, gaz/energia |
| 13 | Procedura Marży | część w implementacji (P50, P66) | **Pogłębia** — 5 szczegółowych reguł (dzieła sztuki, antyki, metoda globalna) |
| 14 | Import Usług | §6 (Crossborder) | **Pogłębia** — tax point, fx rate, podstawa opodatkowania |
| 15 | Podatek u Źródła (WHT) | — (brak szczegółowego w 35) | **Nowy obszar** — 8 reguł WHT (dywidendy, odsetki, licencje, UPO, pay-and-refund) |
| 16 | JDG z Pracownikami | §15.2 (employer checklist) | **Rozszerza** — ZUS DRA/RCA, PIT-11, PFRON, Fundusz Pracy |
| 17 | JDG z Majątkiem | §1.5 (amortyzacja) + rozproszone | **Rozszerza** — KŚT, ulepszenia, sprzedaż, leasing finansowy |
| 18 | Różne Formy Opodatkowania | §5 (Zmiana Formy) + §10 (Forma vs Składki) | **Pogłębia** — terminy wyboru, wykluczone usługi, interakcje z ulgami |
| 19 | Działalność Sezonowa | — (brak w 35) | **Nowy obszar** — 6 reguł dla sezonowego JDG |
| 20 | Kontrola Skarbowa | §7 (Korekty — audit lock) + §8.1 (przedawnienia) | **Rozszerza** — 7 szczegółowych reguł proceduralnych |
| 21 | 🆕 MDR (Mandatory Disclosure Rules) | — (brak) | **Nowy obszar ENTERPRISE** |
| 22 | 🆕 DAC7 (Platform Reporting) | — (brak) | **Nowy obszar ENTERPRISE** |
| 23 | 🆕 ESG / CSRD | — (brak) | **Nowy obszar ENTERPRISE** |
| 24 | 🆕 Upadłość / Niewypłacalność | — (brak) | **Nowy obszar ENTERPRISE** |
| 25 | 🆕 Siła Wyższa (Force Majeure) | — (brak) | **Nowy obszar ENTERPRISE** |
| 26 | 🆕 Kasa Fiskalna | część w implementacji (P145) | **Rozszerza** — pełna macierz zwolnień i obowiązków |

---

## 1. ⏱️ REGUŁY TEMPORALNE — effective_from / effective_to

> **📎 Cross-ref Doc 35:** §11 (Progi i Limity Czasowe, P1614–P1617)
> **📦 Pakiet docelowy:** `jdg.temporal` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — bez temporal metadata reguły nie są audytowalne w czasie

### CO JUŻ JEST:
- `jdg.temporal`: P1600–P1612 (przedawnienia, RMK, Time-Travel, historyczne stawki PIT)
- P1604–P1605: RMK — stawka VAT wg roku
- P1606–P1608: Historyczne stawki PIT 2019/2025
- P1610: Time-Travel OPA — ewaluacja na datę historyczną

### CO BRAKUJE:

| # | Reguła | P | Podstawa prawna | Status |
|---|---|---|---|---|
| 1 | `temporal_effective_from_to_per_rule` — metadane `effective_from`/`effective_to` dla każdej reguły w `_metadata_jdg.rego` | P1800 | Architektura ENTERPRISE | ❌ Brak |
| 2 | `temporal_polski_lad_transition` — okres przejściowy Polski Ład (01.01.2022–30.06.2022) ze starymi stawkami PIT 17% | P1613 | Art. 27 PIT (stan na 01.01.2022) | ❌ Brak |
| 3 | `temporal_covid_legacy` — przedłużone terminy COVID (ZUS, VAT, PIT — rozporządzenia 2020–2021) | P1614 | Rozp. COVID (archiwalne) | ❌ Brak |
| 4 | `temporal_ksef_delayed` — przesunięcie KSeF: planowane 2024 → 01.02.2026 | P1615 | Art. 106na VAT (nowelizacja) | ✅ w ksef_jpk P950 |
| 5 | `temporal_minimum_wage_history` — historyczne stawki płacy minimalnej (2018–2026) dla kalkulacji ZUS | P1616 | Rozp. RM ws. min. wynagr. | ❌ Brak |
| 6 | `temporal_nbp_fx_rate_date` — obowiązek użycia kursu NBP z dnia poprzedzającego transakcję | P1617 | Art. 31a ust. 1 PIT | ⚠️ Częściowo |

#### 🔧 Sygnatura reguły Rego (wzorzec implementacji):

```rego
# P1616 — temporal_minimum_wage_history
# Podstawa: Rozp. RM ws. minimalnego wynagrodzenia (coroczne)
# Cel: Zwróć minimalne wynagrodzenie obowiązujące w dacie transakcji
default min_wage := 0
min_wage := input.thresholds.minimum_wage_2026 {
    input.temporal.effective_date >= "2026-01-01"
}
else := input.thresholds.minimum_wage_2025 {
    input.temporal.effective_date >= "2025-01-01"
}
else := input.thresholds.minimum_wage_2024 {
    input.temporal.effective_date >= "2024-07-01"
}
# ... kontynuacja dla lat 2018-2024
```

---

## 2. ✅ WALIDACJA DANYCH WEJŚCIOWYCH

> **📎 Cross-ref Doc 35:** §13 (jdg.validation, P950–P969) — ten dokument ROZSZERZA katalog reguł
> **📦 Pakiet docelowy:** `jdg.validation` (NOWY — zdefiniowany w Doc 35)
> **🎯 Priorytet ogólny:** P0 — NIP checksum i data consistency to absolutne minimum

### CO JUŻ JEST:
- `jdg.risk`: fraud_graph_match, anomaly_amount, semantic_guard_disallowed
- `jdg.routing`: field confidence (P10–P19)
- Brak dedykowanego pakietu walidacji danych

### CO BRAKUJE:

| # | Reguła | P | Podstawa prawna | Opis |
|---|---|---|---|---|
| 7 | `validate_nip_checksum` | P950 | Rozp. MF ws. NIP | Suma kontrolna NIP: wagi 6,5,7,2,3,4,5,6,7 → mod 11 |
| 8 | `validate_iban_checksum` | P951 | ISO 13616 | IBAN checksum: mod 97 + PL = 2521 |
| 9 | `validate_invoice_date_gt_sale_date` | P952 | Art. 106e VAT | Data faktury ≥ data dostawy/usługi |
| 10 | `validate_vat_rate_positive` | P953 | — | Stawka VAT nie może być ujemna |
| 11 | `validate_net_amount_non_negative` | P954 | Art. 29a VAT | Kwoty netto ≥ 0 (chyba że korekta) |
| 12 | `validate_ceidg_nip_format` | P955 | Art. 5 CEIDG | NIP JDG = 10 cyfr |
| 13 | `validate_regon_checksum` | P956 | Rozp. GUS | REGON 9-cyfrowy: wagi 8,9,2,3,4,5,6,7 → mod 11 |
| 14 | `validate_krs_number_format` | P957 | Art. 36 KRS | KRS: 10 cyfr |
| 15 | `validate_date_range_sanity` | P958 | — | Data transakcji ≠ future, ≠ przed 1990-01-01 |

#### 🔧 Sygnatura reguły Rego:

```rego
# P950 — validate_nip_checksum
# Walidacja sumy kontrolnej NIP (10 cyfr)
validate_nip := result {
    nip := input.entity.nip
    digits := array.slice(regex.split(nip, ""), 0, 10)
    weights := [6, 5, 7, 2, 3, 4, 5, 6, 7]
    sum := sum([to_number(digits[i]) * weights[i] | i := numbers.range(0, 8)])
    checksum := sum % 11
    result := {"valid": checksum == to_number(digits[9]), "nip": nip}
}
```

---

## 3. 📏 LIMITY I PROGI — osobne reguły dla każdego limitu

> **📎 Cross-ref Doc 35:** §11 (P1614–P1617) + rozproszone (P58, P145, P842, P930)
> **📦 Pakiet docelowy:** `jdg.accounting` / `jdg.vat.substantive` / `jdg.zus` (rozszerzenia istniejących)
> **🎯 Priorytet ogólny:** P1 — każdy JDG musi wiedzieć który limit go obowiązuje

### CO JUŻ JEST:
- P58: `vat_exemption_subject_jdg` — limit 200k VAT
- P930: `unregistered_activity_limit` — limit dział. nieewidencjonowanej (50% min. wynagr.)
- P842: `depreciation_one_off` — limit 100k PLN
- P145: `cash_register_b2c_exemption` — limit 20k PLN

### CO BRAKUJE:

| # | Reguła | P | Limit | Podstawa prawna |
|---|---|---|---|---|
| 16 | `limit_lump_sum_revenue_2m_eur` | P340 | 2 000 000 EUR rocznie | Art. 6 ust. 4 ustawy o ryczałcie |
| 17 | `limit_small_taxpayer_2m_eur` | P341 | 2 000 000 EUR rocznie brutto | Art. 2 pkt 25a VAT |
| 18 | `limit_full_accounting_2m_eur` | P342 | 2 000 000 EUR rocznie (PKPiR→Księgi) | Art. 24a ust. 4 PIT |
| 19 | `limit_cash_transaction_15k` | P343 | 15 000 PLN (płatności gotówkowe B2B) | Art. 22p PIT |
| 20 | `limit_tax_free_amount_30k` | P344 | 30 000 PLN kwoty wolnej (skala PIT) | Art. 27 ust. 1 PIT |
| 21 | `limit_lump_sum_quarterly` | P345 | Przychód z poprzedniego roku ≤ 200 000 EUR | Art. 21 ust. 1b ustawy o ryczałcie |
| 22 | `limit_zus_preferential_income` | P346 | Przychód ≤ 120 000 EUR/rok | Art. 18a SUS |
| 23 | `limit_zus_maly_plus_income` | P347 | Przychód ≤ 120 000 EUR/rok | Art. 18c SUS |
| 24 | `limit_rd_costs_tax_deductible` | P348 | Koszty B+R — bez limitu w PIT | Art. 26e PIT |
| 25 | `limit_cesop_reporting_25k_eur` | P349 | 25 000 EUR rocznie cross-border | Rozp. 2020/284 CESOP |

#### 🔧 Sygnatura reguły Rego:

```rego
# P340 — limit_lump_sum_revenue_2m_eur
# Czy JDG może pozostać na ryczałcie?
lump_sum_limit_check := result {
    annual_revenue_eur := input.financials.annual_revenue_pln / input.thresholds.eur_pln_rate
    exceeded := annual_revenue_eur > 2000000
    result := {
        "rule_id": "jdg.limits.lump_sum_2m_eur",
        "matched": exceeded,
        "limit_eur": 2000000,
        "actual_eur": round(annual_revenue_eur, 2),
        "action": "MUST_SWITCH_TO_SCALE_OR_LINEAR" | exceeded else "OK"
    }
}
```

---

## 4. 💰 SANKCJE I ODSETKI

> **📎 Cross-ref Doc 35:** §8 (Przedawnienia i Odpowiedzialność, P1162–P1168)
> **📦 Pakiet docelowy:** `jdg.liability` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — sankcje to mechanizm odstraszający przed błędami

### CO JUŻ JEST:
- P1164: `late_payment_interest`
- P1168: `voluntary_disclosure_active`
- P556: `pit_annual_return_overdue`
- P1112: `statute_barred_correction_block`

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 26 | `sanction_jpk_error_500` | P350 | Kara 500 PLN za błąd JPK uniemożliwiający weryfikację | Art. 109 ust. 3f VAT |
| 27 | `sanction_ksef_missing_100pct_vat` | P351 | Brak KSeF → sankcja 100% VAT | Art. 106nh VAT |
| 28 | `sanction_late_filing_vat` | P352 | Kara za nieterminową deklarację VAT (500–5 000 PLN) | Art. 56 KKS |
| 29 | `sanction_unregistered_activity` | P353 | Kara za niezarejestrowanie JDG w CEIDG | Art. 601 KKS |
| 30 | `sanction_mpp_violation_30pct` | P354 | Sankcja 30% VAT za brak MPP | Art. 108c VAT |
| 31 | `sanction_whitelist_transfer` | P355 | Odpowiedzialność solidarna za VAT kontrahenta (WL) | Art. 117ba Ordynacji |
| 32 | `interest_late_payment_basic_rate` | P356 | Odsetki ustawowe: stopa referencyjna + 3.5% | Art. 56 Ordynacji |
| 33 | `interest_late_payment_reduced_rate` | P357 | Odsetki obniżone: stopa ref. + 1.5% (po korekcie) | Art. 56 § 1a Ordynacji |
| 34 | `interest_overpayment_45_days` | P358 | Odsetki od US za zwrot nadpłaty >45 dni | Art. 78 Ordynacji |

#### 🔧 Sygnatura reguły Rego:

```rego
# P356 — interest_late_payment_basic_rate
# Obliczanie odsetek ustawowych za zwłokę
late_payment_interest := result {
    days_late := time_diff_days(input.liability.due_date, input.liability.payment_date)
    days_late > 0
    ref_rate := input.thresholds.nbp_reference_rate / 100.0
    basic_rate := ref_rate + 0.035  # stopa ref. + 3.5%
    daily_rate := basic_rate / 365.0
    interest_amount := input.liability.tax_due * daily_rate * days_late
    result := {
        "rule_id": "jdg.liability.interest_basic",
        "interest_pln": round(interest_amount, 2),
        "days_late": days_late,
        "rate_pct": round(basic_rate * 100, 2)
    }
}
```

---

## 5. 🧪 SCENARIUSZE WYJĄTKOWE (Edge Cases)

> **📎 Cross-ref Doc 35:** §15 (Scenariusze Brzegowe, P140, P617, P743, P1220–P1222)
> **📦 Pakiet docelowy:** rozproszone po istniejących pakietach + `jdg.conflicts` (NOWY)
> **🎯 Priorytet ogólny:** P0 — edge case'y generują najwięcej błędów podatkowych

### CO JUŻ JEST:
- P910–P914: Zawieszenie JDG
- P920: Sukcesja
- P743: Zbieg etat+JDG

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna | 📦 Pakiet |
|---|---|---|---|---|---|
| 35 | `edge_case_vat_breach_mid_year` | P360 | Przekroczenie limitu VAT 200k w trakcie roku: VAT od NADWYŻKI | Art. 113 ust. 5 VAT | `jdg.vat.substantive` |
| 36 | `edge_case_vat_breach_proportion` | P361 | Nowa JDG: proporcjonalny limit VAT | Art. 113 ust. 9 VAT | `jdg.vat.substantive` |
| 37 | `edge_case_multiple_allowances_income_cap` | P362 | Suma ulg ≤ dochód (z wyjątkiem B+R carry-forward) | Art. 26 ust. 1 PIT | `jdg.conflicts` ⭐ |
| 38 | `edge_case_concurrent_employment_low_salary` | P363 | JDG+etat gdzie pensja < min. wynagr. → ZUS społeczne z JDG | Art. 9 ust. 2a SUS | `jdg.zus` |
| 39 | `edge_case_last_month_start_relief` | P364 | Ostatni miesiąc ulgi na start → automatyczne przejście na preferencyjny/standard | Art. 18a SUS | `jdg.zus` |
| 40 | `edge_case_first_year_lump_sum_loss` | P365 | Pierwszy rok ryczałtu ze stratą → brak możliwości odliczenia KUP | Art. 6 ustawy o ryczałcie | `jdg.pit.forms` |
| 41 | `edge_case_vat_eu_services_b2b_no_pl` | P366 | Usługi B2B z PL wykonane dla kontrahenta UE → VAT rozlicza nabywca | Art. 28b VAT | `jdg.crossborder` |

---

## 6. 📄 DOKUMENTACJA I RETENCJA

> **📎 Cross-ref Doc 35:** Brak bezpośredniego pokrycia (częściowo w implementacji `jdg.retention` P990–P992)
> **📦 Pakiet docelowy:** `jdg.retention` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P2

### CO JUŻ JEST:
- P990–P992: `retention.tax_documents_5yr`, `vat_invoices_extended`, `electronic_archive_requirements`
- P1612: `document_retention_expiry` reminder

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 42 | `doc_invoice_numbering_continuity` | P370 | Ciągłość numeracji faktur (luki w JPK → alert) | Art. 106e VAT |
| 43 | `doc_payment_confirmation_required` | P371 | Przechowywanie potwierdzeń przelewów (dowodów zapłaty) | Art. 86 ust. 1 VAT |
| 44 | `doc_contract_retention_5yr` | P372 | Przechowywanie umów handlowych 5 lat | Art. 74 KC |
| 45 | `doc_hr_records_10yr_post_2019` | P373 | Akta osobowe 10 lat (po raportach ZUS OSW) | Art. 51u SUS |
| 46 | `doc_destruction_procedure` | P374 | Procedura niszczenia dokumentacji po upływie retencji | Art. 6 RODO |
| 47 | `doc_electronic_signature_validity` | P375 | Ważność podpisu elektronicznego (eIDAS) | Rozp. eIDAS 910/2014 |
| 48 | `doc_ksef_schema_validation` | P376 | Walidacja struktury XML KSeF (FA(2) vs schema) | Rozp. KSeF |

---

## 7. 🔍 KONTROLA I AUDYT

> **📎 Cross-ref Doc 35:** §7 (Korekty — P180 audit lock) + §14 (jdg.audit, P970–P989)
> **📦 Pakiet docelowy:** `jdg.audit` (NOWY — zdefiniowany w Doc 35) ⭐
> **🎯 Priorytet ogólny:** P1 — JDG MUSI wiedzieć że jest kontrolowane

### CO JUŻ JEST:
- P1112: Blokada korekty po przedawnieniu
- P1168: Czynny żal (przed kontrolą)
- P1603: Zawieszenie biegu przedawnienia

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 49 | `audit_inspection_notice_compliance` | P380 | Obowiązek udostępnienia dokumentów w 7 dni od wezwania | Art. 287 Ordynacji |
| 50 | `audit_controlled_transaction_flag` | P381 | Oznaczenie transakcji objętej kontrolą — zakaz korekty | Art. 81b Ordynacji |
| 51 | `audit_inspection_protocol_obligation` | P382 | Obowiązek podpisania protokołu kontroli (7 dni na uwagi) | Art. 291 Ordynacji |
| 52 | `audit_statute_suspension_during_inspection` | P383 | Zawieszenie przedawnienia w trakcie kontroli | Art. 70 § 6 Ordynacji |
| 53 | `audit_cross_check_cesop_jpk` | P384 | Krzyżowa kontrola CESOP vs JPK_V7 (cross-border) | Rozp. CESOP |
| 54 | `audit_document_request_deadline` | P385 | Termin dostarczenia dokumentów US: 7 dni (możliwość przedłużenia) | Art. 287 Ordynacji |

#### 🔧 Sygnatura reguły Rego (dla pakietu jdg.audit):

```rego
# P381 — audit_controlled_transaction_flag
# Oznacz transakcję objętą kontrolą → zablokuj korektę
audit_lock := result {
    input.audit.status == "IN_PROGRESS"
    input.transaction.id == input.audit.controlled_transaction_ids[_]
    result := {
        "rule_id": "jdg.audit.controlled_transaction_flag",
        "locked": true,
        "action": "BLOCK_CORRECTION",
        "audit_ref": input.audit.case_number,
        "legal_basis": "Art. 81b § 1 Ordynacji podatkowej"
    }
}
```

---

## 8. 💵 TRANSAKCJE GOTÓWKOWE

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P35, P25)
> **📦 Pakiet docelowy:** `jdg.compliance` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1

### CO JUŻ JEST:
- P35: `cash_transaction_over_limit` — >15k PLN → NKUP
- P25: MPP mandatory

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 55 | `cash_limit_single_day_15k` | P390 | Łączny limit 15k PLN dziennie dla jednego kontrahenta | Art. 22p PIT |
| 56 | `cash_limit_multiple_invoices_aggregate` | P391 | Agregacja wielu faktur gotówkowych tego samego dnia | Art. 22p PIT |
| 57 | `cash_reporting_giif_15k_eur` | P392 | Raportowanie do GIIF >15k EUR (transakcje podejrzane) | Art. 72 AML |
| 58 | `cash_sanction_kup_loss` | P393 | Utrata KUP + sankcja 20% kwoty transakcji | Art. 22p PIT |

#### 🔧 Sygnatura reguły Rego:

```rego
# P390 — cash_limit_single_day_15k
cash_daily_aggregate_check := result {
    day := input.transaction.date
    counterparty := input.transaction.counterparty_id
    total_cash := sum([t.amount | t := input.transactions[_];
                        t.date == day; t.counterparty_id == counterparty;
                        t.payment_method == "CASH"])
    exceeded := total_cash > 15000
    result := {
        "rule_id": "jdg.compliance.cash_daily_15k",
        "matched": exceeded,
        "total_pln": total_cash,
        "action": "NKUP_DISALLOWED" | exceeded else "OK"
    }
}
```

---

## 9. 🔀 SPLIT PAYMENT (MPP)

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P25, P25_b) — ten dokument ROZSZERZA o 5 szczegółowych reguł
> **📦 Pakiet docelowy:** `jdg.compliance` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1

### CO JUŻ JEST:
- P25: `split_payment_mandatory`
- P25_b: `split_payment_voluntary_safe_harbor`
- `_helpers_jdg.rego`: `jdg_is_mpp_sensitive` — lista kategorii

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 59 | `mpp_annex15_complete_check` | P400 | Pełna lista załącznika nr 15 (28 kategorii, nie tylko 6) | Załącznik nr 15 VAT |
| 60 | `mpp_transfer_message_format` | P401 | Obowiązek umieszczenia komunikatu MPP w przelewie | Art. 108a ust. 3 VAT |
| 61 | `mpp_vat_account_destination` | P402 | Przelew na rachunek VAT (oddzielny od podstawowego) | Art. 108a ust. 2 VAT |
| 62 | `mpp_sanction_non_compliance` | P403 | Sankcja 30% VAT + odpowiedzialność solidarna za brak MPP | Art. 108c VAT |
| 63 | `mpp_release_vat_account` | P404 | Warunki zwolnienia środków z rachunku VAT (zgoda US) | Art. 108b VAT |

---

## 10. 🏦 BIAŁA LISTA VAT

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P20, P21) — ten dokument ROZSZERZA o 5 szczegółowych reguł
> **📦 Pakiet docelowy:** `jdg.compliance` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P0 — krytyczne dla bezpieczeństwa transakcji B2B

### CO JUŻ JEST:
- P20: `whitelist_missing_over_limit`
- P21: `whitelist_account_mismatch`

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 64 | `whitelist_verification_before_transfer` | P410 | Obowiązek weryfikacji WL PRZED przelewem | Art. 117ba § 1 Ordynacji |
| 65 | `whitelist_check_expired_30days` | P411 | Ważność weryfikacji WL: 30 dni od sprawdzenia | Art. 96b VAT |
| 66 | `whitelist_3day_buffer_rule` | P412 | 3-dniowy bufor: przelew w ciągu 3 dni od weryfikacji WL → safe | Art. 117ba § 5 Ordynacji |
| 67 | `whitelist_zaw_nr_exemption` | P413 | ZAW-NR w 7 dni od przelewu → zwolnienie z sankcji | Art. 117ba § 3 Ordynacji |
| 68 | `whitelist_multiple_accounts_check` | P414 | Kontrahent z wieloma rachunkami — czy przelew na WŁAŚCIWY rachunek? | Art. 96b VAT |

#### 🔧 Sygnatura reguły Rego:

```rego
# P412 — whitelist_3day_buffer_rule
# Czy przelew został wykonany w ciągu 3 dni od weryfikacji WL?
whitelist_buffer_check := result {
    verification_date := input.whitelist.verification_date
    transfer_date := input.transaction.transfer_date
    days_diff := time_diff_days(verification_date, transfer_date)
    within_buffer := days_diff >= 0
    within_buffer := days_diff <= 3
    result := {
        "rule_id": "jdg.compliance.whitelist_3day_buffer",
        "within_buffer": within_buffer,
        "days_since_verification": days_diff,
        "safe_harbor": within_buffer,
        "action": "OK" | within_buffer else "ZAW_NR_REQUIRED_WITHIN_7_DAYS"
    }
}
```

---

## 11. 💸 ULGA NA ZŁE DŁUGI (szczegółowo)

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P60, P184 VAT; P571, P618 PIT)
> **📦 Pakiet docelowy:** `jdg.vat.deductions` / `jdg.allowances` (rozszerzenia istniejących)
> **🎯 Priorytet ogólny:** P1

### CO JUŻ JEST:
- VAT: P60 `bad_debt_relief_creditor`, P184 `bad_debt_debtor_mandatory`
- PIT: P571 `bad_debt_debtor`, P618 `relief_bad_debt_pit_creditor`

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 69 | `bad_debt_debtor_notification_deadline` | P420 | Dłużnik musi powiadomić wierzyciela o korekcie w 7 dni | Art. 89b ust. 3 VAT |
| 70 | `bad_debt_reversal_on_payment` | P421 | Automatyczne odwrócenie ulgi przy zapłacie po korekcie | Art. 89a ust. 4 VAT |
| 71 | `bad_debt_days_calculation_90` | P422 | Precyzyjne obliczanie 90/150 dni od terminu płatności (z weekendami) | Art. 89a-89b VAT |
| 72 | `bad_debt_excluded_scenarios` | P423 | Wyłączenia: dłużnik w restrukturyzacji/upadłości → brak ulgi | Art. 89a ust. 2 VAT |
| 73 | `bad_debt_creditor_zaw_nr_deadline` | P424 | Wierzyciel: zawiadomienie dłużnika + US w terminie | Art. 89a ust. 3 VAT |

#### 🔧 Sygnatura reguły Rego:

```rego
# P422 — bad_debt_days_calculation_90
# Precyzyjne obliczanie 90/150 dni od terminu płatności
bad_debt_days_check := result {
    due_date := time.parse_rfc3339_ns(input.invoice.due_date)
    today := time.now_ns()
    days_past_due := (today - due_date) / 86400000000000  # ns → dni
    creditor_eligible := days_past_due >= 90  # wierzyciel może korygować po 90 dniach
    debtor_must_correct := days_past_due >= 150  # dłużnik MUSI skorygować po 150 dniach
    result := {
        "rule_id": "jdg.vat.bad_debt_days",
        "days_past_due": round(days_past_due),
        "creditor_eligible": creditor_eligible,
        "debtor_mandatory": debtor_must_correct,
        "excluded": input.counterparty.status == "RESTRUCTURING"  # Art. 89a ust. 2
    }
}
```

---

## 12. 🔄 ODWROTNE OBCIĄŻENIE (Reverse Charge)

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P40, P41, P62, P68)
> **📦 Pakiet docelowy:** `jdg.crossborder` / `jdg.vat.substantive` (rozszerzenia istniejących)
> **🎯 Priorytet ogólny:** P2 — dotyczy specyficznych branż JDG

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 74 | `reverse_charge_annex11_goods` | P430 | Pełna lista towarów z załącznika nr 11 (reverse charge krajowy) | Załącznik nr 11 VAT |
| 75 | `reverse_charge_annex14_services` | P431 | Usługi z załącznika nr 14 (reverse charge krajowy na usługi) | Załącznik nr 14 VAT |
| 76 | `reverse_charge_construction_subcontractor` | P432 | Podwykonawstwo budowlane → reverse charge | Art. 17 ust. 1 pkt 8 VAT |
| 77 | `reverse_charge_gas_electricity` | P433 | Handel gazem i energią elektryczną → reverse charge | Art. 17 ust. 1 pkt 7 VAT |
| 78 | `reverse_charge_evidence_obligation` | P434 | Obowiązek ewidencji transakcji reverse charge (część ewidencyjna JPK) | § 10 JPK_VAT |

---

## 13. 🎨 PROCEDURA MARŻY — Szczegółowa

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P50, P66)
> **📦 Pakiet docelowy:** `jdg.vat.procedures` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P2

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 79 | `margin_scheme_artworks` | P440 | Procedura marży dla dzieł sztuki | Art. 120 ust. 4-5 VAT |
| 80 | `margin_scheme_antiques_collectors` | P441 | Antyki i przedmioty kolekcjonerskie — odrębne zasady | Art. 120 ust. 4 VAT |
| 81 | `margin_scheme_global_method` | P442 | Metoda globalna (per okres) vs jednostkowa (per towar) | Art. 120 ust. 4-5 VAT |
| 82 | `margin_scheme_invoice_requirements` | P443 | Faktura VAT-marża: obowiązkowe oznaczenia + zakaz wykazywania VAT | Art. 106e ust. 1 pkt 18a VAT |
| 83 | `margin_scheme_import_used_goods` | P444 | Import towarów używanych → VAT-marża niemożliwy | Art. 120 ust. 4 VAT |

---

## 14. 📦 IMPORT USŁUG — Szczegółowy

> **📎 Cross-ref Doc 35:** §6 (Crossborder, P250, P255)
> **📦 Pakiet docelowy:** `jdg.crossborder` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — import usług to codzienność w e-commerce

### CO JUŻ JEST:
- P41: `eu_import_services`
- P45: `import_non_eu` (towary)
- P191: `import_vat_deduction_timing`

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 84 | `import_services_non_eu_b2b` | P450 | Import usług spoza UE B2B → reverse charge | Art. 17 ust. 1 pkt 4 VAT |
| 85 | `import_services_non_eu_b2c` | P451 | Import usług B2C spoza UE → VAT należny w PL | Art. 28k-28l VAT |
| 86 | `import_services_tax_point_receipt` | P452 | Moment powstania obowiązku: data wykonania lub zapłaty (wcześniejsza) | Art. 19a ust. 1 VAT |
| 87 | `import_services_fx_rate_nbp` | P453 | Kurs waluty: NBP z dnia poprzedzającego powstanie obowiązku | Art. 31a ust. 1 VAT |
| 88 | `import_services_tax_base_net` | P454 | Podstawa opodatkowania: kwota netto należna dostawcy | Art. 29a ust. 1 VAT |

---

## 15. 🌍 PODATEK U ŹRÓDŁA (WHT)

> **📎 Cross-ref Doc 35:** Brak szczegółowego pokrycia (tylko P100 basic detection)
> **📦 Pakiet docelowy:** `jdg.international` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — globalna gospodarka wymaga WHT

### CO JUŻ JEST:
- P100: `wht_obligation_detection` — podstawowa detekcja

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 89 | `wht_dividend_19pct` | P460 | Dywidendy → 19% WHT | Art. 30a ust. 1 pkt 4 PIT |
| 90 | `wht_interest_20pct` | P461 | Odsetki → 20% WHT | Art. 30a ust. 1 pkt 1 PIT |
| 91 | `wht_royalties_20pct` | P462 | Należności licencyjne → 20% WHT | Art. 30a ust. 1 pkt 2 PIT |
| 92 | `wht_double_taxation_treaty_rate` | P463 | Stawka z umowy UPO (np. 5%/10%/15% zamiast 20%) | Umowy UPO |
| 93 | `wht_certificate_of_residence` | P464 | Obowiązek posiadania certyfikatu rezydencji kontrahenta | Art. 30a ust. 2 PIT |
| 94 | `wht_due_diligence_check` | P465 | Należyta staranność (beneficial owner) | Art. 26 ust. 2e CIT |
| 95 | `wht_remitter_pit8ar_deadline` | P466 | PIT-8AR termin: do końca stycznia za poprzedni rok | Art. 42 ust. 1a PIT |
| 96 | `wht_pay_and_refund_mechanism` | P467 | Mechanizm pay-and-refund dla WHT >2M PLN | Art. 26 ust. 2e CIT |

#### 🔧 Sygnatura reguły Rego:

```rego
# P463 — wht_double_taxation_treaty_rate
# Sprawdź stawkę z umowy UPO (jeśli jest korzystniejsza)
wht_treaty_rate := result {
    payment_type := input.wht.payment_type  # DIVIDEND|INTEREST|ROYALTY
    counterparty_country := input.wht.counterparty_country
    standard_rate := input.thresholds.wht_rates[payment_type]  # 19% lub 20%
    # Sprawdź czy istnieje umowa UPO z danym krajem
    treaty_rate := input.thresholds.dtt_rates[counterparty_country][payment_type]
    effective_rate := min(standard_rate, treaty_rate)
    result := {
        "rule_id": "jdg.international.wht_treaty",
        "standard_rate_pct": standard_rate * 100,
        "treaty_rate_pct": treaty_rate * 100,
        "effective_rate_pct": effective_rate * 100,
        "requires_certificate": true  # Art. 30a ust. 2 PIT
    }
}
```

---

## 16. 👥 JDG Z PRACOWNIKAMI

> **📎 Cross-ref Doc 35:** §15.2 (P1220 employer checklist) + §2.1 (P749 health annual)
> **📦 Pakiet docelowy:** `jdg.employer` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — JDG z pracownikami to PŁATNIK podatków

### CO JUŻ JEST:
- P1200e–P1216e: 50% KUP twórców, standardowe KUP, PPK, PIT-4R, PIT-8AR

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 97 | `employer_zus_dra_monthly` | P470 | ZUS DRA — deklaracja rozliczeniowa miesięczna | Art. 46 SUS |
| 98 | `employer_zus_rca_reporting` | P471 | ZUS RCA — raport imienny o składkach | Art. 40 SUS |
| 99 | `employer_pit11_employee_annual` | P472 | PIT-11 — informacja dla pracownika do 28 lutego | Art. 39 ust. 1 PIT |
| 100 | `employer_zus_zua_registration` | P473 | ZUS ZUA — zgłoszenie pracownika w 7 dni | Art. 36 ust. 1 SUS |
| 101 | `employer_ppk_auto_enrollment` | P474 | PPK — automatyczny zapis pracownika (opcja opt-out) | Art. 32 ustawy PPK |
| 102 | `employer_osh_training_obligation` | P475 | Szkolenie BHP — wstępne + okresowe (KUP 100%) | Art. 237³ KP |
| 103 | `employer_peron_contribution` | P476 | PFRON — składka za niezatrudnianie osób z niepełnosprawnością (≥25 prac.) | Art. 21 ustawy PFRON |
| 104 | `employer_work_fund_labour_fund` | P477 | Fundusz Pracy + FGŚP + Fundusz Solidarnościowy | Art. 104-107 ustawy o promocji zatrudnienia |

---

## 17. 🏗️ JDG Z MAJĄTKIEM (Środki Trwałe)

> **📎 Cross-ref Doc 35:** §1.5 (P870a strata) + §11.2 (P1616 limit amortyzacji temporalny)
> **📦 Pakiet docelowy:** `jdg.accounting` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P2

### CO JUŻ JEST:
- P840: `depreciation_linear`
- P842: `depreciation_one_off`
- P850–P852: `home_office`, `private_mixed_car`
- P860: `operating_lease_full_kup`

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 105 | `fixed_asset_kst_group_classification` | P480 | Klasyfikacja KŚT: 10 grup ze stawkami (2.5%–20%) | KŚT załącznik nr 1 |
| 106 | `fixed_asset_low_value_10k` | P481 | Niskocenne środki trwałe ≤10k PLN → jednorazowa amortyzacja | Art. 22d ust. 1 PIT |
| 107 | `fixed_asset_de_minimis_100k` | P482 | Amortyzacja jednorazowa de minimis do 100k PLN (mały podatnik) | Art. 22k ust. 7 PIT |
| 108 | `fixed_asset_improvement_10k_threshold` | P483 | Ulepszenie >10k PLN → zwiększa wartość początkową | Art. 22g ust. 17 PIT |
| 109 | `fixed_asset_used_first_time_depreciation` | P484 | Używany środek trwały → możliwość skróconej amortyzacji (max 30 mies.) | Art. 22j PIT |
| 110 | `fixed_asset_sale_income_taxable` | P485 | Sprzedaż środka trwałego → przychód podatkowy (różnica od wartości netto) | Art. 14 ust. 2 PIT |
| 111 | `fixed_asset_financial_lease_treatment` | P486 | Leasing finansowy: KUP = amortyzacja + odsetki (nie cała rata) | Art. 23f PIT |

---

## 18. 📊 RÓŻNE FORMY OPODATKOWANIA — Szczegółowe warunki

> **📎 Cross-ref Doc 35:** §5 (Zmiana Formy, P830, P832) + §10 (Forma vs Składki, P754, P756)
> **📦 Pakiet docelowy:** `jdg.pit.forms` / `jdg.pit.transitions` (rozszerzenia istniejących)
> **🎯 Priorytet ogólny:** P2

### CO JUŻ JEST:
- `jdg.pit.forms`: skala 12%/32%, liniowy 19%, ryczałt, karta
- `jdg.pit.transitions`: zmiana formy (mid-year, dual return, health recalc)

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 112 | `tax_form_linear_deadline_jan20` | P490 | Wybór liniowego → oświadczenie do 20 stycznia | Art. 9a ust. 2 PIT |
| 113 | `tax_form_lump_sum_deadline_jan20` | P491 | Wybór ryczałtu → oświadczenie do 20 stycznia | Art. 9 ust. 1 ustawy o ryczałcie |
| 114 | `tax_form_lump_sum_excluded_services` | P492 | Ryczałt — wykluczone usługi (apteki, kantory, lombardy) | Art. 8 ustawy o ryczałcie |
| 115 | `tax_form_linear_no_joint_filing` | P493 | Podatek liniowy → BRAK wspólnego rozliczenia z małżonkiem | Art. 30c PIT |
| 116 | `tax_form_linear_no_child_tax_credit` | P494 | Podatek liniowy → BRAK ulgi na dzieci | Art. 27f PIT |
| 117 | `tax_form_lump_sum_no_tax_free` | P495 | Ryczałt → BRAK kwoty wolnej od podatku | Art. 12 ustawy o ryczałcie |
| 118 | `tax_form_tax_card_eligibility` | P496 | Karta podatkowa — warunki (zakres, liczba pracowników, wiek) | Rozdział 3 ustawy o zryczałtowanym PIT |

---

## 19. 🌾 DZIAŁALNOŚĆ SEZONOWA

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar
> **📦 Pakiet docelowy:** `jdg.business` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P3 — sezonowość to rzadki, ale istotny scenariusz

### CO JUŻ JEST:
- Brak dedykowanych reguł dla działalności sezonowej

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 119 | `seasonal_suspension_trigger` | P500 | Zawieszenie sezonowe: JDG może zawiesić na nieograniczony czas | Art. 22 Prawo przedsiębiorców |
| 120 | `seasonal_pit_advance_proportion` | P501 | Zaliczki w okresie sezonowym — proporcjonalne do miesięcy aktywności | Art. 44 PIT |
| 121 | `seasonal_vat_zero_returns` | P502 | Zerowe deklaracje VAT-7 w okresie sezonowego zawieszenia | Art. 99 VAT |
| 122 | `seasonal_zus_exemption_active_months` | P503 | ZUS tylko za miesiące aktywne (sezonowe) | Art. 36a SUS |
| 123 | `seasonal_annual_pkpir_proportion` | P504 | PKPiR: dochód tylko z miesięcy aktywnych | Art. 24a PIT |
| 124 | `seasonal_start_and_end_year_different_forms` | P505 | Inna forma opodatkowania w sezonie vs poza sezonem? (NIEDOZWOLONE) | — |

---

## 20. 🏛️ KONTROLA SKARBOWA — Procedury

> **📎 Cross-ref Doc 35:** §7 (P180 audit lock) + §8.1 (przedawnienia)
> **📦 Pakiet docelowy:** `jdg.audit` (NOWY) ⭐ + `jdg.liability`
> **🎯 Priorytet ogólny:** P1 — kontrola skarbowa to moment najwyższego ryzyka

### CO BRAKUJE:

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 125 | `tax_audit_notification_7days` | P510 | Zawiadomienie o kontroli — 7 dni przed rozpoczęciem | Art. 282b Ordynacji |
| 126 | `tax_audit_right_to_correct_14days` | P511 | Prawo do korekty deklaracji w ciągu 14 dni od doręczenia protokołu | Art. 81 Ordynacji |
| 127 | `tax_audit_legal_representation` | P512 | Prawo do pełnomocnika podczas kontroli (UPL-1 / PPS-1) | Art. 138a Ordynacji |
| 128 | `tax_audit_appeal_deadline_14days` | P513 | Odwołanie od decyzji w ciągu 14 dni od doręczenia | Art. 223 Ordynacji |
| 129 | `tax_audit_evidence_submission` | P514 | Prawo do składania dowodów i wyjaśnień w trakcie kontroli | Art. 292 Ordynacji |
| 130 | `tax_audit_extended_inspection_limit` | P515 | Maksymalny czas kontroli: 30 dni (mały podatnik), 60 dni (standard) | Art. 83 Prawo przedsiębiorców |
| 131 | `tax_audit_vat_refund_suspension` | P516 | Wstrzymanie zwrotu VAT w trakcie kontroli | Art. 87 ust. 2 VAT |

---

## 🆕 21. MDR — MANDATORY DISCLOSURE RULES (Raportowanie Schematów Podatkowych)

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar ENTERPRISE
> **📦 Pakiet docelowy:** `jdg.compliance` (rozszerzenie) lub nowy `jdg.mdr`
> **🎯 Priorytet ogólny:** P1

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 132 | `mdr_cross_border_arrangement_detection` | P520 | Czy transakcja spełnia kryteria schematu podatkowego transgranicznego? | Art. 86a § 1 Ordynacji |
| 133 | `mdr_hallmark_generic_benefit` | P521 | Kryterium głównej korzyści podatkowej (main benefit test) | Art. 86a § 2 Ordynacji |
| 134 | `mdr_hallmark_specific_a` | P522 | Kryterium szczególne A: cross-border + deductible payments do podmiotów nieopodatkowanych | Załącznik do Rozp. MDR |
| 135 | `mdr_hallmark_specific_b` | P523 | Kryterium szczególne B: automatyczna wymiana informacji, beneficial owner | Załącznik do Rozp. MDR |
| 136 | `mdr_hallmark_specific_e` | P524 | Kryterium szczególne E: transfer trudnych do wyceny wartości niematerialnych | Załącznik do Rozp. MDR |
| 137 | `mdr_deadline_30_days` | P525 | Obowiązek zgłoszenia MDR-3 w ciągu 30 dni od wdrożenia schematu | Art. 86f Ordynacji |
| 138 | `mdr_sanction_non_reporting` | P526 | Sankcja KKS za niezgłoszenie schematu podatkowego | Art. 80f KKS |

#### 🔧 Sygnatura reguły Rego:

```rego
# P520 — mdr_cross_border_arrangement_detection
mdr_detection := result {
    is_cross_border := input.transaction.counterparty_country != "PL"
    exceeds_threshold := input.transaction.amount_eur > 25000  # szacunkowy próg
    has_tax_benefit := input.transaction.effective_tax_rate < input.thresholds.standard_rate * 0.5
    qualifies := is_cross_border && (exceeds_threshold || has_tax_benefit)
    result := {
        "rule_id": "jdg.mdr.cross_border_detection",
        "matched": qualifies,
        "mdr_reportable": qualifies,
        "deadline_days": 30 | qualifies else null,
        "hallmarks_triggered": [h | h := input.thresholds.mdr_hallmarks[_]; h.triggered(input.transaction)],
        "sanction_risk": "HIGH" | qualifies else "NONE"
    }
}
```

---

## 🆕 22. DAC7 — PLATFORM REPORTING (Raportowanie Platform Cyfrowych)

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar ENTERPRISE
> **📦 Pakiet docelowy:** `jdg.digital` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — obowiązek od 2023 roku

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 139 | `dac7_platform_operator_qualification` | P530 | Czy JDG jest operatorem platformy (Art. 4 dyrektywy DAC7)? | Art. 39a-39u Ordynacji (DAC7) |
| 140 | `dac7_seller_threshold_30_transactions` | P531 | Sprzedawca: >30 transakcji lub >2 000 EUR → obowiązek raportowania | Art. 39j Ordynacji |
| 141 | `dac7_seller_data_collection` | P532 | Zakres danych raportowanych: NIP, adres, numer rachunku, kwoty | Art. 39k Ordynacji |
| 142 | `dac7_deadline_january_31` | P533 | Termin raportowania DAC7: 31 stycznia za poprzedni rok | Art. 39n Ordynacji |
| 143 | `dac7_cross_border_exchange` | P534 | Automatyczna wymiana danych między administracjami UE | Art. 39t Ordynacji |
| 144 | `dac7_sanction_platform` | P535 | Sankcja do 1M PLN za brak raportowania DAC7 | Art. 39u Ordynacji |

---

## 🆕 23. ESG / CSRD — Zrównoważony Rozwój i Raportowanie

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar ENTERPRISE
> **📦 Pakiet docelowy:** `jdg.environmental` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P2 — rośnie znaczenie regulacyjne od 2025

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 145 | `esg_large_jdg_csrd_threshold` | P540 | JDG spełnia 2 z 3: >250 prac., >20M EUR aktywów, >40M EUR przychodów → CSRD | Dyrektywa CSRD 2022/2464 |
| 146 | `esg_carbon_footprint_tracking` | P541 | Ślad węglowy — obowiązek raportowania emisji Scope 1/2/3 | EU Taxonomy Regulation 2020/852 |
| 147 | `esg_supply_chain_due_diligence` | P542 | Należyta staranność w łańcuchu dostaw (LkSG / CSDDD) | Dyrektywa CSDDD 2024/1760 |
| 148 | `esg_greenwashing_flag` | P543 | Wykrywanie greenwashingu — deklaracje środowiskowe bez certyfikacji | Taksonomia UE + Art. 7 RODO |
| 149 | `esg_energy_efficiency_certificate` | P544 | Świadectwo charakterystyki energetycznej budynku JDG | Dyrektywa EPBD 2010/31/UE |

---

## 🆕 24. UPADŁOŚĆ / NIEWYPŁACALNOŚĆ JDG

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar ENTERPRISE
> **📦 Pakiet docelowy:** `jdg.restructuring` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — krytyczne dla zarządzania ryzykiem

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 150 | `insolvency_detection_balance_sheet` | P550 | Niewypłacalność: aktywa < pasywa (test bilansowy) + >3 miesiące bez spłaty | Art. 11 PrUpad |
| 151 | `insolvency_filing_obligation_30days` | P551 | Obowiązek złożenia wniosku o upadłość w 30 dni od niewypłacalności | Art. 21 PrUpad |
| 152 | `insolvency_tax_asset_valuation` | P552 | Wycena majątku JDG przy upadłości (wartość rynkowa vs księgowa) | Art. 14 PIT |
| 153 | `insolvency_vat_receivables_write_off` | P553 | VAT od nieściągalnych wierzytelności — korekta ulgi na złe długi | Art. 89a-89b VAT |
| 154 | `insolvency_sanction_late_filing` | P554 | Sankcja za nieterminowe złożenie wniosku o upadłość — do 2 lat więzienia | Art. 586 KSH |
| 155 | `insolvency_restructuring_plan_tax` | P555 | Postępowanie restrukturyzacyjne — skutki podatkowe układu z wierzycielami | Art. 12 PIT, Art. 89 Ordynacji |

---

## 🆕 25. SIŁA WYŻSZA (FORCE MAJEURE) — Pandemia, Klęski Żywiołowe

> **📎 Cross-ref Doc 35:** Brak pokrycia — NOWY obszar ENTERPRISE
> **📦 Pakiet docelowy:** `jdg.temporal` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P2 — relewantne dla ciągłości działania

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 156 | `force_majeure_tax_deadline_extension` | P560 | Przedłużenie terminów podatkowych w stanie klęski żywiołowej | Art. 48-50 Ordynacji |
| 157 | `force_majeure_zus_suspension` | P561 | Zawieszenie składek ZUS (tarcza antykryzysowa — legacy) | Ustawa COVID-19 (archiwalna) |
| 158 | `force_majeure_tax_exemption_damage` | P562 | Zwolnienie z podatku od nieruchomości przy zniszczeniu przez klęskę żywiołową | Art. 48-49 Ordynacji |
| 159 | `force_majeure_insurance_compensation_tax` | P563 | Odszkodowanie ubezpieczeniowe — przychód podatkowy w roku otrzymania | Art. 14 PIT |
| 160 | `force_majeure_loss_documentation` | P564 | Dokumentacja strat do US — inwentaryzacja zniszczonego majątku | Art. 14 ust. 2 PIT |

---

## 🆕 26. KASA FISKALNA — Pełna Macierz Zwolnień i Obowiązków

> **📎 Cross-ref Doc 35:** Częściowo w implementacji (P145: `cash_register_b2c_exemption` — limit 20k PLN)
> **📦 Pakiet docelowy:** `jdg.compliance` (rozszerzenie istniejącego)
> **🎯 Priorytet ogólny:** P1 — obowiązek dla większości JDG sprzedających B2C

| # | Reguła | P | Opis | Podstawa prawna |
|---|---|---|---|---|
| 161 | `cash_register_b2c_mandatory_detection` | P570 | Czy JDG ma obowiązek instalacji kasy fiskalnej? (sprzedaż B2C + przekroczenie limitu) | Art. 111 VAT |
| 162 | `cash_register_exemption_limit_20k` | P571 | Zwolnienie: limit 20 000 PLN sprzedaży B2C rocznie | Rozp. MF ws. zwolnień z kasy |
| 163 | `cash_register_exemption_services_list` | P572 | Pełna lista usług zwolnionych z kasy (np. usługi świadczone zdalnie przez internet) | Rozp. MF ws. zwolnień z kasy |
| 164 | `cash_register_online_vs_virtual` | P573 | Kasa online (obowiązkowa dla wybranych branż) vs kasa wirtualna (aplikacja) | Art. 111 ust. 6a VAT |
| 165 | `cash_register_ulga_700_pln` | P574 | Ulga na zakup kasy fiskalnej: 700 PLN (online) / 90% ceny max 700 PLN | Art. 111 ust. 4 VAT |
| 166 | `cash_register_breach_mid_year_2months` | P575 | Przekroczenie limitu 20k w trakcie roku → kasa w ciągu 2 miesięcy | Rozp. MF § 3 ust. 1 |
| 167 | `cash_register_daily_report_obligation` | P576 | Raport dobowy + miesięczny — archiwizacja 5 lat | Art. 111 ust. 3a VAT |
| 168 | `cash_register_service_review_2yr` | P577 | Przegląd techniczny kasy co 2 lata | Rozp. MF ws. kas rejestrujących |

#### 🔧 Sygnatura reguły Rego:

```rego
# P570 — cash_register_b2c_mandatory_detection
cash_register_mandatory := result {
    has_b2c_sales := input.financials.annual_b2c_revenue > 0
    limit_exceeded := input.financials.annual_b2c_revenue > input.thresholds.cash_register_exemption_limit
    is_exempt_service := input.transaction.service_type in input.thresholds.cash_register_exempt_services
    mandatory := has_b2c_sales && limit_exceeded && not is_exempt_service
    is_online_branch := input.transaction.service_type in input.thresholds.cash_register_online_branches
    result := {
        "rule_id": "jdg.compliance.cash_register_mandatory",
        "matched": mandatory,
        "b2c_revenue_pln": input.financials.annual_b2c_revenue,
        "limit_pln": input.thresholds.cash_register_exemption_limit,
        "type": "ONLINE" | (mandatory && is_online_branch) else "STANDARD",
        "tax_relief_pln": 700 | mandatory else 0,
        "deadline_months": 2 | mandatory else null
    }
}
```

---

## 📦 PODSUMOWANIE: Priorytety Wdrożenia

| Priorytet | Liczba reguł | Obszary | ⭐ Nowe pakiety |
|---|---|---|---|
| **P0 — KRYTYCZNE** | 19 | Walidacja NIP (P950–P958), Edge case VAT breach (P360–P366), Biała Lista (P410–P414) | `jdg.validation` ⭐ |
| **P1 — WYSOKIE** | 68 | Temporal (P1613–P1617), Sankcje (P350–P358), Kontrola (P510–P516), WHT (P460–P467), Import usług (P450–P454), Split payment (P400–P404), Złe długi (P420–P424), Pracownicy (P470–P477), MDR (P520–P526), DAC7 (P530–P535), Upadłość (P550–P555), Kasa fiskalna (P570–P577) | `jdg.audit` ⭐ |
| **P2 — ŚREDNIE** | 55 | Limity (P340–P349), Odwrotne obciążenie (P430–P434), Marża (P440–P444), Majątek (P480–P486), Formy (P490–P496), Dokumentacja (P370–P376), ESG (P540–P544), Siła Wyższa (P560–P564) | `jdg.conflicts` ⭐ |
| **P3 — NISKIE** | 13 | Sezonowość (P500–P505), Retencja szczegółowa (P370–P376) | — |

---

## 🎯 Critical Path — Mapa Drogowa Wdrożenia

| Faza | Tydzień | Priorytet | Liczba reguł | Deliverable |
|---|---|---|---|---|
| **A — Core Validation** | 1 | P0 | 19 | `jdg.validation.rego` + edge cases w `vat.substantive`, `conflicts`, `zus`, `pit.forms`, `crossborder` |
| **B — Compliance & Audit** | 2 | P1 | 30 | `jdg.audit.rego` + rozszerzenie `jdg.compliance` (MDR, DAC7, kasa) |
| **C — Tax & International** | 3 | P1 | 38 | WHT (P460+), Import usług (P450+), Sankcje (P350+), Złe długi (P420+) |
| **D — Lifecycle & Assets** | 4 | P2 | 55 | Limity, Reverse charge, Marża, Majątek, Formy, ESG, Siła Wyższa |
| **E — Edge Cases & Temporal** | 5 | P2-P3 | 38 | Sezonowość, Dokumentacja, Temporal metadata |

---

## 📊 Alignment z nowymi pakietami z Doc 35

| Pakiet (z Doc 35) | Reguły w Doc 36 | Opis |
|---|---|---|
| **`jdg.validation`** ⭐ | P950–P958 (9 reguł) | Walidacja NIP, IBAN, dat, kwot, REGON, KRS |
| **`jdg.audit`** ⭐ | P380–P385, P510–P516 (13 reguł) | Kontrola skarbowa, immutable log, audit lock, terminy |
| **`jdg.conflicts`** ⭐ | P362, P523, P543 (3 reguły + podstawa dla 7 kolejnych) | Edge case'y wielokrotnych ulg, greenwashing detection, hallmark conflicts |

---

> **🔥 Następny krok:** Implementacja Fazy A (P0 — 19 reguł walidacyjnych) w `policies/jdg/validation.rego`

---

*Wygenerowano przez NexusAI Deep Analysis Engine v2.1 — druga, rozszerzona warstwa analizy luk.*
*Data: 2026-07-11 | 26 obszarów × 180 reguł × 6 nowych obszarów ENTERPRISE*
