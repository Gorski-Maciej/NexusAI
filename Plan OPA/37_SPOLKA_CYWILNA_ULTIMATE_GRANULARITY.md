# 🔬 NexusAI Spółka Cywilna — ULTIMATE GRANULARITY: Plan Reguł OPA/Rego ENTERPRISE v5.0

> **Status:** DEFINITYWNY — Każdy artykuł, każdy ustęp, każdy warunek = osobna reguła
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md`
> **Cel:** 600+ mikro-reguł z dekompozycją jeden-warunek-jedna-reguła, gotowych do bezpośredniej implementacji Rego
> **Źródła:** `Plan OPA/Docs SC` — 225 linii, ~100 artykułów, ~800 punktów prawnych
> **Dokumenty referencyjne:** `SC_DEFINITIVE_REGO_PLAN.md`, `SC_EXPANSION_14_AREAS.md`, `35_SPOLKA_CYWILNA_ADVANCED_GAPS.md`, `36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md`
> **Reguły łącznie:** ~600 (opisanych z kompletem 8 elementów) | **Pakietów:** 31 | **Priorytetów:** 0-2599

---

## SPIS TREŚCI

1. [Filozofia Mikro-Dekompozycji](#1-filozofia-mikro-dekompozycji)
2. [31 Pakietów — Mapa Systemu](#2-31-pakietów--mapa-systemu)
3. [Hierarchia First-Match-Wins — 20 Bloków](#3-hierarchia-first-match-wins--20-bloków)
4. [Wymagane Dane Wejściowe (`input`)](#4-wymagane-dane-wejściowe-input)
5. [Katalog Parametrów Dynamicznych (`thresholds`)](#5-katalog-parametrów-dynamicznych-thresholds)
6. [Katalog Reguł — Dekompozycja Mikro](#6-katalog-reguł--dekompozycja-mikro)
   - [6.1 sc.risk — Ryzyko i Fraud (GR-0 do GR-14)](#61-scrisk--ryzyko-i-fraud-gr-0-do-gr-14)
   - [6.2 sc.routing — Field Confidence (GR-15 do GR-24)](#62-scrouting--field-confidence-gr-15-do-gr-24)
   - [6.3 sc.compliance — Zgodność (GR-25 do GR-49)](#63-sccompliance--zgodność-gr-25-do-gr-49)
   - [6.4 sc.crossborder — Transgraniczne (GR-50 do GR-74)](#64-sccrossborder--transgraniczne-gr-50-do-gr-74)
   - [6.5 sc.vat.substantive — Stawki i Zwolnienia (GR-75 do GR-134)](#65-scvatsubstantive--stawki-i-zwolnienia)
   - [6.6 sc.vat.deductions — Odliczenia (GR-135 do GR-169)](#66-scvatdeductions--odliczenia)
   - [6.7 sc.vat.tax_point — Moment Obowiązku (GR-170 do GR-189)](#67-scvattax_point--moment-obowiązku)
   - [6.8 sc.vat.gtu — Kody GTU (GR-190 do GR-204)](#68-scvatgtu--kody-gtu)
   - [6.9 sc.vat.ksef — KSeF (GR-205 do GR-224)](#69-scvatksef--ksef)
   - [6.10 sc.vat.jpk — JPK_VAT (GR-225 do GR-244)](#610-scvatjpk--jpk_vat)
   - [6.11 sc.pit.partners — Podział Proporcjonalny (GR-250 do GR-279)](#611-scpitpartners--podział-proporcjonalny)
   - [6.12 sc.pit.forms — Formy Opodatkowania (GR-280 do GR-324)](#612-scpitforms--formy-opodatkowania)
   - [6.13 sc.pit.kup — KUP per Wspólnik (GR-325 do GR-364)](#613-scpitkup--kup-per-wspólnik)
   - [6.14 sc.pit.advances — Zaliczki (GR-365 do GR-389)](#614-scpitadvances--zaliczki)
   - [6.15 sc.pit.returns — Zeznania Roczne (GR-390 do GR-409)](#615-scpitreturns--zeznania-roczne)
   - [6.16 sc.pit.exemptions — Zwolnienia (GR-410 do GR-434)](#616-scpitexemptions--zwolnienia)
   - [6.17 sc.pit.allowances — Ulgi (GR-435 do GR-474)](#617-scpitallowances--ulgi)
   - [6.18 sc.zus.social — Składki Społeczne (GR-475 do GR-504)](#618-sczussocial--składki-społeczne)
   - [6.19 sc.zus.health — Składka Zdrowotna (GR-505 do GR-529)](#619-sczushealth--składka-zdrowotna)
   - [6.20 sc.accounting.full — Pełna Księgowość (GR-530 do GR-559)](#620-scaccountingfull--pełna-księgowość)
   - [6.21 sc.accounting.pkpir — PKPiR (GR-560 do GR-579)](#621-scaccountingpkpir--pkpir)
   - [6.22 sc.accounting.depreciation — Amortyzacja (GR-580 do GR-604)](#622-scaccountingdepreciation--amortyzacja)
   - [6.23 sc.partnership.formation — Powstanie (GR-610 do GR-624)](#623-scpartnershipformation--powstanie)
   - [6.24 sc.partnership.changes — Zmiany Składu (GR-625 do GR-644)](#624-scpartnershipchanges--zmiany-składu)
   - [6.25 sc.partnership.liability — Odpowiedzialność (GR-645 do GR-679)](#625-scpartnershipliability--odpowiedzialność)
   - [6.26 sc.partnership.representation — Reprezentacja (GR-680 do GR-694)](#626-scpartnershiprepresentation--reprezentacja)
   - [6.27 sc.partnership.dissolution — Rozwiązanie (GR-695 do GR-714)](#627-scpartnershipdissolution--rozwiązanie)
   - [6.28 sc.partnership.succession — Sukcesja (GR-715 do GR-729)](#628-scpartnershipsuccession--sukcesja)
   - [6.29 sc.partnership.suspension — Zawieszenie (GR-730 do GR-744)](#629-scpartnershipsuspension--zawieszenie)
   - [6.30 sc.employer — Pracodawca (GR-745 do GR-769)](#630-scemployer--pracodawca)
   - [6.31 sc.sanctions+interactions — Sankcje i Interakcje (GR-770 do GR-799)](#631-scsanctionsinteractions--sankcje-i-interakcje)
7. [Cross-Reference: Każdy artykuł ustawy → Reguły GR](#7-cross-reference-każdy-artykuł-ustawy--reguły-gr)

---

## 1. Filozofia Mikro-Dekompozycji

### Zasada fundamentalna: JEDEN WARUNEK = JEDNA REGUŁA

Każda reguła w tym katalogu spełnia **dokładnie jedną funkcję decyzyjną**:
- Sprawdza **jeden próg** (np. czy kwota > 200 000 PLN?)
- Weryfikuje **jeden status** (np. czy podatnik jest czynnym podatnikiem VAT?)
- Oblicza **jedną wartość** (np. podatek = podstawa × stawka)
- Ocenia **jeden wyjątek** (np. czy transakcja podlega zwolnieniu?)

### Format reguły GR (Granular Rule):
```
### GR-XXXX: `nazwa_reguly_w_jezyku_angielskim`
- **Cel:** [1 zdanie — co reguła sprawdza]
- **Warunki:** [lista przesłanek]
- **Rezultat:** [co zwraca — allow/deny, wartość, komunikat]
- **Podstawa:** [artykuł, ustawa]
- **Zależności:** [przed GR-X, po GR-Y]
- **Brzegowe:** [kiedy NIE ma zastosowania]
- **Obszary:** [VAT/PIT/ZUS/Księgowość/Odpowiedzialność]
- **Priorytet:** [0-2599]
```

### Konwencje nazewnicze:
- `GR-` prefix oznacza Granular Rule
- Numeracja odpowiada priorytetowi wykonania (first-match-wins)
- Nazwy w języku angielskim, opisy w języku polskim
- Oznaczenia: ★★★ = fundamentalna, ★★ = krytyczna, ★ = ważna

---

## 2. 31 Pakietów — Mapa Systemu

| ID | Pakiet Rego | Zakres | Liczba reguł | Priorytety |
|:--:|-------------|--------|:----------:|:----------:|
| 1 | `sc.risk` | Fraud, integrity, AML, blacklist | 15 | 0-14 |
| 2 | `sc.routing` | Field confidence, document validation | 10 | 15-24 |
| 3 | `sc.compliance` | Biała lista, MPP, terminy, limity | 25 | 25-49 |
| 4 | `sc.crossborder` | WDT, WNT, import/export usług, VAT-UE | 25 | 50-74 |
| 5 | `sc.vat.substantive` | Stawki, zwolnienia, procedury | 60 | 75-134 |
| 6 | `sc.vat.deductions` | Odliczenia VAT, proporcja, korekty | 35 | 135-169 |
| 7 | `sc.vat.tax_point` | Moment obowiązku podatkowego | 20 | 170-189 |
| 8 | `sc.vat.gtu` | Kody GTU | 15 | 190-204 |
| 9 | `sc.vat.ksef` | Faktury ustrukturyzowane | 20 | 205-224 |
| 10 | `sc.vat.jpk` | JPK_V7M/V7K | 20 | 225-244 |
| 11 | `sc.pit.partners` | Podział proporcjonalny (Art. 8 PIT) | 30 | 250-279 |
| 12 | `sc.pit.forms` | Formy opodatkowania per wspólnik | 45 | 280-324 |
| 13 | `sc.pit.kup` | KUP per wspólnik | 40 | 325-364 |
| 14 | `sc.pit.advances` | Zaliczki PIT | 25 | 365-389 |
| 15 | `sc.pit.returns` | Zeznania roczne | 20 | 390-409 |
| 16 | `sc.pit.exemptions` | Zwolnienia PIT | 25 | 410-434 |
| 17 | `sc.pit.allowances` | Ulgi podatkowe | 40 | 435-474 |
| 18 | `sc.zus.social` | Składki społeczne per wspólnik | 30 | 475-504 |
| 19 | `sc.zus.health` | Składka zdrowotna per wspólnik | 25 | 505-529 |
| 20 | `sc.accounting.full` | Pełna księgowość (UoR) | 30 | 530-559 |
| 21 | `sc.accounting.pkpir` | PKPiR | 20 | 560-579 |
| 22 | `sc.accounting.depreciation` | Amortyzacja ŚT i WNiP | 25 | 580-604 |
| 23 | `sc.partnership.formation` | Powstanie SC, walidacja | 15 | 610-624 |
| 24 | `sc.partnership.changes` | Zmiany składu wspólników | 20 | 625-644 |
| 25 | `sc.partnership.liability` | Odpowiedzialność solidarna | 35 | 645-679 |
| 26 | `sc.partnership.representation` | Reprezentacja, pełnomocnictwa | 15 | 680-694 |
| 27 | `sc.partnership.dissolution` | Rozwiązanie, likwidacja | 20 | 695-714 |
| 28 | `sc.partnership.succession` | Sukcesja, zarząd sukcesyjny | 15 | 715-729 |
| 29 | `sc.partnership.suspension` | Zawieszenie, wznowienie | 15 | 730-744 |
| 30 | `sc.employer` | Spółka jako pracodawca | 25 | 745-769 |
| 31 | `sc.sanctions+interactions` | Sankcje KKS, interakcje, fallback | 30 | 770-799 |
| | **RAZEM** | | **~620** | |

---

## 3. Hierarchia First-Match-Wins — 20 Bloków

```
INPUT → BLOK 0: RISK [GR-0..14]
     → BLOK 1: ROUTING [GR-15..24]
     → BLOK 2: COMPLIANCE [GR-25..49]
     → BLOK 3: CROSSBORDER [GR-50..74]
     → BLOK 4: CYKL ŻYCIA SPÓŁKI [GR-610..744]  (formation, changes, representation, suspension, succession, dissolution)
     → BLOK 5: VAT SUBSTANTIVE [GR-75..134]  (stawki, zwolnienia)
     → BLOK 6: VAT TAX POINT [GR-170..189]
     → BLOK 7: VAT DEDUCTIONS [GR-135..169]
     → BLOK 8: VAT GTU [GR-190..204]
     → BLOK 9: VAT KSeF [GR-205..224]
     → BLOK 10: VAT JPK [GR-225..244]
     → BLOK 11: PIT PARTNERS (FUNDAMENT) [GR-250..279]  ★★★ Art. 8 PIT
     → BLOK 12: PIT FORMS [GR-280..324]
     → BLOK 13: PIT KUP [GR-325..364]
     → BLOK 14: PIT ADVANCES [GR-365..389]
     → BLOK 15: PIT EXEMPTIONS + ALLOWANCES [GR-410..474]
     → BLOK 16: PIT RETURNS [GR-390..409]
     → BLOK 17: ZUS SOCIAL [GR-475..504]
     → BLOK 18: ZUS HEALTH [GR-505..529]
     → BLOK 19: ACCOUNTING [GR-530..604]
     → BLOK 20: EMPLOYER + SANCTIONS [GR-745..799]
```

**Zasada:** W każdym bloku — first-match-wins. Pierwsza reguła, której warunki są spełnione, **natychmiast** zwraca werdykt. Kolejne reguły w bloku NIE są sprawdzane.

**Wyjątki od first-match-wins:**
- BLOK 11 (PIT PARTNERS) jest zawsze wykonywany (to fundament obliczeniowy)
- Reguły oznaczone `[AKUMULUJ]` sumują wyniki zamiast zastępować


## 4. Wymagane Dane Wejściowe (`input`)

```json
{
  "invoice": {
    "transaction_date": "2026-06-15",
    "category_code": "IT_OFFICE",
    "amount_net": 10000.00,
    "amount_gross": 12300.00,
    "currency": "PLN",
    "direction": "PURCHASE",
    "expense_type": "OPERATIONAL",
    "pkwiu_code": "62.01.12.0",
    "is_cash_payment": false,
    "is_paid": false,
    "days_overdue": 0,
    "procedure": "",
    "is_correction": false,
    "correction_type": "",
    "delivery_date": "2026-06-10",
    "has_vat_invoice": true,
    "vehicle_gvw_kg": null
  },
  "vendor": {
    "nip": "1234567890",
    "country": "PL",
    "is_business": true,
    "tax_residence": "PL",
    "is_on_vat_whitelist": true,
    "bank_account_on_whitelist": true
  },
  "partnership": {
    "name": "XYZ s.c.",
    "nip": "9876543210",
    "status": "ACTIVE",
    "is_vat_payer": true,
    "is_vat_eu_registered": true,
    "vat_exempt_until": null,
    "accounting_method": "PKPIR",
    "revenue_annual_net": 1500000.00,
    "revenue_annual_eur": 340000.00,
    "employee_count": 3,
    "partner_count": 2,
    "assets_value": 500000.00,
    "owns_real_estate": false,
    "owns_vehicles": false,
    "has_excise_warehouse": false,
    "generates_waste": true,
    "bdo_registered": true,
    "has_active_grants": false
  },
  "partners": [{
    "id": "P1",
    "nip": "1111111111",
    "name": "Jan Kowalski",
    "share_percent": 50,
    "tax_form": "PIT_SCALE",
    "tax_residence": "PL",
    "zus_status": "STANDARD",
    "zus_sickness_opted_in": true,
    "marital_status": "MARRIED",
    "marital_regime": "COMMUNITY",
    "filing_jointly": true,
    "has_disability_certificate": false,
    "age": 42,
    "join_date": "2024-01-01",
    "exit_date": null,
    "deceased": false,
    "bankruptcy_status": null
  }, {
    "id": "P2",
    "nip": "2222222222",
    "name": "Anna Nowak",
    "share_percent": 50,
    "tax_form": "LINEAR",
    "tax_residence": "PL",
    "zus_status": "MALY_ZUS_PLUS",
    "zus_sickness_opted_in": false,
    "marital_status": "SINGLE",
    "age": 35,
    "join_date": "2024-01-01",
    "exit_date": null,
    "deceased": false,
    "bankruptcy_status": null
  }],
  "thresholds": {
    "sc": {
      "bounds": {
        "vat_exemption_limit_pln": 200000,
        "full_accounting_limit_eur": 2000000,
        "eur_pln_rate": 4.35,
        "whitelist_transfer_threshold_pln": 15000,
        "cash_payment_limit_pln": 15000,
        "aml_cash_threshold_eur": 15000,
        "leasing_car_value_limit_pln": 150000,
        "leasing_car_ev_limit_pln": 225000,
        "zus_30x_limit": 234720,
        "ikze_annual_limit": 9370,
        "internet_relief_limit": 760,
        "remote_work_equivalent_limit": 300,
        "succession_max_months": 24,
        "suspension_max_months": 24,
        "audit_max_duration_days": 60,
        "transfer_pricing_revenue_limit_eur": 2000000,
        "transfer_pricing_transaction_limit_pln": 500000
      },
      "rates": {
        "vat_standard": 0.23,
        "vat_reduced_8": 0.08,
        "vat_reduced_5": 0.05,
        "vat_0": 0.00,
        "pit_scale_12": 0.12,
        "pit_scale_32": 0.32,
        "pit_linear": 0.19,
        "pit_ip_box": 0.05,
        "zus_social_total": 0.3194,
        "zus_health_standard": 0.09,
        "zus_health_linear": 0.049,
        "wht_standard": 0.20,
        "penalty_interest": 0.125,
        "tax_free_amount": 30000
      },
      "eu_countries": ["AT","BE","BG","HR","CY","CZ","DK","EE","FI","FR","DE","GR","HU","IE","IT","LV","LT","LU","MT","NL","PL","PT","RO","SK","SI","ES","SE"]
    }
  }
}
```

### Kluczowe pola `input.partners[]`:
- `share_percent`: udział w zyskach/stratach — podstawa podziału (Art. 8 PIT)
- `tax_form`: forma opodatkowania — PIT_SCALE, LINEAR, LUMP_SUM, TAX_CARD, IP_BOX
- `tax_residence`: rezydencja podatkowa — PL = nieograniczony obowiązek, inne = ograniczony
- `zus_status`: STANDARD, ULGA_NA_START, MALY_ZUS_PLUS, RETIREMENT_CONCURRENT
- Każdy wspólnik jest iterowany przez pętlę `walk(partners)`

---

## 5. Katalog Parametrów Dynamicznych (`thresholds`)

Wszystkie wartości liczbowe są ładowane z `input.thresholds.sc.*` – **NIGDY nie są hardcodowane w regułach**. Umożliwia to aktualizację systemu bez zmiany kodu Rego.

| Ścieżka thresholds | Wartość domyślna (2026) | Opis |
|---------------------|:-----------------------:|------|
| `bounds.vat_exemption_limit_pln` | 200 000 | Limit zwolnienia podmiotowego VAT |
| `bounds.full_accounting_limit_eur` | 2 000 000 | Próg pełnej księgowości |
| `bounds.eur_pln_rate` | 4.35 | Kurs EUR/PLN (NBP, 1 października) |
| `bounds.whitelist_transfer_threshold_pln` | 15 000 | Próg Białej Listy VAT |
| `bounds.cash_payment_limit_pln` | 15 000 | Limit płatności gotówkowych B2B |
| `bounds.aml_cash_threshold_eur` | 15 000 | Próg raportowania AML |
| `rates.vat_standard` | 0.23 | Stawka podstawowa VAT |
| `rates.vat_reduced_8` | 0.08 | Stawka obniżona 8% |
| `rates.vat_reduced_5` | 0.05 | Stawka obniżona 5% |
| `rates.pit_scale_12` | 0.12 | Pierwszy próg skali PIT |
| `rates.pit_scale_32` | 0.32 | Drugi próg skali PIT |
| `rates.pit_linear` | 0.19 | Podatek liniowy |
| `rates.zus_social_total` | 0.3194 | Suma stóp składek społecznych |
| `rates.zus_health_standard` | 0.09 | Składka zdrowotna (skala/ryczałt) |
| `rates.zus_health_linear` | 0.049 | Składka zdrowotna (liniowy) |
| `rates.tax_free_amount` | 30 000 | Kwota wolna od podatku |

---

## 6. Katalog Reguł — Dekompozycja Mikro

### 6.1 sc.risk — Ryzyko i Fraud (GR-0 do GR-14)

#### GR-0: `sc_risk_amount_negative` ★
- **Cel:** Wykrywanie ujemnych kwot na fakturze (potencjalny fraud).
- **Warunki:** `input.invoice.amount_net < 0`
- **Rezultat:** `deny` + alert `"NEGATIVE_AMOUNT_DETECTED"`
- **Podstawa:** Art. 62 KKS (oszustwo podatkowe)
- **Zależności:** Pierwsza reguła w systemie.
- **Brzegowe:** Korekty in-minus (faktury korygujące) mogą mieć wartości ujemne — wyjątek gdy `is_correction == true`.
- **Obszary:** VAT, PIT
- **Priorytet:** 0

#### GR-1: `sc_risk_date_future` ★
- **Cel:** Blokada faktur z datą przyszłą (np. 2027-01-01 gdy jest 2026-07-11).
- **Warunki:** `input.invoice.transaction_date > today()`
- **Rezultat:** `deny` + alert `"FUTURE_DATE_DETECTED"`
- **Podstawa:** Art. 19a VAT (moment obowiązku podatkowego)
- **Brzegowe:** Faktury pro-forma (nie dokument księgowy) → dozwolone.
- **Obszary:** VAT
- **Priorytet:** 1

#### GR-2: `sc_risk_date_too_old` ★
- **Cel:** Ostrzeżenie o fakturach starszych niż 5 lat (przedawnienie + ryzyko nieprawidłowości).
- **Warunki:** `input.invoice.transaction_date < today() - 5_years`
- **Rezultat:** `warn` + alert `"TRANSACTION_MAY_BE_PRESCRIBED"`
- **Podstawa:** Art. 70 Ordynacji podatkowej
- **Brzegowe:** Faktury archiwalne (oznaczone jako `is_archived == true`) → pomijane.
- **Obszary:** VAT, PIT
- **Priorytet:** 2

#### GR-3: `sc_risk_vendor_nip_blacklisted` ★★
- **Cel:** Sprawdzenie czy NIP kontrahenta znajduje się na liście ostrzeżeń KAS (podmioty wykreślone z VAT).
- **Warunki:** `vendor_nip IN blacklist.kas_vat_deleted`
- **Rezultat:** `deny` + alert `"VENDOR_VAT_DELETED"` — transakcja ryzykowna
- **Podstawa:** Art. 96 VAT (wykreślenie z rejestru VAT)
- **Brzegowe:** Transakcje poniżej 500 PLN → tylko warn, nie deny.
- **Obszary:** VAT
- **Priorytet:** 3

#### GR-4: `sc_risk_vendor_sanctioned` ★
- **Cel:** Sprawdzenie czy kontrahent podlega sankcjom międzynarodowym (listy OFAC, UE).
- **Warunki:** `vendor_name IN sanctions_lists`
- **Rezultat:** `deny` + alert `"SANCTIONED_ENTITY_DETECTED"`
- **Podstawa:** Rozporządzenia UE o sankcjach
- **Obszary:** VAT, PIT
- **Priorytet:** 4

#### GR-5: `sc_risk_invoice_duplicate` ★
- **Cel:** Wykrywanie duplikatów faktur (ta sama numeracja od tego samego kontrahenta).
- **Warunki:** `same_vendor_nip AND same_invoice_number` w bazie
- **Rezultat:** `deny` + alert `"DUPLICATE_INVOICE"`
- **Podstawa:** Art. 106e VAT (unikalna numeracja faktur)
- **Brzegowe:** Korekty (oznaczone `is_correction == true`) → dozwolone z tym samym numerem.
- **Obszary:** VAT
- **Priorytet:** 5

#### GR-6: `sc_risk_amount_mismatch` ★
- **Cel:** Sprawdzenie czy `amount_net + vat_amount == amount_gross`.
- **Warunki:** `abs(amount_net + vat_amount - amount_gross) > 0.01`
- **Rezultat:** `deny` + alert `"AMOUNT_MISMATCH"`
- **Podstawa:** Art. 106e VAT (prawidłowość kwot)
- **Obszary:** VAT, Księgowość
- **Priorytet:** 6

#### GR-7: `sc_risk_rounding_inconsistency` ★
- **Cel:** Sprawdzenie czy kwoty są prawidłowo zaokrąglone do 2 miejsc po przecinku.
- **Warunki:** `amount_net != round(amount_net, 2)`
- **Rezultat:** `warn` + `amount_rounded: round(amount_net, 2)`
- **Podstawa:** Art. 106e VAT
- **Obszary:** VAT, Księgowość
- **Priorytet:** 7

#### GR-8: `sc_risk_aml_15k_cash` ★★
- **Cel:** Obowiązek raportowania transakcji gotówkowych >15 000 EUR do GIIF.
- **Warunki:** `is_cash_payment == true AND amount_pln > thresholds.bounds.aml_cash_threshold_eur * eur_pln_rate`
- **Rezultat:** `warn` + alert `"AML_REPORT_REQUIRED"`
- **Podstawa:** Art. 72 ustawy o AML
- **Obszary:** VAT, PIT
- **Priorytet:** 8

#### GR-9: `sc_risk_cash_limit_15k_pln` ★★
- **Cel:** Limit płatności gotówkowych B2B do 15 000 PLN. Powyżej → obowiązek przelewu.
- **Warunki:** `is_cash_payment == true AND amount_gross > 15000 AND vendor.is_business == true`
- **Rezultat:** `deny` + alert `"CASH_LIMIT_EXCEEDED"` — koszty NKUP
- **Podstawa:** Art. 19 Prawa przedsiębiorców
- **Obszary:** PIT (KUP)
- **Priorytet:** 9

#### GR-10: `sc_risk_related_party_transaction` ★
- **Cel:** Oznaczenie transakcji z podmiotami powiązanymi (rodzina, wspólnicy).
- **Warunki:** `vendor_is_spouse OR vendor_is_child OR vendor_is_partner`
- **Rezultat:** `flag: "RELATED_PARTY"` + wymóg weryfikacji cen transferowych
- **Podstawa:** Art. 23m PIT
- **Brzegowe:** Transakcje < 500 PLN → pomijane.
- **Obszary:** PIT
- **Priorytet:** 10

#### GR-11: `sc_risk_structuring_detection` ★
- **Cel:** Wykrywanie strukturyzacji transakcji (dzielenie na mniejsze kwoty dla ominięcia limitów).
- **Warunki:** `count(transactions_to_same_vendor_today) >= 3 AND each_amount < 15000 AND total_amount > 15000`
- **Rezultat:** `flag: "STRUCTURING_SUSPECTED"`
- **Podstawa:** Art. 54 KKS, Art. 72 ustawy o AML
- **Obszary:** VAT, PIT
- **Priorytet:** 11

#### GR-12: `sc_risk_partner_bankruptcy_active` ★★
- **Cel:** Sprawdzenie czy którykolwiek wspólnik jest w trakcie upadłości konsumenckiej.
- **Warunki:** `any(partners[].bankruptcy_status == "CONSUMER_BANKRUPTCY")`
- **Rezultat:** `deny` + alert `"PARTNER_IN_BANKRUPTCY"` — spółka w likwidacji
- **Podstawa:** Art. 874 pkt 2 KC
- **Obszary:** Odpowiedzialność, Księgowość
- **Priorytet:** 12

#### GR-13: `sc_risk_partner_deceased` ★★
- **Cel:** Sprawdzenie czy którykolwiek wspólnik nie żyje.
- **Warunki:** `any(partners[].deceased == true)`
- **Rezultat:** `flag: "PARTNER_DECEASED"` — uruchomienie procedury sukcesji
- **Podstawa:** Art. 872 KC
- **Obszary:** Odpowiedzialność
- **Priorytet:** 13

#### GR-14: `sc_risk_integrity_hash` ★
- **Cel:** Weryfikacja integralności danych wejściowych (checksum).
- **Warunki:** `input._integrity_hash != sha256(input)`
- **Rezultat:** `deny` + alert `"DATA_INTEGRITY_FAILURE"`
- **Brzegowe:** W trybie testowym `_skip_integrity == true` — pomijane.
- **Obszary:** Wszystkie
- **Priorytet:** 14


### 6.2 sc.routing — Field Confidence (GR-15 do GR-24)

#### GR-15: `sc_routing_field_confidence_score` ★
- **Cel:** Obliczenie ogólnego wskaźnika pewności danych wejściowych.
- **Warunki:** Zawsze wykonywane. Sprawdza kompletność pól: `invoice.*`, `vendor.*`, `partnership.*`.
- **Rezultat:** `field_confidence: 0.0-1.0` — gdzie 1.0 = wszystkie pola wypełnione.
- **Podstawa:** Wewnętrzny standard jakości danych.
- **Zależności:** Przed wszystkimi regułami w bloku.
- **Brzegowe:** Pola opcjonalne (np. `vehicle_gvw_kg`) nie obniżają score jeśli puste.
- **Obszary:** Wszystkie
- **Priorytet:** 15

#### GR-16: `sc_routing_nip_format` ★
- **Cel:** Walidacja formatu NIP (10 cyfr, checksum).
- **Warunki:** `vendor.nip NOT matching "^[0-9]{10}$" OR failed_nip_checksum(vendor.nip)`
- **Rezultat:** `deny` + alert `"INVALID_NIP_FORMAT"`
- **Podstawa:** Art. 7 ust. 1 ustawy o NIP
- **Brzegowe:** NIP zagraniczny (VAT-UE) → inny format, osobna reguła GR-17.
- **Obszary:** VAT
- **Priorytet:** 16

#### GR-17: `sc_routing_eu_vat_format` ★
- **Cel:** Walidacja formatu VAT-UE (kod kraju + 2-12 znaków).
- **Warunki:** `vendor.country IN eu_countries AND vendor.country != "PL" AND NOT valid_eu_vat(vendor.nip, vendor.country)`
- **Rezultat:** `warn` + alert `"INVALID_EU_VAT_FORMAT"`
- **Podstawa:** Dyrektywa VAT UE
- **Obszary:** VAT
- **Priorytet:** 17

#### GR-18: `sc_routing_required_fields_sale` ★
- **Cel:** Sprawdzenie kompletności pól wymaganych dla faktury sprzedaży.
- **Warunki:** `direction == "SALE" AND (customer_nip == null OR pkwiu_code == null)`
- **Rezultat:** `deny` + alert `"MISSING_REQUIRED_FIELDS_SALE"`
- **Podstawa:** Art. 106e VAT
- **Obszary:** VAT
- **Priorytet:** 18

#### GR-19: `sc_routing_required_fields_purchase` ★
- **Cel:** Sprawdzenie kompletności pól wymaganych dla faktury zakupu.
- **Warunki:** `direction == "PURCHASE" AND (vendor_nip == null OR expense_type == null)`
- **Rezultat:** `deny` + alert `"MISSING_REQUIRED_FIELDS_PURCHASE"`
- **Podstawa:** Art. 106e VAT, Art. 22 PIT
- **Obszary:** VAT, PIT
- **Priorytet:** 19

#### GR-20: `sc_routing_pkwiu_validation` ★
- **Cel:** Walidacja kodu PKWiU (format 2015: XX.XX.XX.X).
- **Warunki:** `pkwiu_code != null AND NOT matching("^[0-9]{2}\\.[0-9]{2}\\.[0-9]{2}\\.[0-9]$", pkwiu_code)`
- **Rezultat:** `warn` + alert `"INVALID_PKWIU_FORMAT"`
- **Podstawa:** Rozporządzenie Rady Ministrów w sprawie PKWiU 2015
- **Obszary:** VAT (GTU)
- **Priorytet:** 20

#### GR-21: `sc_routing_currency_check` ★
- **Cel:** Weryfikacja czy waluta faktury jest obsługiwana.
- **Warunki:** `currency NOT IN ["PLN", "EUR", "USD", "GBP", "CHF", "CRYPTO"]`
- **Rezultat:** `warn` + alert `"UNSUPPORTED_CURRENCY"`
- **Podstawa:** Art. 106e VAT
- **Brzegowe:** CRYPTO → akceptowane ale wymaga dodatkowej wyceny (GR-1246 crypto).
- **Obszary:** VAT, Księgowość
- **Priorytet:** 21

#### GR-22: `sc_routing_counterparty_country_mismatch` ★
- **Cel:** Sprawdzenie spójności kraju kontrahenta z formatem NIP.
- **Warunki:** `vendor.country == "PL" AND vendor.nip NOT matching "^[0-9]{10}$"`
- **Rezultat:** `warn` + alert `"COUNTRY_NIP_MISMATCH"`
- **Obszary:** VAT
- **Priorytet:** 22

#### GR-23: `sc_routing_direction_sanity` ★
- **Cel:** Sprawdzenie czy kierunek faktury jest logiczny (sprzedaż z kwotą dodatnią, zakup z kwotą dodatnią).
- **Warunki:** `direction IN ["SALE", "PURCHASE"] AND amount_net > 0`
- **Rezultat:** `allow` — logiczny kierunek
- **Brzegowe:** Korekty in-minus → `amount_net` może być ujemne. Faktury korygujące oznaczone `is_correction == true`.
- **Obszary:** VAT, PIT
- **Priorytet:** 23

#### GR-24: `sc_routing_partnership_status_block` ★★
- **Cel:** Blokada księgowania gdy spółka jest w stanie uniemożliwiającym normalną działalność.
- **Warunki:** `partnership.status IN ["DISSOLVED", "BANKRUPT"]`
- **Rezultat:** `deny` + alert `"PARTNERSHIP_INACTIVE"`
- **Podstawa:** Art. 874-875 KC
- **Obszary:** Wszystkie
- **Priorytet:** 24

---

### 6.3 sc.compliance — Zgodność (GR-25 do GR-49)

#### GR-25: `sc_compliance_vat_whitelist_check` ★★
- **Cel:** Sprawdzenie czy kontrahent figuruje na Białej Liście VAT (czynny podatnik).
- **Warunki:** `direction == "PURCHASE" AND amount_gross > 15000 AND vendor.is_on_vat_whitelist == false`
- **Rezultat:** `warn` + alert `"VENDOR_NOT_ON_WHITELIST"` + `joint_liability_risk: true`
- **Podstawa:** Art. 96b VAT, Art. 117ba OP
- **Zależności:** Przed GR-26 (rachunek bankowy).
- **Brzegowe:** Zgłoszenie do US w ciągu 7 dni → zwolnienie z odpowiedzialności solidarnej.
- **Obszary:** VAT, Odpowiedzialność
- **Priorytet:** 25

#### GR-26: `sc_compliance_bank_account_whitelist` ★★
- **Cel:** Sprawdzenie czy rachunek bankowy kontrahenta jest na Białej Liście.
- **Warunki:** `amount_gross > 15000 AND is_bank_transfer == true AND vendor.bank_account_on_whitelist == false`
- **Rezultat:** `deny` + alert `"BANK_ACCOUNT_NOT_ON_WHITELIST"`
- **Podstawa:** Art. 96b VAT
- **Brzegowe:** Mechanizm podzielonej płatności (MPP) → można zapłacić na rachunek VAT (zawsze na białej liście).
- **Obszary:** VAT, Odpowiedzialność
- **Priorytet:** 26

#### GR-27: `sc_compliance_split_payment_mandatory` ★★
- **Cel:** Obowiązkowy mechanizm podzielonej płatności (MPP) dla faktur >15 000 PLN brutto z załącznika nr 15.
- **Warunki:** `amount_gross > 15000 AND pkwiu_code IN mpp_mandatory_codes AND is_split_payment_used == false`
- **Rezultat:** `deny` + alert `"SPLIT_PAYMENT_MANDATORY"`
- **Podstawa:** Art. 108a VAT, Załącznik nr 15 ustawy o VAT
- **Brzegowe:** Płatność kartą płatniczą → zwolnienie z MPP.
- **Obszary:** VAT
- **Priorytet:** 27

#### GR-28: `sc_compliance_split_payment_optional` ★
- **Cel:** Dobrowolny MPP — zachęta dla podatnika.
- **Warunki:** `amount_gross > 15000 AND is_split_payment_requested == true`
- **Rezultat:** `flag: "SPLIT_PAYMENT_VOLUNTARY"` — szybszy zwrot VAT (25 dni zamiast 60)
- **Podstawa:** Art. 108a ust. 1c VAT
- **Obszary:** VAT
- **Priorytet:** 28

#### GR-29: `sc_compliance_invoice_number_format` ★
- **Cel:** Sprawdzenie czy numer faktury zawiera wymagane elementy (unikalny w ramach miesiąca).
- **Warunki:** `invoice_number == null OR invoice_number == ""`
- **Rezultat:** `deny` + alert `"MISSING_INVOICE_NUMBER"`
- **Podstawa:** Art. 106e ust. 1 pkt 2 VAT
- **Obszary:** VAT
- **Priorytet:** 29

#### GR-30: `sc_compliance_vat_registration_check` ★★
- **Cel:** Sprawdzenie czy spółka jest zarejestrowanym podatnikiem VAT (jeśli powinna).
- **Warunki:** `partnership.revenue_annual_net > 200000 AND partnership.is_vat_payer == false`
- **Rezultat:** `deny` + alert `"VAT_REGISTRATION_REQUIRED"`
- **Podstawa:** Art. 113 VAT (zwolnienie podmiotowe do 200 000 PLN)
- **Obszary:** VAT
- **Priorytet:** 30

#### GR-31: `sc_compliance_vat_r_filing` ★
- **Cel:** Termin złożenia VAT-R (rejestracja VAT) — przed pierwszą czynnością opodatkowaną.
- **Warunki:** `partnership.is_vat_payer == false AND partnership.vat_exempt_until == null AND invoice.vat_taxable == true`
- **Rezultat:** `deny` + alert `"VAT_R_REQUIRED_BEFORE_TRANSACTION"`
- **Podstawa:** Art. 96 VAT (VAT-R)
- **Obszary:** VAT
- **Priorytet:** 31

#### GR-32: `sc_compliance_vat_eu_registration` ★★
- **Cel:** Obowiązek rejestracji VAT-UE przed transakcją WDT/WNT.
- **Warunki:** `vendor.country IN eu_countries AND partnership.is_vat_eu_registered == false AND direction IN ["PURCHASE", "SALE"]`
- **Rezultat:** `deny` + alert `"VAT_UE_REGISTRATION_REQUIRED"`
- **Podstawa:** Art. 97 VAT
- **Brzegowe:** Spółka zwolniona z VAT → nie może się zarejestrować VAT-UE.
- **Obszary:** VAT
- **Priorytet:** 32

#### GR-33: `sc_compliance_invoice_due_date` ★
- **Cel:** Termin płatności faktury nie może być wcześniejszy niż data wystawienia.
- **Warunki:** `due_date < transaction_date`
- **Rezultat:** `warn` + alert `"DUE_DATE_BEFORE_ISSUE_DATE"`
- **Podstawa:** Art. 106e VAT
- **Obszary:** VAT, Księgowość
- **Priorytet:** 33

#### GR-34: `sc_compliance_vat_exemption_limit_tracking` ★★
- **Cel:** Monitorowanie limitu zwolnienia VAT 200 000 PLN — dotyczy CAŁEJ spółki.
- **Warunki:** `partnership.revenue_annual_net > 200000 AND partnership.is_vat_payer == false`
- **Rezultat:** `warn` + alert `"VAT_EXEMPTION_LIMIT_EXCEEDED"` — obowiązek rejestracji VAT
- **Podstawa:** Art. 113 VAT
- **Brzegowe:** Limit liczony proporcjonalnie jeśli działalność rozpoczęta w trakcie roku.
- **Obszary:** VAT
- **Priorytet:** 34

#### GR-35 do GR-49: COMPLIANCE — pozostałe [zwięźle]

#### GR-35: `sc_compliance_annual_vat_correction` ★
- **Cel:** Roczna korekta VAT (proporcja wstępna vs rzeczywista).
- **Warunki:** `partnership.vat_pre_pro_rata_applicable == true AND end_of_year`
- **Rezultat:** `vat_annual_correction: (actual_proportion - estimated_proportion) * total_input_vat`
- **Podstawa:** Art. 91 VAT
- **Obszary:** VAT
- **Priorytet:** 35

#### GR-36: `sc_compliance_bad_debt_relief_vat` ★
- **Cel:** Ulga na złe długi w VAT — możliwość korekty VAT należnego po 90 dniach.
- **Warunki:** `direction == "SALE" AND days_overdue > 90 AND is_paid == false AND vendor.is_business == true`
- **Rezultat:** `vat_bad_debt_relief: vat_amount` — korekta in-minus
- **Podstawa:** Art. 89a VAT
- **Brzegowe:** Dłużnik w trakcie restrukturyzacji → ulga zawieszona.
- **Obszary:** VAT
- **Priorytet:** 36

#### GR-37 do GR-49: [zwięźle — kluczowe compliance]

#### GR-37: `sc_compliance_bad_debt_pit` ★
- **Cel:** Ulga na złe długi w PIT — możliwość pomniejszenia przychodu.
- **Warunki:** `days_overdue > 90 AND is_paid == false AND has_court_claim == true`
- **Rezultat:** `pit_revenue_reduction: amount_net * share_percent / 100` per partner
- **Podstawa:** Art. 26i PIT
- **Obszary:** PIT
- **Priorytet:** 37

#### GR-38: `sc_compliance_transfer_pricing_documentation` ★
- **Cel:** Obowiązek dokumentacji cen transferowych.
- **Warunki:** `partnership.revenue_annual_eur > 2000000 AND transaction_with_related_party > 500000`
- **Rezultat:** `tp_documentation_required: true`
- **Podstawa:** Art. 23m-23zf PIT
- **Obszary:** PIT
- **Priorytet:** 38

#### GR-39 do GR-49: [standardowe compliance]

#### GR-39: `sc_compliance_pkpir_obligation_check` ★
- **Cel:** Sprawdzenie czy spółka ma obowiązek prowadzenia PKPiR.
- **Warunki:** `accounting_method == "NONE" AND any_partner_tax_form IN ["PIT_SCALE", "LINEAR"]`
- **Rezultat:** `warn` + `pkpir_required: true`
- **Podstawa:** Art. 24a PIT
- **Obszary:** PIT, Księgowość
- **Priorytet:** 39

#### GR-40: `sc_compliance_ksef_obligation` ★★
- **Cel:** Obowiązek wystawiania faktur przez KSeF od 1.02.2026.
- **Warunki:** `today >= 2026-02-01 AND invoice_type == "SALE" AND is_ksef_sent == false`
- **Rezultat:** `deny` + alert `"KSEF_MANDATORY"`
- **Podstawa:** Ustawa z 16.06.2023 o KSeF
- **Brzegowe:** Faktury konsumenckie (paragonowe) → zwolnione z KSeF.
- **Obszary:** VAT
- **Priorytet:** 40

#### GR-41: `sc_compliance_vat_exempt_invoice_note` ★
- **Cel:** Faktura zwolniona z VAT musi zawierać adnotację "zw." lub podstawę prawną.
- **Warunki:** `vat_rate == 0 AND is_exempt == true AND exemption_basis == null`
- **Rezultat:** `warn` + alert `"MISSING_EXEMPTION_BASIS"`
- **Podstawa:** Art. 106e ust. 1 pkt 19 VAT
- **Obszary:** VAT
- **Priorytet:** 41

#### GR-42 do GR-49: [zwięźle — obowiązki sprawozdawcze]

#### GR-42: `sc_compliance_jpk_deadline_check` ★
- **Cel:** Termin złożenia JPK_VAT — 25. dnia miesiąca następnego.
- **Warunki:** `today > 25th_day_of_next_month AND jpk_submitted == false`
- **Rezultat:** `warn` + alert `"JPK_DEADLINE_MISSED"`
- **Podstawa:** Art. 99 VAT
- **Obszary:** VAT
- **Priorytet:** 42

#### GR-43: `sc_compliance_pit_deadline_check` ★
- **Cel:** Termin złożenia zeznania PIT — 30 kwietnia.
- **Warunki:** `today > 2027-04-30 AND pit_return_submitted == false AND tax_year == 2026`
- **Rezultat:** `warn` + alert `"PIT_RETURN_DEADLINE_MISSED"`
- **Podstawa:** Art. 45 PIT
- **Obszary:** PIT
- **Priorytet:** 43

#### GR-44: `sc_compliance_zus_deadline_check` ★
- **Cel:** Termin opłacenia składek ZUS — 15. dnia (20. dla pełnej księgowości).
- **Warunki:** `today > 20th_day_of_month AND zus_paid == false`
- **Rezultat:** `warn` + alert `"ZUS_DEADLINE_MISSED"`
- **Podstawa:** Art. 36 ustawy o SUS
- **Obszary:** ZUS
- **Priorytet:** 44

#### GR-45: `sc_compliance_penalty_interest_calculation` ★
- **Cel:** Obliczenie odsetek za zwłokę (12.5% rocznie).
- **Warunki:** `days_overdue > 0 AND tax_due > 0`
- **Rezultat:** `penalty_interest: tax_due * 0.125 * days_overdue / 365`
- **Podstawa:** Art. 53-56 Ordynacji podatkowej
- **Obszary:** VAT, PIT
- **Priorytet:** 45

#### GR-46: `sc_compliance_statute_of_limitations_vat` ★
- **Cel:** Sprawdzenie przedawnienia zobowiązania VAT (5 lat).
- **Warunki:** `transaction_date < today() - 5_years AND korekta_requested == true`
- **Rezultat:** `deny` + alert `"VAT_OBLIGATION_PRESCRIBED"`
- **Podstawa:** Art. 70 OP
- **Obszary:** VAT
- **Priorytet:** 46

#### GR-47: `sc_compliance_statute_of_limitations_pit` ★
- **Cel:** Sprawdzenie przedawnienia zobowiązania PIT (5 lat).
- **Warunki:** `transaction_date < today() - 5_years AND pit_correction_requested == true`
- **Rezultat:** `deny` + alert `"PIT_OBLIGATION_PRESCRIBED"`
- **Podstawa:** Art. 70 OP
- **Obszary:** PIT
- **Priorytet:** 47

#### GR-48: `sc_compliance_voluntary_disclosure` ★
- **Cel:** Czynny żal — możliwość uniknięcia kary KKS przy samodzielnym zgłoszeniu.
- **Warunki:** `tax_underpayment > 0 AND voluntary_disclosure_filed == true AND audit_in_progress == false`
- **Rezultat:** `kks_penalty: 0` — czynny żal wyłącza karę
- **Podstawa:** Art. 16 KKS
- **Brzegowe:** Nie można złożyć czynnego żalu PO wszczęciu kontroli.
- **Obszary:** VAT, PIT
- **Priorytet:** 48

#### GR-49: `sc_compliance_gaar_risk_flag` ★
- **Cel:** Oznaczenie transakcji jako potencjalnie objętej klauzulą GAAR.
- **Warunki:** `transaction_is_artificial == true AND tax_benefit > 100000 AND no_economic_substance == true`
- **Rezultat:** `flag: "GAAR_SCRUTINY"` — rekomendacja analizy
- **Podstawa:** Art. 119a-119f OP
- **Obszary:** VAT, PIT
- **Priorytet:** 49


### 6.4 sc.crossborder — Transgraniczne (GR-55 do GR-74)


#### GR-55: `sc_crossborder_wdt_goods` 
- **Cel:** Wewnątrzwspólnotowa dostawa towarów (WDT) — stawka 0% VAT
- **Warunki:** vendor.country IN eu_countries AND vendor.is_business AND direction==SALE AND category_code==GOODS AND goods_transported_to_eu==true
- **Rezultat:** vat_rate:0.00, procedure:WDT, vat_ue_summary:true
- **Podstawa:** Art. 13 VAT
- **Zależności:** po GR-32 (VAT-UE reg)
- **Brzegowe:** Brak dokumentacji transportowej → stawka krajowa
- **Obszary:** VAT
- **Priorytet:** 55


#### GR-56: `sc_crossborder_wdt_transport_documentation` 
- **Cel:** Wymóg posiadania dokumentów transportowych dla WDT 0%
- **Warunki:** wdt_triggered AND has_transport_docs==false
- **Rezultat:** vat_rate:0.23 — stawka krajowa gdy brak dokumentów
- **Podstawa:** Art. 42 ust. 1 pkt 2 VAT
- **Zależności:** po GR-55
- **Brzegowe:** Dokumenty: CMR, list przewozowy, specyfikacja
- **Obszary:** VAT,PIT
- **Priorytet:** 56


#### GR-57: `sc_crossborder_wnt_goods` 
- **Cel:** Wewnątrzwspólnotowe nabycie towarów (WNT) — reverse charge
- **Warunki:** vendor.country IN eu_countries AND direction==PURCHASE AND category_code==GOODS AND partnership.is_vat_payer
- **Rezultat:** procedure:WNT, vat_to_self_assess:true, vat_deductible:IMMEDIATE
- **Podstawa:** Art. 9-11 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 57


#### GR-58: `sc_crossborder_wnt_triangular` 
- **Cel:** Transakcja trójstronna — uproszczona procedura WNT
- **Warunki:** 3_parties_in_3_eu_countries AND middle_party_is_pl AND simplified_procedure_applied
- **Rezultat:** wnt_by_final_recipient:true, middle_party_exempt:true
- **Podstawa:** Art. 135-138 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 58


#### GR-59: `sc_crossborder_import_services_eu` 
- **Cel:** Import usług z UE — reverse charge B2B
- **Warunki:** vendor.country IN eu_countries AND vendor.is_business AND direction==PURCHASE
- **Rezultat:** procedure:IMPORT_SERVICES, vat_to_self_assess:true, gtu:GTU_12
- **Podstawa:** Art. 28b, Art. 17 ust. 1 pkt 4 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 59


#### GR-60: `sc_crossborder_export_services_eu` 
- **Cel:** Eksport usług do UE B2B — NP
- **Warunki:** direction==SALE AND vendor.country IN eu_countries AND vendor.is_business
- **Rezultat:** vat_rate:NP, vat_ue_summary:true
- **Podstawa:** Art. 28b VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 60


#### GR-61: `sc_crossborder_export_goods_non_eu` 
- **Cel:** Eksport towarów poza UE — 0% z IE-599
- **Warunki:** direction==SALE AND vendor.country NOT IN eu_countries AND category_code==GOODS AND has_ie599
- **Rezultat:** vat_rate:0.00, procedure:EXPORT
- **Podstawa:** Art. 41 ust. 6-9 VAT
- **Brzegowe:** Brak IE-599 w ciągu 10 mies. → korekta na stawkę krajową
- **Obszary:** VAT,PIT
- **Priorytet:** 61


#### GR-62: `sc_crossborder_import_goods_non_eu` 
- **Cel:** Import towarów spoza UE — cło + VAT importowy
- **Warunki:** direction==PURCHASE AND vendor.country NOT IN eu_countries AND category_code==GOODS
- **Rezultat:** customs_duty: cif*rate, import_vat: (cif+duty)*vat_rate
- **Podstawa:** UKC 952/2013, Art. 30a VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 62


#### GR-63: `sc_crossborder_vat_ue_summary_deadline` 
- **Cel:** Termin informacji podsumowującej VAT-UE — 25. dnia
- **Warunki:** has_wdt_or_export_services AND today>25th AND vat_ue_submitted==false
- **Rezultat:** warn:MISSING_VAT_UE_SUMMARY
- **Podstawa:** Art. 100 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 63


#### GR-64: `sc_crossborder_oss_procedure` 
- **Cel:** Procedura OSS dla sprzedaży B2C do UE
- **Warunki:** direction==SALE AND vendor.is_business==false AND vendor.country IN eu_countries AND partnership.is_oss_registered
- **Rezultat:** vat_rate:country_of_consumer, procedure:OSS
- **Podstawa:** Art. 138a-138j VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 64


#### GR-65: `sc_crossborder_non_eu_import_services` 
- **Cel:** Import usług spoza UE — reverse charge
- **Warunki:** vendor.country NOT IN eu_countries AND direction==PURCHASE AND vendor.is_business
- **Rezultat:** procedure:IMPORT_SERVICES_NON_EU, vat_to_self_assess:true
- **Podstawa:** Art. 17 ust. 1 pkt 4 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 65


#### GR-66: `sc_crossborder_fx_invoice_conversion` 
- **Cel:** Przeliczenie faktury walutowej na PLN wg kursu NBP
- **Warunki:** currency!=PLN AND date_of_vat_obligation!=null
- **Rezultat:** amount_pln: foreign_amount * nbp_rate(date_of_vat_obligation)
- **Podstawa:** Art. 31a VAT
- **Brzegowe:** Dla faktur zaliczkowych — kurs z dnia otrzymania zaliczki
- **Obszary:** VAT,PIT
- **Priorytet:** 66


#### GR-67: `sc_crossborder_vat_refund_non_eu` 
- **Cel:** Zwrot VAT dla podmiotów spoza UE
- **Warunki:** vendor.country NOT IN eu_countries AND direction==SALE AND vendor.requests_vat_refund
- **Rezultat:** vat_refund_possible:true IF reciprocity
- **Podstawa:** Art. 89 VAT, Rozporządzenie MF
- **Obszary:** VAT,PIT
- **Priorytet:** 67


#### GR-68: `sc_crossborder_foreign_currency_fx_difference` 
- **Cel:** Różnice kursowe od transakcji walutowych
- **Warunki:** currency!=PLN AND is_paid AND payment_date!=invoice_date
- **Rezultat:** fx_difference: paid_amount - invoiced_amount
- **Podstawa:** Art. 24c PIT, Art. 30 UoR
- **Obszary:** VAT,PIT
- **Priorytet:** 68


#### GR-69: `sc_crossborder_customs_aeo_certified` 
- **Cel:** Status AEO — uproszczone procedury celne
- **Warunki:** partnership.has_aeo_certificate AND direction==PURCHASE AND vendor.country NOT IN eu_countries
- **Rezultat:** customs_procedure:SIMPLIFIED, fewer_checks:true
- **Podstawa:** Art. 38-39 UKC
- **Obszary:** VAT,PIT
- **Priorytet:** 69


#### GR-70: `sc_crossborder_intrastat_reporting` 
- **Cel:** Obowiązek raportowania Intrastat — przepływ towarów UE
- **Warunki:** wdt_or_wnt_annual_value > intrastat_threshold AND month_end
- **Rezultat:** intrastat_declaration_required:true, deadline:10th
- **Podstawa:** Art. 52 Ustawy o statystyce publicznej
- **Obszary:** VAT,PIT
- **Priorytet:** 70


#### GR-71: `sc_crossborder_tax_residence_certificate` 
- **Cel:** Wymóg certyfikatu rezydencji dla zastosowania UPO
- **Warunki:** vendor.tax_residence!=PL AND wht_rate < 0.20 AND cert_residence_valid==false
- **Rezultat:** wht_rate_override:0.20 — bez certyfikatu pełny WHT
- **Podstawa:** Art. 26 CIT, Art. 4a PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 71


#### GR-72: `sc_crossborder_foreign_permanent_establishment` 
- **Cel:** Zagraniczny zakład SC — czy powstaje PE?
- **Warunki:** partnership.has_fixed_place_abroad AND duration>6_months
- **Rezultat:** pe_risk:HIGH, foreign_tax_obligation:true
- **Podstawa:** Art. 5 Umowy Modelowej OECD
- **Obszary:** VAT,PIT
- **Priorytet:** 72


#### GR-73: `sc_crossborder_cfc_rules` 
- **Cel:** Zagraniczna spółka kontrolowana (CFC)
- **Warunki:** partnership.owns_foreign_entity AND foreign_tax_rate<14.25
- **Rezultat:** cfc_income_taxable_in_pl:true, cfc_tax_rate:0.19
- **Podstawa:** Art. 30f PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 73


### 6.5 sc.vat.substantive — Stawki i Zwolnienia (GR-75 do GR-134)


#### GR-74: `sc_vat_rate_standard` 
- **Cel:** Stawka podstawowa VAT 23%
- **Warunki:** NOT in reduced_rate_codes AND NOT in exempt_codes
- **Rezultat:** vat_rate:0.23
- **Podstawa:** Art. 41 ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 74


#### GR-75: `sc_vat_rate_reduced_8` 
- **Cel:** Stawka obniżona 8% — towary i usługi z załącznika
- **Warunki:** pkwiu_code IN reduced_8_codes
- **Rezultat:** vat_rate:0.08
- **Podstawa:** Art. 41 ust. 2 VAT + Rozp. MF
- **Obszary:** VAT,PIT
- **Priorytet:** 75


#### GR-76: `sc_vat_rate_reduced_5` 
- **Cel:** Stawka obniżona 5% — podstawowe artykuły spożywcze, książki
- **Warunki:** pkwiu_code IN reduced_5_codes
- **Rezultat:** vat_rate:0.05
- **Podstawa:** Art. 41 ust. 2a VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 76


#### GR-77: `sc_vat_rate_0` 
- **Cel:** Stawka 0% — eksport, WDT, usługi międzynarodowe
- **Warunki:** procedure IN [WDT,EXPORT] AND documentation_complete
- **Rezultat:** vat_rate:0.00
- **Podstawa:** Art. 41 ust. 3-11 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 77


#### GR-78: `sc_vat_exempt_healthcare` 
- **Cel:** Zwolnienie podmiotowe — usługi medyczne
- **Warunki:** pkwiu_code IN healthcare_codes AND provider_is_licensed
- **Rezultat:** vat_rate:EXEMPT, exemption_basis:Art.43.1.18
- **Podstawa:** Art. 43 ust. 1 pkt 18 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 78


#### GR-79: `sc_vat_exempt_education` 
- **Cel:** Zwolnienie — usługi edukacyjne
- **Warunki:** pkwiu_code IN education_codes AND provider_is_registered
- **Rezultat:** vat_rate:EXEMPT
- **Podstawa:** Art. 43 ust. 1 pkt 26 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 79


#### GR-80: `sc_vat_exempt_financial` 
- **Cel:** Zwolnienie — usługi finansowe i ubezpieczeniowe
- **Warunki:** category_code IN [BANKING,INSURANCE,LOAN]
- **Rezultat:** vat_rate:EXEMPT
- **Podstawa:** Art. 43 ust. 1 pkt 37-41 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 80


#### GR-81: `sc_vat_exempt_postal` 
- **Cel:** Zwolnienie — usługi pocztowe
- **Warunki:** category_code==POSTAL AND provider_is_poczta_polska
- **Rezultat:** vat_rate:EXEMPT
- **Podstawa:** Art. 43 ust. 1 pkt 17 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 81


#### GR-82: `sc_vat_exempt_cultural` 
- **Cel:** Zwolnienie — usługi kulturalne
- **Warunki:** category_code IN [THEATER,MUSEUM,LIBRARY] AND provider_is_cultural_institution
- **Rezultat:** vat_rate:EXEMPT
- **Podstawa:** Art. 43 ust. 1 pkt 33 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 82


#### GR-83: `sc_vat_subject_exemption_200k` 
- **Cel:** Zwolnienie podmiotowe do 200 000 PLN
- **Warunki:** partnership.revenue_annual_net <= 200000 AND partnership.is_vat_payer==false
- **Rezultat:** vat_rate:EXEMPT, vat_invoice_not_required
- **Podstawa:** Art. 113 VAT
- **Brzegowe:** Limit dotyczy CAŁEJ spółki cywilnej, nie poszczególnych wspólników
- **Obszary:** VAT,PIT
- **Priorytet:** 83


#### GR-84: `sc_vat_subject_exemption_loss_on_registration` 
- **Cel:** Utrata zwolnienia podmiotowego — przekroczenie limitu
- **Warunki:** partnership.revenue_ytd > 200000 AND partnership.is_vat_payer==false
- **Rezultat:** vat_registration_mandatory:true, effective_from:next_day
- **Podstawa:** Art. 113 ust. 5 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 84


#### GR-85: `sc_vat_subject_exemption_proportional` 
- **Cel:** Limit zwolnienia proporcjonalny w roku rozpoczęcia
- **Warunki:** partnership.started_mid_year AND remaining_months < 12
- **Rezultat:** vat_exemption_limit_proportional: 200000 * remaining_months/12
- **Podstawa:** Art. 113 ust. 9 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 85


#### GR-86: `sc_vat_reverse_charge_domestic` 
- **Cel:** Odwrotne obciążenie — krajowe (załącznik nr 11)
- **Warunki:** pkwiu_code IN reverse_charge_domestic_codes AND vendor.is_vat_payer
- **Rezultat:** procedure:REVERSE_CHARGE, vat_by_buyer:true
- **Podstawa:** Art. 17 ust. 1 pkt 7 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 86


#### GR-87: `sc_vat_split_payment_mark` 
- **Cel:** Oznaczenie faktury 'mechanizm podzielonej płatności'
- **Warunki:** mpp_mandatory AND amount_gross>15000
- **Rezultat:** invoice_note:MPP_REQUIRED, split_payment_mandatory:true
- **Podstawa:** Art. 108a ust. 1a VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 87


#### GR-88: `sc_vat_margin_scheme` 
- **Cel:** Procedura VAT-marża — towary używane, dzieła sztuki
- **Warunki:** procedure==MARGIN OR category_code IN [SECOND_HAND,ART,ANTIQUES]
- **Rezultat:** vat_base:MARGIN, vat_rate:0.23, no_input_vat_deduction
- **Podstawa:** Art. 120 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 88


#### GR-89: `sc_vat_correction_invoice_note` 
- **Cel:** Adnotacja na fakturze korygującej
- **Warunki:** is_correction AND correction_type==PRICE_REDUCTION
- **Rezultat:** invoice_note:CORRECTION_REASON_REQUIRED
- **Podstawa:** Art. 106j VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 89


#### GR-90: `sc_vat_cash_accounting` 
- **Cel:** Metoda kasowa — VAT od zapłaconych faktur
- **Warunki:** partnership.uses_cash_accounting AND is_paid==false
- **Rezultat:** vat_due:0 — odroczony do zapłaty
- **Podstawa:** Art. 21 VAT
- **Brzegowe:** Mały podatnik (<1.2M EUR) może stosować
- **Obszary:** VAT,PIT
- **Priorytet:** 90


#### GR-91: `sc_vat_self_invoicing` 
- **Cel:** Samofakturowanie — nabywca wystawia fakturę
- **Warunki:** self_invoicing_agreement_exists AND direction==PURCHASE
- **Rezultat:** invoice_issued_by:BUYER, same_vat_rules_apply
- **Podstawa:** Art. 106d VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 91


#### GR-92: `sc_vat_e_invoice_structured` 
- **Cel:** Faktura ustrukturyzowana KSeF — wymóg od 2026
- **Warunki:** today>=2026-02-01 AND direction==SALE AND vendor.is_business
- **Rezultat:** ksef_required:true
- **Podstawa:** Ustawa KSeF 2023
- **Obszary:** VAT,PIT
- **Priorytet:** 92


#### GR-93: `sc_vat_paragon_up_to_450` 
- **Cel:** Paragon z NIP do 450 PLN = faktura uproszczona
- **Warunki:** direction==SALE AND amount_gross<=450 AND receipt_has_nip
- **Rezultat:** vat_invoice_recognized:true, simplified_invoice:true
- **Podstawa:** Art. 106e ust. 5 pkt 3 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 93


### 6.6 sc.vat.deductions — Odliczenia VAT (GR-95 do GR-119)


#### GR-94: `sc_vat_deduct_full` 
- **Cel:** Pełne odliczenie VAT naliczonego
- **Warunki:** purchase_related_to_taxable_activity AND has_vat_invoice AND partnership.is_vat_payer
- **Rezultat:** vat_deductible: vat_amount, vat_deduction_percent:100
- **Podstawa:** Art. 86 ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 94


#### GR-95: `sc_vat_deduct_no_invoice` 
- **Cel:** Brak faktury VAT — brak odliczenia
- **Warunki:** has_vat_invoice==false AND partnership.is_vat_payer
- **Rezultat:** vat_deductible:0
- **Podstawa:** Art. 86 ust. 2 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 95


#### GR-96: `sc_vat_deduct_car_50pct` 
- **Cel:** Ograniczenie 50% VAT od samochodów osobowych
- **Warunki:** category_code==VEHICLE AND vehicle_type==PASSENGER_CAR AND private_use_possible
- **Rezultat:** vat_deductible_percent:50
- **Podstawa:** Art. 86a VAT
- **Brzegowe:** Samochód ciężarowy → 100% odliczenia
- **Obszary:** VAT,PIT
- **Priorytet:** 96


#### GR-97: `sc_vat_deduct_fuel_50pct` 
- **Cel:** Ograniczenie 50% VAT od paliwa do samochodów osobowych
- **Warunki:** category_code==FUEL AND vehicle_type==PASSENGER_CAR
- **Rezultat:** vat_deductible_percent:50
- **Podstawa:** Art. 86a ust. 2 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 97


#### GR-98: `sc_vat_deduct_pre_pro_rata` 
- **Cel:** Odliczenie proporcjonalne (pre-współczynnik)
- **Warunki:** partnership.vat_pre_pro_rata_applicable AND mixed_use_purchase
- **Rezultat:** vat_deductible: vat * pre_proportion
- **Podstawa:** Art. 86 ust. 2a-2h VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 98


#### GR-99: `sc_vat_deduct_actual_proportion` 
- **Cel:** Rzeczywista proporcja VAT na koniec roku
- **Warunki:** end_of_year AND pre_pro_rata_applicable
- **Rezultat:** actual_proportion: taxable_turnover/total_turnover, annual_correction_required
- **Podstawa:** Art. 91 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 99


#### GR-100: `sc_vat_deduct_bad_debt_correction` 
- **Cel:** Korekta VAT należnego — ulga na złe długi
- **Warunki:** direction==SALE AND days_overdue>90 AND is_paid==false
- **Rezultat:** vat_correction_in_minus: vat_amount
- **Podstawa:** Art. 89a VAT
- **Brzegowe:** Wymagane: dłużnik nie jest w restrukturyzacji
- **Obszary:** VAT,PIT
- **Priorytet:** 100


#### GR-101: `sc_vat_deduct_bad_debt_repayment` 
- **Cel:** Obowiązek zwrotu VAT skorygowanego przy zapłacie
- **Warunki:** bad_debt_corrected AND is_paid==true AND paid_after_90_days
- **Rezultat:** vat_repayment_due: previously_corrected_vat
- **Podstawa:** Art. 89a ust. 4 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 101


#### GR-102: `sc_vat_deduct_fixed_asset_correction_5y` 
- **Cel:** Korekta 5-letnia VAT od nieruchomości
- **Warunki:** category_code==REAL_ESTATE AND years_since_purchase<=5 AND usage_change
- **Rezultat:** vat_annual_correction: 1/5 * initial_vat * (new_proportion - old_proportion)
- **Podstawa:** Art. 91 ust. 2 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 102


#### GR-103: `sc_vat_deduct_fixed_asset_correction_1y` 
- **Cel:** Korekta 1-roczna VAT od ruchomości
- **Warunki:** category_code==FIXED_ASSET_MOVABLE AND value>15000 AND usage_change
- **Rezultat:** vat_annual_correction: initial_vat * (new_proportion - old_proportion)
- **Podstawa:** Art. 91 ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 103


#### GR-104: `sc_vat_deduct_invoice_missing_data` 
- **Cel:** Brak NIP nabywcy na fakturze — brak odliczenia
- **Warunki:** has_vat_invoice AND invoice.customer_nip==null AND direction==PURCHASE
- **Rezultat:** vat_deductible:0
- **Podstawa:** Art. 88 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 104


#### GR-105: `sc_vat_deduct_empty_invoice` 
- **Cel:** Pusta faktura — brak odliczenia
- **Warunki:** invoice_documents_no_real_transaction
- **Rezultat:** vat_deductible:0, penalty_kks:true
- **Podstawa:** Art. 88 ust. 3a pkt 4 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 105


#### GR-106: `sc_vat_refund_60_days` 
- **Cel:** Standardowy termin zwrotu VAT — 60 dni
- **Warunki:** vat_balance < 0 AND standard_conditions
- **Rezultat:** vat_refund_deadline:60_days
- **Podstawa:** Art. 87 ust. 2 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 106


#### GR-107: `sc_vat_refund_25_days` 
- **Cel:** Przyspieszony zwrot VAT — 25 dni
- **Warunki:** split_payment_used_on_all_purchases AND vat_balance<0
- **Rezultat:** vat_refund_deadline:25_days
- **Podstawa:** Art. 87 ust. 6 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 107


#### GR-108: `sc_vat_deduction_period` 
- **Cel:** Okres odliczenia VAT — bieżący JPK
- **Warunki:** vat_invoice_received_this_month
- **Rezultat:** vat_deduction_period: CURRENT_MONTH
- **Podstawa:** Art. 86 ust. 10-11 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 108


### 6.7 sc.vat.tax_point — Moment Obowiązku (GR-120 do GR-134)


#### GR-109: `sc_vat_tax_point_delivery` 
- **Cel:** Moment podatkowy — data wydania towaru
- **Warunki:** category_code==GOODS AND delivery_date!=null
- **Rezultat:** vat_tax_point: delivery_date
- **Podstawa:** Art. 19a ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 109


#### GR-110: `sc_vat_tax_point_service` 
- **Cel:** Moment podatkowy — data wykonania usługi
- **Warunki:** category_code==SERVICE AND completion_date!=null
- **Rezultat:** vat_tax_point: completion_date
- **Podstawa:** Art. 19a ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 110


#### GR-111: `sc_vat_tax_point_invoice` 
- **Cel:** Moment podatkowy — faktura przed dostawą
- **Warunki:** invoice_date < delivery_date AND invoice_issued
- **Rezultat:** vat_tax_point: invoice_date
- **Podstawa:** Art. 19a ust. 3 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 111


#### GR-112: `sc_vat_tax_point_advance` 
- **Cel:** Moment podatkowy — otrzymanie zaliczki
- **Warunki:** advance_received AND delivery_not_yet_made
- **Rezultat:** vat_tax_point: payment_received_date
- **Podstawa:** Art. 19a ust. 8 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 112


#### GR-113: `sc_vat_tax_point_continuous` 
- **Cel:** Usługi ciągłe — moment podatkowy
- **Warunki:** is_continuous_service AND payment_due_date_reached
- **Rezultat:** vat_tax_point: last_day_of_payment_period
- **Podstawa:** Art. 19a ust. 3 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 113


#### GR-114: `sc_vat_tax_point_30_days` 
- **Cel:** Faktura >30 dni po dostawie
- **Warunki:** delivery_date + 30_days < invoice_date
- **Rezultat:** vat_tax_point_overridden: delivery_date + 30_days
- **Podstawa:** Art. 19a ust. 7 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 114


#### GR-115: `sc_vat_tax_point_construction` 
- **Cel:** Roboty budowlane — 30. dzień od wykonania
- **Warunki:** category_code==CONSTRUCTION AND completion_date!=null
- **Rezultat:** vat_tax_point: 30_days_after_completion
- **Podstawa:** Art. 19a ust. 2 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 115


### 6.8 sc.vat.gtu — Kody GTU (GR-135 do GR-149)


#### GR-116: `sc_vat_gtu_gtu_01_alcohol` 
- **Cel:** Oznaczenie GTU: GTU_01_ALCOHOL
- **Warunki:** category_code IN gtu_GTU_01_ALCOHOL_codes
- **Rezultat:** gtu_code:GTU_01_ALCOHOL
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 116


#### GR-117: `sc_vat_gtu_gtu_02_fuel_oil` 
- **Cel:** Oznaczenie GTU: GTU_02_FUEL_OIL
- **Warunki:** category_code IN gtu_GTU_02_FUEL_OIL_codes
- **Rezultat:** gtu_code:GTU_02_FUEL_OIL
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 117


#### GR-118: `sc_vat_gtu_gtu_03_fuel_gas` 
- **Cel:** Oznaczenie GTU: GTU_03_FUEL_GAS
- **Warunki:** category_code IN gtu_GTU_03_FUEL_GAS_codes
- **Rezultat:** gtu_code:GTU_03_FUEL_GAS
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 118


#### GR-119: `sc_vat_gtu_gtu_04_tobacco` 
- **Cel:** Oznaczenie GTU: GTU_04_TOBACCO
- **Warunki:** category_code IN gtu_GTU_04_TOBACCO_codes
- **Rezultat:** gtu_code:GTU_04_TOBACCO
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 119


#### GR-120: `sc_vat_gtu_gtu_05_waste` 
- **Cel:** Oznaczenie GTU: GTU_05_WASTE
- **Warunki:** category_code IN gtu_GTU_05_WASTE_codes
- **Rezultat:** gtu_code:GTU_05_WASTE
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 120


#### GR-121: `sc_vat_gtu_gtu_06_electronics` 
- **Cel:** Oznaczenie GTU: GTU_06_ELECTRONICS
- **Warunki:** category_code IN gtu_GTU_06_ELECTRONICS_codes
- **Rezultat:** gtu_code:GTU_06_ELECTRONICS
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 121


#### GR-122: `sc_vat_gtu_gtu_07_vehicles` 
- **Cel:** Oznaczenie GTU: GTU_07_VEHICLES
- **Warunki:** category_code IN gtu_GTU_07_VEHICLES_codes
- **Rezultat:** gtu_code:GTU_07_VEHICLES
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 122


#### GR-123: `sc_vat_gtu_gtu_08_metals` 
- **Cel:** Oznaczenie GTU: GTU_08_METALS
- **Warunki:** category_code IN gtu_GTU_08_METALS_codes
- **Rezultat:** gtu_code:GTU_08_METALS
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 123


#### GR-124: `sc_vat_gtu_gtu_09_medicines` 
- **Cel:** Oznaczenie GTU: GTU_09_MEDICINES
- **Warunki:** category_code IN gtu_GTU_09_MEDICINES_codes
- **Rezultat:** gtu_code:GTU_09_MEDICINES
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 124


#### GR-125: `sc_vat_gtu_gtu_10_buildings` 
- **Cel:** Oznaczenie GTU: GTU_10_BUILDINGS
- **Warunki:** category_code IN gtu_GTU_10_BUILDINGS_codes
- **Rezultat:** gtu_code:GTU_10_BUILDINGS
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 125


#### GR-126: `sc_vat_gtu_gtu_11_greenhouse_gas` 
- **Cel:** Oznaczenie GTU: GTU_11_GREENHOUSE_GAS
- **Warunki:** category_code IN gtu_GTU_11_GREENHOUSE_GAS_codes
- **Rezultat:** gtu_code:GTU_11_GREENHOUSE_GAS
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 126


#### GR-127: `sc_vat_gtu_gtu_12_services_crossborder` 
- **Cel:** Oznaczenie GTU: GTU_12_SERVICES_CROSSBORDER
- **Warunki:** category_code IN gtu_GTU_12_SERVICES_CROSSBORDER_codes
- **Rezultat:** gtu_code:GTU_12_SERVICES_CROSSBORDER
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 127


#### GR-128: `sc_vat_gtu_gtu_13_financial` 
- **Cel:** Oznaczenie GTU: GTU_13_FINANCIAL
- **Warunki:** category_code IN gtu_GTU_13_FINANCIAL_codes
- **Rezultat:** gtu_code:GTU_13_FINANCIAL
- **Podstawa:** Rozp. MF JPK_VAT, zał. do struktury JPK
- **Obszary:** VAT,PIT
- **Priorytet:** 128


### 6.9 sc.vat.ksef+jpk — KSeF i JPK (GR-150 do GR-169)


#### GR-129: `sc_ksef_invoice_send` 
- **Cel:** Wysłanie faktury do KSeF — obowiązek
- **Warunki:** today>=2026-02-01 AND direction==SALE AND vendor.is_business AND is_ksef_sent==false
- **Rezultat:** deny:KSEF_NOT_SENT
- **Podstawa:** Ustawa KSeF 2023
- **Obszary:** VAT,PIT
- **Priorytet:** 129


#### GR-130: `sc_ksef_receive` 
- **Cel:** Odbieranie faktur z KSeF
- **Warunki:** direction==PURCHASE AND vendor.uses_ksef
- **Rezultat:** ksef_receipt_confirmation:true
- **Podstawa:** Ustawa KSeF 2023
- **Obszary:** VAT,PIT
- **Priorytet:** 130


#### GR-131: `sc_ksef_offline_mode` 
- **Cel:** KSeF offline — awaria systemu
- **Warunki:** ksef_system_unavailable AND force_majeure
- **Rezultat:** offline_invoice_allowed:true, upload_within_7_days
- **Podstawa:** Ustawa KSeF 2023
- **Obszary:** VAT,PIT
- **Priorytet:** 131


#### GR-132: `sc_jpk_v7m_monthly` 
- **Cel:** JPK_V7M — deklaracja miesięczna
- **Warunki:** partnership.is_vat_payer AND month_end
- **Rezultat:** jpk_filing_required:true, deadline:25th
- **Podstawa:** Art. 99 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 132


#### GR-133: `sc_jpk_v7k_quarterly` 
- **Cel:** JPK_V7K — deklaracja kwartalna
- **Warunki:** partnership.is_vat_payer AND partnership.vat_filing==QUARTERLY AND quarter_end
- **Rezultat:** jpk_filing_required:true, deadline:25th_after_quarter
- **Podstawa:** Art. 99 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 133


#### GR-134: `sc_jpk_deadline_v7m` 
- **Cel:** Termin JPK_V7M — 25. dnia
- **Warunki:** jpk_v7m_required AND today > 25th
- **Rezultat:** jpk_overdue:true
- **Podstawa:** Art. 99 ust. 1 VAT
- **Obszary:** VAT,PIT
- **Priorytet:** 134


#### GR-135: `sc_jpk_correction` 
- **Cel:** Korekta JPK — błędy w deklaracji
- **Warunki:** jpk_submitted AND error_detected
- **Rezultat:** jpk_correction_required:true, file:JPK_V7K_KOREKTA
- **Podstawa:** Art. 81 OP
- **Obszary:** VAT,PIT
- **Priorytet:** 135

### 6.11 sc.pit.partners — Podział Proporcjonalny ★★★ (GR-170 do GR-209)

> **Fundament systemu.** Art. 8 PIT: przychody i koszty spółki dzielone proporcjonalnie do udziałów wspólników.


#### GR-170: `sc_pit_partner_profit_split_proportional` 
- **Cel:** ★★★ Podział przychodu spółki proporcjonalnie do udziałów
- **Warunki:** partnership.total_revenue > 0 AND partner.share_percent > 0
- **Rezultat:** partner.revenue_share: total_revenue * share_percent/100
- **Podstawa:** Art. 8 ust. 1 PIT
- **Zależności:** przed GR-325 KUP
- **Brzegowe:** Udział w zyskach ≠ udział w stratach (umowa może przewidywać inny podział)
- **Obszary:** PIT
- **Priorytet:** 170


#### GR-171: `sc_pit_partner_cost_split_proportional` 
- **Cel:** ★★★ Podział kosztów spółki proporcjonalnie do udziałów
- **Warunki:** partnership.total_costs > 0 AND partner.share_percent > 0
- **Rezultat:** partner.cost_share: total_costs * share_percent/100
- **Podstawa:** Art. 8 ust. 1 PIT
- **Zależności:** po GR-325
- **Brzegowe:** Koszty NKUP są wyłączane PRZED podziałem
- **Obszary:** PIT
- **Priorytet:** 171


#### GR-172: `sc_pit_partner_share_percent_must_sum_100` 
- **Cel:** ★★ Suma udziałów wszystkich wspólników musi wynosić 100%
- **Warunki:** sum(partners[].share_percent) != 100
- **Rezultat:** deny:SHARE_PERCENT_SUM_INVALID
- **Podstawa:** Art. 867 KC
- **Zależności:** przed GR-170
- **Obszary:** PIT,Odpowiedzialność
- **Priorytet:** 172


#### GR-173: `sc_pit_partner_asymmetric_profit_split` 
- **Cel:** ★ Asymetryczny podział zysku — umowa SC może przewidywać inny podział
- **Warunki:** partnership.profit_split_ratio != partnership.share_split_ratio
- **Rezultat:** pit_split_ratio: profit_split_ratio
- **Podstawa:** Art. 867 § 2 KC, Art. 8 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 173


#### GR-174: `sc_pit_partner_revenue_recognition_cash` 
- **Cel:** Moment powstania przychodu — metoda kasowa
- **Warunki:** partner.tax_form==LUMP_SUM AND is_paid
- **Rezultat:** revenue_date: payment_date
- **Podstawa:** Art. 14 ust. 1c PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 174


#### GR-175: `sc_pit_partner_revenue_recognition_accrual` 
- **Cel:** Moment powstania przychodu — metoda memoriałowa
- **Warunki:** partner.tax_form IN [PIT_SCALE,LINEAR] AND delivery_completed
- **Rezultat:** revenue_date: delivery_date
- **Podstawa:** Art. 14 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 175


#### GR-176: `sc_pit_partner_revenue_recognition_advance` 
- **Cel:** Zaliczka = przychód w momencie otrzymania
- **Warunki:** advance_received AND delivery_not_completed
- **Rezultat:** revenue_date: advance_received_date, revenue_amount: advance_amount
- **Podstawa:** Art. 14 ust. 3 pkt 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 176


#### GR-177: `sc_pit_partner_cost_deductibility_timing` 
- **Cel:** KUP w momencie poniesienia
- **Warunki:** partner.tax_form IN [PIT_SCALE,LINEAR] AND cost_incurred AND documented
- **Rezultat:** kup_date: cost_date
- **Podstawa:** Art. 22 ust. 4-6b PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 177


#### GR-178: `sc_pit_partner_loss_carry_forward` 
- **Cel:** Strata podatkowa — odliczenie w 5 kolejnych latach
- **Warunki:** partner.annual_income < 0 AND prior_year_losses > 0
- **Rezultat:** loss_deduction_current_year: min(50%_current_income, remaining_loss)
- **Podstawa:** Art. 9 ust. 3 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 178


#### GR-179: `sc_pit_partner_loss_5y_limit` 
- **Cel:** Limit 5 lat na odliczenie straty
- **Warunki:** loss_year < current_year - 5
- **Rezultat:** loss_expired:true, remaining_loss:0
- **Podstawa:** Art. 9 ust. 3 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 179


### 6.12 sc.pit.forms — Formy Opodatkowania (GR-210 do GR-254)


#### GR-180: `sc_pit_form_scale_12pct` 
- **Cel:** Skala podatkowa — próg 12% do 120 000 PLN
- **Warunki:** partner.tax_form==PIT_SCALE AND partner.annual_income <= 120000
- **Rezultat:** tax_rate:0.12, tax_free_amount:30000
- **Podstawa:** Art. 27 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 180


#### GR-181: `sc_pit_form_scale_32pct` 
- **Cel:** Skala podatkowa — próg 32% powyżej 120 000 PLN
- **Warunki:** partner.tax_form==PIT_SCALE AND partner.annual_income > 120000
- **Rezultat:** tax: 10800 + 0.32*(income-120000), tax_free_amount_phased_out
- **Podstawa:** Art. 27 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 181


#### GR-182: `sc_pit_form_linear_19pct` 
- **Cel:** Podatek liniowy 19%
- **Warunki:** partner.tax_form==LINEAR
- **Rezultat:** tax_rate:0.19, no_tax_free_amount, no_joint_filing
- **Podstawa:** Art. 30c PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 182


#### GR-183: `sc_pit_form_lump_sum_general` 
- **Cel:** Ryczałt ewidencjonowany — stawki 2%-17%
- **Warunki:** partner.tax_form==LUMP_SUM AND revenue_from_sc > 0
- **Rezultat:** tax: revenue * lump_sum_rate(pkwiu_code)
- **Podstawa:** Art. 12 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 183


#### GR-184: `sc_pit_form_lump_sum_2m_eur_limit` 
- **Cel:** ★★ Limit 2M EUR dla ryczałtu — dotyczy przychodu SPÓŁKI
- **Warunki:** any_partner_on_lump_sum AND partnership.revenue_annual_eur > 2000000
- **Rezultat:** lump_sum_right_lost:true, all_partners_to_scale_from_next_year
- **Podstawa:** Art. 6 ust. 4 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 184


#### GR-185: `sc_pit_form_lump_sum_excluded_activities` 
- **Cel:** Działalności wykluczone z ryczałtu
- **Warunki:** partner.tax_form==LUMP_SUM AND category_code IN [PHARMACY,CAR_PARTS,CURRENCY_EXCHANGE]
- **Rezultat:** lump_sum_right_lost:true, form_change:OBLIGATORY_TO_SCALE
- **Podstawa:** Art. 8 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 185


#### GR-186: `sc_pit_form_tax_card_conditions` 
- **Cel:** Karta podatkowa — warunki stosowania
- **Warunki:** partner.tax_form==TAX_CARD AND employee_count<5 AND no_related_services
- **Rezultat:** tax: fixed_amount_from_decision
- **Podstawa:** Art. 25 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 186


#### GR-187: `sc_pit_form_ip_box_5pct` 
- **Cel:** IP Box — 5% stawka dla dochodów z kwalifikowanych IP
- **Warunki:** partner.tax_form==IP_BOX AND income_from_qualified_ip > 0
- **Rezultat:** tax_rate:0.05, separate_calculation:true
- **Podstawa:** Art. 30ca PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 187


#### GR-188: `sc_pit_form_ip_box_nexus` 
- **Cel:** IP Box — wskaźnik nexus (koszty kwalifikowane/całkowite)
- **Warunki:** partner.tax_form==IP_BOX AND rnd_costs > 0
- **Rezultat:** nexus_ratio: qualified_costs * 1.3 / total_costs
- **Podstawa:** Art. 30ca ust. 4 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 188


#### GR-189: `sc_pit_form_different_forms_per_partner` 
- **Cel:** ★★ Różne formy PIT dla różnych wspólników SC — DOZWOLONE
- **Warunki:** partner_a.tax_form != partner_b.tax_form
- **Rezultat:** different_forms_allowed:true
- **Podstawa:** Art. 8 PIT, Art. 9a PIT
- **Brzegowe:** Skutek: różna składka zdrowotna dla każdego wspólnika
- **Obszary:** VAT,PIT
- **Priorytet:** 189


#### GR-190: `sc_pit_form_change_obligatory` 
- **Cel:** Utrata prawa do ryczałtu → przymusowa skala
- **Warunki:** partner.lump_sum_lost AND partner.form_change_date != null
- **Rezultat:** new_tax_form:PIT_SCALE, effective_from:next_month
- **Podstawa:** Art. 22 ust. 1 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 190


#### GR-191: `sc_pit_form_change_deadline` 
- **Cel:** Termin oświadczenia o zmianie formy — do 20. dnia miesiąca
- **Warunki:** partner.form_change_voluntary AND today > 20th_of_month_after_change
- **Rezultat:** form_change_invalid:true, old_form_continues
- **Podstawa:** Art. 9a ust. 4 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 191


#### GR-192: `sc_pit_form_change_two_returns` 
- **Cel:** Zmiana formy mid-year → dwa zeznania roczne
- **Warunki:** partner.form_changed_mid_year
- **Rezultat:** two_returns_required:true
- **Podstawa:** Art. 45 PIT, Art. 21 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 192


### 6.13 sc.pit.kup — KUP per Wspólnik (GR-255 do GR-294)


#### GR-193: `sc_pit_kup_general_rule` 
- **Cel:** ★★ KUP: wydatek poniesiony w celu osiągnięcia przychodu
- **Warunki:** expense_related_to_revenue AND documented AND actually_incurred
- **Rezultat:** kup_qualification:FULL
- **Podstawa:** Art. 22 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 193


#### GR-194: `sc_pit_kup_not_documented` 
- **Cel:** Brak dokumentacji → NKUP
- **Warunki:** has_invoice==false AND has_other_proof==false
- **Rezultat:** kup_qualification:NOT_KUP
- **Podstawa:** Art. 22 ust. 1 PIT
- **Brzegowe:** Wyjątek: wydatki udokumentowane dowodem wewnętrznym do 500 PLN
- **Obszary:** VAT,PIT
- **Priorytet:** 194


#### GR-195: `sc_pit_kup_zus_social_partner` 
- **Cel:** Składki ZUS społeczne wspólnika → KUP
- **Warunki:** partner.zus_social_paid > 0
- **Rezultat:** kup_zus_deduction: partner.zus_social_paid
- **Podstawa:** Art. 26 ust. 1 pkt 2 PIT
- **Brzegowe:** Składki wspólnika NIE są kosztem spółki — odlicza każdy wspólnik indywidualnie
- **Obszary:** VAT,PIT
- **Priorytet:** 195


#### GR-196: `sc_pit_kup_car_insurance` 
- **Cel:** Ubezpieczenie AC/OC samochodu firmowego → KUP
- **Warunki:** category_code==VEHICLE_INSURANCE AND vehicle_used_in_business
- **Rezultat:** kup:FULL
- **Podstawa:** Art. 22 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 196


#### GR-197: `sc_pit_kup_car_operating_cost_limit` 
- **Cel:** Limit 150k PLN amortyzacji samochodu osobowego
- **Warunki:** vehicle_value > 150000 AND vehicle_type==PASSENGER_CAR AND category_code==DEPRECIATION
- **Rezultat:** kup_depreciation_capped: 150000/vehicle_value * depreciation
- **Podstawa:** Art. 23 ust. 1 pkt 4 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 197


#### GR-198: `sc_pit_kup_representation_nkup` 
- **Cel:** Reprezentacja i reklama nietypowa → NKUP
- **Warunki:** category_code IN [REPRESENTATION,HOSPITALITY_ALCOHOL]
- **Rezultat:** kup_qualification:NOT_KUP
- **Podstawa:** Art. 23 ust. 1 pkt 23 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 198


#### GR-199: `sc_pit_kup_donations_nkup` 
- **Cel:** Darowizny → NKUP (odliczane od dochodu, nie od przychodu)
- **Warunki:** category_code==DONATION AND donation_to_non_opp
- **Rezultat:** kup_qualification:NOT_KUP, relief_possible:true
- **Podstawa:** Art. 23 ust. 1 pkt 11 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 199


#### GR-200: `sc_pit_kup_fines_nkup` 
- **Cel:** Kary i grzywny → NKUP
- **Warunki:** category_code IN [PENALTY,FINE,KKS_PENALTY]
- **Rezultat:** kup_qualification:NOT_KUP
- **Podstawa:** Art. 23 ust. 1 pkt 16 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 200


#### GR-201: `sc_pit_kup_cash_over_15k_nkup` 
- **Cel:** Płatność gotówkowa >15k PLN B2B → NKUP
- **Warunki:** is_cash_payment AND amount_gross > 15000 AND vendor.is_business
- **Rezultat:** kup_qualification:NOT_KUP
- **Podstawa:** Art. 22p PIT, Art. 19 PP
- **Obszary:** VAT,PIT
- **Priorytet:** 201


#### GR-202: `sc_pit_kup_private_use_exclusion` 
- **Cel:** Prywatny użytek składnika majątku → NKUP proporcjonalnie
- **Warunki:** private_use_percent > 0
- **Rezultat:** kup_percent: 100 - private_use_percent
- **Podstawa:** Art. 23 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 202


#### GR-203: `sc_pit_kup_leasing_operational` 
- **Cel:** Leasing operacyjny — raty KUP
- **Warunki:** category_code==LEASING_OPERATIONAL AND lease_meets_conditions
- **Rezultat:** kup:FULL
- **Podstawa:** Art. 23b PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 203


#### GR-204: `sc_pit_kup_leasing_finance` 
- **Cel:** Leasing finansowy — tylko odsetki + amortyzacja KUP
- **Warunki:** category_code==LEASING_FINANCE
- **Rezultat:** kup_interest: interest_portion, kup_depreciation: depreciation, principal:NKUP
- **Podstawa:** Art. 23f PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 204


#### GR-205: `sc_pit_kup_borrowing_cost_limit` 
- **Cel:** Limit kosztów finansowania dłużnego — 3M PLN lub 30% EBITDA
- **Warunki:** category_code==INTEREST AND debt_financing_cost > 3000000
- **Rezultat:** excess_interest_nkup: max(0, cost - max(3000000, 0.3*EBITDA))
- **Podstawa:** Art. 15c CIT (odpowiednio PIT)
- **Obszary:** VAT,PIT
- **Priorytet:** 205


### 6.14 sc.pit.advances — Zaliczki (GR-295 do GR-314)


#### GR-206: `sc_pit_advance_monthly_scale` 
- **Cel:** Zaliczka miesięczna — skala podatkowa
- **Warunki:** partner.tax_form==PIT_SCALE AND month_end
- **Rezultat:** advance: (cumulative_income - cumulative_kup - zus_social) * 0.12 - tax_free_monthly - previous_advances
- **Podstawa:** Art. 44 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 206


#### GR-207: `sc_pit_advance_simplified` 
- **Cel:** Zaliczka uproszczona — 1/12 dochodu z poprzedniego roku
- **Warunki:** partner.advance_method==SIMPLIFIED
- **Rezultat:** advance: last_year_tax / 12
- **Podstawa:** Art. 44 ust. 6b PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 207


#### GR-208: `sc_pit_advance_linear` 
- **Cel:** Zaliczka liniowa 19%
- **Warunki:** partner.tax_form==LINEAR AND month_end
- **Rezultat:** advance: (cumulative_income - cumulative_kup - zus_social) * 0.19 - previous_advances
- **Podstawa:** Art. 44 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 208


#### GR-209: `sc_pit_advance_lump_sum` 
- **Cel:** Ryczałt — płatność do 20. dnia miesiąca
- **Warunki:** partner.tax_form==LUMP_SUM AND month_end
- **Rezultat:** lump_sum_due: revenue * rate, deadline:20th
- **Podstawa:** Art. 21 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 209


#### GR-210: `sc_pit_advance_quarterly_lump_sum` 
- **Cel:** Ryczałt kwartalny — opcja dla małych podatników
- **Warunki:** partner.tax_form==LUMP_SUM AND partnership.revenue_annual_eur < 200000
- **Rezultat:** lump_sum_filing:QUARTERLY, deadline:20th_after_quarter
- **Podstawa:** Art. 21 ust. 1b ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 210


#### GR-211: `sc_pit_advance_deadline_20th` 
- **Cel:** Termin wpłaty zaliczki — 20. dnia miesiąca
- **Warunki:** advance_due AND today > 20th
- **Rezultat:** advance_overdue:true
- **Podstawa:** Art. 44 ust. 6 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 211


#### GR-212: `sc_pit_advance_zero_if_loss` 
- **Cel:** Zaliczka = 0 gdy strata narastająco
- **Warunki:** cumulative_income - cumulative_kup <= 0
- **Rezultat:** advance:0
- **Podstawa:** Art. 44 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 212


### 6.15 sc.pit.returns — Zeznania Roczne (GR-315 do GR-329)


#### GR-213: `sc_pit_return_pit36` 
- **Cel:** PIT-36 — zeznanie roczne dla skali podatkowej
- **Warunki:** partner.tax_form==PIT_SCALE AND year_end
- **Rezultat:** form:PIT-36, deadline:April_30
- **Podstawa:** Art. 45 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 213


#### GR-214: `sc_pit_return_pit36l` 
- **Cel:** PIT-36L — zeznanie roczne dla podatku liniowego
- **Warunki:** partner.tax_form==LINEAR AND year_end
- **Rezultat:** form:PIT-36L, deadline:April_30
- **Podstawa:** Art. 45 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 214


#### GR-215: `sc_pit_return_pit28` 
- **Cel:** PIT-28 — zeznanie roczne dla ryczałtu
- **Warunki:** partner.tax_form==LUMP_SUM AND year_end
- **Rezultat:** form:PIT-28, deadline:end_of_february
- **Podstawa:** Art. 21 ustawy o ryczałcie
- **Obszary:** VAT,PIT
- **Priorytet:** 215


#### GR-216: `sc_pit_return_joint_filing` 
- **Cel:** Wspólne rozliczenie małżonków
- **Warunki:** partner.tax_form==PIT_SCALE AND partner.marital_status==MARRIED AND partner.filing_jointly
- **Rezultat:** joint_tax: (income_a+income_b)/2 * 2 * 0.12
- **Podstawa:** Art. 6 ust. 2 PIT
- **Brzegowe:** Tylko dla skali, nie dla liniowego/ryczałtu
- **Obszary:** VAT,PIT
- **Priorytet:** 216


#### GR-217: `sc_pit_return_single_parent` 
- **Cel:** Rozliczenie jako osoba samotnie wychowująca dziecko
- **Warunki:** partner.is_single_parent AND partner.has_dependent_child
- **Rezultat:** tax_calculation: 2 * tax_on(income/2)
- **Podstawa:** Art. 6 ust. 4 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 217


#### GR-218: `sc_pit_return_1pct_charity` 
- **Cel:** 1% podatku na OPP
- **Warunki:** partner.designated_opp_krs != null
- **Rezultat:** 1pct_transfer: tax_due * 0.01
- **Podstawa:** Art. 45c PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 218


#### GR-219: `sc_pit_return_deadline_april30` 
- **Cel:** Termin złożenia zeznania — 30 kwietnia
- **Warunki:** year_end AND today > 2027-04-30 AND pit_return_submitted==false
- **Rezultat:** return_overdue:true
- **Podstawa:** Art. 45 ust. 1 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 219


#### GR-220: `sc_pit_return_correction` 
- **Cel:** Korekta zeznania rocznego
- **Warunki:** pit_return_submitted AND error_detected AND audit_in_progress==false
- **Rezultat:** correction_possible:true, use_same_form
- **Podstawa:** Art. 81 OP
- **Obszary:** VAT,PIT
- **Priorytet:** 220


### 6.16 sc.pit.exemptions — Zwolnienia PIT (GR-330 do GR-349)


#### GR-221: `sc_pit_exempt_young_under_26` 
- **Cel:** Zwolnienie dla młodych do 26 r.ż. — limit 85 528 PLN
- **Warunki:** partner.age <= 26 AND partner.annual_income <= 85528
- **Rezultat:** exempt_amount: income, remaining_limit: 85528 - income
- **Podstawa:** Art. 21 ust. 1 pkt 148 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 221


#### GR-222: `sc_pit_exempt_return_from_abroad` 
- **Cel:** Ulga na powrót — 4 lata zwolnienia po powrocie z emigracji
- **Warunki:** partner.returned_from_abroad AND years_since_return <= 4 AND partner.annual_income <= 85528
- **Rezultat:** exempt_amount: income
- **Podstawa:** Art. 21 ust. 1 pkt 152 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 222


#### GR-223: `sc_pit_exempt_family_4plus` 
- **Cel:** Zwolnienie dla rodzin 4+ — limit 85 528 PLN na rodzica
- **Warunki:** partner.children_count >= 4 AND partner.annual_income <= 85528
- **Rezultat:** exempt_amount: income
- **Podstawa:** Art. 21 ust. 1 pkt 153 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 223


#### GR-224: `sc_pit_exempt_working_senior` 
- **Cel:** Zwolnienie dla pracujących emerytów
- **Warunki:** partner.age >= 65m_60f AND partner.annual_income <= 85528 AND partner.not_receiving_pension_before
- **Rezultat:** exempt_amount: income
- **Podstawa:** Art. 21 ust. 1 pkt 154 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 224


#### GR-225: `sc_pit_exempt_child_benefit` 
- **Cel:** Świadczenie 500+/800+ — zwolnione z PIT
- **Warunki:** category_code==CHILD_BENEFIT
- **Rezultat:** taxable:false
- **Podstawa:** Art. 21 ust. 1 pkt 8b PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 225


#### GR-226: `sc_pit_exempt_social_assistance` 
- **Cel:** Zasiłki z pomocy społecznej — zwolnione z PIT
- **Warunki:** category_code==SOCIAL_ASSISTANCE
- **Rezultat:** taxable:false
- **Podstawa:** Art. 21 ust. 1 pkt 79 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 226


#### GR-227: `sc_pit_relief_child` 
- **Cel:** Ulga na dziecko — 1 112,04 PLN/1e, 2 224,08 PLN/2e, 4 448,16 PLN/3e, 2 668,92 PLN/4e+
- **Warunki:** partner.has_children AND partner.annual_income < 112000 (single) or 56000 (married)
- **Rezultat:** child_relief: applicable_amount * children_count
- **Podstawa:** Art. 27f PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 227


#### GR-228: `sc_pit_relief_termomodernization` 
- **Cel:** Ulga termomodernizacyjna — limit 53 000 PLN
- **Warunki:** category_code==THERMOMODERNIZATION AND building_is_residential AND partner.is_owner
- **Rezultat:** relief_amount: min(costs, 53000)
- **Podstawa:** Art. 26h PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 228


#### GR-229: `sc_pit_relief_rd` 
- **Cel:** Ulga B+R — odliczenie 100% kosztów kwalifikowanych
- **Warunki:** category_code==RND AND costs_qualify
- **Rezultat:** rd_deduction: qualified_costs * 1.0
- **Podstawa:** Art. 26e PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 229


#### GR-230: `sc_pit_relief_rd_200pct` 
- **Cel:** Ulga B+R — 200% dla centrów badawczo-rozwojowych
- **Warunki:** partnership.is_rnd_center AND category_code==RND
- **Rezultat:** rd_deduction: qualified_costs * 2.0
- **Podstawa:** Art. 26e ust. 7 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 230


#### GR-231: `sc_pit_relief_prototype` 
- **Cel:** Ulga na prototyp — 30% kosztów
- **Warunki:** category_code==PROTOTYPE AND costs_qualified
- **Rezultat:** prototype_deduction: costs * 0.30, carry_forward:6y
- **Podstawa:** Art. 26eb PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 231


#### GR-232: `sc_pit_relief_robotization` 
- **Cel:** Ulga na robotyzację — 50% kosztów
- **Warunki:** category_code==ROBOTICS AND asset_is_new
- **Rezultat:** robotization_deduction: costs * 0.50
- **Podstawa:** Art. 26gb PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 232


#### GR-233: `sc_pit_relief_expansion` 
- **Cel:** Ulga na ekspansję — koszty targów i promocji za granicą
- **Warunki:** category_code IN [TRADE_FAIR,EXPORT_PROMOTION] AND vendor.country!=PL
- **Rezultat:** expansion_deduction: costs, max_1m_pln
- **Podstawa:** Art. 26ec PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 233


#### GR-234: `sc_pit_relief_rehabilitation` 
- **Cel:** Ulga rehabilitacyjna
- **Warunki:** partner.has_disability_certificate AND category_code IN [REHAB,MEDICAL_ADAPTATION]
- **Rezultat:** rehabilitation_deduction: actual_costs
- **Podstawa:** Art. 26 ust. 1 pkt 6 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 234


#### GR-235: `sc_pit_relief_ikze` 
- **Cel:** Odliczenie IKZE — limit 9 370 PLN
- **Warunki:** category_code==IKZE_CONTRIBUTION AND amount <= 9370
- **Rezultat:** ikze_deduction: amount
- **Podstawa:** Art. 26 ust. 1 pkt 2b PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 235


#### GR-236: `sc_pit_relief_donation` 
- **Cel:** Darowizny na OPP — odliczenie do 6% dochodu
- **Warunki:** category_code==DONATION_OPP AND amount <= 0.06 * income
- **Rezultat:** donation_deduction: amount
- **Podstawa:** Art. 26 ust. 1 pkt 9 PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 236


#### GR-237: `sc_pit_relief_internet` 
- **Cel:** Ulga internetowa — do 760 PLN, max 2 lata
- **Warunki:** category_code==INTERNET AND partner.internet_relief_years < 2
- **Rezultat:** internet_deduction: min(760, costs)
- **Podstawa:** Art. 26 ust. 1 pkt 6a PIT
- **Obszary:** VAT,PIT
- **Priorytet:** 237


### 6.18 sc.zus.social — Składki Społeczne per Wspólnik (GR-380 do GR-404)


#### GR-238: `sc_zus_partner_standard_base` 
- **Cel:** ★★ Podstawa wymiaru składek społecznych: 60% przeciętnego wynagrodzenia
- **Warunki:** partner.zus_status==STANDARD
- **Rezultat:** zus_base: 0.60 * average_wage, zus_social: base * 0.3194
- **Podstawa:** Art. 18 ust. 8 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 238


#### GR-239: `sc_zus_ulga_na_start_6m` 
- **Cel:** Ulga na start — 6 mies. bez składek społecznych
- **Warunki:** partner.zus_status==ULGA_NA_START AND months_since_start <= 6
- **Rezultat:** zus_social:0
- **Podstawa:** Art. 18a SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 239


#### GR-240: `sc_zus_maly_zus_plus` 
- **Cel:** Mały ZUS Plus — podstawa od dochodu (max 36 mies.)
- **Warunki:** partner.zus_status==MALY_ZUS_PLUS AND partner.annual_income <= 120000
- **Rezultat:** zus_base: income/12 * 0.50
- **Podstawa:** Art. 18c SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 240


#### GR-241: `sc_zus_sickness_voluntary` 
- **Cel:** ★★ Składka chorobowa DOBROWOLNA dla wspólników SC
- **Warunki:** partner.zus_sickness_opted_in==false
- **Rezultat:** sickness_contribution:0
- **Podstawa:** Art. 11 ust. 2 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 241


#### GR-242: `sc_zus_30x_limit` 
- **Cel:** Limit 30-krotności — zaprzestanie składek emerytalno-rentowych
- **Warunki:** partner.cumulative_zus_base > 234720
- **Rezultat:** emerytalna:0, rentowa:0, pozostałe:normalnie
- **Podstawa:** Art. 19 ust. 1 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 242


#### GR-243: `sc_zus_concurrent_employment` 
- **Cel:** ★★ Zbieg etat+SC — ZUS z etatu, ze SC tylko zdrowotna
- **Warunki:** partner.has_employment_income AND partner.employment_zus_base >= minimum
- **Rezultat:** zus_social_from_sc:0, zus_health_from_sc:income*rate
- **Podstawa:** Art. 9 ust. 2 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 243


#### GR-244: `sc_zus_retirement_concurrent` 
- **Cel:** Zbieg emerytura+SC — składki od SC
- **Warunki:** partner.has_pension AND partner.pension_amount >= minimum
- **Rezultat:** zus_social: standard, zus_health: standard
- **Podstawa:** Art. 9 ust. 4-5 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 244


#### GR-245: `sc_zus_proportional_days` 
- **Cel:** Składki proporcjonalne przy rozpoczęciu/zakończeniu w trakcie miesiąca
- **Warunki:** partner.join_date.day > 1 OR partner.exit_date.day < last_day
- **Rezultat:** zus_base: base * active_days/total_days
- **Podstawa:** Art. 18 ust. 8-9 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 245


#### GR-246: `sc_zus_deadline_20th` 
- **Cel:** Termin opłaty składek ZUS — 20. dnia miesiąca
- **Warunki:** month_end AND today > 20th AND zus_paid==false
- **Rezultat:** zus_overdue:true, interest_accruing
- **Podstawa:** Art. 36 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 246


#### GR-247: `sc_zus_deadline_15th_small` 
- **Cel:** Termin dla małych płatników — 15. dnia
- **Warunki:** partnership.employee_count < 5 AND today > 15th AND zus_paid==false
- **Rezultat:** zus_overdue:true
- **Podstawa:** Art. 36 ust. 2 SUS
- **Obszary:** VAT,PIT
- **Priorytet:** 247


### 6.19 sc.zus.health — Składka Zdrowotna (GR-405 do GR-429)


#### GR-248: `sc_zus_health_scale_9pct` 
- **Cel:** Składka zdrowotna 9% — skala podatkowa
- **Warunki:** partner.tax_form==PIT_SCALE
- **Rezultat:** health_rate:0.09, health_base:annual_income, min_health: 0.09*12*min_wage
- **Podstawa:** Art. 81 ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 248


#### GR-249: `sc_zus_health_linear_4_9pct` 
- **Cel:** Składka zdrowotna 4,9% — podatek liniowy
- **Warunki:** partner.tax_form==LINEAR
- **Rezultat:** health_rate:0.049, health_base:annual_income, min_health: 0.049*12*min_wage
- **Podstawa:** Art. 81 ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 249


#### GR-250: `sc_zus_health_lump_sum_tiers` 
- **Cel:** Składka zdrowotna — ryczałt (3 progi wg przychodu)
- **Warunki:** partner.tax_form==LUMP_SUM
- **Rezultat:** health: tier_based_amount(annual_revenue)
- **Podstawa:** Art. 81 ust. 2e ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 250


#### GR-251: `sc_zus_health_tax_card` 
- **Cel:** Składka zdrowotna — karta podatkowa (9% min. wynagrodzenia)
- **Warunki:** partner.tax_form==TAX_CARD
- **Rezultat:** health: 0.09 * minimum_wage
- **Podstawa:** Art. 81 ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 251


#### GR-252: `sc_zus_health_minimum` 
- **Cel:** Minimalna składka zdrowotna — 9% minimalnego wynagrodzenia
- **Warunki:** partner.health_due < 0.09 * minimum_wage
- **Rezultat:** health_due: 0.09 * minimum_wage
- **Podstawa:** Art. 81 ust. 2b ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 252


#### GR-253: `sc_zus_health_annual_reconciliation` 
- **Cel:** Roczne rozliczenie składki zdrowotnej
- **Warunki:** year_end AND partner.tax_form IN [PIT_SCALE,LINEAR]
- **Rezultat:** health_balance: annual_due - monthly_paid
- **Podstawa:** Art. 81 ust. 2 ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 253


#### GR-254: `sc_zus_health_asset_sale_exclusion` 
- **Cel:** Wyłączenie sprzedaży ŚT z podstawy zdrowotnej
- **Warunki:** category_code==FIXED_ASSET_SALE AND asset_held_over_6y
- **Rezultat:** health_base_excluded: sale_price
- **Podstawa:** Art. 81 ust. 2ca ustawy o świadczeniach
- **Obszary:** VAT,PIT
- **Priorytet:** 254

### 6.17 sc.pit.allowances — Ulgi Podatkowe per Wspólnik (GR-255 do GR-279)
> Ulgi stosowane INDYWIDUALNIE przez kazdego wspolnika od jego czesci dochodu.

#### GR-255: `sc_allowance_rnd_main` 
- **Cel:** Ulga B+R — odliczenie 100% kosztow kwalifikowanych
- **Warunki:** partner.rnd_eligible_costs > 0 AND partner.tax_form != TAX_CARD
- **Rezultat:** rnd_deduction: partner.rnd_eligible_costs * input.thresholds.rnd_deduction_pct
- **Podstawa:** Art. 26e PIT
- **Zależności:** Po GR-170
- **Obszary:** PIT
- **Priorytet:** 255

#### GR-256: `sc_allowance_rnd_200pct_centers` 
- **Cel:** Ulga B+R 200% — status CBR
- **Warunki:** partner.rnd_eligible_costs > 0 AND partner.has_cbr_status == true
- **Rezultat:** rnd_deduction_pct: input.thresholds.rnd_deduction_cbr_pct
- **Podstawa:** Art. 26e ust. 2 PIT
- **Zależności:** Po GR-255
- **Brzegowe:** Centrum Badawczo-Rozwojowe
- **Obszary:** PIT
- **Priorytet:** 256

#### GR-257: `sc_allowance_rnd_cap` 
- **Cel:** Limit odliczenia B+R — max dochod z dzialalnosci
- **Warunki:** partner.total_income * partner.share_pct < partner.rnd_deduction
- **Rezultat:** rnd_deduction_capped: partner.total_income * partner.share_pct; rnd_carryforward_6y: excess
- **Podstawa:** Art. 26e ust. 9 PIT
- **Zależności:** Po GR-255
- **Brzegowe:** Nadwyzka przenoszona 6 lat
- **Obszary:** PIT
- **Priorytet:** 257

#### GR-258: `sc_allowance_prototype` 
- **Cel:** Ulga na prototyp — odliczenie 30% kosztow
- **Warunki:** partner.prototype_costs > 0 AND prototype_is_new_product == true
- **Rezultat:** prototype_deduction: partner.prototype_costs * input.thresholds.prototype_deduction_pct
- **Podstawa:** Art. 26eb PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Prototyp musi byc nowym produktem
- **Obszary:** PIT
- **Priorytet:** 258

#### GR-259: `sc_allowance_prototype_cap` 
- **Cel:** Limit ulgi prototypowej — 10% dochodu
- **Warunki:** partner.prototype_deduction > 0.10 * partner.sc_income
- **Rezultat:** prototype_deduction_capped: 0.10 * partner.sc_income
- **Podstawa:** Art. 26eb ust. 5 PIT
- **Zależności:** Po GR-258
- **Obszary:** PIT
- **Priorytet:** 259

#### GR-260: `sc_allowance_robotization` 
- **Cel:** Ulga na robotyzacje — 50% kosztow
- **Warunki:** partner.robot_costs > 0 AND robot_is_new_acquisition == true
- **Rezultat:** robot_deduction: partner.robot_costs * input.thresholds.robotization_deduction_pct
- **Podstawa:** Art. 26gb PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Tylko nowe roboty przemyslowe
- **Obszary:** PIT
- **Priorytet:** 260

#### GR-261: `sc_allowance_expansion` 
- **Cel:** Ulga na ekspansje — wzrost przychodow
- **Warunki:** partner.expansion_costs > 0 AND partner.revenue_growth_yoy > input.thresholds.expansion_growth_min
- **Rezultat:** expansion_deduction: min(partner.expansion_costs, input.thresholds.expansion_cap)
- **Podstawa:** Art. 26ec PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Wymagany udokumentowany wzrost sprzedazy
- **Obszary:** PIT
- **Priorytet:** 261

#### GR-262: `sc_allowance_expansion_cap` 
- **Cel:** Limit ulgi ekspansyjnej — 1M PLN
- **Warunki:** partner.expansion_deduction > input.thresholds.expansion_cap
- **Rezultat:** expansion_deduction_capped: input.thresholds.expansion_cap
- **Podstawa:** Art. 26ec ust. 4 PIT
- **Zależności:** Po GR-261
- **Brzegowe:** Limit 1 mln PLN rocznie
- **Obszary:** PIT
- **Priorytet:** 262

#### GR-263: `sc_allowance_ip_box` 
- **Cel:** IP Box — 5% stawka od dochodu z IP
- **Warunki:** partner.qualifying_ip_income > 0 AND partner.tax_form == PIT_SCALE
- **Rezultat:** ip_box_rate: 0.05; ip_box_tax: partner.qualifying_ip_income * 0.05
- **Podstawa:** Art. 30ca PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Nexus ratio wymagany
- **Obszary:** PIT
- **Priorytet:** 263

#### GR-264: `sc_allowance_ip_box_nexus` 
- **Cel:** IP Box — wskaznik nexus
- **Warunki:** partner.ip_box_nexus_ratio < 1.0
- **Rezultat:** ip_box_qualified_income: partner.ip_income * partner.ip_box_nexus_ratio
- **Podstawa:** Art. 30ca ust. 4 PIT
- **Zależności:** Po GR-263
- **Brzegowe:** Nexus = (koszty_kwalifikowane * 1.3) / koszty_calkowite
- **Obszary:** PIT
- **Priorytet:** 264

#### GR-265: `sc_allowance_rnd_ipbox_exclusion` 
- **Cel:** B+R a IP Box — wykluczenie podwojnego odliczenia
- **Warunki:** partner.rnd_costs_overlap_with_ip == true
- **Rezultat:** rnd_deduction_excluded_from_ip_income: true
- **Podstawa:** Art. 26e ust. 9a PIT
- **Zależności:** Po GR-255 AND Po GR-263
- **Brzegowe:** Koszty B+R nie moga byc jednoczesnie w IP Box
- **Obszary:** PIT
- **Priorytet:** 265

#### GR-266: `sc_allowance_thermo` 
- **Cel:** Ulga termomodernizacyjna — max 53k PLN
- **Warunki:** partner.thermo_costs > 0 AND partner.owns_building == true
- **Rezultat:** thermo_deduction: min(partner.thermo_costs, input.thresholds.thermo_cap)
- **Podstawa:** Art. 26h PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Limit 53 000 PLN na wspolnika
- **Obszary:** PIT
- **Priorytet:** 266

#### GR-267: `sc_allowance_rehabilitation` 
- **Cel:** Ulga rehabilitacyjna
- **Warunki:** partner.is_disabled == true OR partner.dependent_is_disabled == true
- **Rezultat:** rehab_deduction: sum_of_eligible_rehab_costs
- **Podstawa:** Art. 26 ust. 1 pkt 6 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Bez limitu kwotowego
- **Obszary:** PIT
- **Priorytet:** 267

#### GR-268: `sc_allowance_young` 
- **Cel:** Ulga dla mlodych — zwolnienie do 85 528 PLN
- **Warunki:** partner.age < 26 AND partner.sc_income <= input.thresholds.young_income_limit
- **Rezultat:** young_exemption: partner.sc_income
- **Podstawa:** Art. 21 ust. 1 pkt 148 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Limit 85 528 PLN przychodu rocznie
- **Obszary:** PIT
- **Priorytet:** 268

#### GR-269: `sc_allowance_return` 
- **Cel:** Ulga na powrot — 4 lata zwolnienia
- **Warunki:** partner.returned_to_pl == true AND partner.years_since_return < 4
- **Rezultat:** return_exemption: min(partner.sc_income, input.thresholds.return_income_cap)
- **Podstawa:** Art. 21 ust. 1 pkt 152 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Musi byc rezydentem PL przez ostatnie 3 lata
- **Obszary:** PIT
- **Priorytet:** 269

#### GR-270: `sc_allowance_family_4plus` 
- **Cel:** Ulga dla rodzin 4+ — calkowite zwolnienie z PIT
- **Warunki:** partner.children_count >= 4 AND partner.sc_income <= input.thresholds.family4plus_cap
- **Rezultat:** family4_exemption: partner.sc_income
- **Podstawa:** Art. 21 ust. 1 pkt 153 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Limit 85 528 PLN rocznie
- **Obszary:** PIT
- **Priorytet:** 270

#### GR-271: `sc_allowance_working_senior` 
- **Cel:** Ulga dla pracujacych emerytow
- **Warunki:** partner.age >= input.thresholds.senior_age AND partner.sc_income <= input.thresholds.senior_income_cap
- **Rezultat:** senior_exemption: partner.sc_income
- **Podstawa:** Art. 21 ust. 1 pkt 154 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Nie pobiera emerytury LUB emerytura < limit
- **Obszary:** PIT
- **Priorytet:** 271

#### GR-272: `sc_allowance_ikze` 
- **Cel:** Odliczenie IKZE od dochodu
- **Warunki:** partner.ikze_contributions > 0
- **Rezultat:** ikze_deduction: min(partner.ikze_contributions, input.thresholds.ikze_limit)
- **Podstawa:** Art. 26 ust. 1 pkt 2b PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Limit roczny wedlug ogloszenia MF
- **Obszary:** PIT
- **Priorytet:** 272

#### GR-273: `sc_allowance_donations` 
- **Cel:** Odliczenie darowizn — max 6% dochodu
- **Warunki:** partner.charitable_donations > 0
- **Rezultat:** donation_deduction: min(partner.charitable_donations, 0.06 * partner.sc_income)
- **Podstawa:** Art. 26 ust. 1 pkt 9 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Limit 6% dochodu
- **Obszary:** PIT
- **Priorytet:** 273

#### GR-274: `sc_allowance_internet` 
- **Cel:** Ulga internetowa
- **Warunki:** partner.internet_costs > 0 AND partner.claimed_internet_years < 2
- **Rezultat:** internet_deduction: min(partner.internet_costs, input.thresholds.internet_cap)
- **Podstawa:** Art. 26 ust. 1 pkt 6a PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Tylko 2 kolejne lata
- **Obszary:** PIT
- **Priorytet:** 274

#### GR-275: `sc_allowance_loss_carryforward` 
- **Cel:** Odliczenie straty z lat ubieglych
- **Warunki:** partner.loss_carryforward > 0
- **Rezultat:** loss_deduction: min(partner.loss_carryforward * input.thresholds.loss_deduction_pct, partner.sc_income)
- **Podstawa:** Art. 9 ust. 3 PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Max 50% straty w jednym roku, max 5 lat
- **Obszary:** PIT
- **Priorytet:** 275

#### GR-276: `sc_allowance_total_cap` 
- **Cel:** Suma ulg nie przekracza dochodu
- **Warunki:** sum_of_all_allowances > partner.sc_income
- **Rezultat:** allowances_capped: partner.sc_income
- **Podstawa:** Art. 26 ust. 1 PIT
- **Zależności:** Po wszystkich ulgach
- **Brzegowe:** Ulgi nie moga stworzyc straty
- **Obszary:** PIT
- **Priorytet:** 276

### 6.18 sc.zus.social — Skladki Spoleczne — Kontynuacja (GR-280 do GR-304)

#### GR-277: `sc_zus_social_base_calc` 
- **Cel:** Podstawa wymiaru — 60% przecietnego wynagrodzenia
- **Warunki:** partner.zus_status == STANDARD
- **Rezultat:** zus_base: input.thresholds.zus_base_pct * input.thresholds.average_wage
- **Podstawa:** Art. 18 ust. 8 SUS
- **Zależności:** Po GR-170
- **Brzegowe:** 60% przecietnego wynagrodzenia
- **Obszary:** ZUS
- **Priorytet:** 277

#### GR-278: `sc_zus_pension_rate` 
- **Cel:** Skladka emerytalna — 19.52%
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_pension: zus_base * input.thresholds.zus_pension_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Obszary:** ZUS
- **Priorytet:** 278

#### GR-279: `sc_zus_disability_rate` 
- **Cel:** Skladka rentowa — 8%
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_disability: zus_base * input.thresholds.zus_disability_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Obszary:** ZUS
- **Priorytet:** 279

#### GR-280: `sc_zus_sickness_voluntary` 
- **Cel:** Skladka chorobowa — 2.45% (dobrowolna)
- **Warunki:** partner.zus_sickness_opted == true
- **Rezultat:** zus_sickness: zus_base * input.thresholds.zus_sickness_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Brzegowe:** Dobrowolna dla SC
- **Obszary:** ZUS
- **Priorytet:** 280

#### GR-281: `sc_zus_accident_rate` 
- **Cel:** Skladka wypadkowa — zmienna wg PKD
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_accident: zus_base * input.thresholds.zus_accident_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Brzegowe:** Stawka zalezna od PKD
- **Obszary:** ZUS
- **Priorytet:** 281

#### GR-282: `sc_zus_labor_fund` 
- **Cel:** Fundusz Pracy — 2.45%
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_labor_fund: zus_base * input.thresholds.zus_labor_fund_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Obszary:** ZUS
- **Priorytet:** 282

#### GR-283: `sc_zus_solidarity_fund` 
- **Cel:** Fundusz Solidarnosciowy — 0.001%
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_solidarity_fund: zus_base * input.thresholds.zus_solidarity_rate
- **Podstawa:** Art. 22 ust. 1 SUS
- **Zależności:** Po GR-280
- **Obszary:** ZUS
- **Priorytet:** 283

#### GR-284: `sc_zus_total_social` 
- **Cel:** Suma skladek spolecznych
- **Warunki:** partner.zus_obligatory == true
- **Rezultat:** zus_total: sum_of_all_social_components
- **Podstawa:** Art. 22 SUS
- **Zależności:** Po GR-281 do GR-287
- **Obszary:** ZUS
- **Priorytet:** 284

#### GR-285: `sc_zus_start_relief` 
- **Cel:** Ulga na start — 6 m-cy bez skladek spolecznych
- **Warunki:** partner.business_months <= 6 AND partner.previous_business_gap >= 60
- **Rezultat:** zus_social_due: 0.00; zus_health_due: minimum
- **Podstawa:** Art. 18a PP
- **Zależności:** Po GR-280
- **Brzegowe:** Tylko skladka zdrowotna
- **Obszary:** ZUS
- **Priorytet:** 285

#### GR-286: `sc_zus_small_zus_plus` 
- **Cel:** Maly ZUS Plus — obnizona podstawa
- **Warunki:** partner.zus_status == SMALL_ZUS_PLUS AND partner.annual_revenue <= input.thresholds.small_zus_cap
- **Rezultat:** zus_base: partner.annual_revenue / 365 * input.thresholds.small_zus_daily_pct
- **Podstawa:** Art. 18c PP
- **Zależności:** Po GR-280
- **Brzegowe:** Max 36 miesiecy w ciagu 60
- **Obszary:** ZUS
- **Priorytet:** 286

#### GR-287: `sc_zus_30x_limit` 
- **Cel:** Limit 30-krotnosci podstawy rocznej
- **Warunki:** partner.cumulative_annual_zus_base > input.thresholds.zus_30x_limit
- **Rezultat:** zus_pension_suspended: true; zus_disability_suspended: true
- **Podstawa:** Art. 19 ust. 1 SUS
- **Zależności:** Po GR-281
- **Brzegowe:** Po przekroczeniu skladki ER i RE ustaja
- **Obszary:** ZUS
- **Priorytet:** 287

#### GR-288: `sc_zus_dual_employment` 
- **Cel:** Zbieg tytulow — etat + SC
- **Warunki:** partner.has_employment == true AND partner.employment_zus_base >= input.thresholds.zus_min_base
- **Rezultat:** zus_base_sc: max(0, zus_base - employment_zus_base)
- **Podstawa:** Art. 9 ust. 2a SUS
- **Zależności:** Po GR-280
- **Brzegowe:** Skladki tylko od SC jesli etat pokrywa minimum
- **Obszary:** ZUS
- **Priorytet:** 288

#### GR-289: `sc_zus_deadline_10th` 
- **Cel:** Standardowy termin platnosci ZUS — 10. dnia
- **Warunki:** partner.zus_payment_mode == STANDARD
- **Rezultat:** zus_deadline: 10th_of_next_month
- **Podstawa:** Art. 47 ust. 1 pkt 2 SUS
- **Zależności:** Po GR-288
- **Obszary:** ZUS
- **Priorytet:** 289

#### GR-290: `sc_zus_deadline_weekend` 
- **Cel:** Przesuniecie terminu na dzien roboczy
- **Warunki:** is_weekend(zus_deadline) OR is_holiday(zus_deadline)
- **Rezultat:** zus_deadline: next_business_day(zus_deadline)
- **Podstawa:** Art. 12 par. 5 OP
- **Zależności:** Po GR-302
- **Obszary:** ZUS
- **Priorytet:** 290

#### GR-291: `sc_zus_non_registered_activity_guard` 
- **Cel:** Strażnik — dzialalnosc nieewidencjonowana NIE dla SC
- **Warunki:** partner.business_type == UNREGISTERED
- **Rezultat:** _deny: true; _warning: Dzialalnosc nieewidencjonowana niedostepna dla spolki cywilnej
- **Podstawa:** Art. 5 PP
- **Zależności:** Przed wszystkimi ZUS
- **Brzegowe:** SC wymaga umowy pisemnej — nie moze byc nieewidencjonowana
- **Obszary:** ZUS
- **Priorytet:** 291

### 6.20 sc.accounting.full — Pelna Ksiegowosc (GR-305 do GR-339)
> Obowiazek po przekroczeniu 2 mln EUR przez SPOLKE jako calosc.

#### GR-292: `sc_acct_full_threshold_check` 
- **Cel:** ★★★ Prog 2 mln EUR dla spolki
- **Warunki:** partnership.prev_year_revenue_eur > input.thresholds.full_accounting_eur_limit
- **Rezultat:** accounting_method: FULL_ACCOUNTING
- **Podstawa:** Art. 24a ust. 4 PIT
- **Zależności:** Przed wszystkimi regulami ksiegowymi
- **Brzegowe:** Przychod CALEJ spolki
- **Obszary:** ACCOUNTING
- **Priorytet:** 292

#### GR-293: `sc_acct_full_currency` 
- **Cel:** Przeliczenie EUR po kursie NBP z 30.09
- **Warunki:** partnership.prev_year_pln / nbp_eur_sep30 > input.thresholds.full_accounting_eur_limit
- **Rezultat:** accounting_method: FULL_ACCOUNTING
- **Podstawa:** Art. 24a ust. 4 PIT
- **Zależności:** Po GR-305
- **Brzegowe:** Kurs NBP z 30 wrzesnia
- **Obszary:** ACCOUNTING
- **Priorytet:** 293

#### GR-294: `sc_acct_full_transition` 
- **Cel:** Przejscie od 1 stycznia nastepnego roku
- **Warunki:** prev_year_revenue_exceeded == true
- **Rezultat:** full_accounting_from: january_1_next_year
- **Podstawa:** Art. 24a ust. 4 PIT
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 294

#### GR-295: `sc_acct_full_coa` 
- **Cel:** Obowiazkowy plan kont
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** chart_of_accounts: MANDATORY
- **Podstawa:** Art. 10 ust. 1 UoR
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 295

#### GR-296: `sc_acct_full_journal` 
- **Cel:** Dziennik — zapis chronologiczny
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** journal_required: true; chronological: true
- **Podstawa:** Art. 14 ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Bez luk
- **Obszary:** ACCOUNTING
- **Priorytet:** 296

#### GR-297: `sc_acct_full_ledger` 
- **Cel:** Ksiega glowna — podwojny zapis
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** general_ledger: MANDATORY; double_entry: true
- **Podstawa:** Art. 15 ust. 1 UoR
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 297

#### GR-298: `sc_acct_full_subsidiary` 
- **Cel:** Ksiegi pomocnicze
- **Warunki:** accounting_method == FULL_ACCOUNTING AND partnership.has_analytics == true
- **Rezultat:** subsidiary_ledgers: MANDATORY
- **Podstawa:** Art. 16 ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Kontrahenci, ST, rozrachunki
- **Obszary:** ACCOUNTING
- **Priorytet:** 298

#### GR-299: `sc_acct_full_balance_sheet` 
- **Cel:** Bilans roczny
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** balance_sheet: MANDATORY; balance_date: dec_31
- **Podstawa:** Art. 45 ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Aktywa = Pasywa
- **Obszary:** ACCOUNTING
- **Priorytet:** 299

#### GR-300: `sc_acct_full_pl` 
- **Cel:** Rachunek zyskow i strat
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** pl_statement: MANDATORY
- **Podstawa:** Art. 47 ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Wariant porownawczy/kalkulacyjny
- **Obszary:** ACCOUNTING
- **Priorytet:** 300

#### GR-301: `sc_acct_full_cash_flow` 
- **Cel:** Przeplywy pieniezne
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** cash_flow: MANDATORY
- **Podstawa:** Art. 48b ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Metoda posrednia
- **Obszary:** ACCOUNTING
- **Priorytet:** 301

#### GR-302: `sc_acct_full_notes` 
- **Cel:** Informacja dodatkowa
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** notes: MANDATORY
- **Podstawa:** Art. 48 ust. 1 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Polityka rachunkowosci
- **Obszary:** ACCOUNTING
- **Priorytet:** 302

#### GR-303: `sc_acct_full_inventory` 
- **Cel:** Inwentaryzacja
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** inventory: MANDATORY; frequency: thresholds
- **Podstawa:** Art. 26 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Co 2-4 lata
- **Obszary:** ACCOUNTING
- **Priorytet:** 303

#### GR-304: `sc_acct_full_valuation` 
- **Cel:** Wycena — wartosc godziwa / koszt historyczny
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** valuation_method: input.thresholds.valuation; impairment: true
- **Podstawa:** Art. 28 UoR
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 304

#### GR-305: `sc_acct_full_closing` 
- **Cel:** Zamkniecie roku — do 31 marca
- **Warunki:** accounting_method == FULL_ACCOUNTING AND year_end
- **Rezultat:** closing_deadline: march_31
- **Podstawa:** Art. 52 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** 3 miesiace od dnia bilansowego
- **Obszary:** ACCOUNTING
- **Priorytet:** 305

#### GR-306: `sc_acct_full_depreciation` 
- **Cel:** Amortyzacja bilansowa
- **Warunki:** accounting_method == FULL_ACCOUNTING AND fixed_assets > 0
- **Rezultat:** depreciation_schedule: MANDATORY
- **Podstawa:** Art. 32 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Stawki bilansowe
- **Obszary:** ACCOUNTING
- **Priorytet:** 306

#### GR-307: `sc_acct_full_accruals` 
- **Cel:** RMK czynne i bierne
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** accruals: both_active_and_passive
- **Podstawa:** Art. 39 UoR
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 307

#### GR-308: `sc_acct_full_deferred_tax` 
- **Cel:** Podatek odroczony
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** deferred_tax: MANDATORY
- **Podstawa:** Art. 37 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Aktywa i rezerwy
- **Obszary:** ACCOUNTING
- **Priorytet:** 308

#### GR-309: `sc_acct_full_audit` 
- **Cel:** ★★ Obowiazek badania
- **Warunki:** accounting_method == FULL_ACCOUNTING AND prev_year_2of3_criteria_met
- **Rezultat:** audit_required: true
- **Podstawa:** Art. 64 UoR
- **Zależności:** Po GR-305
- **Brzegowe:** Spolka jako calosc
- **Obszary:** ACCOUNTING
- **Priorytet:** 309

#### GR-310: `sc_acct_full_kpir_transition` 
- **Cel:** Przejscie PKPiR -> pelna
- **Warunki:** prev_year_method == PKPIR AND current_year == FULL
- **Rezultat:** opening_balance: MANDATORY; inventory: MANDATORY
- **Podstawa:** Art. 24a ust. 5 PIT
- **Zależności:** Po GR-307
- **Brzegowe:** Spis z natury na dzien przejscia
- **Obszary:** ACCOUNTING
- **Priorytet:** 310

### 6.21 sc.accounting.pkpir — PKPiR (GR-340 do GR-354)

#### GR-311: `sc_pkpir_mandatory_columns` 
- **Cel:** 17 kolumn PKPiR
- **Warunki:** accounting_method == PKPIR
- **Rezultat:** pkpir_17_columns: MANDATORY
- **Podstawa:** par. 9 rozp. PKPiR
- **Zależności:** Po GR-305
- **Obszary:** ACCOUNTING
- **Priorytet:** 311

#### GR-312: `sc_pkpir_chronology` 
- **Cel:** Zapis chronologiczny bez luk
- **Warunki:** accounting_method == PKPIR
- **Rezultat:** chronological: true; no_gaps: true
- **Podstawa:** par. 9 ust. 1 rozp. PKPiR
- **Zależności:** Po GR-340
- **Obszary:** ACCOUNTING
- **Priorytet:** 312

#### GR-313: `sc_pkpir_one_per_year` 
- **Cel:** Jedna PKPiR rocznie
- **Warunki:** accounting_method == PKPIR
- **Rezultat:** pkpir_per_year: 1
- **Podstawa:** par. 8 rozp. PKPiR
- **Zależności:** Po GR-340
- **Brzegowe:** Mozna elektronicznie
- **Obszary:** ACCOUNTING
- **Priorytet:** 313

#### GR-314: `sc_pkpir_error_correction` 
- **Cel:** Korekta bledow
- **Warunki:** pkpir_error AND accounting_method == PKPIR
- **Rezultat:** correction: storno_red OR storno_black
- **Podstawa:** par. 10 rozp. PKPiR
- **Zależności:** Po GR-340
- **Brzegowe:** Opis przyczyny
- **Obszary:** ACCOUNTING
- **Priorytet:** 314

#### GR-315: `sc_pkpir_revenue_columns` 
- **Cel:** Kolumny przychodow 7-9
- **Warunki:** has_revenue AND accounting_method == PKPIR
- **Rezultat:** columns: SPRZEDAZ_TOWAROW, SPRZEDAZ_USLUG, POZOSTALE
- **Podstawa:** par. 9 ust. 1 pkt 6-8 rozp. PKPiR
- **Zależności:** Po GR-340
- **Obszary:** ACCOUNTING
- **Priorytet:** 315

#### GR-316: `sc_pkpir_cost_columns` 
- **Cel:** Kolumny kosztow 10-14
- **Warunki:** has_cost AND accounting_method == PKPIR
- **Rezultat:** columns: UBOCZNE, WYNAGRODZENIA, POZOSTALE
- **Podstawa:** par. 9 ust. 1 pkt 9-14 rozp. PKPiR
- **Zależności:** Po GR-340
- **Obszary:** ACCOUNTING
- **Priorytet:** 316

#### GR-317: `sc_pkpir_monthly_summary` 
- **Cel:** Podsumowanie miesieczne
- **Warunki:** month_end AND accounting_method == PKPIR
- **Rezultat:** monthly: revenue_sum, cost_sum, income
- **Podstawa:** par. 20 rozp. PKPiR
- **Zależności:** Po GR-342
- **Obszary:** ACCOUNTING
- **Priorytet:** 317

#### GR-318: `sc_pkpir_annual_close` 
- **Cel:** Zamkniecie roczne
- **Warunki:** year_end AND accounting_method == PKPIR
- **Rezultat:** annual: total_revenue - total_costs
- **Podstawa:** par. 21 rozp. PKPiR
- **Zależności:** Po GR-347
- **Brzegowe:** Podstawa PIT wspolnikow
- **Obszary:** ACCOUNTING
- **Priorytet:** 318

#### GR-319: `sc_pkpir_storage` 
- **Cel:** Przechowywanie 5 lat
- **Warunki:** accounting_method == PKPIR
- **Rezultat:** storage: 5_years
- **Podstawa:** Art. 70 par. 1 OP
- **Zależności:** Po GR-340
- **Obszary:** ACCOUNTING
- **Priorytet:** 319

### 6.22 sc.accounting.vat_register — Ewidencja VAT + Amortyzacja (GR-355 do GR-369)

#### GR-320: `sc_vat_register_sales` 
- **Cel:** Rejestr sprzedazy VAT
- **Warunki:** partnership.is_vat_taxpayer == true
- **Rezultat:** vat_sales_register: MANDATORY; columns: 10+ fields
- **Podstawa:** Art. 109 ust. 3 VAT
- **Zależności:** Po GR-150
- **Brzegowe:** JPK_V7
- **Obszary:** VAT
- **Priorytet:** 320

#### GR-321: `sc_vat_register_purchases` 
- **Cel:** Rejestr zakupow VAT
- **Warunki:** partnership.is_vat_taxpayer == true
- **Rezultat:** vat_purchases_register: MANDATORY
- **Podstawa:** Art. 109 ust. 3 VAT
- **Zależności:** Po GR-355
- **Brzegowe:** JPK_V7
- **Obszary:** VAT
- **Priorytet:** 321

#### GR-322: `sc_vat_register_deadline` 
- **Cel:** Termin ewidencji — do 25. dnia
- **Warunki:** vat_entry_date > 25th_of_next_month
- **Rezultat:** _warning: VAT_ENTRY_OVERDUE
- **Podstawa:** Art. 109 ust. 3 VAT
- **Zależności:** Po GR-355
- **Obszary:** VAT
- **Priorytet:** 322

#### GR-323: `sc_depreciation_tax_methods` 
- **Cel:** Metody amortyzacji podatkowej
- **Warunki:** fixed_asset_count > 0
- **Rezultat:** depreciation_methods: LINEAR, DEGRESSIVE, ONE_TIME
- **Podstawa:** Art. 22a-22o PIT
- **Zależności:** Po GR-305
- **Brzegowe:** Stawki z zalacznika
- **Obszary:** PIT
- **Priorytet:** 323

#### GR-324: `sc_depreciation_rate_check` 
- **Cel:** Stawki amortyzacji — zgodne z wykazem
- **Warunki:** depreciation_rate NOT IN allowed_rates
- **Rezultat:** _error: INVALID_DEPRECIATION_RATE
- **Podstawa:** Zalacznik do ustawy PIT
- **Zależności:** Po GR-358
- **Obszary:** PIT
- **Priorytet:** 324

#### GR-325: `sc_depreciation_low_value` 
- **Cel:** Jednorazowa amortyzacja do 10k PLN
- **Warunki:** asset_value <= input.thresholds.low_value_asset_limit
- **Rezultat:** depreciation: ONE_TIME_FULL
- **Podstawa:** Art. 22d ust. 1 PIT
- **Zależności:** Po GR-358
- **Brzegowe:** Limit 10 000 PLN
- **Obszary:** PIT
- **Priorytet:** 325

#### GR-326: `sc_depreciation_used_asset` 
- **Cel:** Amortyzacja srodka uzywanego — stawka indywidualna
- **Warunki:** asset_is_used == true AND asset_first_time_in_company == true
- **Rezultat:** depreciation: INDIVIDUAL_RATE; min_period: 36_months
- **Podstawa:** Art. 22j PIT
- **Zależności:** Po GR-358
- **Brzegowe:** Min 36 m-cy dla budynkow 120 m-cy
- **Obszary:** PIT
- **Priorytet:** 326

#### GR-327: `sc_depreciation_car_limit` 
- **Cel:** Limit amortyzacji samochodu — 150k/225k PLN
- **Warunki:** asset_type == CAR AND asset_value > input.thresholds.car_depreciation_limit
- **Rezultat:** depreciation_base_capped: car_limit
- **Podstawa:** Art. 23 ust. 1 pkt 4 PIT
- **Zależności:** Po GR-358
- **Brzegowe:** 150k spalinowy / 225k elektryczny
- **Obszary:** PIT
- **Priorytet:** 327

#### GR-328: `sc_depreciation_intangible` 
- **Cel:** Amortyzacja WNiP — min 60 miesiecy
- **Warunki:** asset_type == INTANGIBLE
- **Rezultat:** depreciation_period: min_60_months
- **Podstawa:** Art. 22m PIT
- **Zależności:** Po GR-358
- **Obszary:** PIT
- **Priorytet:** 328

#### GR-329: `sc_depreciation_improvement` 
- **Cel:** Ulepszenie ST > 10k PLN — zwieksza wartosc
- **Warunki:** improvement_value > input.thresholds.improvement_limit
- **Rezultat:** asset_value_increased: improvement_value
- **Podstawa:** Art. 22g ust. 17 PIT
- **Zależności:** Po GR-358
- **Brzegowe:** Limit 10 000 PLN
- **Obszary:** PIT
- **Priorytet:** 329

### 6.23 sc.partnership.formation — Powstanie i Walidacja Spolki (GR-330 do GR-349)
> Art. 860-865 KC — umowa spolki, wklady, reprezentacja.

#### GR-330: `sc_formation_contract_written` 
- **Cel:** ★★ Umowa spolki cywilnej wymaga formy pisemnej dla celow dowodowych
- **Warunki:** partnership.formation_document == VERBAL
- **Rezultat:** _deny: true; _warning: Umowa SC powinna byc na pismie — art. 860 KC
- **Podstawa:** Art. 860 par. 1 KC
- **Zależności:** Przed wszystkimi
- **Brzegowe:** Forma pisemna ad probationem — nie ad solemnitatem
- **Obszary:** PARTNERSHIP
- **Priorytet:** 330

#### GR-331: `sc_formation_min_partners` 
- **Cel:** Minimalna liczba wspolnikow — 2
- **Warunki:** count(partners) < 2
- **Rezultat:** _deny: true; _error: MIN_PARTNERS_VIOLATION
- **Podstawa:** Art. 860 par. 1 KC
- **Zależności:** Przed GR-330
- **Obszary:** PARTNERSHIP
- **Priorytet:** 331

#### GR-332: `sc_formation_contributions` 
- **Cel:** Kazdy wspolnik wnosi wklad
- **Warunki:** partner.contribution_value <= 0
- **Rezultat:** _warning: NO_CONTRIBUTION_DECLARED
- **Podstawa:** Art. 861 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Wkladem moze byc rowniez praca/uslugi
- **Obszary:** PARTNERSHIP
- **Priorytet:** 332

#### GR-333: `sc_formation_contributions_valuation` 
- **Cel:** Wycena wkladow niepienieznych
- **Warunki:** partner.contribution_type == IN_KIND AND partner.contribution_valuation == MISSING
- **Rezultat:** _warning: IN_KIND_CONTRIBUTION_NOT_VALUED
- **Podstawa:** Art. 861 par. 2 KC
- **Zależności:** Po GR-332
- **Brzegowe:** Domniemanie rownosci wkladow
- **Obszary:** PARTNERSHIP
- **Priorytet:** 333

#### GR-334: `sc_formation_common_goal` 
- **Cel:** Wspolny cel gospodarczy
- **Warunki:** partnership.business_purpose == UNDEFINED
- **Rezultat:** _warning: BUSINESS_PURPOSE_NOT_DEFINED
- **Podstawa:** Art. 860 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Istota SC — dzialanie dla wspolnego celu
- **Obszary:** PARTNERSHIP
- **Priorytet:** 334

#### GR-335: `sc_formation_registration_ceidg` 
- **Cel:** Kazdy wspolnik rejestruje sie w CEIDG
- **Warunki:** partner.registered_in_ceidg == false
- **Rezultat:** _error: PARTNER_NOT_IN_CEIDG
- **Podstawa:** Art. 5 PP
- **Zależności:** Po GR-330
- **Brzegowe:** Wspolnik SC jest przedsiebiorca — musi byc w CEIDG
- **Obszary:** PARTNERSHIP
- **Priorytet:** 335

#### GR-336: `sc_formation_nip_registration` 
- **Cel:** Spolka rejestruje wlasny NIP (dla VAT)
- **Warunki:** partnership.is_vat_taxpayer == true AND partnership.nip == null
- **Rezultat:** _error: PARTNERSHIP_NIP_MISSING
- **Podstawa:** Art. 2 ustawy o NIP
- **Zależności:** Po GR-150
- **Brzegowe:** SC ma wlasny NIP jako podatnik VAT
- **Obszary:** PARTNERSHIP
- **Priorytet:** 336

#### GR-337: `sc_formation_regon` 
- **Cel:** Spolka uzyskuje REGON
- **Warunki:** partnership.regon == null
- **Rezultat:** _warning: REGON_MISSING
- **Podstawa:** Art. 42 ustawy o statystyce
- **Zależności:** Po GR-330
- **Obszary:** PARTNERSHIP
- **Priorytet:** 337

#### GR-338: `sc_formation_contract_nip_listing` 
- **Cel:** Umowa SC musi zawierac NIP wspolnikow
- **Warunki:** any_partner_nip_missing_in_contract == true
- **Rezultat:** _warning: PARTNER_NIP_MISSING_IN_CONTRACT
- **Podstawa:** Art. 5 PP
- **Zależności:** Po GR-330
- **Obszary:** PARTNERSHIP
- **Priorytet:** 338

#### GR-339: `sc_formation_share_allocation` 
- **Cel:** Okreslenie udzialow w zyskach i stratach
- **Warunki:** sum_of_all_partner_shares != 100
- **Rezultat:** _error: SHARE_SUM_NOT_100
- **Podstawa:** Art. 867 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Domyslnie rowno jesli nie ustalono
- **Obszary:** PARTNERSHIP
- **Priorytet:** 339

#### GR-340: `sc_formation_management_rights` 
- **Cel:** Kazdy wspolnik ma prawo prowadzenia spraw
- **Warunki:** partner.management_excluded == true AND partnership.has_management_agreement == false
- **Rezultat:** _warning: MANAGEMENT_RESTRICTION_WITHOUT_BASIS
- **Podstawa:** Art. 865 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Domyslnie wszyscy prowadza sprawy
- **Obszary:** PARTNERSHIP
- **Priorytet:** 340

#### GR-341: `sc_formation_representation` 
- **Cel:** Reprezentacja spolki — kazdy wspolnik
- **Warunki:** partnership.representation_rules == UNDEFINED
- **Rezultat:** _default: each_partner_represents_separately
- **Podstawa:** Art. 866 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Mozna umownie zmodyfikowac
- **Obszary:** PARTNERSHIP
- **Priorytet:** 341

#### GR-342: `sc_formation_contract_amendments` 
- **Cel:** Zmiana umowy SC
- **Warunki:** contract_amendment_exists AND amendment_agreed_by_all
- **Rezultat:** contract_amendment_valid: ALL_PARTNERS_MUST_AGREE
- **Podstawa:** Art. 860 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Jednomyslnosc do zmian
- **Obszary:** PARTNERSHIP
- **Priorytet:** 342

#### GR-343: `sc_formation_state_of_emergency` 
- **Cel:** SC nie moze byc zawiazana w stanie wyzszej koniecznosci
- **Warunki:** partner.under_duress == true
- **Rezultat:** _deny: true; _error: CONTRACT_UNDER_DURESS
- **Podstawa:** Art. 82 KC
- **Zależności:** Przed GR-330
- **Brzegowe:** Wada oswiadczenia woli
- **Obszary:** PARTNERSHIP
- **Priorytet:** 343

### 6.24 sc.partnership.changes — Zmiany Skladu Wspolnikow (GR-350 do GR-384)
> Art. 869-873 KC — przyjecie, wystapienie, smierc wspolnika. Kazdy scenariusz ma odmienne skutki podatkowe.

#### GR-344: `sc_changes_new_partner_admission` 
- **Cel:** ★★ Przyjecie nowego wspolnika — zmiana umowy
- **Warunki:** new_partner_admission_date != null
- **Rezultat:** contract_amendment_required: true; all_partners_must_agree: true
- **Podstawa:** Art. 869 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Nowy wspolnik odpowiada rowniez za zobowiazania sprzed przystapienia
- **Obszary:** PARTNERSHIP
- **Priorytet:** 344

#### GR-345: `sc_changes_new_partner_liability` 
- **Cel:** ★★★ Nowy wspolnik odpowiada za stare dlugi
- **Warunki:** partner.join_date > partnership.founding_date AND partnership.has_preexisting_debts == true
- **Rezultat:** new_partner_liable_for_preexisting: true
- **Podstawa:** Art. 864 KC
- **Zależności:** Po GR-350
- **Brzegowe:** Solidarna odpowiedzialnosc rowniez za zobowiazania sprzed przystapienia
- **Obszary:** LIABILITY
- **Priorytet:** 345

#### GR-346: `sc_changes_new_partner_share` 
- **Cel:** Udzial nowego wspolnika w zyskach i stratach
- **Warunki:** partner.is_new == true AND partner.share_redefined == false
- **Rezultat:** _default: equal_share_among_all_current_partners
- **Podstawa:** Art. 867 par. 1 KC
- **Zależności:** Po GR-350
- **Brzegowe:** Domniemanie rownosci
- **Obszary:** PARTNERSHIP
- **Priorytet:** 346

#### GR-347: `sc_changes_exit_by_notice` 
- **Cel:** ★★ Wystapienie wspolnika za wypowiedzeniem
- **Warunki:** partner.exit_notice_date != null AND partner.exit_date = exit_notice_date + 3_months
- **Rezultat:** partner_exit_effective: exit_notice_date + 3_months
- **Podstawa:** Art. 869 par. 2 KC
- **Zależności:** Po GR-350
- **Brzegowe:** 3 miesiace okresu wypowiedzenia
- **Obszary:** PARTNERSHIP
- **Priorytet:** 347

#### GR-348: `sc_changes_exit_settlement` 
- **Cel:** ★★ Rozliczenie z wystepujacym wspolnikiem
- **Warunki:** partner.exit_date_passed == true
- **Rezultat:** settlement_required: true; settlement_basis: partner_positive_balance
- **Podstawa:** Art. 871 KC
- **Zależności:** Po GR-353
- **Brzegowe:** Zwrot wkladu + udzial w nadwyzce
- **Obszary:** PARTNERSHIP
- **Priorytet:** 348

#### GR-349: `sc_changes_exit_settlement_in_kind` 
- **Cel:** ★ Wyplata udzialu w naturze — faktura VAT
- **Warunki:** partner.exit_settlement_type == IN_KIND
- **Rezultat:** vat_invoice_required: true; vat_rate: standard_rate_for_asset
- **Podstawa:** Art. 7 VAT, Art. 871 KC
- **Zależności:** Po GR-354
- **Brzegowe:** Odbior srodka trwalego to dostawa towaru
- **Obszary:** VAT,PARTNERSHIP
- **Priorytet:** 349

#### GR-350: `sc_changes_exit_vat_on_settlement` 
- **Cel:** VAT od wyplaty udzialu
- **Warunki:** settlement_amount > 0 AND settlement_involves_assets == true
- **Rezultat:** vat_due: settlement_asset_value * applicable_vat_rate
- **Podstawa:** Art. 5 VAT
- **Zależności:** Po GR-355
- **Obszary:** VAT
- **Priorytet:** 350

#### GR-351: `sc_changes_exit_pit_for_exiting` 
- **Cel:** PIT wystepujacego wspolnika
- **Warunki:** partner.exit_settlement_received > partner.contribution_original_value
- **Rezultat:** pit_taxable: settlement_received - contribution_value
- **Podstawa:** Art. 14 ust. 2 pkt 16 PIT
- **Zależności:** Po GR-354
- **Brzegowe:** Nadwyzka ponad wklad = przychod
- **Obszary:** PIT
- **Priorytet:** 351

#### GR-352: `sc_changes_exit_pit_for_remaining` 
- **Cel:** PIT pozostajacych wspolnikow — zwiekszenie udzialow
- **Warunki:** remaining_partner_share_increase > 0
- **Rezultat:** _no_immediate_tax: share_revaluation_NOT_taxable
- **Podstawa:** Art. 8 PIT
- **Zależności:** Po GR-354
- **Brzegowe:** Zwiekszenie udzialu nie jest zdarzeniem podatkowym
- **Obszary:** PIT
- **Priorytet:** 352

#### GR-353: `sc_changes_exit_liability_after` 
- **Cel:** ★★★ Odpowiedzialnosc po wystapieniu — 3 lata
- **Warunki:** partner.exit_date < now() AND partner.exit_date > now() - 3_years
- **Rezultat:** ex_partner_still_liable: true; liable_for_debts_up_to: exit_date
- **Podstawa:** Art. 864 KC + Art. 118 KC
- **Zależności:** Po GR-354
- **Brzegowe:** Odpowiada za zobowiazania powstale PRZED wystapieniem
- **Obszary:** LIABILITY
- **Priorytet:** 353

#### GR-354: `sc_changes_death_of_partner` 
- **Cel:** ★★★ Smierc wspolnika — skutki
- **Warunki:** partner.death_date != null
- **Rezultat:** partnership_status: TRANSITION; succession_manager_may_be_appointed
- **Podstawa:** Art. 872 KC
- **Zależności:** Po GR-350
- **Brzegowe:** SC nie rozwiazuje sie automatycznie
- **Obszary:** PARTNERSHIP
- **Priorytet:** 354

#### GR-355: `sc_changes_death_contract_clause` 
- **Cel:** Klauzula umowna po smierci wspolnika
- **Warunki:** partner.death_date != null AND contract_has_succession_clause == true
- **Rezultat:** heirs_enter: according_to_contract; OR partnership_dissolves: if_clause_says_so
- **Podstawa:** Art. 872 zd. 2 KC
- **Zależności:** Po GR-360
- **Brzegowe:** Spadkobiercy moga wstapic jesli umowa tak stanowi
- **Obszary:** PARTNERSHIP
- **Priorytet:** 355

#### GR-356: `sc_changes_death_no_clause` 
- **Cel:** Brak klauzuli — SC trwa z pozostalymi
- **Warunki:** partner.death_date != null AND contract_has_succession_clause == false
- **Rezultat:** partnership_continues_with_remaining_partners; heirs_receive_settlement
- **Podstawa:** Art. 872 zd. 1 KC
- **Zależności:** Po GR-360
- **Obszary:** PARTNERSHIP
- **Priorytet:** 356

#### GR-357: `sc_changes_share_transfer` 
- **Cel:** Zbycie udzialu w SC
- **Warunki:** partner.share_transfer_attempt == true
- **Rezultat:** _deny_default: SHARE_TRANSFER_NOT_ALLOWED_WITHOUT_ALL_PARTNERS_CONSENT
- **Podstawa:** Art. 10 KC
- **Zależności:** Po GR-350
- **Brzegowe:** Udzial w SC nie jest zbywalny bez zgody wszystkich
- **Obszary:** PARTNERSHIP
- **Priorytet:** 357

#### GR-358: `sc_changes_partner_exclusion` 
- **Cel:** Wylaczenie wspolnika
- **Warunki:** partner.exclusion_court_ruling == true
- **Rezultat:** partner_excluded: effective_from_ruling_date; settlement: as_standard_exit
- **Podstawa:** Art. 870 KC
- **Zależności:** Po GR-350
- **Brzegowe:** Wylaczenie przez sad na wniosek pozostalych
- **Obszary:** PARTNERSHIP
- **Priorytet:** 358

#### GR-359: `sc_changes_proportional_split_midyear` 
- **Cel:** ★★★ Podzial proporcjonalny przy zmianie udzialow w trakcie roku
- **Warunki:** any_partner.share_changed_midyear == true
- **Rezultat:** pit_split: calculate_per_period_with_different_shares
- **Podstawa:** Art. 8 ust. 1 PIT
- **Zależności:** Po GR-500
- **Brzegowe:** Dzielimy przychody/koszty wg udzialow obowiazujacych w danym okresie
- **Obszary:** PIT
- **Priorytet:** 359

#### GR-360: `sc_changes_midyear_new_partner_tax` 
- **Cel:** Nowy wspolnik w trakcie roku — podzial od daty przystapienia
- **Warunki:** partner.join_date_in_year == true
- **Rezultat:** taxable_from: partner.join_date; share_of_year: days_in_partnership / 365
- **Podstawa:** Art. 8 PIT
- **Zależności:** Po GR-350
- **Brzegowe:** Dochod tylko za okres czlonkostwa
- **Obszary:** PIT
- **Priorytet:** 360

### 6.25 sc.partnership.dissolution — Rozwiazanie i Likwidacja (GR-385 do GR-414)
> Art. 874-875 KC — rozwiazanie spolki, podzial majatku, odpowiedzialnosc po rozwiazaniu.

#### GR-385: `sc_dissolution_all_partners_agree` 
- **Cel:** ★★ Rozwiazanie SC za zgoda wszystkich
- **Warunki:** all_partners.agreed_to_dissolve == true
- **Rezultat:** dissolution_effective: agreement_date
- **Podstawa:** Art. 874 par. 1 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Jednomyslna zgoda
- **Obszary:** PARTNERSHIP
- **Priorytet:** 385

#### GR-386: `sc_dissolution_court_ruling` 
- **Cel:** Rozwiazanie przez sad
- **Warunki:** partnership.court_dissolution_ruling != null
- **Rezultat:** dissolution_effective: ruling_date
- **Podstawa:** Art. 874 par. 2 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Na wniosek wspolnika z waznych powodow
- **Obszary:** PARTNERSHIP
- **Priorytet:** 386

#### GR-387: `sc_dissolution_asset_liquidation` 
- **Cel:** Likwidacja majatku spolki
- **Warunki:** partnership.status == DISSOLVING
- **Rezultat:** liquidation_process: SELL_ASSETS -> COLLECT_RECEIVABLES -> PAY_DEBTS -> DISTRIBUTE_REMAINDER
- **Podstawa:** Art. 875 par. 1 KC
- **Zależności:** Po GR-385
- **Obszary:** PARTNERSHIP
- **Priorytet:** 387

#### GR-388: `sc_dissolution_vat_on_liquidation` 
- **Cel:** ★★ VAT przy likwidacji — sprzedaz majatku
- **Warunki:** dissolution_asset_sale == true
- **Rezultat:** vat_due: sale_price * applicable_vat_rate
- **Podstawa:** Art. 14 ust. 1 VAT
- **Zależności:** Po GR-387
- **Brzegowe:** Sprzedaz majatku = dostawa towarow
- **Obszary:** VAT
- **Priorytet:** 388

#### GR-389: `sc_dissolution_vat_remnant_assets` 
- **Cel:** VAT od pozostalych towarow po likwidacji
- **Warunki:** liquidation_complete AND inventory_remaining_value > 0
- **Rezultat:** vat_due_on_remnant: inventory_value * applicable_rate
- **Podstawa:** Art. 14 ust. 5 VAT
- **Zależności:** Po GR-387
- **Brzegowe:** Towary przekazane wspolnikom = dostawa
- **Obszary:** VAT
- **Priorytet:** 389

#### GR-390: `sc_dissolution_vat_deregistration` 
- **Cel:** Wyrejestrowanie VAT
- **Warunki:** partnership.dissolved == true AND partnership.was_vat_taxpayer == true
- **Rezultat:** vat_deregistration: VAT_Z; deadline: within_7_days_of_dissolution
- **Podstawa:** Art. 96 ust. 6 VAT
- **Zależności:** Po GR-387
- **Obszary:** VAT
- **Priorytet:** 390

#### GR-391: `sc_dissolution_final_vat_return` 
- **Cel:** Ostatnia deklaracja VAT po likwidacji
- **Warunki:** partnership.dissolved == true AND partnership.was_vat_taxpayer == true
- **Rezultat:** final_vat_return: JPK_V7M_for_last_period; deadline: 25th_of_next_month
- **Podstawa:** Art. 99 VAT
- **Zależności:** Po GR-390
- **Obszary:** VAT
- **Priorytet:** 391

#### GR-392: `sc_dissolution_pit_settlement` 
- **Cel:** PIT wspolnikow z likwidacji
- **Warunki:** partner.received_liquidation_share > partner.contribution_value
- **Rezultat:** pit_taxable: liquidation_share_received - contribution_original_value
- **Podstawa:** Art. 14 ust. 2 pkt 16 PIT
- **Zależności:** Po GR-387
- **Brzegowe:** Nadwyzka podlega PIT
- **Obszary:** PIT
- **Priorytet:** 392

#### GR-393: `sc_dissolution_pit_final_return` 
- **Cel:** Ostatnie zeznanie PIT wspolnika
- **Warunki:** partnership.dissolved == true AND partner.has_sc_income == true
- **Rezultat:** final_pit_return: PIT_36 or PIT_36L or PIT_28; deadline: april_30
- **Podstawa:** Art. 45 PIT
- **Zależności:** Po GR-392
- **Obszary:** PIT
- **Priorytet:** 393

#### GR-394: `sc_dissolution_liability_after` 
- **Cel:** ★★★ Odpowiedzialnosc po rozwiazaniu
- **Warunki:** partnership.dissolved == true AND partnership.has_unpaid_debts == true
- **Rezultat:** all_ex_partners_jointly_liable: unlimited
- **Podstawa:** Art. 875 par. 3 KC
- **Zależności:** Po GR-387
- **Brzegowe:** Odpowiedzialnosc solidarna trwa po rozwiazaniu
- **Obszary:** LIABILITY
- **Priorytet:** 394

#### GR-395: `sc_dissolution_kpir_close` 
- **Cel:** Zamkniecie PKPiR przy likwidacji
- **Warunki:** dissolution AND accounting_method == PKPIR
- **Rezultat:** final_pkpir_entry: liquidation_date; spis_z_natury: MANDATORY
- **Podstawa:** par. 27 rozp. PKPiR
- **Zależności:** Po GR-387
- **Brzegowe:** Remament likwidacyjny
- **Obszary:** ACCOUNTING
- **Priorytet:** 395

#### GR-396: `sc_dissolution_full_accounting_close` 
- **Cel:** Zamkniecie pelnej ksiegowosci
- **Warunki:** dissolution AND accounting_method == FULL_ACCOUNTING
- **Rezultat:** liquidation_balance_sheet: MANDATORY; final_pl: MANDATORY
- **Podstawa:** Art. 52 UoR
- **Zależności:** Po GR-387
- **Obszary:** ACCOUNTING
- **Priorytet:** 396

#### GR-397: `sc_dissolution_employee_termination` 
- **Cel:** Rozwiazanie umow z pracownikami
- **Warunki:** partnership.dissolving == true AND partnership.has_employees == true
- **Rezultat:** employee_termination: MANDATORY; severance_pay_may_apply
- **Podstawa:** Art. 30 par. 1 KP
- **Zależności:** Po GR-387
- **Obszary:** EMPLOYER
- **Priorytet:** 397

#### GR-398: `sc_dissolution_archiving` 
- **Cel:** Archiwizacja dokumentow — 5 lat
- **Warunki:** partnership.dissolved == true
- **Rezultat:** document_archiving: 5_years_min; responsible: last_active_partner
- **Podstawa:** Art. 70 par. 1 OP
- **Zależności:** Po GR-387
- **Obszary:** PARTNERSHIP
- **Priorytet:** 398

#### GR-399: `sc_dissolution_single_partner_remaining` 
- **Cel:** ★★ SC z 1 wspolnikiem — rozwiazanie z mocy prawa
- **Warunki:** count(active_partners) == 1
- **Rezultat:** dissolution_by_law: true; grace_period: none_for_SC
- **Podstawa:** Art. 874 par. 3 KC
- **Zależności:** Po GR-330
- **Brzegowe:** SC nie moze istniec z 1 wspolnikiem
- **Obszary:** PARTNERSHIP
- **Priorytet:** 399

### 6.26 sc.partnership.liability — Odpowiedzialnosc Solidarna (GR-415 do GR-459)
> Art. 864 KC — fundament SC. Wspolnicy odpowiadaja solidarnie CALYM swoim majatkiem.

#### GR-400: `sc_liability_joint_and_several` 
- **Cel:** ★★★ Odpowiedzialnosc solidarna — art. 864 KC
- **Warunki:** partnership.has_liabilities == true
- **Rezultat:** all_partners_jointly_liable: true; liability_extends_to: PERSONAL_ASSETS
- **Podstawa:** Art. 864 KC
- **Zależności:** Przed wszystkimi regulami odpowiedzialnosci
- **Brzegowe:** Bez ograniczenia — caly majatek osobisty
- **Obszary:** LIABILITY
- **Priorytet:** 400

#### GR-401: `sc_liability_unlimited` 
- **Cel:** Odpowiedzialnosc nieograniczona
- **Warunki:** partnership.has_liabilities == true
- **Rezultat:** liability_limit: NONE; personal_assets_under_execution: YES
- **Podstawa:** Art. 864 KC
- **Zależności:** Po GR-415
- **Brzegowe:** Brak gornego limitu odpowiedzialnosci
- **Obszary:** LIABILITY
- **Priorytet:** 401

#### GR-402: `sc_liability_creditor_choice` 
- **Cel:** Wierzyciel moze egzekwowac od dowolnego wspolnika
- **Warunki:** partnership.debt_overdue == true
- **Rezultat:** creditor_right: sue_any_partner_for_full_amount
- **Podstawa:** Art. 366 par. 1 KC
- **Zależności:** Po GR-415
- **Brzegowe:** Solidarnosc bierna
- **Obszary:** LIABILITY
- **Priorytet:** 402

#### GR-403: `sc_liability_regress_among_partners` 
- **Cel:** ★★ Regres miedzy wspolnikami
- **Warunki:** partner_A_paid_more_than_share == true
- **Rezultat:** partner_A_regress_against_others: proportional_to_their_shares
- **Podstawa:** Art. 376 par. 1 KC
- **Zależności:** Po GR-417
- **Brzegowe:** Wspolnik ktory zaplacil calosc moze zadac zwrotu od pozostalych
- **Obszary:** LIABILITY
- **Priorytet:** 403

#### GR-404: `sc_liability_regress_calculation` 
- **Cel:** Obliczenie regresu
- **Warunki:** partner.overpaid_for_debt > 0
- **Rezultat:** regress_from_each: debt * (other_partner.share_pct / 100)
- **Podstawa:** Art. 376 par. 2 KC
- **Zależności:** Po GR-418
- **Brzegowe:** Proporcjonalnie do udzialow w zyskach
- **Obszary:** LIABILITY
- **Priorytet:** 404

#### GR-405: `sc_liability_ex_partner` 
- **Cel:** ★★★ Odpowiedzialnosc bylego wspolnika
- **Warunki:** partner.exit_date < debt_incurred_date AND debt_incurred_date <= current_date
- **Rezultat:** ex_partner_liable: true
- **Podstawa:** Art. 864 KC
- **Zależności:** Po GR-415
- **Brzegowe:** Odpowiada za dlugi powstale PODCZAS czlonkostwa
- **Obszary:** LIABILITY
- **Priorytet:** 405

#### GR-406: `sc_liability_ex_partner_time_limit` 
- **Cel:** Przedawnienie roszczen wobec bylego wspolnika
- **Warunki:** partner.exit_date < debt_incurred_date AND current_date - debt_due_date > statute_of_limitations
- **Rezultat:** ex_partner_liability_expired: true
- **Podstawa:** Art. 118 KC
- **Zależności:** Po GR-420
- **Brzegowe:** Przedawnienie zobowiazan
- **Obszary:** LIABILITY
- **Priorytet:** 406

#### GR-407: `sc_liability_new_partner` 
- **Cel:** ★★★ Odpowiedzialnosc nowego wspolnika za stare dlugi
- **Warunki:** partner.join_date > debt_incurred_date
- **Rezultat:** new_partner_liable: YES — nawet za dlugi sprzed przystapienia
- **Podstawa:** Art. 864 KC
- **Zależności:** Po GR-415
- **Brzegowe:** SC — nowy wspolnik odpowiada za wszystkie istniejace zobowiazania
- **Obszary:** LIABILITY
- **Priorytet:** 407

#### GR-408: `sc_liability_spouse_protection` 
- **Cel:** Ochrona majatku malzonka
- **Warunki:** partner.marital_regime == COMMUNITY AND debt_is_related_to_partnership == true
- **Rezultat:** spouse_may_object: YES; spouse_consent_needed_for_execution: YES
- **Podstawa:** Art. 41 par. 1 KRO
- **Zależności:** Po GR-415
- **Brzegowe:** Wierzyciel potrzebuje zgody malzonka na egzekucje ze wspolnego majatku
- **Obszary:** LIABILITY
- **Priorytet:** 408

#### GR-409: `sc_liability_spouse_separate_property` 
- **Cel:** Rozdzielnosc majatkowa — ochrona
- **Warunki:** partner.marital_regime == SEPARATE_PROPERTY
- **Rezultat:** spouse_assets_protected: FULLY
- **Podstawa:** Art. 51 KRO
- **Zależności:** Po GR-415
- **Obszary:** LIABILITY
- **Priorytet:** 409

#### GR-410: `sc_liability_personal_asset_exclusions` 
- **Cel:** Wylaczenia spod egzekucji
- **Warunki:** execution_against_partner_personal_assets == true
- **Rezultat:** excluded: household_basics, tools_of_trade_up_to_limit, social_benefits
- **Podstawa:** Art. 829-833 KPC
- **Zależności:** Po GR-416
- **Obszary:** LIABILITY
- **Priorytet:** 410

#### GR-411: `sc_liability_vat_liability` 
- **Cel:** Odpowiedzialnosc za zobowiazania VAT spolki
- **Warunki:** partnership.vat_debt > 0
- **Rezultat:** all_partners_liable_for_vat: jointly_and_severally
- **Podstawa:** Art. 15 ust. 1 VAT
- **Zależności:** Po GR-415
- **Brzegowe:** SC jest podatnikiem, ale wspolnicy odpowiadaja
- **Obszary:** VAT,LIABILITY
- **Priorytet:** 411

#### GR-412: `sc_liability_pit_withholding` 
- **Cel:** Odpowiedzialnosc za PIT od pracownikow
- **Warunki:** partnership.failed_to_withhold_pit == true
- **Rezultat:** all_partners_liable_for_unpaid_withholding: YES
- **Podstawa:** Art. 30 par. 1 OP
- **Zależności:** Po GR-415
- **Brzegowe:** Platnik = SC (reprezentowana przez wspolnikow)
- **Obszary:** LIABILITY,EMPLOYER
- **Priorytet:** 412

#### GR-413: `sc_liability_zus_contributions` 
- **Cel:** Odpowiedzialnosc za skladki ZUS od pracownikow
- **Warunki:** partnership.zus_employee_debt > 0
- **Rezultat:** all_partners_liable: YES
- **Podstawa:** Art. 31 SUS
- **Zależności:** Po GR-415
- **Obszary:** LIABILITY
- **Priorytet:** 413

#### GR-414: `sc_liability_damages_to_third_parties` 
- **Cel:** Odpowiedzielnosc deliktowa
- **Warunki:** partnership.caused_damage_to_third_party == true
- **Rezultat:** all_partners_liable: solidarnie za szkode
- **Podstawa:** Art. 415-420 KC
- **Zależności:** Po GR-415
- **Obszary:** LIABILITY
- **Priorytet:** 414

### 6.27 sc.partnership.succession — Sukcesja i Zarzad Sukcesyjny (GR-460 do GR-484)
> Ustawa o zarzadzie sukcesyjnym — smierc wspolnika, zarzadca, kontynuacja SC.

#### GR-415: `sc_succession_manager_appointment` 
- **Cel:** ★★ Powolanie zarzadcy sukcesyjnego
- **Warunki:** partner.death_date != null AND partner.had_succession_manager_named == true
- **Rezultat:** succession_manager: named_person; manager_powers: LIMITED_TO_BUSINESS
- **Podstawa:** Art. 7-9 ustawy o ZS
- **Zależności:** Po GR-360
- **Brzegowe:** Zarzadce powoluje przedsiebiorca za zycia
- **Obszary:** PARTNERSHIP
- **Priorytet:** 415

#### GR-416: `sc_succession_manager_scope` 
- **Cel:** Zakres uprawnien zarzadcy
- **Warunki:** succession_manager_active == true
- **Rezultat:** manager_can: RUN_BUSINESS, PAY_TAXES, SIGN_INVOICES, MANAGE_EMPLOYEES; manager_cannot: SELL_FIXED_ASSETS, DISSOLVE_PARTNERSHIP
- **Podstawa:** Art. 21-30 ustawy o ZS
- **Zależności:** Po GR-460
- **Obszary:** PARTNERSHIP
- **Priorytet:** 416

#### GR-417: `sc_succession_nip_suffix` 
- **Cel:** NIP z sufiksem po smierci
- **Warunki:** partner.death_date != null AND succession_manager_appointed == true
- **Rezultat:** nip_suffix: .S after_death_date
- **Podstawa:** Art. 12 ustawy o ZS
- **Zależności:** Po GR-460
- **Obszary:** PARTNERSHIP
- **Priorytet:** 417

#### GR-418: `sc_succession_nip_for_inheritance` 
- **Cel:** NIP ogolny spadku
- **Warunki:** partner.death_date != null AND succession_manager_NOT_appointed
- **Rezultat:** nip_suffix: .Z date_of_death
- **Podstawa:** Art. 13 ustawy o ZS
- **Zależności:** Po GR-460
- **Obszary:** PARTNERSHIP
- **Priorytet:** 418

#### GR-419: `sc_succession_manager_duration` 
- **Cel:** Czas trwania zarzadu sukcesyjnego
- **Warunki:** succession_manager_active == true
- **Rezultat:** manager_max_term: 2_years_from_death; extension_possible: up_to_25_years
- **Podstawa:** Art. 59-60 ustawy o ZS
- **Zależności:** Po GR-460
- **Obszary:** PARTNERSHIP
- **Priorytet:** 419

#### GR-420: `sc_succession_manager_vat` 
- **Cel:** VAT w okresie zarzadu sukcesyjnego
- **Warunki:** succession_manager_active == true AND partnership.is_vat_taxpayer == true
- **Rezultat:** vat_obligations_continue: YES; manager_submits_JPK
- **Podstawa:** Art. 15 VAT
- **Zależności:** Po GR-460
- **Obszary:** VAT
- **Priorytet:** 420

#### GR-421: `sc_succession_manager_pit` 
- **Cel:** PIT za zmarlych — role zarzadcy
- **Warunki:** succession_manager_active == true
- **Rezultat:** pit_for_deceased_partner: manager_files_PIT_36; deadline: april_30
- **Podstawa:** Art. 45 PIT, Art. 26 ustawy o ZS
- **Zależności:** Po GR-460
- **Obszary:** PIT
- **Priorytet:** 421

#### GR-422: `sc_succession_heirs_entry` 
- **Cel:** Spadkobiercy wstepuja w prawa zmarlych
- **Warunki:** succession_closed == true AND contract_allows_heirs == true
- **Rezultat:** heirs_become_partners: YES; heirs_share: inherited
- **Podstawa:** Art. 872 KC
- **Zależności:** Po GR-462
- **Obszary:** PARTNERSHIP
- **Priorytet:** 422

#### GR-423: `sc_succession_heirs_not_entering` 
- **Cel:** Spadkobiercy nie chca wstepowac
- **Warunki:** succession_closed == true AND heirs.declined_entry == true
- **Rezultat:** settlement_to_heirs: value_of_inherited_share
- **Podstawa:** Art. 871 KC
- **Zależności:** Po GR-462
- **Obszary:** PARTNERSHIP
- **Priorytet:** 423

#### GR-424: `sc_succession_heirs_minor` 
- **Cel:** Spadkobierca maloletni
- **Warunki:** heir.age < 18
- **Rezultat:** court_approval_required: YES; guardian_must_represent
- **Podstawa:** Art. 101 KRO
- **Zależności:** Po GR-467
- **Obszary:** PARTNERSHIP
- **Priorytet:** 424

### 6.28 sc.partnership.suspension — Zawieszenie i Wznowienie (GR-485 do GR-509)
> Art. 22-25 PP — zawieszenie dzialalnosci przez wspolnikow. Skutki podatkowe i skladkowe.

#### GR-425: `sc_suspension_all_partners` 
- **Cel:** Zawieszenie calej SC
- **Warunki:** all_partners.suspended == true
- **Rezultat:** partnership_operations: FULLY_SUSPENDED
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-330
- **Brzegowe:** Wszyscy wspolnicy musza zawiesic
- **Obszary:** PARTNERSHIP
- **Priorytet:** 425

#### GR-426: `sc_suspension_single_partner_effect` 
- **Cel:** Zawieszenie jednego wspolnika — SC dziala dalej
- **Warunki:** partner.suspended == true AND count(active_partners) >= 2
- **Rezultat:** partnership_continues: YES; suspended_partner: NO_MANAGEMENT_RIGHTS
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-330
- **Brzegowe:** SC dziala jesli >= 2 aktywnych
- **Obszary:** PARTNERSHIP
- **Priorytet:** 426

#### GR-427: `sc_suspension_max_36_months` 
- **Cel:** Max 36 miesiecy zawieszenia w ciagu 60
- **Warunki:** partner.cumulative_suspension_months > 36 AND partner.suspension_in_60months == true
- **Rezultat:** _deny: SUSPENSION_LIMIT_EXCEEDED
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-485
- **Obszary:** PARTNERSHIP
- **Priorytet:** 427

#### GR-428: `sc_suspension_min_full_month` 
- **Cel:** Minimalny okres zawieszenia — pelny miesiac
- **Warunki:** partner.suspension_start_date != 1st_of_month OR partner.suspension_end_date != last_of_month
- **Rezultat:** _error: SUSPENSION_MUST_BE_FULL_MONTHS
- **Podstawa:** powiazane z CEIDG
- **Zależności:** Po GR-485
- **Obszary:** PARTNERSHIP
- **Priorytet:** 428

#### GR-429: `sc_suspension_zus_during` 
- **Cel:** ZUS w trakcie zawieszenia — BRAK skladek spolecznych
- **Warunki:** partner.suspended == true
- **Rezultat:** zus_social_due: 0; zus_health_still_due: YES (minimum)
- **Podstawa:** Art. 22 ust. 7 PP, Art. 18a SUS
- **Zależności:** Po GR-485
- **Brzegowe:** Skladka zdrowotna nadal obowiazkowa
- **Obszary:** ZUS
- **Priorytet:** 429

#### GR-430: `sc_suspension_vat_inactive` 
- **Cel:** VAT w trakcie zawieszenia
- **Warunki:** partnership.fully_suspended == true AND partnership.is_vat_taxpayer == true
- **Rezultat:** vat_returns_may_be_simplified; no_sales_invoices_allowed
- **Podstawa:** Art. 99 VAT
- **Zależności:** Po GR-485
- **Brzegowe:** Zawieszony podatnik nie wystawia faktur
- **Obszary:** VAT
- **Priorytet:** 430

#### GR-431: `sc_suspension_pit_during` 
- **Cel:** PIT wspolnika w trakcie zawieszenia
- **Warunki:** partner.suspended == true
- **Rezultat:** pit_on_income_from_suspended_period: NO_INCOME_SO_NO_ADVANCE
- **Podstawa:** Art. 44 PIT
- **Zależności:** Po GR-485
- **Brzegowe:** Brak dzialalnosci = brak zaliczek
- **Obszary:** PIT
- **Priorytet:** 431

#### GR-432: `sc_suspension_reactivation` 
- **Cel:** Wznowienie dzialalnosci
- **Warunki:** partner.reactivation_date != null
- **Rezultat:** zus_obligations_restart: from_reactivation_date
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-485
- **Obszary:** PARTNERSHIP
- **Priorytet:** 432

#### GR-433: `sc_suspension_ceidg_sync` 
- **Cel:** Zawieszenie/wznowienie przez CEIDG
- **Warunki:** partner.ceidg_status_change == true
- **Rezultat:** suspension_effective: ceidg_change_date
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-485
- **Obszary:** PARTNERSHIP
- **Priorytet:** 433

### 6.29 sc.partnership.representation — Reprezentacja i Pelnomocnictwa (GR-434 do GR-454)
> Art. 866 KC — reprezentacja SC. Pelnomocnictwa podatkowe PPS-1, UPL-1.

#### GR-434: `sc_rep_default_rule` 
- **Cel:** Domyslnie kazdy wspolnik reprezentuje SC
- **Warunki:** partnership.representation_rules == DEFAULT
- **Rezultat:** each_partner_can_act_alone: true; each_partner_can_sign: true
- **Podstawa:** Art. 866 par. 1 KC
- **Zależności:** Po GR-330
- **Obszary:** PARTNERSHIP
- **Priorytet:** 434

#### GR-435: `sc_rep_joint_representation` 
- **Cel:** Reprezentacja laczna — umowa
- **Warunki:** partnership.representation_rules == JOINT
- **Rezultat:** representation_requires: at_least_2_partners; single_partner_cannot_represent: true
- **Podstawa:** Art. 866 par. 2 KC
- **Zależności:** Po GR-330
- **Brzegowe:** Mozna umownie zastrzec
- **Obszary:** PARTNERSHIP
- **Priorytet:** 435

#### GR-436: `sc_rep_management_board` 
- **Cel:** Wydzielony zarzad SC
- **Warunki:** partnership.has_designated_manager == true
- **Rezultat:** manager_represents: with_limits_in_contract; other_partners: NO_REPRESENTATION
- **Podstawa:** Art. 865 par. 2 KC
- **Zależności:** Po GR-330
- **Obszary:** PARTNERSHIP
- **Priorytet:** 436

#### GR-437: `sc_rep_tax_proxy_pps1` 
- **Cel:** Pelnomocnictwo podatkowe PPS-1
- **Warunki:** partnership.tax_proxy_active == true
- **Rezultat:** proxy_powers: FILE_TAX_RETURNS, SIGN_DECLARATIONS, RECEIVE_CORRESPONDENCE; proxy_type: PPS-1
- **Podstawa:** Art. 138a-138z OP
- **Zależności:** Po GR-434
- **Brzegowe:** PPS-1 — pelnomocnictwo ogolne
- **Obszary:** PARTNERSHIP
- **Priorytet:** 437

#### GR-438: `sc_rep_tax_proxy_upl1` 
- **Cel:** Pelnomocnictwo UPL-1 — do doręczen
- **Warunki:** partnership.upl1_proxy_active == true
- **Rezultat:** proxy_powers: RECEIVE_ALL_TAX_CORRESPONDENCE; proxy_type: UPL-1
- **Podstawa:** Art. 138a OP
- **Zależności:** Po GR-434
- **Brzegowe:** UPL-1 — tylko do doręczen
- **Obszary:** PARTNERSHIP
- **Priorytet:** 438

#### GR-439: `sc_rep_proxy_by_non_partner` 
- **Cel:** Pelnomocnik spoza grona wspolnikow
- **Warunki:** tax_proxy_is_non_partner == true
- **Rezultat:** proxy_valid: YES; no_partnership_rights: YES
- **Podstawa:** Art. 137 OP
- **Zależności:** Po GR-437
- **Brzegowe:** Kazdy moze byc pelnomocnikiem
- **Obszary:** PARTNERSHIP
- **Priorytet:** 439

#### GR-440: `sc_rep_proxy_attorney` 
- **Cel:** Pelnomocnictwo dla adwokata/radcy prawnego
- **Warunki:** proxy_is_lawyer == true
- **Rezultat:** automatic_representation: court_proceedings, tax_audits
- **Podstawa:** Art. 138d OP
- **Zależności:** Po GR-437
- **Obszary:** PARTNERSHIP
- **Priorytet:** 440

#### GR-441: `sc_rep_act_ultra_vires` 
- **Cel:** Dzialanie poza zakresem reprezentacji
- **Warunki:** partner_acted_beyond_representation_scope == true
- **Rezultat:** act_may_be_invalid: depends_on_good_faith_of_counterparty
- **Podstawa:** Art. 39 KC
- **Zależności:** Po GR-434
- **Brzegowe:** Przekroczenie zakresu umocowania
- **Obszary:** PARTNERSHIP
- **Priorytet:** 441

#### GR-442: `sc_rep_contractor_protection` 
- **Cel:** Ochrona kontrahenta dzialajacego w dobrej wierze
- **Warunki:** counterparty_knew_no_limits AND partner_purported_to_represent == true
- **Rezultat:** contract_valid: YES
- **Podstawa:** Art. 39 KC + Art. 866 KC
- **Zależności:** Po GR-442
- **Brzegowe:** Ochrona osob trzecich
- **Obszary:** PARTNERSHIP
- **Priorytet:** 442

#### GR-443: `sc_rep_signature_on_invoice` 
- **Cel:** Kto podpisuje faktury SC
- **Warunki:** invoice_needs_signature == true
- **Rezultat:** authorized_signatories: all_partners_or_designated_manager
- **Podstawa:** Art. 106e ust. 1 pkt 6 VAT
- **Zależności:** Po GR-150
- **Obszary:** VAT
- **Priorytet:** 443

### 6.30 sc.employer — Spolka jako Pracodawca (GR-455 do GR-494)
> SC jako platnik PIT i ZUS od wynagrodzen pracownikow. PPK, PFRON.

#### GR-444: `sc_employer_pit_withholding` 
- **Cel:** Pobor zaliczek PIT od wynagrodzen
- **Warunki:** partnership.has_employees == true
- **Rezultat:** pit_advance: 12%_or_32%_of_income; pit_remit_deadline: 20th_of_next_month
- **Podstawa:** Art. 32, 38 PIT
- **Zależności:** Po GR-415
- **Brzegowe:** Platnik = SC
- **Obszary:** EMPLOYER
- **Priorytet:** 444

#### GR-445: `sc_employer_pit4r` 
- **Cel:** Deklaracja PIT-4R — roczna
- **Warunki:** partnership.has_employees == true
- **Rezultat:** pit_4r_deadline: january_31
- **Podstawa:** Art. 42 ust. 1a PIT
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 445

#### GR-446: `sc_employer_pit11` 
- **Cel:** Informacja PIT-11 dla pracownikow
- **Warunki:** partnership.has_employees == true
- **Rezultat:** pit_11_deadline: january_31; distribute_to_employees: yes; send_to_us: yes
- **Podstawa:** Art. 39 ust. 1 PIT
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 446

#### GR-447: `sc_employer_pit_rz` 
- **Cel:** PIT-RZ dla US
- **Warunki:** partnership.has_employees == true
- **Rezultat:** pit_rz_deadline: january_31
- **Podstawa:** Art. 39 ust. 1a PIT
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 447

#### GR-448: `sc_employer_zus_contributions` 
- **Cel:** Skladki ZUS od pracownikow
- **Warunki:** partnership.has_employees == true
- **Rezultat:** zus_employee_part: 13.71%_of_gross; zus_employer_part: ~20%_of_gross
- **Podstawa:** Art. 16-22 SUS
- **Zależności:** Po GR-455
- **Brzegowe:** Platnik = SC
- **Obszary:** EMPLOYER
- **Priorytet:** 448

#### GR-449: `sc_employer_zus_dra` 
- **Cel:** Deklaracja ZUS DRA — miesieczna
- **Warunki:** partnership.has_employees == true
- **Rezultat:** zus_dra_deadline: 15th_of_next_month
- **Podstawa:** Art. 46 SUS
- **Zależności:** Po GR-459
- **Obszary:** EMPLOYER
- **Priorytet:** 449

#### GR-450: `sc_employer_ppk` 
- **Cel:** Pracownicze Plany Kapitalowe
- **Warunki:** partnership.employee_count >= 1
- **Rezultat:** ppk_obligatory: autoenrollment; ppk_employer_contribution: 1.5%_of_salary; ppk_employee_contribution: 2%
- **Podstawa:** Ustawa o PPK
- **Zależności:** Po GR-455
- **Brzegowe:** SC jako pracodawca
- **Obszary:** EMPLOYER
- **Priorytet:** 450

#### GR-451: `sc_employer_ppk_optout` 
- **Cel:** Rezygnacja pracownika z PPK
- **Warunki:** employee.ppk_opted_out == true
- **Rezultat:** ppk_for_this_employee: SUSPENDED; reenrollment_every_4_years: YES
- **Podstawa:** Ustawa o PPK
- **Zależności:** Po GR-461
- **Obszary:** EMPLOYER
- **Priorytet:** 451

#### GR-452: `sc_employer_pfron` 
- **Cel:** PFRON — skladka na osoby niepelnosprawne
- **Warunki:** partnership.employee_count >= 25 AND partnership.disabled_employee_pct < 6
- **Rezultat:** pfron_due: (0.06 * total_employees - disabled_employees) * average_wage
- **Podstawa:** Ustawa o PFRON
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 452

#### GR-453: `sc_employer_pfron_exemption` 
- **Cel:** Zwolnienie z PFRON — status ZPChr
- **Warunki:** partnership.is_zpchr == true AND partnership.disabled_employee_pct >= 30
- **Rezultat:** pfron_due: 0
- **Podstawa:** Ustawa o PFRON
- **Zależności:** Po GR-463
- **Brzegowe:** Zaklad Pracy Chronionej
- **Obszary:** EMPLOYER
- **Priorytet:** 453

#### GR-454: `sc_employer_safety_training` 
- **Cel:** Szkolenia BHP
- **Warunki:** partnership.has_employees == true
- **Rezultat:** initial_safety_training: MANDATORY; periodic_training: every_12_months
- **Podstawa:** Art. 2373 par. 2 KP
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 454

#### GR-455: `sc_employer_work_regulations` 
- **Cel:** Regulamin pracy po 50 pracownikach
- **Warunki:** partnership.employee_count >= 50
- **Rezultat:** work_regulations: MANDATORY
- **Podstawa:** Art. 104 KP
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 455

#### GR-456: `sc_employer_zfss` 
- **Cel:** ZFŚS — Fundusz Socjalny po 50 zatrudnionych
- **Warunki:** partnership.employee_count >= 50
- **Rezultat:** zfss_contributions: MANDATORY; zfss_rate: 37.5%_of_average_wage_per_employee
- **Podstawa:** Ustawa o ZFŚS
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 456

#### GR-457: `sc_employer_remote_work` 
- **Cel:** Praca zdalna — obowiazki BHP
- **Warunki:** employee.work_mode == REMOTE
- **Rezultat:** remote_work_agreement: MANDATORY; bhp_check: EMPLOYEE_SELF_DECLARATION; equipment_ergonomics: EMPLOYER_RESPONSIBILITY
- **Podstawa:** Art. 6728-6732 KP
- **Zależności:** Po GR-455
- **Brzegowe:** Nowe przepisy
- **Obszary:** EMPLOYER
- **Priorytet:** 457

#### GR-458: `sc_employer_remote_compensation` 
- **Cel:** Ekwiwalent za prace zdalna
- **Warunki:** employee.work_mode == REMOTE AND partnership.pays_remote_allowance == true
- **Rezultat:** remote_allowance: input.thresholds.remote_allowance_rate; taxable: NO if_below_limit
- **Podstawa:** Art. 6733 KP
- **Zależności:** Po GR-468
- **Obszary:** EMPLOYER
- **Priorytet:** 458

#### GR-459: `sc_employer_a1_delegation` 
- **Cel:** Delegowanie pracownikow za granice — formularz A1
- **Warunki:** employee.delegated_to_eu == true
- **Rezultat:** a1_form_required: YES; a1_deadline: before_delegation
- **Podstawa:** Art. 12-16 rozporzadzenia 883/2004
- **Zależności:** Po GR-455
- **Obszary:** EMPLOYER
- **Priorytet:** 459

#### GR-460: `sc_employer_employee_capital` 
- **Cel:** Zwrot kosztow uzywania prywatnego samochodu
- **Warunki:** employee.uses_personal_car == true
- **Rezultat:** mileage_reimbursement: rate_per_km * business_km; tax_free_up_to_limit
- **Podstawa:** Rozporzadzenie w sprawie podrozy sluzbowych
- **Zależności:** Po GR-455
- **Obszary:** PIT
- **Priorytet:** 460

### 6.31 sc.sanctions — Kary, Odsetki, Przedawnienia (GR-495 do GR-519)
> Art. 53-70 OP, KKS — odsetki od zaleglosci, kary, przedawnienia.

#### GR-461: `sc_sanctions_late_payment_interest` 
- **Cel:** Odsetki od zaleglosci podatkowych
- **Warunki:** tax_paid_after_deadline == true
- **Rezultat:** interest_rate: lombard_rate * input.thresholds.tax_interest_multiplier; interest_days: days_overdue
- **Podstawa:** Art. 56 OP
- **Zależności:** Po regulach podatkowych
- **Brzegowe:** Stawka odsetek = lombardowa NBP * 2 + 2%
- **Obszary:** SANCTIONS
- **Priorytet:** 461

#### GR-462: `sc_sanctions_late_filing` 
- **Cel:** Kara za nieterminowe zlozenie deklaracji
- **Warunki:** tax_return_filed_late == true
- **Rezultat:** penalty_note: MANDATORY; potential_criminal_tax_proceedings: YES
- **Podstawa:** Art. 56a OP
- **Zależności:** Po GR-455
- **Obszary:** SANCTIONS
- **Priorytet:** 462

#### GR-463: `sc_sanctions_tax_evasion` 
- **Cel:** Kara za uchylanie sie od opodatkowania
- **Warunki:** tax_base_understated_sigificantly == true
- **Rezultat:** penalty_rate: 75%_of_understated_tax
- **Podstawa:** Art. 56d OP
- **Zależności:** Po GR-495
- **Brzegowe:** Stawka sankcyjna 75%
- **Obszary:** SANCTIONS
- **Priorytet:** 463

#### GR-464: `sc_sanctions_no_registration` 
- **Cel:** Kara za brak rejestracji VAT
- **Warunki:** partnership.should_be_vat_registered == true AND partnership.vat_registered == false
- **Rezultat:** vat_penalty: 30%_of_vat_liability; criminal_charges_possible
- **Podstawa:** Art. 112 KKS
- **Zależności:** Po GR-150
- **Obszary:** SANCTIONS
- **Priorytet:** 464

#### GR-465: `sc_sanctions_fake_invoice` 
- **Cel:** Kara za falszywa fakture
- **Warunki:** invoice_deemed_fraudulent == true
- **Rezultat:** vat_penalty: 100%_of_vat_on_fake_invoice; criminal_prosecution: YES
- **Podstawa:** Art. 108a VAT, Art. 62 KKS
- **Zależności:** Po GR-0
- **Obszary:** SANCTIONS
- **Priorytet:** 465

#### GR-466: `sc_sanctions_statute_of_limitations_tax` 
- **Cel:** Przedawnienie zobowiazan podatkowych — 5 lat
- **Warunki:** tax_year + 5_years < current_year
- **Rezultat:** tax_obligation_expired: true; no_enforcement_possible
- **Podstawa:** Art. 70 par. 1 OP
- **Zależności:** Po GR-455
- **Brzegowe:** 5 lat od konca roku kalendarzowego
- **Obszary:** SANCTIONS
- **Priorytet:** 466

#### GR-467: `sc_sanctions_suspension_of_limitations` 
- **Cel:** Zawieszenie biegu przedawnienia
- **Warunki:** tax_audit_in_progress == true OR criminal_tax_proceedings_active == true
- **Rezultat:** limitation_period_suspended: YES
- **Podstawa:** Art. 70c OP
- **Zależności:** Po GR-500
- **Brzegowe:** Kontrola skarbowa zawiesza bieg
- **Obszary:** SANCTIONS
- **Priorytet:** 467

#### GR-468: `sc_sanctions_zus_interest` 
- **Cel:** Odsetki od zaleglych skladek ZUS
- **Warunki:** zus_paid_after_deadline == true
- **Rezultat:** zus_interest_rate: statutory_rate; zus_interest_days: days_overdue
- **Podstawa:** Art. 23 SUS
- **Zależności:** Po GR-280
- **Obszary:** SANCTIONS
- **Priorytet:** 468

#### GR-469: `sc_sanctions_criminal_tax_threshold` 
- **Cel:** KKS — prog przestepstwa 5 mln PLN
- **Warunki:** understated_tax > input.thresholds.criminal_tax_threshold
- **Rezultat:** criminal_liability: YES; imprisonment_possible: YES
- **Podstawa:** Art. 54 KKS
- **Zależności:** Po GR-495
- **Brzegowe:** Powyzej 5 mln PLN = przestepstwo skarbowe
- **Obszary:** SANCTIONS
- **Priorytet:** 469

#### GR-470: `sc_sanctions_voluntary_disclosure` 
- **Cel:** Czynny zal — unikniecie kary
- **Warunki:** taxpayer_self_reported_before_audit == true
- **Rezultat:** penalty_waived: YES; only_tax_and_interest_due
- **Podstawa:** Art. 16 KKS
- **Zależności:** Po GR-495
- **Brzegowe:** Czynny zal = brak kary jesli przed kontrola
- **Obszary:** SANCTIONS
- **Priorytet:** 470

### 6.32 sc.interactions — Interakcje Miedzyobszarowe (GR-520 do GR-554)
> Reguly laczace rozne obszary: forma PIT a skladka zdrowotna, limit VAT a status wspolnikow.

#### GR-471: `sc_interact_taxform_vs_health` 
- **Cel:** ★★ Forma opodatkowania a stawka zdrowotna
- **Warunki:** partner.tax_form != partner_last_health_rate_form
- **Rezultat:** health_rate_recalculated: according_to_tax_form
- **Podstawa:** Art. 81 ustawy o swiadczeniach
- **Zależności:** Po GR-248 AND Po GR-510
- **Brzegowe:** Skala=9%, Liniowy=4.9%, Ryczałt=progi, Karta=9%min
- **Obszary:** INTERACTIONS
- **Priorytet:** 471

#### GR-472: `sc_interact_health_rate_change_notification` 
- **Cel:** Obowiazek powiadomienia ZUS o zmianie stawki
- **Warunki:** partner.health_rate_changed == true
- **Rezultat:** zus_zua_form: update_within_7_days
- **Podstawa:** Art. 36 ust. 14 SUS
- **Zależności:** Po GR-520
- **Obszary:** INTERACTIONS
- **Priorytet:** 472

#### GR-473: `sc_interact_vat_exemption_vs_partner_status` 
- **Cel:** Zwolnienie 200k a nowy wspolnik
- **Warunki:** partnership_is_vat_exempt == true AND new_partner.previously_vat_registered == true
- **Rezultat:** vat_exemption_reevaluated: PARTNERSHIP_WIDE_CHECK
- **Podstawa:** Art. 113 VAT
- **Zależności:** Po GR-58 AND Po GR-350
- **Brzegowe:** Spolka jako calosc liczy limit
- **Obszary:** INTERACTIONS
- **Priorytet:** 473

#### GR-474: `sc_interact_full_accounting_vs_partner_form` 
- **Cel:** Pelna ksiegowosc a forma PIT wspolnika
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** partner_tax_form_unaffected: still_individual_choice; accounting_just_different_method
- **Podstawa:** Art. 24a PIT
- **Zależności:** Po GR-315 AND Po GR-510
- **Brzegowe:** Pelna ksiegowosc nie zmienia formy PIT
- **Obszary:** INTERACTIONS
- **Priorytet:** 474

#### GR-475: `sc_interact_zus_vs_health_base` 
- **Cel:** Skladki spoleczne obnizaja podstawe zdrowotna
- **Warunki:** partner.zus_social_paid > 0 AND partner.tax_form == LINEAR
- **Rezultat:** health_base: partner.sc_income - partner.zus_social_paid
- **Podstawa:** Art. 81 ust. 2c ustawy o swiadczeniach
- **Zależności:** Po GR-249 AND Po GR-280
- **Brzegowe:** Dla liniowego: dochod pomniejszony o skladki spoleczne
- **Obszary:** INTERACTIONS
- **Priorytet:** 475

#### GR-476: `sc_interact_loss_vs_health` 
- **Cel:** Strata a skladka zdrowotna
- **Warunki:** partner.sc_income - partner.zus_social < 0
- **Rezultat:** health_base: MINIMUM_WAGE_BASED
- **Podstawa:** Art. 81 ust. 2b
- **Zależności:** Po GR-252
- **Brzegowe:** Gdy dochod ujemny — minimalna podstawa
- **Obszary:** INTERACTIONS
- **Priorytet:** 476

#### GR-477: `sc_interact_vat_split_payment_vs_pit` 
- **Cel:** Split payment a data KUP w PIT
- **Warunki:** split_payment_applied == true
- **Rezultat:** pit_kup_recognition: ON_PAYMENT_DATE not_invoice_date
- **Podstawa:** Art. 22p PIT
- **Zależności:** Po GR-180 AND Po GR-560
- **Brzegowe:** Dla split payment KUP dopiero przy platnosci
- **Obszary:** INTERACTIONS
- **Priorytet:** 477

#### GR-478: `sc_interact_change_of_partner_vs_vat_reg` 
- **Cel:** Zmiana wspolnika a obowiazek rejestracji VAT
- **Warunki:** partnership_passed_vat_threshold_due_to_new_partner == true
- **Rezultat:** vat_registration: MANDATORY
- **Podstawa:** Art. 96 VAT
- **Zależności:** Po GR-58 AND Po GR-350
- **Brzegowe:** Limit liczony dla calej SC
- **Obszary:** INTERACTIONS
- **Priorytet:** 478

#### GR-479: `sc_interact_suspension_vs_health` 
- **Cel:** Zawieszenie a skladka zdrowotna
- **Warunki:** partner.suspended == true
- **Rezultat:** health_due: MINIMUM even_during_suspension
- **Podstawa:** Art. 82 ust. 8 ustawy o swiadczeniach
- **Zależności:** Po GR-489 AND Po GR-248
- **Brzegowe:** Skladka zdrowotna bez wzgledu na zawieszenie
- **Obszary:** INTERACTIONS
- **Priorytet:** 479

#### GR-480: `sc_interact_succession_vs_vat_continuity` 
- **Cel:** Sukcesja a VAT — kontynuacja
- **Warunki:** succession_manager_active == true
- **Rezultat:** vat_continuation: YES; vat_returns_continue_as_before
- **Podstawa:** Art. 15 VAT
- **Zależności:** Po GR-460 AND Po GR-55
- **Brzegowe:** Zarzadca sukcesyjny kontynuuje obowiazki VAT
- **Obszary:** INTERACTIONS
- **Priorytet:** 480

#### GR-481: `sc_interact_dissolution_vs_partner_zus` 
- **Cel:** Rozwiazanie SC a ZUS wspolnika
- **Warunki:** partnership.dissolved == true
- **Rezultat:** partner_zus_obligations: CONTINUE_AS_POST_SC_JDG
- **Podstawa:** Art. 18 SUS
- **Zależności:** Po GR-387 AND Po GR-280
- **Brzegowe:** Po rozwiazaniu SC wspolnik moze kontynuowac jako JDG
- **Obszary:** INTERACTIONS
- **Priorytet:** 481

#### GR-482: `sc_interact_car_private_use_vat` 
- **Cel:** Samochod firmowy z uzyciem prywatnym — VAT 50%
- **Warunki:** vehicle_used_privately == true
- **Rezultat:** vat_deductible_pct: 0.50
- **Podstawa:** Art. 86a ust. 1 VAT
- **Zależności:** Po GR-180
- **Brzegowe:** 50% odliczenia VAT
- **Obszary:** INTERACTIONS
- **Priorytet:** 482

#### GR-483: `sc_interact_car_private_use_pit` 
- **Cel:** Samochod firmowy z uzyciem prywatnym — PIT wspolnika
- **Warunki:** partner.uses_company_car_privately == true
- **Rezultat:** pit_taxable_value: input.thresholds.company_car_private_use_value
- **Podstawa:** Art. 12 ust. 2a PIT
- **Zależności:** Po GR-170
- **Brzegowe:** Ryczałt za prywatne uzycie auta
- **Obszary:** INTERACTIONS
- **Priorytet:** 483

### 6.33 Cross-Reference — Mapa Zaleznosci (GR-555 do GR-579)
> Najwazniejsze zaleznosci miedzy regulami do implementacji Rego.

#### GR-484: `sc_xref_partner_profit_split` 
- **Cel:** ★★★ Podzial proporcjonalny — podstawa WSZYSTKICH regul PIT
- **Warunki:** always
- **Rezultat:** GR-170 do GR-209 must_execute_BEFORE any PIT per-partner rule
- **Podstawa:** Art. 8 PIT
- **Zależności:** Przed GR-210
- **Brzegowe:** Fundament calej architektury PIT
- **Obszary:** ARCHITECTURE
- **Priorytet:** 484

#### GR-485: `sc_xref_vat_before_pit` 
- **Cel:** VAT przed PIT — kolejnosc
- **Warunki:** always
- **Rezultat:** all_vat_rules must_execute_BEFORE pit_proportional_split
- **Podstawa:** Art. 8 PIT
- **Zależności:** GR-75-169 PRZED GR-170
- **Brzegowe:** VAT spolki determinuje kwoty netto do podzialu PIT
- **Obszary:** ARCHITECTURE
- **Priorytet:** 485

#### GR-486: `sc_xref_formation_before_all` 
- **Cel:** Walidacja spolki przed regulami
- **Warunki:** always
- **Rezultat:** GR-330 do GR-349 must_execute_BEFORE any functional rule
- **Podstawa:** Art. 860 KC
- **Zależności:** Przed GR-0 (risk)
- **Brzegowe:** SC musi istniec zanim zastosujemy reguly
- **Obszary:** ARCHITECTURE
- **Priorytet:** 486

#### GR-487: `sc_xref_liability_overrides` 
- **Cel:** Odpowiedzialnosc solidarna nadpisuje
- **Warunki:** partnership.has_debts == true
- **Rezultat:** GR-415 do GR-430 override all_tax_rules if_debt_triggers
- **Podstawa:** Art. 864 KC
- **Zależności:** Po wszystkich regulach podatkowych
- **Brzegowe:** Fundament bezpieczenstwa
- **Obszary:** ARCHITECTURE
- **Priorytet:** 487

#### GR-488: `sc_xref_full_accounting_routing` 
- **Cel:** Pelna ksiegowosc zmienia routing
- **Warunki:** accounting_method == FULL_ACCOUNTING
- **Rezultat:** GR-305 do GR-339 activate; GR-340 do GR-354 disabled
- **Podstawa:** Art. 24a PIT
- **Zależności:** Po GR-315
- **Brzegowe:** Wylacz PKPiR gdy pelna
- **Obszary:** ARCHITECTURE
- **Priorytet:** 488

#### GR-489: `sc_xref_death_triggers_succession` 
- **Cel:** Smierc → sukcesja
- **Warunki:** partner.death_date != null
- **Rezultat:** GR-460 do GR-484 activate
- **Podstawa:** Art. 872 KC
- **Zależności:** Po GR-360
- **Obszary:** ARCHITECTURE
- **Priorytet:** 489

#### GR-490: `sc_xref_exit_triggers_liability` 
- **Cel:** Wystapienie → odpowiedzialnosc
- **Warunki:** partner.exit_date != null
- **Rezultat:** GR-420 do GR-421 activate
- **Podstawa:** Art. 864 KC
- **Zależności:** Po GR-353
- **Obszary:** ARCHITECTURE
- **Priorytet:** 490

#### GR-491: `sc_xref_dissolution_triggers_all_final` 
- **Cel:** Rozwiazanie → finalne zamkniecia
- **Warunki:** partnership.dissolved == true
- **Rezultat:** GR-385 do GR-414: VAT_final, PIT_final, accounting_close
- **Podstawa:** Art. 874-875 KC
- **Zależności:** Po GR-385
- **Obszary:** ARCHITECTURE
- **Priorytet:** 491

#### GR-492: `sc_xref_suspension_disables_zus_social` 
- **Cel:** Zawieszenie → ZUS social = 0
- **Warunki:** partner.suspended == true
- **Rezultat:** GR-485 do GR-509 override ZUS_social rates
- **Podstawa:** Art. 22 PP
- **Zależności:** Po GR-485
- **Brzegowe:** Skladki spoleczne STOP, zdrowotna dalej
- **Obszary:** ARCHITECTURE
- **Priorytet:** 492

#### GR-493: `sc_xref_allowances_after_partner_income` 
- **Cel:** Ulgi po obliczeniu dochodu wspolnika
- **Warunki:** partner.sc_taxable_income > 0
- **Rezultat:** GR-255 do GR-279 activate
- **Podstawa:** Art. 26 PIT
- **Zależności:** Po GR-170-209 i GR-210-254
- **Brzegowe:** Ulgi stosowane po podziale proporcjonalnym
- **Obszary:** ARCHITECTURE
- **Priorytet:** 493
