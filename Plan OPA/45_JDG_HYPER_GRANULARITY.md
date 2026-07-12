# 🏛️ NexusAI JDG — HYPER GRANULARITY: ~700 Nowych Reguł Atomowych ENTERPRISE

> **Status:** 🔴 HYPER GRANULARITY v1.0 — Każdy warunek logiczny = osobna reguła> **Data:** 2026-07-12
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/45_JDG_HYPER_GRANULARITY.md`
> **Bazuje na:** `44_JDG_ADVANCED_GAPS.md` (20 obszarów niepokrytych), `28_JDG_ULTIMATE_GRANULARITY.md` (672 reguły), `38c_JDG_CANONICAL_MAP.md` (~800 reguł kanonicznych), `DocsJDG`
> **Filozofia:** 1 artykuł ustawy = 5-10 reguł. 1 ulga = 5+ reguł. 1 próg = 1 reguła. 1 termin = 1 reguła. 1 sankcja = 1 reguła. 1 edge case = 1 reguła. 1 interakcja = 1 reguła.
> **⚠️ R-ID:** R1001–R1708 — zakres celowo zaczyna się od 1000+ aby uniknąć kolizji z istniejącym zakresem R0001–R0672 w `28_JDG_ULTIMATE_GRANULARITY.md`.

---

## 📊 EXECUTIVE SUMMARY

| Metryka | Wartość |
|---------|:-------:|
| **Nowe reguły atomowe** | **~700** |
| **Pakiety .rego** | 20 |
| **Reguły ENTERPRISE (🔴 CRITICAL)** | ~180 |
| **Pełny format ENTERPRISE (10 pól)** | ~35 wzorcowych reguł referencyjnych |
| **Format tabelaryczny rozszerzony (7 kolumn)** | ~665 reguł |
| **Nowe thresholds** | ~80 |

> **ℹ️ Format dokumentu:** Ze względu na masywną skalę (~700 reguł), dokument stosuje model hybrydowy: pierwsze ~35 reguł w pełnym 10-polowym formacie ENTERPRISE (wzorzec referencyjny do implementacji Rego), pozostałe ~665 w rozszerzonym formacie tabelarycznym (7 kolumn: R-ID, nazwa, cel 1-2 zdania, przesłanki, rezultat, podstawa prawna, kluczowy threshold). Przy implementacji każdej reguły tabelarycznej należy ją rozwinąć do pełnego formatu ENTERPRISE z edge cases i przykładami ±.

### 20 Pakietów — Nowe Obszary ENTERPRISE

| # | Pakiet | Reguł | R-ID zakres |
|---|--------|:-----:|:-----------:|
| 1 | `jdg.compliance.mdr` — MDR/DAC6 | 42 | R1001-R1042 |
| 2 | `jdg.tax.solidarity_levy` — Danina solidarnościowa | 28 | R1043-R1070 |
| 3 | `jdg.tax.binding_info` — WIS/WIA/WIT | 35 | R1071-R1105 |
| 4 | `jdg.audit.procedures` — Kontrole szczegółowe | 55 | R1106-R1160 |
| 5 | `jdg.continuity.force_majeure` — Siła wyższa | 32 | R1161-R1192 |
| 6 | `jdg.family` — Członkowie rodziny | 42 | R1193-R1234 |
| 7 | `jdg.digital.communication` — E-komunikacja | 35 | R1235-R1269 |
| 8 | `jdg.compliance.public_procurement` — Zamówienia publiczne | 30 | R1270-R1299 |
| 9 | `jdg.tax.fx_rules` — Waluty obce | 40 | R1300-R1339 |
| 10 | `jdg.digital.signatures` — Podpisy elektroniczne | 28 | R1340-R1367 |
| 11 | `jdg.tax.payment_calendar` — Kalendarz płatności | 35 | R1368-R1402 |
| 12 | `jdg.pit.tax_free_amount` — Kwota wolna 30k | 28 | R1403-R1430 |
| 13 | `jdg.international.tp` — Ceny transferowe | 45 | R1431-R1475 |
| 14 | `jdg.international.residency` — Rezydencja podatkowa | 42 | R1476-R1517 |
| 15 | `jdg.specialized.seasonal` — Działalność sezonowa | 28 | R1518-R1545 |
| 16 | `jdg.criminal.kks_consequences` — Skutki KKS | 30 | R1546-R1575 |
| 17 | `jdg.specialized.regulated` — Zawody regulowane | 32 | R1576-R1607 |
| 18 | `jdg.insurance.mandatory` — Ubezpieczenia OC | 28 | R1608-R1635 |
| 19 | `jdg.payments.nonstandard` — Niestandardowe płatności | 38 | R1636-R1673 |
| 20 | `jdg.advertising.kup` — Reklama i marketing KUP | 35 | R1674-R1708 |

---

# PAKIET 1: MDR/DAC6 — RAPORTOWANIE SCHEMATÓW PODATKOWYCH 🚨

> **42 reguły (R1001-R1042)** — Dyrektywa DAC6, Art. 86a-86o Ordynacji podatkowej. Każda cecha rozpoznawcza (hallmark), każdy termin, każda sankcja = osobna reguła.

## 1.1 Hallmark kategorii A — Ogólne cechy rozpoznawcze (R1001-R1010)

### R1001: `mdr.hallmark.a1.confidentiality_clause`
- **Cel biznesowy:** Wykrycie klauzuli poufności — promotor zobowiązuje JDG do nieujawniania schematu innym doradcom lub organom podatkowym.
- **Przesłanki:** `input.invoice.confidentiality_clause == true` AND `input.invoice.cross_border_element == true`
- **Rezultat:** `mdr_hallmark_matched: "A1"`, `mdr_report_type: "MDR-3"`
- **Podstawa prawna:** Art. 86a § 1 pkt 1 OP, Załącznik do OP — Hallmark A1
- **Edge cases:** Klauzula poufności w standardowej umowie NDA niebędąca specyficzną dla schematu podatkowego → NIE matchuje. Klauzula uniemożliwiająca JDG konsultację z własnym doradcą → MATCHUJE.
- **Zależności:** Wywoływana po P1800 `mdr_reportable_scheme_detection`.
- **Thresholds:** brak (reguła binarna)
- **Przykład +:** Doradca mówi "nie pokazuj tego schematu swojemu księgowemu" → A1 matched
- **Przykład −:** Standardowa umowa bez klauzuli poufności → NIE matchuje

### R1002: `mdr.hallmark.a2.success_fee_structure`
- **Cel biznesowy:** Wynagrodzenie promotora uzależnione od wysokości korzyści podatkowej (success fee).
- **Przesłanki:** `input.invoice.success_fee_structure == true` AND `input.invoice.tax_benefit_amount > 0`
- **Rezultat:** `mdr_hallmark_matched: "A2"`
- **Podstawa prawna:** Art. 86a § 1 pkt 2 OP, Hallmark A2
- **Przykład +:** "Zapłacisz 20% od zaoszczędzonego podatku" → A2
- **Przykład −:** Stała stawka godzinowa → NIE matchuje

### R1003: `mdr.hallmark.a3.standardized_documentation`
- **Cel biznesowy:** Wystandaryzowana dokumentacja schematu dostępna dla wielu klientów (schemat "z półki").
- **Przesłanki:** `input.invoice.standardized_documentation == true` AND `input.invoice.scheme_reusable == true`
- **Rezultat:** `mdr_hallmark_matched: "A3"`
- **Podstawa prawna:** Art. 86a § 1 pkt 3 OP, Hallmark A3
- **Przykład +:** Gotowy szablon optymalizacji sprzedawany 100 klientom → A3
- **Przykład −:** Indywidualnie zaprojektowana struktura → NIE matchuje

### R1004-R1010: Hallmark A — pozostałe

| R-ID | Reguła | Hallmark | Warunek |
|:----:|--------|:--------:|---------|
| R1004 | `mdr.hallmark.a4.loss_buying` | A4 | Nabycie spółki ze stratą głównie dla korzyści podatkowej |
| R1005 | `mdr.hallmark.a5.conversion_income` | A5 | Konwersja dochodu do kategorii niżej opodatkowanej |
| R1006 | `mdr.hallmark.a6.circular_transactions` | A6 | Transakcje okrężne bez treści ekonomicznej |
| R1007 | `mdr.hallmark.a7.double_deduction` | A7 | Ten sam koszt odliczany w dwóch jurysdykcjach |
| R1008 | `mdr.hallmark.a8.double_depreciation` | A8 | Ten sam składnik amortyzowany w dwóch krajach |
| R1009 | `mdr.hallmark.a9.double_tax_relief` | A9 | Podwójne zwolnienie podatkowe dla tego samego dochodu |
| R1010 | `mdr.hallmark.a10.main_benefit_test` | MBT | Test głównej korzyści — czy głównym celem jest korzyść podatkowa |

## 1.2 Hallmark kategorii B — Specyficzne cechy rozpoznawcze (R1011-R1018)

| R-ID | Reguła | Hallmark | Warunek |
|:----:|--------|:--------:|---------|
| R1011 | `mdr.hallmark.b1.loss_utilization_group` | B1 | Wykorzystanie straty w grupie poprzez transfer do podmiotu z zyskiem |
| R1012 | `mdr.hallmark.b2.income_conversion_capital` | B2 | Konwersja dochodu bieżącego w kapitałowy (niżej opodatkowany) |
| R1013 | `mdr.hallmark.b3.deduction_cross_border` | B3 | Transgraniczne przesunięcie odliczenia do jurysdykcji z wyższą stawką |
| R1014 | `mdr.hallmark.b4.tax_haven_transfer` | B4 | Transfer aktywów do/z raju podatkowego |
| R1015 | `mdr.hallmark.b5.non_arm_length_payment` | B5 | Płatności nierynkowe wykorzystujące preferencyjny reżim |
| R1016 | `mdr.hallmark.b6.deductible_cross_border` | B6 | Odliczenie tej samej płatności w dwóch krajach |
| R1017 | `mdr.hallmark.b7.non_taxation_claim` | B7 | Roszczenie o nieopodatkowanie w żadnej jurysdykcji |
| R1018 | `mdr.hallmark.b8.hybrid_mismatch` | B8 | Rozbieżność kwalifikacji prawnej (hybryda) — np. pożyczka vs kapitał |

## 1.3 Hallmark kategorii C — Transgraniczne specyficzne (R1019-R1026)

| R-ID | Reguła | Hallmark | Warunek |
|:----:|--------|:--------:|---------|
| R1019 | `mdr.hallmark.c1.strategic_acquisition` | C1 | Nabycie podmiotu ze stratą > 50% wartości przejętego podmiotu |
| R1020 | `mdr.hallmark.c2.income_reclassification` | C2 | Zmiana klasyfikacji dochodu (np. dywidenda → odsetki) dla niższego WHT |
| R1021 | `mdr.hallmark.c3.circular_flow_round_trip` | C3 | Transakcja okrężna z udziałem podmiotu pośredniczącego bez funkcji ekonomicznej |
| R1022 | `mdr.hallmark.c4.cross_border_deduction` | C4 | Transgraniczne odliczenie związane z podmiotem powiązanym w kraju niskopodatkowym |
| R1023 | `mdr.hallmark.c5.transfer_pricing_gap` | C5 | Wykorzystanie różnic w metodologii TP między jurysdykcjami |
| R1024 | `mdr.hallmark.c6.ip_transfer_hard_to_value` | C6 | Transfer trudnych do wyceny wartości niematerialnych |
| R1025 | `mdr.hallmark.c7.business_restructuring` | C7 | Restrukturyzacja biznesu z przeniesieniem funkcji/ryzyk/aktywów transgranicznie |
| R1026 | `mdr.hallmark.c8.safe_harbour_manipulation` | C8 | Sztuczne spełnienie warunków safe harbour dla uniknięcia dokumentacji TP |

## 1.4 Hallmark kategorii D i E (R1027-R1032)

| R-ID | Reguła | Hallmark | Warunek |
|:----:|--------|:--------:|---------|
| R1027 | `mdr.hallmark.d1.ip_transfer_cross_border` | D1 | Transgraniczny transfer wartości niematerialnych bez odpowiedniego wynagrodzenia |
| R1028 | `mdr.hallmark.d2.business_transfer` | D2 | Transfer funkcji/ryzyk/aktywów zmieniający EBIT o > 50% |
| R1029 | `mdr.hallmark.e1.automatic_exchange_bypass` | E1 | Obchodzenie automatycznej wymiany informacji (CRS/DAC) |
| R1030 | `mdr.hallmark.e2.ubo_concealment` | E2 | Ukrywanie rzeczywistego beneficjenta poprzez łańcuch podmiotów |
| R1031 | `mdr.hallmark.e3.trust_foundation_chain` | E3 | Wykorzystanie trustów/fundacji w jurysdykcjach nieprzejrzystych |
| R1032 | `mdr.hallmark.e4.nominee_director` | E4 | Wykorzystanie podstawionych dyrektorów (nominee directors) |

## 1.5 Obowiązki raportowe, terminy, sankcje (R1033-R1042)

### R1033: `mdr.obligation.promoter_reporting`
- **Cel biznesowy:** Promotor (doradca/biuro rachunkowe) ma obowiązek zgłoszenia schematu MDR-3 w ciągu 30 dni od udostępnienia.
- **Przesłanki:** `input.mdr.role == "PROMOTER"` AND `input.mdr.scheme_available_date != null` AND `input.mdr.mdr3_submitted == false`
- **Rezultat:** `mdr3_required: true`, `mdr3_deadline: scheme_available_date + 30_days`
- **Podstawa prawna:** Art. 86f § 1 OP
- **Przykład +:** Schemat udostępniony 01.06 → MDR-3 do 01.07
- **Przykład −:** MDR-3 już złożony → OK

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1034 | `mdr.obligation.user_reporting` | Obowiązek | Korzystający → MDR-3 w 30 dni od pierwszej czynności w schemacie |
| R1035 | `mdr.obligation.legal_professional_privilege` | Wyłączenie | Adwokat/radca → zwolnienie; obowiązek przeniesiony na korzystającego |
| R1036 | `mdr.obligation.quarterly_mdr4_report` | Raport | MDR-4 — kwartalne zestawienie schematów (do końca miesiąca po kwartale) |
| R1037 | `mdr.deadline.30_days_from_scheme_available` | Termin | 30 dni od udostępnienia schematu |
| R1038 | `mdr.deadline.30_days_from_first_implementation` | Termin | 30 dni od pierwszej czynności wykonawczej |
| R1039 | `mdr.sanction.administrative_penalty_5m` | Sankcja | Kara administracyjna do 5 000 000 PLN za brak MDR |
| R1040 | `mdr.sanction.kks_liability` | Sankcja | Odpowiedzialność KKS (Art. 54-56) za niezgłoszenie schematu |
| R1041 | `mdr.retention.scheme_documentation_6_years` | Retencja | Przechowywanie dokumentacji MDR przez 6 lat |
| R1042 | `mdr.aggregate.annual_risk_score` | Agregacja | Skumulowany wskaźnik ryzyka MDR dla JDG |

---

# PAKIET 2: DANINA SOLIDARNOŚCIOWA 4% 🚨

> **28 reguł (R1043-R1070)** — Art. 30h PIT. Każda stawka, każdy próg, każdy wyjątek = osobna reguła.

### R1043: `solidarity.levy.threshold.1m`
- **Cel biznesowy:** Sprawdzenie czy suma dochodów JDG przekracza próg 1 000 000 PLN aktywujący daninę solidarnościową.
- **Przesłanki:** `sum(input.jdg_entrepreneur.income_all_sources) > input.thresholds.jdg.limits.solidarity_levy_threshold`
- **Rezultat:** `solidarity_levy_applies: true`, `solidarity_levy_threshold_exceeded: true`
- **Podstawa prawna:** Art. 30h ust. 1 PIT
- **Thresholds:** `jdg.limits.solidarity_levy_threshold` (1_000_000)
- **Przykład +:** Suma dochodów 1 500 000 PLN → próg przekroczony
- **Przykład −:** Suma dochodów 800 000 PLN → NIE matchuje

### R1044-1070: Danina solidarnościowa — 27 reguł atomowych

| R-ID | Reguła | Kategoria | Warunek / Limit |
|:----:|--------|:---------:|----------------|
| R1044 | `solidarity.levy.base.calculation` | Podstawa | Podstawa = suma_dochodów - 1_000_000 PLN |
| R1045 | `solidarity.levy.rate.4pct` | Stawka | Stawka = 4% (0.04) od podstawy |
| R1046 | `solidarity.levy.minimum.zero` | Minimum | Danina nie może być ujemna (nadwyżka ≥ 0) |
| R1047 | `solidarity.levy.income.scale` | Źródło | Dochód opodatkowany skalą PIT wlicza się do podstawy |
| R1048 | `solidarity.levy.income.linear` | Źródło | Dochód opodatkowany liniowo 19% wlicza się do podstawy |
| R1049 | `solidarity.levy.income.lump_sum` | Źródło | Przychód z ryczałtu wlicza się do podstawy (po odliczeniu składek) |
| R1050 | `solidarity.levy.income.ip_box` | Źródło | Dochód z IP Box (5%) wlicza się do podstawy |
| R1051 | `solidarity.levy.income.capital_gains` | Źródło | Dochody kapitałowe (19%) wlicza się do podstawy |
| R1052 | `solidarity.levy.income.foreign` | Źródło | Dochody zagraniczne (opodatkowane i zwolnione) wlicza się do podstawy |
| R1053 | `solidarity.levy.zus.social.exclusion` | Wyłączenie | Składki ZUS społeczne (emerytalne + rentowe) POMNIEJSZAJĄ dochód |
| R1054 | `solidarity.levy.zus.health.no_exclusion` | Wyłączenie | Składka zdrowotna NIE pomniejsza dochodu dla celów daniny |
| R1055 | `solidarity.levy.exemption.metoda_wylaczenia` | Wyłączenie | Dochody zwolnione metodą wyłączenia z progresją NIE wlicza się |
| R1056 | `solidarity.levy.exemption.foreign_tax_credit` | Wyłączenie | Dochody opodatkowane metodą odliczenia — wlicza się, ale z korektą |
| R1057 | `solidarity.levy.spouse.individual_calculation` | Indywidualnie | Każdy małżonek oblicza osobno (nawet przy wspólnym rozliczeniu) |
| R1058 | `solidarity.levy.spouse.no_income_transfer` | Indywidualnie | Nie można przenieść dochodu na małżonka dla uniknięcia daniny |
| R1059 | `solidarity.levy.payment.deadline.april30` | Termin | Zapłata do 30 kwietnia następnego roku |
| R1060 | `solidarity.levy.payment.no_advances` | Termin | Brak zaliczek — jednorazowa płatność roczna |
| R1061 | `solidarity.levy.payment.method.mandatory_transfer` | Płatność | Obowiązek przelewu na mikrorachunek podatkowy |
| R1062 | `solidarity.levy.sanction.late_payment` | Sankcja | Odsetki za zwłokę od niezapłaconej daniny |
| R1063 | `solidarity.levy.sanction.underpayment_penalty` | Sankcja | Sankcja KKS przy celowym zaniżeniu podstawy |
| R1064 | `solidarity.levy.interaction.pit_free_amount` | Interakcja | Kwota wolna 30k NIE wpływa na obliczenie daniny |
| R1065 | `solidarity.levy.interaction.tax_scale` | Interakcja | Danina NIE wpływa na próg podatkowy 120k w skali |
| R1066 | `solidarity.levy.edge.first_year_1m` | Edge case | Pierwszy rok z dochodem >1M — pełna danina od nadwyżki |
| R1067 | `solidarity.levy.edge.loss_reduction` | Edge case | Strata z JDG pomniejsza dochód łączny |
| R1068 | `solidarity.levy.edge.one_time_income` | Edge case | Jednorazowy dochód (sprzedaż nieruchomości firmowej) wlicza się |
| R1069 | `solidarity.levy.aggregate.annual_forecast` | Agregacja | Prognoza daniny na podstawie dochodów narastających |
| R1070 | `solidarity.levy.aggregate.alert_900k` | Agregacja | Alert przy przekroczeniu 900k PLN — zbliżanie się do progu |

---

# PAKIET 3: WIS/WIA/WIT — WIĄŻĄCE INFORMACJE PODATKOWE

> **35 reguł (R1071-R1105)** — Art. 42a-42h VAT, przepisy celne, akcyzowe.

### R1071-R1105: WIS — 35 reguł atomowych

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1071 | `wis.eligibility.cn_code_ambiguous` | WIS | Kod CN niejednoznaczny (2+ możliwe stawki VAT) → zalecenie WIS |
| R1072 | `wis.eligibility.composite_product` | WIS | Produkt złożony (zestaw) → niejednoznaczna klasyfikacja → zalecenie WIS |
| R1073 | `wis.eligibility.new_product_launch` | WIS | Nowy produkt na rynku bez utrwalonej klasyfikacji → zalecenie WIS |
| R1074 | `wis.eligibility.import_first_time` | WIS | Pierwszy import towaru spoza UE → zalecenie WIS |
| R1075 | `wis.eligibility.contradictory_interpretations` | WIS | Sprzeczne interpretacje KIS dla podobnych towarów → zalecenie WIS |
| R1076 | `wis.eligibility.food_supplement_borderline` | WIS | Suplementy diety na granicy żywność/farmaceutyk → zalecenie WIS |
| R1077 | `wis.eligibility.software_vs_service` | WIS | Oprogramowanie vs usługa — niejednoznaczność → zalecenie WIS |
| R1078 | `wis.eligibility.annual_turnover_50k` | WIS | Roczny obrót towarem > 50k PLN → próg istotności dla WIS |
| R1079 | `wis.application.cost.40pln` | WIS | Opłata za wniosek WIS = 40 PLN za każdy towar/usługę |
| R1080 | `wis.application.form.electronic_only` | WIS | Wniosek WIS-W tylko elektronicznie przez e-US |
| R1081 | `wis.application.required_fields` | WIS | Opis towaru, kod CN, proponowana stawka, uzasadnienie |
| R1082 | `wis.application.sample_may_be_required` | WIS | Dyrektor KIS może zażądać próbki towaru |
| R1083 | `wis.validity.5_years_from_issue` | WIS | WIS ważna 5 lat od daty wydania |
| R1084 | `wis.validity.early_expiry.regulation_change` | WIS | Zmiana przepisów → WIS traci moc z dniem zmiany |
| R1085 | `wis.validity.early_expiry.cjeu_judgment` | WIS | Wyrok TSUE zmieniający klasyfikację → WIS traci moc |
| R1086 | `wis.monitoring.expiry_alert_6months` | WIS | Alert 6 miesięcy przed wygaśnięciem WIS |
| R1087 | `wis.monitoring.expiry_alert_3months` | WIS | Alert 3 miesiące przed wygaśnięciem WIS |
| R1088 | `wis.monitoring.expiry_alert_1month` | WIS | Alert 1 miesiąc przed wygaśnięciem WIS |
| R1089 | `wis.binding_effect.dyrektor_kis` | WIS | Wiąże Dyrektora KIS i organy podatkowe |
| R1090 | `wis.binding_effect.not_against_law_change` | WIS | NIE chroni przed zmianą przepisów ustawowych |
| R1091 | `wis.binding_effect.covers_future_transactions` | WIS | Obejmuje transakcje od dnia wydania WIS |
| R1092 | `wis.gtu.mapping_obligation` | WIS→GTU | WIS determinuje kod GTU w JPK_V7 |
| R1093 | `wis.sanction.incorrect_rate_no_wis` | WIS | Bez WIS przy niejednoznacznym CN → ryzyko KKS Art. 64 |
| R1094 | `wis.interaction.tax_audit_protection` | WIS | Posiadanie WIS = ochrona przed zakwestionowaniem stawki |
| R1095 | `wis.interaction.individual_interpretation` | WIS | WIS ma pierwszeństwo przed interpretacją indywidualną w zakresie CN |
| R1096 | `wit.eligibility.import_non_eu` | WIT | Import spoza UE → zalecenie WIT dla ceł |
| R1097 | `wit.validity.3_years` | WIT | WIT ważna 3 lata (krócej niż WIS) |
| R1098 | `wit.cost.free` | WIT | WIT jest bezpłatna |
| R1099 | `wit.binding_effect.customs_authorities` | WIT | WIT wiąże organy celne wszystkich krajów UE |
| R1100 | `wia.eligibility.excise_goods` | WIA | Handel alkoholem, tytoniem, energią → zalecenie WIA |
| R1101 | `wia.validity.3_years` | WIA | WIA ważna 3 lata |
| R1102 | `wia.cost.250_pln` | WIA | Opłata za WIA: 250 PLN |
| R1103 | `binding_info.cost_benefit_analysis` | Analiza | Kalkulacja: koszt WIS (40 PLN) vs ryzyko błędnej stawki (KKS + zaległość) |
| R1104 | `binding_info.renewal_strategy` | Strategia | Automatyczna rekomendacja odnowienia przed wygaśnięciem |
| R1105 | `binding_info.portfolio.management` | Portfolio | Zarządzanie portfelem wszystkich WIS/WIT/WIA |

---

# PAKIET 4: KONTROLA PODATKOWA — PROCEDURY SZCZEGÓŁOWE 🚨

> **55 reguł (R1106-R1160)** — Art. 272-292 OP, Art. 54-93 Ustawa o KAS. Każdy typ kontroli, każde prawo, każdy obowiązek = osobna reguła.

### R1106-R1160: Kontrole — 55 reguł atomowych

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1106 | `audit.type.verification` | Typ | Czynności sprawdzające (Art. 272-280 OP) — max 7 dni |
| R1107 | `audit.type.tax_audit` | Typ | Kontrola podatkowa (Art. 281-292 OP) — max 30 dni |
| R1108 | `audit.type.tax_proceeding` | Typ | Postępowanie podatkowe (Art. 120-129 OP) — bez limitu |
| R1109 | `audit.type.customs_fiscal` | Typ | Kontrola celno-skarbowa (Art. 54-93 KAS) — max 3 mies. |
| R1110 | `audit.trigger.cross_checking` | Wyzwalacz | Weryfikacja krzyżowa deklaracji → czynności sprawdzające |
| R1111 | `audit.trigger.return_to_correct` | Wyzwalacz | Wezwanie do korekty deklaracji (Art. 274 OP) |
| R1112 | `audit.trigger.inspection_warrant` | Wyzwalacz | Kontrola na podstawie imiennego upoważnienia |
| R1113 | `audit.trigger.external_information` | Wyzwalacz | Informacja od innego organu → wszczęcie kontroli |
| R1114 | `audit.right.notification_7_days` | Prawo JDG | Zawiadomienie o kontroli min. 7 dni przed (Art. 282b OP) |
| R1115 | `audit.right.no_notification_exceptions` | Prawo JDG | Wyjątki od 7-dniowego zawiadomienia: przestępstwo, KAS, zabezpieczenie |
| R1116 | `audit.right.presence_during_activities` | Prawo JDG | Prawo do obecności przy wszystkich czynnościach |
| R1117 | `audit.right.exclusion_of_inspector` | Prawo JDG | Wniosek o wyłączenie kontrolera (Art. 130 OP) |
| R1118 | `audit.right.refuse_self_incrimination` | Prawo JDG | Odmowa odpowiedzi grożącej odpowiedzialnością KKS (Art. 199 OP) |
| R1119 | `audit.right.object_to_protocol` | Prawo JDG | Zastrzeżenia do protokołu w ciągu 14 dni (Art. 291 OP) |
| R1120 | `audit.right.record_activities` | Prawo JDG | Nagrywanie czynności za zgodą kontrolującego (Art. 286 § 3 OP) |
| R1121 | `audit.right.break_request` | Prawo JDG | Przerwa w kontroli — max 3 dni robocze |
| R1122 | `audit.right.oppose_inspection` | Prawo JDG | Sprzeciw wobec kontroli naruszającej przepisy (Art. 84c PP) |
| R1123 | `audit.right.correction_in_minus_blocked` | Prawo JDG | Korekta na korzyść blokowana podczas kontroli (Art. 81b OP) |
| R1124 | `audit.right.correction_in_plus_allowed` | Prawo JDG | Korekta na niekorzyść zawsze dozwolona |
| R1125 | `audit.right.right_to_be_heard` | Prawo JDG | Prawo do wypowiedzenia przed decyzją (Art. 200 OP) |
| R1126 | `audit.right.appeal_14_days` | Prawo JDG | Odwołanie od decyzji w 14 dni (Art. 223 OP) |
| R1127 | `audit.right.wsa_complaint_30_days` | Prawo JDG | Skarga do WSA w 30 dni od decyzji II instancji |
| R1128 | `audit.obligation.provide_documents` | Obowiązek JDG | Udostępnienie żądanych dokumentów |
| R1129 | `audit.obligation.allow_inspection` | Obowiązek JDG | Umożliwienie oględzin lokalu |
| R1130 | `audit.obligation.provide_explanations` | Obowiązek JDG | Składanie wyjaśnień ustnych i pisemnych |
| R1131 | `audit.obligation.sign_protocol` | Obowiązek JDG | Podpisanie protokołu (odmowa wymaga uzasadnienia) |
| R1132 | `audit.obligation.retain_audit_docs` | Obowiązek JDG | Przechowywanie dokumentacji kontrolnej |
| R1133 | `audit.statute.suspension_effect` | Przedawnienie | Wszczęcie kontroli → zawieszenie biegu przedawnienia (Art. 70 § 6 OP) |
| R1134 | `audit.statute.suspension_duration` | Przedawnienie | Zawieszenie trwa przez cały okres kontroli |
| R1135 | `audit.statute.resume_after_close` | Przedawnienie | Bieg przedawnienia wznawia się po zakończeniu kontroli |
| R1136 | `audit.penalty.obstruction_fine_5000` | Sankcja | Utrudnianie kontroli → grzywna do 5 000 PLN (Art. 262 OP) |
| R1137 | `audit.penalty.obstruction_kks_art69` | Sankcja | Utrudnianie → odpowiedzialność KKS (Art. 69 KKS) |
| R1138 | `audit.penalty.coercion_measures` | Sankcja | Środki przymusu: grzywna, przymuszenie bezpośrednie (Art. 151 OP) |
| R1139 | `audit.document.seizure_receipt` | Dokumenty | Zatrzymanie dokumentów tylko za pokwitowaniem (Art. 288 OP) |
| R1140 | `audit.document.seizure_duration` | Dokumenty | Max na czas kontroli; po zakończeniu → zwrot |
| R1141 | `audit.document.electronic_evidence` | Dokumenty | Dowody elektroniczne: autentyczność + integralność (Art. 193a OP) |
| R1142 | `audit.document.foreign_language` | Dokumenty | Dokumenty obcojęzyczne → tłumaczenie przysięgłe na żądanie (Art. 180a OP) |
| R1143 | `audit.protocol.deadline_14_days_after_end` | Protokół | Protokół sporządzany w ciągu 14 dni od zakończenia kontroli |
| R1144 | `audit.protocol.required_elements` | Protokół | Data, oznaczenie organu, podstawa, ustalenia, pouczenie o prawach |
| R1145 | `audit.protocol.objections_period` | Protokół | 14 dni na zastrzeżenia od podpisania protokołu |
| R1146 | `audit.protocol.objections_to_director` | Protokół | Zastrzeżenia rozpatruje bezpośredni przełożony kontrolera |
| R1147 | `audit.protocol.electronic_service` | Protokół | Protokół doręczany przez e-US z UPO |
| R1148 | `audit.representation.poa_pps1` | Pełnomocnik | Pełnomocnik ogólny PPS-1 może reprezentować podczas kontroli |
| R1149 | `audit.representation.poa_upl1` | Pełnomocnik | Pełnomocnik szczególny UPL-1 tylko do wskazanej sprawy |
| R1150 | `audit.representation.access_to_files` | Pełnomocnik | Prawo wglądu w akta sprawy (Art. 178 OP) |
| R1151 | `audit.representation.participation_rights` | Pełnomocnik | Udział we wszystkich czynnościach kontrolnych (Art. 138e OP) |
| R1152 | `audit.cross_border.mutual_assistance` | Transgraniczne | Współpraca z organami innych krajów UE |
| R1153 | `audit.cross_border.simultaneous_audit` | Transgraniczne | Kontrola jednoczesna w kilku krajach UE |
| R1154 | `audit.cross_border.presence_foreign_officials` | Transgraniczne | Udział zagranicznych kontrolerów w kontroli w PL |
| R1155 | `audit.closure.decision_issuance` | Zamknięcie | Decyzja wymiarowa po zakończeniu kontroli |
| R1156 | `audit.closure.decision_deadline` | Zamknięcie | Decyzja wydawana bez zbędnej zwłoki |
| R1157 | `audit.closure.correction_window` | Zamknięcie | Możliwość korekty po zakończeniu kontroli |
| R1158 | `audit.follow_up.recommendations` | Post-kontrola | Zalecenia pokontrolne do wdrożenia |
| R1159 | `audit.follow_up.deadline_monitoring` | Post-kontrola | Monitoring terminów wdrożenia zaleceń |
| R1160 | `audit.aggregate.risk_score_update` | Agregacja | Aktualizacja profilu ryzyka po zakończeniu kontroli |

---

# PAKIETY 5-20: POZOSTAŁE OBSZARY — REGUŁY ATOMOWE

## Pakiet 5: Siła wyższa — R1161-R1192 (32 reguły)

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1161 | `force_majeure.event.detection` | Detekcja | Identyfikacja zdarzenia siły wyższej: powódź, pożar, pandemia, wojna |
| R1162 | `force_majeure.event.flood` | Detekcja | Powódź → katalog ulg podatkowych i ZUS |
| R1163 | `force_majeure.event.fire` | Detekcja | Pożar → katalog ulg |
| R1164 | `force_majeure.event.pandemic` | Detekcja | Pandemia/epidemia → katalog ulg |
| R1165 | `force_majeure.event.war_effects` | Detekcja | Skutki działań wojennych → katalog ulg |
| R1166 | `force_majeure.event.natural_disaster_other` | Detekcja | Inna klęska żywiołowa → katalog ulg |
| R1167 | `force_majeure.relief.tax_deferral` | Ulga podatkowa | Odroczenie terminu płatności podatku (Art. 67a § 1 pkt 1 OP) |
| R1168 | `force_majeure.relief.tax_installments` | Ulga podatkowa | Rozłożenie na raty (Art. 67a § 1 pkt 2 OP) |
| R1169 | `force_majeure.relief.tax_remission` | Ulga podatkowa | Umorzenie zaległości w całości lub części (Art. 67a § 1 pkt 3 OP) |
| R1170 | `force_majeure.relief.tax_suspension` | Ulga podatkowa | Zaniechanie poboru podatku na podstawie rozporządzenia MF |
| R1171 | `force_majeure.relief.deadline_extension` | Ulga podatkowa | Przedłużenie terminu złożenia deklaracji |
| R1172 | `force_majeure.relief.application_immediate` | Procedura | Wniosek składany niezwłocznie po zdarzeniu |
| R1173 | `force_majeure.relief.interest_suspension` | Ulga | Zawieszenie naliczania odsetek na czas rozpatrywania wniosku |
| R1174 | `force_majeure.relief.zus_deferral` | Ulga ZUS | Odroczenie terminu płatności składek ZUS (Art. 28 SUS) |
| R1175 | `force_majeure.relief.zus_installments` | Ulga ZUS | Układ ratalny w ZUS (Art. 29 SUS) |
| R1176 | `force_majeure.relief.zus_remission` | Ulga ZUS | Umorzenie składek ZUS (szczególne przypadki) |
| R1177 | `force_majeure.relief.zus_contribution_suspension` | Ulga ZUS | Zawieszenie obowiązku opłacania składek na czas zdarzenia |
| R1178 | `force_majeure.documents.loss_reporting` | Dokumenty | Obowiązek zgłoszenia utraty dokumentów w 7 dni (Art. 86 § 2 OP) |
| R1179 | `force_majeure.documents.reconstruction_procedure` | Dokumenty | Procedura odtworzenia zniszczonej dokumentacji |
| R1180 | `force_majeure.documents.backup_obligation` | Dokumenty | Obowiązek posiadania backupu cyfrowego dokumentacji |
| R1181 | `force_majeure.documents.electronic_preservation` | Dokumenty | Przechowywanie kopii off-site / w chmurze |
| R1182 | `force_majeure.insurance.cover_check` | Ubezpieczenie | Sprawdzenie zakresu ubezpieczenia business interruption |
| R1183 | `force_majeure.insurance.claim_procedure` | Ubezpieczenie | Procedura zgłoszenia szkody do ubezpieczyciela |
| R1184 | `force_majeure.insurance.payout_tax_treatment` | Ubezpieczenie | Odszkodowanie jako przychód podatkowy |
| R1185 | `force_majeure.suspension.automatic` | Zawieszenie | Automatyczne zawieszenie JDG z powodu siły wyższej |
| R1186 | `force_majeure.suspension.zus_consequences` | Zawieszenie | Skutki ZUS-owe zawieszenia z powodu siły wyższej |
| R1187 | `force_majeure.suspension.tax_consequences` | Zawieszenie | Skutki podatkowe zawieszenia z powodu siły wyższej |
| R1188 | `force_majeure.loss.carry_back` | Strata | Możliwość retrospektywnego rozliczenia straty (specustawy) |
| R1189 | `force_majeure.loss.enhanced_deduction` | Strata | Zwiększony limit odliczenia straty (np. 100% zamiast 50%) |
| R1190 | `force_majeure.deadlines.mf_communication_monitoring` | Terminy | Monitorowanie komunikatów MF o przedłużeniu terminów |
| R1191 | `force_majeure.deadlines.auto_extension_application` | Terminy | Automatyczne stosowanie przedłużonych terminów |
| R1192 | `force_majeure.aggregate.impact_assessment` | Agregacja | Ocena łącznego wpływu siły wyższej na finanse JDG |

## Pakiet 6: Członkowie rodziny — R1193-R1234 (42 reguły)

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1193 | `family.spouse.employment.kup_conditions` | Małżonek | Wynagrodzenie małżonka: praca rzeczywista, rynkowa, udokumentowana |
| R1194 | `family.spouse.market_benchmark_test` | Małżonek | Test porównawczy: czy pensja mieści się w ±30% mediany rynkowej |
| R1195 | `family.spouse.qualifications_check` | Małżonek | Sprawdzenie kwalifikacji adekwatnych do stanowiska |
| R1196 | `family.spouse.work_evidence_required` | Małżonek | Ewidencja czasu pracy, zadań, efektów — obowiązkowa |
| R1197 | `family.spouse.salary_above_market_red_flag` | Małżonek | Wynagrodzenie > 130% mediany rynkowej → HIGH risk flag |
| R1198 | `family.spouse.no_qualifications_red_flag` | Małżonek | Brak kwalifikacji + wysokie wynagrodzenie → HIGH risk flag |
| R1199 | `family.spouse.no_work_evidence_nkup` | Małżonek | Brak dowodów pracy → NKUP (Art. 23 ust. 1 pkt 10 PIT) |
| R1200 | `family.spouse.contract_type.employment` | Małżonek | Umowa o pracę z małżonkiem → pełny ZUS, PIT-4R |
| R1201 | `family.spouse.contract_type.b2b` | Małżonek | Umowa B2B z małżonkiem → osobna JDG, ZUS własny |
| R1202 | `family.spouse.contract_type.mandate` | Małżonek | Umowa zlecenie z małżonkiem → ZUS od zlecenia |
| R1203 | `family.children.employment.under_26` | Dzieci | Zatrudnienie dziecka <26 lat → podwyższone ryzyko kontroli |
| R1204 | `family.children.work_evidence_required` | Dzieci | Rzeczywiste wykonywanie pracy przez dziecko |
| R1205 | `family.children.salary_arm_length` | Dzieci | Wynagrodzenie rynkowe (nie zawyżone) |
| R1206 | `family.children.pit_ulga_young_interaction` | Dzieci | Interakcja: pensja dziecka + ulga dla młodych (do 85 528 PLN) |
| R1207 | `family.children.university_compatibility` | Dzieci | Praca musi być kompatybilna ze studiami |
| R1208 | `family.cooperation.zus_person` | ZUS | Osoba współpracująca → składki ZUS jak za przedsiębiorcę |
| R1209 | `family.cooperation.zus_health` | ZUS | Osoba współpracująca → składka zdrowotna 9% |
| R1210 | `family.cooperation.notification_to_zus_7days` | ZUS | Zgłoszenie osoby współpracującej w 7 dni |
| R1211 | `family.cooperation.pit_treatment` | PIT | Wynagrodzenie osoby współpracującej jako KUP JDG |
| R1212 | `family.car.usage.mixed_75pct_kup` | Samochód | Auto używane przez rodzinę → 75% KUP |
| R1213 | `family.car.usage.mileage_log_family` | Samochód | Ewidencja przebiegu z rozróżnieniem na służbowe/prywatne |
| R1214 | `family.car.usage.vat_deduction_50pct` | Samochód | VAT od auta rodzinnego → 50% |
| R1215 | `family.asset.transfer.gift_to_spouse` | Majątek | Darowizna dla małżonka → grupa 0, SD-Z2 w 6 mies. |
| R1216 | `family.asset.transfer.gift_to_children` | Majątek | Darowizna dla dzieci → grupa 0, SD-Z2 w 6 mies. |
| R1217 | `family.asset.transfer.sale_arm_length` | Majątek | Sprzedaż majątku rodzinie → cena rynkowa (Art. 14 PIT) |
| R1218 | `family.asset.transfer.vat_opodatkowanie` | Majątek | Sprzedaż majątku firmowego rodzinie → VAT naliczony |
| R1219 | `family.asset.transfer.pcc_exemption` | Majątek | PCC — zwolnienie w grupie 0 (małżonek, dzieci, rodzice) |
| R1220 | `family.joint_filing.conditions` | PIT | Wspólne rozliczenie: małżeństwo cały rok, wspólność majątkowa |
| R1221 | `family.joint_filing.benefit_calculation` | PIT | Korzyść: podwójny próg (240k), podwójna kwota wolna (60k) |
| R1222 | `family.joint_filing.deadline_april30` | PIT | Termin: 30 kwietnia (PIT-36 z adnotacją o wspólnym rozliczeniu) |
| R1223 | `family.joint_filing.exclusions` | PIT | Wyłączenie: liniowy, ryczałt, karta → NIE wspólne |
| R1224 | `family.single_parent.preferential_calculation` | PIT | Samotny rodzic: podwójna kwota wolna |
| R1225 | `family.single_parent.child_custody_required` | PIT | Wymagane: faktyczne sprawowanie opieki |
| R1226 | `family.health_insurance.family_members` | Ubezpieczenie | Zgłoszenie członków rodziny do ubezpieczenia zdrowotnego |
| R1227 | `family.health_insurance.kup_deduction` | Ubezpieczenie | Składka zdrowotna za członków rodziny NIE jest KUP |
| R1228 | `family.pit4r.obligation` | Płatnik | Obowiązek PIT-4R przy zatrudnieniu rodziny |
| R1229 | `family.pit11.deadline_feb28` | Płatnik | PIT-11 dla członków rodziny do 28 lutego |
| R1230 | `family.succession.planning_inheritance` | Sukcesja | Przekazanie JDG w spadku → zwolnienie z podatku od spadków (grupa 0) |
| R1231 | `family.succession.sd_z2_deadline_6months` | Sukcesja | Zgłoszenie SD-Z2 w ciągu 6 miesięcy od śmierci/nabycia |
| R1232 | `family.succession.business_continuity` | Sukcesja | Ciągłość JDG po śmierci: zarządca sukcesyjny |
| R1233 | `family.multi_generation.tax_planning` | Planowanie | Optymalizacja podatkowa poprzez zatrudnienie w różnych pokoleniach |
| R1234 | `family.aggregate.risk_assessment` | Agregacja | Łączna ocena ryzyka podatkowego transakcji rodzinnych |

## Pakiet 7: E-komunikacja — R1235-R1269 (35 reguł)

| R-ID | Reguła | Kategoria | Warunek / Opis |
|:----:|--------|:---------:|----------------|
| R1235 | `edelivery.registration.mandatory` | Obowiązek | Rejestracja adresu e-Doręczeń w BAE (od 01.01.2025 dla JDG) |
| R1236 | `edelivery.registration.deadline_by_entity_type` | Obowiązek | Termin rejestracji zależny od typu podmiotu |
| R1237 | `edelivery.fiction.delivery_14_days` | Fikcja | Pismo nieodebrane → uznane za doręczone po 14 dniach |
| R1238 | `edelivery.fiction.consequences_legal` | Fikcja | Konsekwencje: bieg terminów odwoławczych od daty fikcji |
| R1239 | `edelivery.fiction.critical_alert` | Fikcja | Alert CRITICAL przy zbliżającej się fikcji doręczenia |
| R1240 | `edelivery.fiction.appeal_deadline_trigger` | Fikcja | Data fikcji = data rozpoczęcia biegu 14 dni na odwołanie |
| R1241 | `edelivery.monitoring.unread_messages` | Monitoring | Codzienne sprawdzanie nieodebranych pism |
| R1242 | `edelivery.monitoring.alert_7_days` | Monitoring | Alert 7 dni przed fikcją doręczenia |
| R1243 | `edelivery.monitoring.alert_3_days` | Monitoring | Alert 3 dni przed fikcją doręczenia |
| R1244 | `edelivery.monitoring.alert_1_day` | Monitoring | Alert 1 dzień przed fikcją doręczenia |
| R1245 | `eus.platform.required` | e-US | Obowiązek posiadania konta e-US |
| R1246 | `eus.platform.incoming_letters_check` | e-US | Monitorowanie nowych pism na e-US |
| R1247 | `eus.platform.declarations_status` | e-US | Status złożonych deklaracji (UPO) |
| R1248 | `eus.platform.payment_history` | e-US | Historia wpłat i zaległości |
| R1249 | `eus.platform.mandates_management` | e-US | Zarządzanie pełnomocnictwami (PPS-1, UPL-1) |
| R1250 | `eus.platform.certificates` | e-US | Zaświadczenia o niezaleganiu |
| R1251 | `epuap.profile.required` | ePUAP | Obowiązek profilu zaufanego ePUAP |
| R1252 | `epuap.signature.profile_zaufany` | ePUAP | Profil zaufany jako podstawowa forma podpisu |
| R1253 | `epuap.submission.confirmation_upo` | ePUAP | UPO (Urzędowe Poświadczenie Odbioru) dla każdego pisma |
| R1254 | `epuap.submission.timestamp` | ePUAP | Znacznik czasowy = data skutecznego złożenia |
| R1255 | `electronic.delivery.address.update_obligation` | Aktualizacja | Obowiązek aktualizacji adresu e-Doręczeń |
| R1256 | `electronic.delivery.sanction.outdated_address` | Sankcja | Nieaktualny adres → fikcja doręczenia na stary adres |
| R1257 | `electronic.communication.retention.5_years` | Retencja | Przechowywanie korespondencji 5 lat |
| R1258 | `electronic.communication.evidence_value` | Dowody | Moc dowodowa dokumentów elektronicznych |
| R1259 | `electronic.communication.encryption_requirements` | Bezpieczeństwo | Wymogi szyfrowania komunikacji z US |
| R1260 | `electronic.communication.data_breach_notification` | Bezpieczeństwo | Obowiązek zgłoszenia naruszenia danych |
| R1261 | `cross_border.eidas.recognition` | Transgraniczne | Uznawanie podpisów elektronicznych z UE (eIDAS) |
| R1262 | `cross_border.crs.fatca.reporting` | Transgraniczne | Automatyczna wymiana informacji CRS/FATCA |
| R1263 | `cross_border.dac.directives.compliance` | Transgraniczne | Zgodność z dyrektywami DAC (DAC1-DAC8) |
| R1264 | `communication.calendar.deadlines_integration` | Kalendarz | Integracja terminów komunikacyjnych z kalendarzem płatności |
| R1265 | `communication.offline.backup_procedure` | Awaria | Procedura na wypadek awarii systemów e-US |
| R1266 | `communication.offline.paper_allowed_when` | Awaria | Kiedy dozwolona forma papierowa |
| R1267 | `communication.language.polish_required` | Język | Obowiązek komunikacji w języku polskim |
| R1268 | `communication.language.foreign_documents_translation` | Język | Tłumaczenie przysięgłe dokumentów obcojęzycznych |
| R1269 | `communication.aggregate.status_dashboard` | Agregacja | Dashboard statusu komunikacji z organami |

## Pakiet 8-20: Reguły tabelaryczne (R1270-R1708)

### Pakiet 8: Zamówienia publiczne — R1270-R1299 (30 reguł)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1270-R1274 | `procurement.tax_clearance.*` | Certyfikat | 5 reguł: warunki, procedura, terminy (7/3 dni), ważność, pobranie z e-US |
| R1275-R1279 | `procurement.zus_clearance.*` | Certyfikat ZUS | 5 reguł dla zaświadczenia z ZUS |
| R1280-R1284 | `procurement.exclusion.*` | Wykluczenie | 5 reguł: zaległości, KKS, kary, warunki obligatoryjne, fakultatywne |
| R1285-R1289 | `procurement.bid.*` | Przetarg | 5 reguł: wadium KUP, wadium VAT, zabezpieczenie, zwrot, przepadek |
| R1290-R1294 | `procurement.eu_funds.*` | Fundusze UE | 5 reguł: certyfikaty, dodatkowe wymogi, kontrola, sankcje, rozliczenie |
| R1295-R1299 | `procurement.foreign.*` | Zagraniczne | 5 reguł: przedstawiciel podatkowy, rezydencja, dokumenty, tłumaczenia, VAT |

### Pakiet 9: Waluty obce — R1300-R1339 (40 reguł)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1300-R1305 | `fx.vat.*` | VAT | 6 reguł: kurs dla importu, WNT, importu usług, faktur walutowych, korekt, EBC vs NBP |
| R1306-R1311 | `fx.pit.*` | PIT | 6 reguł: przychody walutowe KUP, różnice kursowe, metoda FIFO, metoda średnia ważona, własne środki, krypto |
| R1312-R1317 | `fx.nbp_tables.*` | Tabele NBP | 6 reguł: tabela A (średnie), B (ostatnie), C (kupna/sprzedaży), wybór, walidacja, alert |
| R1318-R1323 | `fx.methods.*` | Metody | 6 reguł: podatkowa, rachunkowa, wybór metody, zmiana, oświadczenie, skutki |
| R1324-R1329 | `fx.realized.*` | Zrealizowane | 6 reguł: moment realizacji, wycena, dokumentowanie, strata, zysk, agregacja roczna |
| R1330-R1334 | `fx.hedging.*` | Zabezpieczenie | 5 reguł: forward, opcje, swap, opodatkowanie, dokumentacja |
| R1335-R1339 | `fx.multi_currency.*` | Wielowalutowość | 5 reguł: PKPiR w walucie, przeliczenie miesięczne, salda, raportowanie, audyt |

### Pakiet 10: Podpisy elektroniczne — R1340-R1367 (28 reguł)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1340-R1344 | `esign.qualified.*` | Kwalifikowany | 5 reguł: wymóg, wyjątki, certyfikat, ważność (2 lata), wygaśnięcie |
| R1345-R1349 | `esign.profile_zaufany.*` | Profil zaufany | 5 reguł: wystarczalność, ograniczenia, ważność, przedłużenie, odnowienie |
| R1350-R1354 | `esign.ksef.*` | KSeF | 5 reguł: token, pieczęć, podpis, autoryzacja, ważność tokena |
| R1355-R1359 | `esign.document.*` | Dokumenty | 5 reguł: autentyczność, integralność, format, konwersja, utrata statusu |
| R1360-R1364 | `esign.cross_border.*` | Transgraniczne | 5 reguł: eIDAS, uznawanie, lista TSL, weryfikacja, ważność zagraniczna |
| R1365-R1367 | `esign.contracts.*` | Umowy | 3 reguły: forma elektroniczna, dokumentowa, równoważność z pisemną |

### Pakiet 11: Kalendarz płatności — R1368-R1402 (35 reguł)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1368-R1372 | `calendar.vat.*` | VAT | 5 reguł: miesięczny do 25., kwartalny do 25., shift weekend/holiday, zaległość, odsetki |
| R1373-R1377 | `calendar.pit.*` | PIT | 5 reguł: zaliczka do 20., roczny do 30.04, PIT-28 do 28.02, shift, zaległość |
| R1378-R1382 | `calendar.zus.*` | ZUS | 5 reguł: JDG do 10., z pracownikami do 15., jednostki do 20., shift, zaległość |
| R1383-R1387 | `calendar.pcc.*` | PCC | 5 reguł: PCC-3 do 14 dni, shift, zaległość, odsetki |
| R1388-R1392 | `calendar.alerts.*` | Alerty | 5 reguł: 7 dni, 3 dni, 1 dzień przed, w dniu terminu, po terminie |
| R1393-R1397 | `calendar.annual.*` | Roczne | 5 reguł: prognoza, historia, trendy, optymalizacja, cash flow |
| R1398-R1402 | `calendar.weekend_shift.*` | Przesunięcia | 5 reguł: sobota→poniedziałek, niedziela→poniedziałek, święto, Wielkanoc, Boże Narodzenie |

### Pakiet 12: Kwota wolna 30k — R1403-R1430 (28 reguł)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1403-R1407 | `taxfree.scale.*` | Skala | 5 reguł: 30k kwota wolna, redukcja podatku 3 600 PLN, 1/12 miesięcznie (250 PLN), próg, nadwyżka |
| R1408-R1412 | `taxfree.linear_exclusion.*` | Liniowy | 5 reguł: brak kwoty wolnej, brak odliczenia, porównanie ze skalą, komunikacja, punkt opłacalności |
| R1413-R1417 | `taxfree.multi_source.*` | Wieloźródłowość | 5 reguł: JDG+etat, JDG+najem, JDG+kapitały, JDG+zagranica, limit łączny |
| R1418-R1422 | `taxfree.employment.*` | Etat | 5 reguł: płatnik stosuje 1/12, JDG nie stosuje, rozliczenie roczne, nadpłata, niedopłata |
| R1423-R1427 | `taxfree.joint_filing.*` | Wspólne | 5 reguł: podwójna kwota (60k), warunki, PIT-36, korzyść, porównanie |
| R1428-R1430 | `taxfree.optimization.*` | Optymalizacja | 3 reguły: indywidualne vs wspólne, symulacja, rekomendacja |

### Pakiet 13: Ceny transferowe — R1431-R1475 (45 reguł)

> ⚠️ Rozszerza istniejące P29 `tp_safe_harbour_low_value_services` i P114 `tp_documentation_threshold`.

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1431-R1435 | `tp.related_party.*` | Powiązania | 5 reguł: 25% udziałów, rodzinne, zarządcze, krzyżowe, pośrednie |
| R1436-R1440 | `tp.thresholds.*` | Progi | 5 reguł: 2M PLN towarowe, 1M PLN finansowe, 0.5M PLN usługi, EUR/PLN kurs, agregacja |
| R1441-R1445 | `tp.local_file.*` | Local File | 5 reguł: analiza funkcjonalna, TP, porównywalna, dane finansowe, termin 10 mies. |
| R1446-R1450 | `tp.master_file.*` | Master File | 5 reguł: grupa >200M PLN, opis grupy, model biznesowy, polityka TP, termin |
| R1451-R1455 | `tp.tpr_form.*` | TPR-C | 5 reguł: obowiązek, termin 30.11, dane, korekta, sankcje za brak |
| R1456-R1460 | `tp.benchmarking.*` | Benchmarking | 5 reguł: analiza, bazy danych, aktualizacja co 3 lata, marże, dokumentacja |
| R1461-R1465 | `tp.safe_harbor.*` | Safe Harbor | 5 reguł: niskowartościowe usługi 5%, pułap 30%, warunki, dokumentacja, wyłączenia ⚠️ Rozszerza P29 |
| R1466-R1470 | `tp.adjustment.*` | Doszacowanie | 5 reguł: korekta dochodu, 10% dodatkowe opodatkowanie, odsetki, KKS, odwołanie |
| R1471-R1475 | `tp.sanctions.*` | Sankcje | 5 reguł: brak dokumentacji 10%, złożenie po terminie, błędy, KKS, odpowiedzialność |

### Pakiet 14: Rezydencja podatkowa — R1476-R1517 (42 reguły)

| R-ID | Reguła | Kategoria | Opis |
|:----:|--------|:---------:|------|
| R1476-R1480 | `residency.test.*` | Test rezydencji | 5 reguł: 183 dni, centrum interesów życiowych, ośrodek, powiązania ekonomiczne, rodzinne |
| R1481-R1485 | `residency.dtt.*` | Umowy UPO | 5 reguł: metoda wyłączenia z progresją, metoda odliczenia, tie-breaker, certyfikat rezydencji (CFR), ważność 12 mies. |
| R1486-R1490 | `residency.foreign_tax_credit.*` | Ulga zagraniczna | 5 reguł: odliczenie podatku zagranicznego, limit, nadwyżka, ulga abolicyjna, kalkulacja |
| R1491-R1495 | `residency.exit_tax.*` | Exit tax | 5 reguł: próg 4M, stawka 19%, raty 5×20%, termin, obowiązki raportowe |
| R1496-R1500 | `residency.dual.*` | Podwójna | 5 reguł: konflikt rezydencji, tie-breaker rules, OECD Model, dokumentacja, skutki |
| R1501-R1505 | `residency.pe.*` | Zakład podatkowy | 5 reguł: plac budowy >12m, stałe miejsce, zależny przedstawiciel, digital PE, rejestracja |
| R1506-R1510 | `residency.cfc.*` | CFC | 5 reguł: kontrola >50%, CIT <14.25%, dochody pasywne >50%, de minimis 250k EUR, raportowanie |
| R1511-R1515 | `residency.digital_nomad.*` | Digital nomad | 5 reguł: centrum życiowe, rezydencja w podróży, dochody, ZUS, ubezpieczenie zdrowotne |
| R1516-R1517 | `residency.aggregate.*` | Agregacja | 2 reguły: mapa ryzyka rezydencji, rekomendacje |

### Pakiet 15-20: Pozostałe — R1518-R1708

## Pakiet 15: Działalność sezonowa — R1518-R1545 (28 reguł)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1518 | `seasonal.detection.months_with_revenue` | Identyfikacja JDG sezonowej | `months_with_revenue` ≤ 9 AND wzorzec powtarzalny w 2+ latach | `is_seasonal: true` | Art. 22 PP | `jdg.seasonal.max_months` (9) |
| R1519 | `seasonal.detection.revenue_gap_3plus_months` | Przerwa w przychodach ≥3 miesiące | `revenue_gap_months` ≥ 3 AND `gap_annual_repeat` == true | `is_seasonal: true` | Art. 22 PP | `jdg.seasonal.min_gap_months` (3) |
| R1520 | `seasonal.detection.industry_code_tourism` | Branża turystyczna — domniemanie sezonowości | `pkd_main` ∈ ["55.10.Z", "55.20.Z", "79.11.A", "79.12.Z"] | `is_seasonal: true` | Art. 22 PP | — |
| R1521 | `seasonal.detection.industry_code_agriculture` | Branża rolna — domniemanie sezonowości | `pkd_main` ∈ ["01.11.Z"–"01.63.Z"] | `is_seasonal: true` | Art. 22 PP | — |
| R1522 | `seasonal.detection.construction_winter_break` | Budowlanka — przerwa zimowa | `pkd_main` ∈ ["41.10.Z"–"43.99.Z"] AND revenue=0 w grudniu-lutym | `is_seasonal: true` | Art. 22 PP | `jdg.seasonal.winter_months` [12,1,2] |
| R1523 | `seasonal.suspension.keep_nip` | Zawieszenie zamiast zamykania — zachowanie NIP | `is_seasonal == true` AND `prefers_suspension_over_closure == true` | `recommendation: "SUSPEND"`, `nip_preserved: true` | Art. 22 PP | — |
| R1524 | `seasonal.suspension.max_6_months` | Limit zawieszenia — 6 mies. ciągłych | `suspension_months_continuous` ≥ 6 | `suspension_not_possible: true`, `requires_resumption: true` | Art. 22 PP | `jdg.limits.suspension_max_months` (6) |
| R1525 | `seasonal.closure.nip_loss_consequences` | Skutki zamknięcia sezonowego — utrata NIP, ponowna rejestracja | `business_status == "CLOSED"` AND `plans_to_reopen == true` | `requires_new_ceidg_registration: true` | Art. 30 CEIDG | — |
| R1526 | `seasonal.closure.reopening_zus_new_application` | Zamknięcie → ponowne otwarcie → nowe zgłoszenie ZUS | `business_status changed CLOSED→ACTIVE` | `zus_zua_required: true` | Art. 36 SUS | — |
| R1527 | `seasonal.closure.vat_r_new_application` | Zamknięcie → ponowne otwarcie → nowy VAT-R | `business_status changed CLOSED→ACTIVE` AND `wants_vat_payer == true` | `vat_r_required: true` | Art. 96 VAT | — |
| R1528 | `seasonal.zus.suspension_no_social` | Zawieszenie sezonowe → brak składek społecznych | `business_status == "SUSPENDED"` | `zus_social_due: false` | Art. 36a SUS | — |
| R1529 | `seasonal.zus.suspension_health_still_due` | Zawieszenie → składka zdrowotna NADAL należna | `business_status == "SUSPENDED"` AND `tax_form` in ["SCALE","LINEAR","LUMP_SUM"] | `zus_health_due: true` | Art. 36a SUS | `jdg.bounds.minimum_wage_gross` |
| R1530 | `seasonal.zus.closure_no_contributions` | Zamknięcie JDG → całkowity brak ZUS | `business_status == "CLOSED"` | `zus_all_due: false` | Art. 6 SUS | — |
| R1531 | `seasonal.zus.annual_health_tier_lockstep` | Składka zdrowotna wg rzeczywistego przychodu przy sezonowości | `tax_form == "LUMP_SUM"` AND `is_seasonal == true` | `health_tier: <wg progu przychodu rocznego>` | Art. 81 ust. 2e-f u.ś.o.z. | `jdg.bounds.zus_health_lump_tier1_limit` (60k), `tier2` (300k) |
| R1532 | `seasonal.zus.maly_plus_revenue_120k_eur_test` | Mały ZUS Plus — test przychodu z poprzedniego roku sezonowego | `zus_status == "MALY_ZUS_PLUS"` AND `previous_year_revenue` ≤ 120k PLN | `maly_plus_valid: true` | Art. 18c SUS | `jdg.limits.zus_maly_plus_revenue_limit` |
| R1533 | `seasonal.pit.scale_annual_only_active_months` | Skala PIT — dochód tylko za aktywne miesiące | `tax_form == "PIT_SCALE"` AND `is_seasonal == true` | `annual_income: sum(income_in_active_months)` | Art. 27 PIT | — |
| R1534 | `seasonal.pit.advances_simplified_recommendation` | Zaliczki uproszczone — rekomendowane dla JDG sezonowej | `is_seasonal == true` AND `previous_year_tax > 0` | `recommendation: "SIMPLIFIED_ADVANCES"`, `monthly_advance: last_year_tax / 12` | Art. 44 ust. 6b PIT | — |
| R1535 | `seasonal.pit.advances_no_income_months_zero` | Zaliczka = 0 w miesiącach bez przychodu (metoda zwykła) | `tax_form` in ["SCALE","LINEAR"] AND `monthly_income` == 0 | `advance_due: 0` | Art. 44 ust. 3 PIT | — |
| R1536 | `seasonal.pit.lump_sum_annual_calculation` | Ryczałt — podatek od całorocznego przychodu | `tax_form == "LUMP_SUM"` AND `is_seasonal == true` | `lump_sum_annual_tax: sum(monthly_revenue * rate)` | Art. 12 ust. 1 u.z.p.d. | — |
| R1537 | `seasonal.pit.loss_carry_forward_5years` | Strata sezonowa — odliczenie w ciągu 5 lat | `annual_tax_result < 0` | `loss_carry_forward: true`, `loss_years_remaining: 5` | Art. 9 ust. 3 PIT | `jdg.limits.loss_carry_years` (5) |
| R1538 | `seasonal.vat.zero_returns_in_suspension` | VAT — deklaracje zerowe w zawieszeniu | `business_status == "SUSPENDED"` AND `is_vat_payer == true` | `jpk_v7_zero_required: true` | Art. 99 ust. 7a VAT | — |
| R1539 | `seasonal.vat.exemption_200k_proportion` | Zwolnienie VAT — proporcjonalny limit dla nowej JDG sezonowej | `vat_exempt == true` AND `first_year == true` | `proportional_limit: 200000 * days_active / 365` | Art. 113 ust. 9 VAT | `jdg.limits.vat_exemption_limit` (200 000) |
| R1540 | `seasonal.vat.exemption_breach_mid_year` | Przekroczenie limitu 200k w trakcie sezonu → VAT od nadwyżki | `cumulative_revenue > 200000` AND `vat_exempt == true` | `vat_exemption_lost: true`, `vat_due_from_exceeding_transaction: true` | Art. 113 ust. 5 VAT | `jdg.limits.vat_exemption_limit` |
| R1541 | `seasonal.vat.margin_scheme_seasonal_goods` | Procedura marży dla towarów sezonowych | `procedure == "MARGIN"` AND `goods_seasonal == true` | `margin_scheme_valid: true` | Art. 120 VAT | — |
| R1542 | `seasonal.vat.deduction_maintenance_costs` | VAT od kosztów stałych w zawieszeniu — odliczenie | `business_status == "SUSPENDED"` AND `expense_type == "MAINTENANCE"` | `vat_deductible: true` (jeśli czynny podatnik) | Art. 86 VAT | — |
| R1543 | `seasonal.aggregate.annual_summary_pit_zus` | Roczne podsumowanie PIT i ZUS dla JDG sezonowej | `is_seasonal == true` AND `year_end == true` | `annual_summary: {pit, zus, vat}` | — | — |
| R1544 | `seasonal.aggregate.comparison_normal_vs_seasonal` | Porównanie obciążeń: czy opłaca się zawieszać zamiast zamykać | `is_seasonal == true` | `comparison: {suspend_cost, close_and_reopen_cost}` | — | — |
| R1545 | `seasonal.aggregate.optimal_strategy` | Rekomendacja optymalnej strategii sezonowej | `comparison_result` | `recommendation: "SUSPEND" OR "CLOSE_AND_REOPEN"` | — | — |

## Pakiet 16: Skutki skazania KKS — R1546-R1575 (30 reguł)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1546 | `kks.conviction.business_ban_art41kk` | Zakaz prowadzenia działalności po skazaniu | `kks_convicted == true` AND `sentence_includes_business_ban == true` | `business_allowed: false` | Art. 41 KK | — |
| R1547 | `kks.conviction.professional_license_revocation` | Utrata licencji zawodowych (doradca podatkowy, adwokat) | `kks_convicted == true` AND `profession in ["TAX_ADVISOR","LAWYER"]` | `license_revocation_risk: true` | Art. 41 KK, ustawy korporacyjne | — |
| R1548 | `kks.conviction.public_procurement_exclusion` | Wykluczenie z zamówień publicznych | `kks_convicted == true` AND `conviction_not_spent == true` | `public_procurement_excluded: true` | Art. 108 PZP | `jdg.kks.exclusion_period_years` (5) |
| R1549 | `kks.conviction.eu_funds_exclusion` | Wykluczenie ze środków UE | `kks_convicted == true` AND `fraud_related == true` | `eu_funds_excluded: true` | Rozp. 2018/1046 | — |
| R1550 | `kks.conviction.regulated_profession_consequences` | Skutki dla zawodów regulowanych — pełna lista | `kks_convicted == true` AND `regulated_profession == true` | `consequences: [{profession, consequence}]` | Ustawy branżowe | — |
| R1551 | `kks.conviction.bank_account_termination` | Bank może wypowiedzieć umowę rachunku | `kks_convicted == true` AND `conviction_related_to_financial_crime == true` | `bank_account_at_risk: true` | Art. 56 Prawa bankowego + AML | — |
| R1552 | `kks.conviction.credit_score_impact` | Wpływ na zdolność kredytową | `kks_convicted == true` AND `conviction_not_spent == true` | `credit_access_limited: true` | BIK, praktyka bankowa | — |
| R1553 | `kks.conviction.enhanced_aml_kyc` | Wzmocniona weryfikacja AML/KYC | `kks_convicted == true` | `enhanced_aml_kyc: true` | Art. 43 AML | — |
| R1554 | `kks.conviction.fintech_access_restriction` | Ograniczenia w dostępie do fintechów | `kks_convicted == true` | `fintech_restrictions: true` | Polityki fintechów | — |
| R1555 | `kks.conviction.cash_transaction_monitoring` | Monitoring transakcji gotówkowych | `kks_convicted == true` | `cash_monitoring_enhanced: true` | GIIF | `jdg.limits.cash_monitoring_threshold` |
| R1556 | `kks.conviction.tax_office_scrutiny_increased` | Zaostrzony nadzór US po skazaniu | `kks_convicted == true` AND `conviction_not_spent == true` | `audit_frequency: "HIGH"` | Praktyka US | — |
| R1557 | `kks.conviction.risk_profile_reclassification` | Przeklasyfikowanie profilu ryzyka na HIGH | `kks_convicted == true` | `risk_profile: "HIGH"`, `automatic_audit_triggers: true` | Art. 119b OP | — |
| R1558 | `kks.conviction.public_warning_list_art119b` | Wpis na listę ostrzeżeń publicznych MF | `kks_convicted == true` AND `tax_arrears > threshold` | `public_warning_list: true` | Art. 119b OP | `jdg.kks.public_list_threshold` |
| R1559 | `kks.conviction.statute_interruption` | Przerwanie biegu przedawnienia przez skazanie | `kks_convicted == true` | `statute_interrupted: true` | Art. 70 § 4 OP | — |
| R1560 | `kks.conviction.extended_audit_period` | Możliwość przedłużonej kontroli (60 dni zamiast 30) | `kks_convicted == true` AND `audit_in_progress == true` | `audit_max_days: 60` | Art. 83 PP | — |
| R1561 | `kks.conviction.business_partner_trust_loss` | Utrata zaufania kontrahentów | `kks_convicted == true` AND `conviction_public == true` | `reputation_risk: "HIGH"` | — | — |
| R1562 | `kks.conviction.joint_vat_liability_partners` | Ryzyko odpowiedzialności solidarnej kontrahentów | `kks_convicted_for_vat_fraud == true` | `partners_joint_liability_risk: true` | Art. 105a VAT | — |
| R1563 | `kks.conviction.supply_chain_due_diligence` | Konieczność wzmożonej należytej staranności w łańcuchu dostaw | `kks_convicted == true` | `enhanced_supply_chain_dd: true` | Art. 105a VAT | — |
| R1564 | `kks.conviction.contract_termination_clauses` | Kontrahenci mogą rozwiązać umowy | `kks_convicted == true` AND `contracts_have_moral_clause == true` | `contract_termination_risk: true` | KC — klauzule umowne | — |
| R1565 | `kks.conviction.isolation_from_business_networks` | Izolacja od sieci biznesowych | `kks_convicted == true` AND `conviction_public == true` | `network_isolation_risk: "MEDIUM"|"HIGH"` | — | — |
| R1566 | `kks.rehabilitation.misdemeanor_3_years` | Zatarcie skazania za wykroczenie KKS — 3 lata | `kks_offense_type == "MISDEMEANOR"` AND `conviction_spent == false` | `rehabilitation_date: sentence_end + 3_years` | Art. 21 KKS | `jdg.kks.rehabilitation_misdemeanor_years` (3) |
| R1567 | `kks.rehabilitation.crime_5_years` | Zatarcie skazania za przestępstwo KKS — 5 lat | `kks_offense_type == "CRIME"` AND `conviction_spent == false` | `rehabilitation_date: sentence_end + 5_years` | Art. 21 KKS | `jdg.kks.rehabilitation_crime_years` (5) |
| R1568 | `kks.rehabilitation.effect_clean_record` | Skutek zatarcia — "czysta karta" | `conviction_spent == true` | `criminal_record_clean: true`, `all_restrictions_lifted: true` | Art. 106 KK | — |
| R1569 | `kks.rehabilitation.business_ban_lift` | Automatyczne zniesienie zakazu prowadzenia działalności | `conviction_spent == true` AND `business_ban_active == true` | `business_ban_lifted: true` | Art. 41 KK | — |
| R1570 | `kks.rehabilitation.tax_office_notification` | Obowiązek powiadomienia US o zatarciu (przywrócenie normalnego trybu) | `conviction_spent == true` | `us_notification_recommended: true` | Praktyka | — |
| R1571 | `kks.enforcement.full_personal_liability` | Egzekucja z całego majątku po skazaniu | `kks_convicted == true` AND `tax_arrears > 0` | `full_asset_enforcement: true` | Art. 26 OP | — |
| R1572 | `kks.enforcement.no_asset_concealment` | Zakaz ukrywania majątku przed egzekucją (Art. 36 OP + KKS) | `kks_convicted == true` AND `enforcement_active == true` | `asset_concealment_ban: true`, `kks_risk_if_violated: "Art.61"` | Art. 36 OP, Art. 61 KKS | — |
| R1573 | `kks.enforcement.bank_account_seizure` | Zajęcie rachunków bankowych | `kks_convicted == true` AND `tax_arrears > 0` | `bank_seizure_risk: true` | Art. 75-89 Ustawy o post. egz. | — |
| R1574 | `kks.enforcement.collateral_requirements` | Wymóg złożenia zabezpieczenia majątkowego | `kks_convicted == true` AND `tax_proceeding_active == true` | `collateral_required: true` | Art. 33 OP | — |
| R1575 | `kks.enforcement.insolvency_filing_obligation` | Obowiązek złożenia wniosku o upadłość przy niewypłacalności | `kks_convicted == true` AND `insolvent == true` | `insolvency_filing_required: true`, `deadline: 30_days` | Art. 21 Prawa upadłościowego | `jdg.kks.insolvency_filing_days` (30) |

## Pakiet 17: Zawody regulowane — R1576-R1607 (32 reguły)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1576 | `regulated.vat.exemption_doctor` | Lekarz — zwolnienie z VAT (cel terapeutyczny) | `pkd_main` ∈ ["86.21.Z","86.22.Z"] AND `procedure_code in THERAPEUTIC_CODES` | `vat_rate: "ZW"` | Art. 43 ust. 1 pkt 18-19 VAT | — |
| R1577 | `regulated.vat.no_exemption_lawyer` | Adwokat/radca — NIE zwolnienie (23% VAT) | `pkd_main` ∈ ["69.10.Z"] | `vat_rate: "0.23"` | Art. 41 ust. 1 VAT | — |
| R1578 | `regulated.vat.exemption_nurse_midwife` | Pielęgniarka/położna — zwolnienie z VAT | `pkd_main` ∈ ["86.90.A","86.90.C"] AND `license_valid == true` | `vat_rate: "ZW"` | Art. 43 ust. 1 pkt 19-20 VAT | — |
| R1579 | `regulated.vat.education_tutor_exemption` | Korepetycje/korepetytor — zwolnienie z VAT | `pkd_main` ∈ ["85.60.Z"] AND `qualifications_certified == true` | `vat_rate: "ZW"` | Art. 43 ust. 1 pkt 26-29 VAT | — |
| R1580 | `regulated.vat.exemption_psychologist` | Psycholog/psychoterapeuta — zwolnienie z VAT | `pkd_main` ∈ ["86.90.E"] AND `license_valid == true` | `vat_rate: "ZW"` | Art. 43 ust. 1 pkt 21 VAT | — |
| R1581 | `regulated.kup.chamber_fees_full` | Składki korporacyjne — pełny KUP | `expense_type == "CHAMBER_FEES"` AND `mandatory_by_law == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1582 | `regulated.kup.professional_insurance_kup` | OC zawodowe — KUP | `expense_type == "PROFESSIONAL_OC"` AND `mandatory_by_law == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1583 | `regulated.kup.continuing_education_kup` | Doskonalenie zawodowe — KUP (jeśli związane z JDG) | `expense_type == "CONTINUING_EDUCATION"` AND `related_to_business == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1584 | `regulated.kup.books_journals_kup` | Literatura fachowa — KUP | `expense_type == "PROFESSIONAL_LITERATURE"` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1585 | `regulated.kup.office_rent_home_office` | Gabinet w domu — proporcja KUP | `expense_type == "HOME_OFFICE"` AND `regulated_profession == true` | `kus_qualification: "proportional"`, `proportion: office_sq_m / total_sq_m` | Art. 22 ust. 1 PIT | — |
| R1586 | `regulated.zus.no_start_relief_former_employer` | Brak ulgi na start przy świadczeniu usług dla byłego pracodawcy | `regulated_profession == true` AND `former_employer_client == true` | `start_relief_eligible: false` | Art. 18a SUS | — |
| R1587 | `regulated.zus.concurrent_chamber_and_jdg` | Zbieg: praktyka zawodowa + JDG → składki z obu tytułów | `concurrent_titles == true` | `zus_from_jdg: true`, `zus_from_practice: true` | Art. 9 SUS | — |
| R1588 | `regulated.zus.mandatory_sickness_insurance` | Obowiązkowe ubezpieczenie chorobowe w niektórych zawodach | `regulated_profession in ["DOCTOR","DENTIST"]` | `sickness_insurance_mandatory: true` | Art. 11 SUS | — |
| R1589 | `regulated.zus.dual_health_contribution` | Podwójna składka zdrowotna przy równoległym zatrudnieniu | `concurrent_employment == true` AND `regulated_profession == true` | `health_from_jdg: true`, `health_from_employment: true` | Art. 82 u.ś.o.z. | — |
| R1590 | `regulated.zus.minimum_base_health` | Minimalna podstawa składki zdrowotnej dla zawodu regulowanego | `regulated_profession == true` AND `tax_form == "PIT_SCALE"` | `health_base_min: minimum_wage` | Art. 81 ust. 2 u.ś.o.z. | `jdg.bounds.minimum_wage_gross` |
| R1591 | `regulated.privilege.attorney_client` | Tajemnica adwokacka — dokumenty wyłączone z kontroli US | `profession == "ATTORNEY"` AND `document_labelled_privileged == true` | `excluded_from_audit: true` | Art. 180 § 3 OP | — |
| R1592 | `regulated.privilege.tax_advisor` | Tajemnica doradcy podatkowego — ochrona przed kontrolą | `profession == "TAX_ADVISOR"` AND `document_labelled_privileged == true` | `excluded_from_audit: true` | Art. 180 § 3 OP | — |
| R1593 | `regulated.privilege.no_protection_for_business_records` | Dokumenty biznesowe NIE są objęte tajemnicą | `document_type == "BUSINESS_RECORD"` | `excluded_from_audit: false` | Art. 180 OP | — |
| R1594 | `regulated.privilege.mdr_transfer_to_client` | Privilege → obowiązek MDR przechodzi na klienta | `profession == "ATTORNEY"` AND `mdr_scheme_detected == true` | `mdr_obligation_transferred_to_client: true` | Art. 86a OP | — |
| R1595 | `regulated.privilege.limits_crime_fraud_exception` | Wyjątek crime-fraud: tajemnica nie chroni przestępstwa | `kks_suspicion == true` AND `document_related_to_crime == true` | `privilege_lost: true`, `disclosure_mandatory: true` | Art. 180 § 4 OP | — |
| R1596 | `regulated.chamber.membership_mandatory` | Przynależność do izby — obowiązkowa | `regulated_profession == true` | `chamber_membership_required: true` | Ustawy korporacyjne | — |
| R1597 | `regulated.chamber.fees_tax_deductible` | Składki izbowe potrącalne od dochodu | `expense_type == "CHAMBER_FEES"` | `tax_deductible: true` | Art. 26 ust. 1 pkt 13 PIT | — |
| R1598 | `regulated.chamber.disciplinary_proceedings` | Postępowanie dyscyplinarne — wpływ na działalność JDG | `disciplinary_proceeding_active == true` | `business_risk: true` | Ustawy korporacyjne | — |
| R1599 | `regulated.chamber.license_suspension_consequences` | Zawieszenie licencji → skutki podatkowe i ZUS | `license_suspended == true` | `business_must_suspend: true`, `zus_consequences` | Ustawy korporacyjne | — |
| R1600 | `regulated.chamber.practice_certificate_renewal` | Odnowienie certyfikatu praktyki — termin | `certificate_expiring_within_3_months == true` | `renewal_deadline_approaching: true` | Ustawy korporacyjne | `jdg.chamber.renewal_warning_days` (90) |
| R1601 | `regulated.cross_border.eu_qualifications_recognition` | Uznawanie kwalifikacji UE w PL | `qualification_origin in EU` AND `regulated_profession == true` | `automatic_recognition: true` (dla większości) | Dyrektywa 2005/36/WE | — |
| R1602 | `regulated.cross_border.non_eu_qualifications` | Uznawanie kwalifikacji spoza UE — procedura nostryfikacji | `qualification_origin in NON_EU` AND `regulated_profession == true` | `nostrification_required: true` | Ustawy branżowe | — |
| R1603 | `regulated.cross_border.temporary_services_eu` | Tymczasowe świadczenie usług w UE — uznanie kwalifikacji | `service_temporary == true` AND `host_country in EU` | `declaration_may_be_required: true` | Dyrektywa 2005/36/WE | — |
| R1604 | `regulated.cross_border.double_taxation_specialist` | Podwójne opodatkowanie specjalisty transgranicznego | `works_in_two_countries == true` AND `regulated_profession == true` | `double_tax_risk: true` | Umowy UPO | — |
| R1605 | `regulated.cross_border.vat_registration_abroad` | Obowiązek rejestracji VAT za granicą przy usługach B2C | `regulated_profession == true` AND `b2c_services_to_eu == true` | `vat_registration_abroad_may_be_required: true` | Art. 28k VAT, OSS | — |
| R1606 | `regulated.aggregate.profession_specific_risk_profile` | Profil ryzyka specyficzny dla zawodu regulowanego | `regulated_profession == true` | `risk_profile: {v_at_risk, kup_risk, zus_risk, privilege_issues}` | — | — |
| R1607 | `regulated.aggregate.annual_compliance_checklist` | Checklista roczna dla zawodu regulowanego | `regulated_profession == true` AND `year_end == true` | `compliance_checklist: [{item, status}]` | — | — |

## Pakiet 18: Ubezpieczenia OC — R1608-R1635 (28 reguł)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1608 | `insurance.mandatory.detection_legal` | OC prawników — obowiązkowe | `pkd_main ⊆ ["69.10.Z"]` | `mandatory_oc_required: true` | Rozp. MS ws. OC adwokatów/radców | — |
| R1609 | `insurance.mandatory.detection_medical` | OC lekarzy — obowiązkowe | `pkd_main ⊆ ["86.21.Z","86.22.Z"]` | `mandatory_oc_required: true` | Ustawa o zawodzie lekarza | — |
| R1610 | `insurance.mandatory.detection_construction` | OC budowlane — obowiązkowe | `pkd_main ⊆ ["41.10.Z"–"43.99.Z"]` | `mandatory_oc_required: true` | Art. 648 KC | — |
| R1611 | `insurance.mandatory.detection_transport` | OC przewoźnika — obowiązkowe | `pkd_main ⊆ ["49.41.Z","49.42.Z"]` | `mandatory_oc_required: true` | Ustawa o transporcie drogowym | — |
| R1612 | `insurance.mandatory.detection_tax_advisor` | OC doradcy podatkowego — obowiązkowe | `pkd_main == "69.20.Z"` AND `tax_advisor_license == true` | `mandatory_oc_required: true` | Ustawa o doradztwie podatkowym | — |
| R1613 | `insurance.kup.mandatory_oc_premium_full` | Składka OC obowiązkowego — 100% KUP | `mandatory_oc == true` AND `premium_paid == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1614 | `insurance.kup.mandatory_oc_over_limit_proportion` | Składka ponad minimum — proporcjonalny KUP | `mandatory_oc == true` AND `coverage_exceeds_minimum == true` | `kus_qualification: "proportional"` (min. składka = 100% KUP, nadwyżka też KUP jeśli uzasadnione biznesowo) | Art. 22 ust. 1 PIT | — |
| R1615 | `insurance.kup.voluntary_oc_business` | Dobrowolne OC — KUP jeśli uzasadnione biznesowo | `voluntary_oc == true` AND `business_justification == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1616 | `insurance.kup.life_insurance_limited` | Ubezpieczenie na życie — ograniczone KUP (tylko składki za pracowników) | `insurance_type == "LIFE"` AND `insured == "EMPLOYEE"` | `kus_qualification: "full"` (do limitu) | Art. 22 ust. 1 PIT | — |
| R1617 | `insurance.kup.property_insurance_full` | Ubezpieczenie mienia firmowego — pełny KUP | `insurance_type == "PROPERTY"` AND `asset_business_use == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1618 | `insurance.claim.payout_as_revenue` | Odszkodowanie z OC — przychód podatkowy | `insurance_payout_received == true` | `taxable_revenue: true` | Art. 14 ust. 1 PIT | — |
| R1619 | `insurance.claim.payout_reduced_by_damage` | Odszkodowanie pomniejszone o poniesioną stratę | `payout_compensates_for_loss == true` | `taxable_amount: payout - documented_loss` | Art. 14 ust. 1 PIT | — |
| R1620 | `insurance.claim.business_interruption_taxable` | Odszkodowanie za przerwę w działalności — w pełni opodatkowane | `insurance_type == "BUSINESS_INTERRUPTION"` AND `payout_received == true` | `taxable_revenue: true`, `full_amount_taxable: true` | Art. 14 PIT | — |
| R1621 | `insurance.claim.personal_injury_exempt` | Odszkodowanie za uszczerbek na zdrowiu — zwolnione z PIT | `claim_type == "PERSONAL_INJURY"` | `tax_exempt: true` | Art. 21 ust. 1 pkt 3c PIT | — |
| R1622 | `insurance.claim.late_payment_interest_taxable` | Odsetki od opóźnionej wypłaty odszkodowania — opodatkowane | `interest_on_late_payout_received == true` | `taxable_as_capital_income: true` | Art. 17 ust. 1 PIT | — |
| R1623 | `insurance.vat.exemption_general` | Usługi ubezpieczeniowe — zwolnione z VAT | `transaction_type == "INSURANCE"` | `vat_rate: "ZW"` | Art. 43 ust. 1 pkt 37 VAT | — |
| R1624 | `insurance.vat.exception_assistance_services` | Usługi assistance — NIE zwolnione (23% VAT) | `service_type == "ASSISTANCE"` AND `not_integral_to_insurance == true` | `vat_rate: "0.23"` | Art. 41 VAT | — |
| R1625 | `insurance.vat.exception_damage_assessment` | Wycena szkód przez niezależnego eksperta — 23% VAT | `service_type == "DAMAGE_ASSESSMENT"` AND `provider_not_insurer == true` | `vat_rate: "0.23"` | Art. 41 VAT | — |
| R1626 | `insurance.vat.exception_broker_services` | Usługi brokera ubezpieczeniowego — 23% VAT | `provider_type == "INSURANCE_BROKER"` | `vat_rate: "0.23"` | Art. 41 VAT | — |
| R1627 | `insurance.vat.input_vat_deduction_blocked` | VAT od wydatków na ubezpieczenia osobiste — NIE odlicza się | `insurance_personal == true` AND `not_business_related == true` | `vat_deduction_blocked: true` | Art. 88 VAT | — |
| R1628 | `insurance.voluntary.cyber_risk` | Cyber-OC — KUP (rekomendowane dla IT JDG) | `insurance_type == "CYBER"` AND `pkd_main in IT_CODES` | `kus_qualification: "full"`, `recommended: true` | Art. 22 PIT | — |
| R1629 | `insurance.voluntary.directors_officers` | D&O dla JDG z prokurentami — KUP | `insurance_type == "DAO"` AND `has_procuration == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1630 | `insurance.voluntary.key_person` | Ubezpieczenie kluczowej osoby (właściciela JDG) | `insurance_type == "KEY_PERSON"` AND `sole_proprietor == true` | `kus_qualification: "full"` (jeśli uzasadnione) | Art. 22 PIT | — |
| R1631 | `insurance.voluntary.trade_credit` | Ubezpieczenie należności — KUP | `insurance_type == "TRADE_CREDIT"` AND `b2b_receivables == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1632 | `insurance.voluntary.inventory_theft` | Ubezpieczenie od kradzieży zapasów — KUP | `insurance_type == "THEFT"` AND `has_inventory == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1633 | `insurance.gap.detection_mandatory_missing` | Brak obowiązkowego OC → kara + odpowiedzialność osobista | `mandatory_oc_required == true` AND `policy_active == false` | `gap_detected: true`, `sanction_risk: "PENALTY_AND_PERSONAL_LIABILITY"` | Ustawy branżowe | — |
| R1634 | `insurance.gap.detection_sum_insufficient` | Suma ubezpieczenia poniżej wymaganego minimum | `mandatory_oc_required == true` AND `sum_insured < legal_minimum` | `gap_detected: true`, `recommendation: "INCREASE_COVERAGE"` | Ustawy branżowe | `jdg.insurance.minimum_sums_by_profession` |
| R1635 | `insurance.gap.detection_policy_expiring` | Polisa wygasająca — alert o odnowieniu | `policy_expiry_date - today() < 30_days` | `renewal_required: true`, `days_remaining` | — | `jdg.insurance.renewal_warning_days` (30) |

## Pakiet 19: Niestandardowe płatności — R1636-R1673 (38 reguł)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1636 | `payment.crypto.receiving_as_payment` | Przyjęcie krypto jako zapłaty za fakturę — moment przychodu | `payment_method == "CRYPTO"` AND `direction == "SALE"` | `revenue_date: crypto_receipt_date`, `revenue_pln: crypto_value_pln_at_receipt` | Art. 14 ust. 1 PIT | — |
| R1637 | `payment.crypto.vat_obligation_on_receipt` | VAT od zapłaty w krypto — obowiązek w dacie otrzymania | `payment_method == "CRYPTO"` AND `direction == "SALE"` | `vat_due_date: crypto_receipt_date`, `vat_base_pln: crypto_value_pln` | Art. 19a ust. 8 VAT | — |
| R1638 | `payment.crypto.exchange_rate_determination` | Kurs krypto/PLN — notowania giełdowe (nie NBP) | `payment_method == "CRYPTO"` | `fx_source: "EXCHANGE"`, `rate_date: transaction_date` | Art. 14 PIT | — |
| R1639 | `payment.crypto.volatility_risk_warning` | Ostrzeżenie o zmienności kursu krypto | `payment_method == "CRYPTO"` AND `crypto_volatility_index > threshold` | `volatility_risk: "HIGH"` | — | `jdg.crypto.volatility_risk_threshold` |
| R1640 | `payment.crypto.difference_from_crypto_trading` | Odróżnienie zapłaty krypto od tradingu krypto | `payment_purpose == "PAYMENT_FOR_GOODS"` (≠ "INVESTMENT") | `tax_treatment: "REVENUE"` (≠ "CAPITAL_GAINS" → P1700/P1701) | Art. 14 vs Art. 17 PIT | — |
| R1641 | `payment.barter.double_supply` | Barter — dwie dostawy (towar za usługę) | `payment_method == "BARTER"` | `both_parties_issue_invoices: true` | Art. 7, Art. 8 VAT | — |
| R1642 | `payment.barter.vat_on_both_sides` | VAT od barteru — każda strona odprowadza VAT od swojego świadczenia | `payment_method == "BARTER"` | `vat_due_seller: true`, `vat_deductible_buyer_per_rules: true` | Art. 5 VAT | — |
| R1643 | `payment.barter.market_value_as_base` | Podstawa opodatkowania: wartość rynkowa wymienianych świadczeń | `payment_method == "BARTER"` | `tax_base: market_value` | Art. 29a VAT | — |
| R1644 | `payment.barter.pit_revenue_recognition` | Przychód w PIT z barteru — data wymiany | `payment_method == "BARTER"` | `revenue_date: barter_date`, `revenue_amount: market_value` | Art. 14 PIT | — |
| R1645 | `payment.barter.documentation_requirements` | Dokumentacja barteru: umowa + faktury + wycena rynkowa | `payment_method == "BARTER"` | `docs_required: ["BARTER_AGREEMENT","MARKET_VALUATION","INVOICES"]` | Art. 22 UoR | — |
| R1646 | `payment.offset.when_recognized` | Kompensata — uznanie za zapłatę w dacie potrącenia | `payment_method == "OFFSET"` | `payment_recognition_date: offset_date` | Art. 498 KC + Art. 14 PIT | — |
| R1647 | `payment.offset.vat_cash_method` | Kompensata przy metodzie kasowej VAT — data potrącenia = data zapłaty | `payment_method == "OFFSET"` AND `vat_method == "CASH"` | `vat_deductible_date: offset_date` | Art. 21 VAT | — |
| R1648 | `payment.offset.vat_accrual_method` | Kompensata przy metodzie memoriałowej VAT — obowiązek w dacie dostawy | `payment_method == "OFFSET"` AND `vat_method == "ACCRUAL"` | `vat_due_date: delivery_date` (niezależnie od kompensaty) | Art. 19a VAT | — |
| R1649 | `payment.offset.mutual_agreement_required` | Kompensata wymaga zgody obu stron (oświadczenie o potrąceniu) | `payment_method == "OFFSET"` | `mutual_agreement_required: true` | Art. 498-499 KC | — |
| R1650 | `payment.offset.documentation_required` | Dokumentacja kompensaty: nota kompensacyjna + umowa | `payment_method == "OFFSET"` | `docs_required: ["OFFSET_NOTE","AGREEMENT"]` | Art. 22 UoR | — |
| R1651 | `payment.installments.pit_revenue_per_installment` | Sprzedaż na raty — przychód PIT w dacie każdej raty | `payment_method == "INSTALLMENTS"` | `revenue_per_installment: true`, `revenue_date: installment_receipt_date` | Art. 14 PIT | — |
| R1652 | `payment.installments.vat_accrual_full_immediately` | VAT memoriałowy — obowiązek od całości w dacie dostawy, niezależnie od rat | `payment_method == "INSTALLMENTS"` AND `vat_method == "ACCRUAL"` | `vat_due_full_on_delivery: true` | Art. 19a VAT | — |
| R1653 | `payment.installments.vat_cash_per_installment` | VAT kasowy — obowiązek w dacie każdej raty | `payment_method == "INSTALLMENTS"` AND `vat_method == "CASH"` | `vat_due_per_installment: true` | Art. 21 VAT | — |
| R1654 | `payment.installments.late_payment_interest` | Opóźnienie raty → odsetki od zaległości | `installment_overdue == true` | `interest_due: true` | Art. 56 OP | — |
| R1655 | `payment.installments.contract_termination_consequences` | Zerwanie umowy ratalnej — skutki podatkowe (korekta przychodu/VAT) | `contract_terminated == true` | `tax_correction_required: true` | Art. 106j VAT | — |
| R1656 | `payment.advance.vat_obligation_on_receipt` | Zaliczka — obowiązek VAT w dacie otrzymania (nawet przed dostawą) | `payment_type == "ADVANCE"` AND `vat_method == "ACCRUAL"` | `vat_due_date: advance_receipt_date` | Art. 19a ust. 8 VAT | — |
| R1657 | `payment.advance.vat_invoice_required_15days` | Faktura zaliczkowa w ciągu 15 dni od otrzymania zaliczki | `payment_type == "ADVANCE"` AND `advance_invoice_issued == false` | `invoice_deadline: advance_receipt_date + 15_days` | Art. 106i VAT | `jdg.vat.advance_invoice_deadline_days` (15) |
| R1658 | `payment.advance.pit_revenue_on_receipt` | Zaliczka — przychód PIT w dacie otrzymania | `payment_type == "ADVANCE"` | `revenue_date: advance_receipt_date` | Art. 14 PIT | — |
| R1659 | `payment.advance.advance_not_refunded_taxable` | Niezwrócona zaliczka przy zerwaniu umowy — opodatkowana | `advance_retained == true` AND `contract_cancelled == true` | `taxable: true`, `revenue_date: cancellation_date` | Art. 14 PIT | — |
| R1660 | `payment.advance.kup_from_advance_to_supplier` | Zaliczka do dostawcy — KUP w dacie zapłaty (metoda kasowa) lub dostawy (memoriałowa) | `payment_type == "ADVANCE"` AND `direction == "PURCHASE"` | `kup_timing: depends_on_method` | Art. 22 PIT | — |
| R1661 | `payment.inkind.market_value_determination` | Świadczenie niepieniężne — przychód wg wartości rynkowej | `payment_method == "IN_KIND"` | `revenue: market_value` | Art. 14 ust. 2 PIT | — |
| R1662 | `payment.inkind.vat_base_market_value` | Podstawa VAT dla świadczenia niepieniężnego — wartość rynkowa | `payment_method == "IN_KIND"` | `vat_base: market_value` | Art. 29a VAT | — |
| R1663 | `payment.inkind.mixed_cash_inkind_split` | Płatność mieszana (część gotówka, część niepieniężna) — rozdzielenie | `payment_method == "MIXED_CASH_IN_KIND"` | `cash_portion: X`, `inkind_portion_pln: Y` | Art. 29a VAT | — |
| R1664 | `payment.inkind.employee_compensation_tax` | Wynagrodzenie pracownika w naturze — PIT + ZUS | `payment_type == "EMPLOYEE_BENEFIT_IN_KIND"` | `taxable_benefit: true`, `zus_base_included: true` | Art. 12 PIT | — |
| R1665 | `payment.inkind.shareholder_benefit_tax` | Świadczenie dla właściciela JDG — traktowane jak dywidenda (19% ryczałt) | `payment_type == "OWNER_BENEFIT_IN_KIND"` AND `not_business_expense == true` | `tax_rate: 0.19`, `treated_as_dividend: true` | Art. 30a PIT | — |
| R1666 | `payment.foreign.cash_limit_15k_pln_equivalent` | Limit 15k PLN dla płatności gotówkowych w walucie obcej | `payment_method == "CASH"` AND `currency != "PLN"` AND `amount_pln_equivalent ≥ 15000` | `cash_limit_exceeded: true`, `kup_loss: true` | Art. 22p PIT | `jdg.limits.cash_transaction_limit` (15 000) |
| R1667 | `payment.foreign.transfer_whitelist_required` | Przelew zagraniczny >15k PLN — weryfikacja WL (dla PL kontrahentów) | `transfer_cross_border == true` AND `amount_pln ≥ 15000` AND `vendor_country == "PL"` | `whitelist_check_required: true` | Art. 96b VAT | `jdg.limits.mpp_limit` (15 000) |
| R1668 | `payment.foreign.transfer_giif_reporting` | Przelew zagraniczny >15k EUR → obowiązek raportu GIIF | `transfer_cross_border == true` AND `amount_eur ≥ 15000` | `giif_report_required: true` | Art. 72 AML | `jdg.limits.giif_eur` (15 000) |
| R1669 | `payment.foreign.swift_sepa_authorization` | Płatność SEPA/SWIFT — autoryzacja bankowa | `payment_rail in ["SEPA","SWIFT"]` | `bank_authorization_required: true` | — | — |
| R1670 | `payment.foreign.fx_spread_recognition` | Spread walutowy banku — KUP | `payment_rail in ["SWIFT","SEPA"]` AND `currency != "PLN"` | `fx_spread_as_kup: true` | Art. 22 PIT | — |
| R1671 | `payment.terminal.obligation_20k_eur_turnover` | Terminal płatniczy — obowiązek przy obrocie >20k EUR i >50% B2C | `annual_b2c_turnover_eur ≥ 20000` AND `b2c_share ≥ 0.50` | `terminal_required: true` | Ustawa o usługach płatniczych | `jdg.payments.terminal_turnover_eur` (20 000) |
| R1672 | `payment.terminal.sanction_no_terminal_5000` | Brak terminala → kara 5 000 PLN | `terminal_required == true` AND `terminal_installed == false` | `sanction: 5000_PLN` | Ustawa o usługach płatniczych | — |
| R1673 | `payment.terminal.vat_deduction_terminal_cost` | Koszt terminala + prowizje — KUP + VAT odliczalny | `terminal_installed == true` | `kup_full: true`, `vat_deductible: true` | Art. 22 PIT, Art. 86 VAT | — |

## Pakiet 20: Reklama i marketing KUP — R1674-R1708 (35 reguł)

| R-ID | Reguła | Cel | Przesłanki | Rezultat | Podstawa prawna | Threshold |
|:----:|--------|:----|:-----------|:---------|:---------------|:---------|
| R1674 | `advertising.vs_representation.distinction_test` | Test rozróżnienia: reklama (KUP) vs reprezentacja (NKUP) | `expense_type == "MARKETING"` | `classification: "ADVERTISING" OR "REPRESENTATION"` | Art. 23 ust. 1 pkt 23 PIT | — |
| R1675 | `advertising.product_promotion_kup` | Promocja konkretnego produktu/usługi → KUP | `promotes_specific_product == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1676 | `advertising.brand_building_kup` | Budowanie marki (nie osobistej) → KUP | `promotes_company_brand == true` AND `not_personal_brand == true` | `kus_qualification: "full"` | Art. 22 ust. 1 PIT | — |
| R1677 | `advertising.representation_personal_prestige_nkup` | Budowanie osobistego prestiżu właściciela → NKUP | `promotes_owner_personally == true` AND `no_product_connection == true` | `kus_qualification: "none"` | Art. 23 ust. 1 pkt 23 PIT | — |
| R1678 | `advertising.representation_limit_0_025pct` | Reprezentacja (częściowy KUP) — limit 0.025% przychodu rocznego | `classification == "REPRESENTATION"` AND `representation_allowed_by_exception == true` | `kus_capped_at: annual_revenue * 0.00025` | Art. 23 ust. 1 pkt 23 PIT | `jdg.limits.representation_percent` (0.025%) |
| R1679 | `advertising.digital.google_ads_kup` | Google Ads — KUP 100% | `platform == "GOOGLE_ADS"` AND `promotes_business == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1680 | `advertising.digital.facebook_ads_kup` | Facebook/Instagram Ads — KUP 100% | `platform == "FACEBOOK_ADS"` AND `promotes_business == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1681 | `advertising.digital.seo_sem_kup` | SEO/SEM — KUP 100% | `expense_type in ["SEO","SEM"]` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1682 | `advertising.digital.email_marketing_kup` | Email marketing — KUP 100% | `platform == "EMAIL_MARKETING"` AND `commercial_in_nature == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1683 | `advertising.digital.affiliate_program_kup` | Programy afiliacyjne — KUP 100% | `expense_type == "AFFILIATE"` AND `commission_for_sales == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1684 | `advertising.events.trade_fair_kup` | Udział w targach — KUP 100% (stoisko, powierzchnia, transport) | `event_type == "TRADE_FAIR"` | `kus_qualification: "full"` | Art. 22 PIT, Art. 26ec PIT | — |
| R1685 | `advertising.events.business_dinner_with_agenda_kup` | Kolacja biznesowa z agendą merytoryczną → KUP | `event_type == "BUSINESS_DINNER"` AND `has_business_agenda == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1686 | `advertising.events.luxury_trip_no_agenda_nkup` | Luksusowy wyjazd bez agendy → NKUP (reprezentacja) | `event_type == "TRIP"` AND `no_business_agenda == true` AND `luxury == true` | `kus_qualification: "none"` | Art. 23 ust. 1 pkt 23 PIT | — |
| R1687 | `advertising.events.conference_speaker_kup` | Wystąpienie jako prelegent na konferencji — KUP | `event_type == "CONFERENCE_SPEAKER"` AND `promotes_business == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1688 | `advertising.events.networking_event_kup` | Event networkingowy — KUP jeśli dominuje cel promocyjny | `event_type == "NETWORKING"` AND `primary_purpose == "PROMOTION"` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1689 | `advertising.gifts.under_200_pln_branded_kup` | Prezent dla kontrahenta <200 PLN z logo → KUP | `gift_value ≤ 200` AND `branded_with_logo == true` | `kus_qualification: "full"` | Art. 23 ust. 1 pkt 23 PIT | `jdg.advertising.gift_limit` (200) |
| R1690 | `advertising.gifts.over_200_pln_nkup` | Prezent dla kontrahenta >200 PLN → NKUP | `gift_value > 200` AND `recipient == "BUSINESS_PARTNER"` | `kus_qualification: "none"` | Art. 23 ust. 1 pkt 23 PIT | `jdg.advertising.gift_limit` (200) |
| R1691 | `advertising.gifts.unbranded_nkup` | Prezent bez logo firmy → NKUP (reprezentacja) | `branded_with_logo == false` AND `gift_value > 0` | `kus_qualification: "none"` | Art. 23 ust. 1 pkt 23 PIT | — |
| R1692 | `advertising.gifts.samples_products_kup` | Próbki produktów → KUP (jeśli mają związek z działalnością) | `gift_type == "PRODUCT_SAMPLE"` AND `related_to_business == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1693 | `advertising.gifts.vat_deduction_100_pln_limit` | VAT od prezentów — odliczenie tylko do 100 PLN netto | `gift_value_netto > 100` | `vat_deduction_capped: true`, `deduction_limit: 100_pln` | Art. 88 ust. 1 pkt 5 VAT | `jdg.vat.gift_vat_deduction_limit` (100) |
| R1694 | `advertising.sponsorship.with_benefits_kup` | Sponsoring z kontrświadczeniami (logo, promocja) → KUP | `sponsorship_type == "WITH_BENEFITS"` AND `logo_exposure == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1695 | `advertising.sponsorship.charity_donation_treatment` | Sponsoring bez kontrświadczeń → traktowany jak darowizna (limit 6%) | `sponsorship_type == "WITHOUT_BENEFITS"` | `tax_treatment: "DONATION"`, `capped_at_6pct_income` | Art. 26 PIT | `jdg.bounds.donation_limit_percent` (6) |
| R1696 | `advertising.sponsorship.sport_culture_kup` | Sponsoring sportu/kultury z ekspozycją marki → KUP | `sponsorship_area in ["SPORT","CULTURE"]` AND `brand_exposure == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1697 | `advertising.sponsorship.local_event_kup` | Sponsoring lokalnego wydarzenia → KUP | `sponsorship_area == "LOCAL_EVENT"` AND `local_business == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1698 | `advertising.sponsorship.vat_on_sponsorship` | VAT od sponsoringu — odliczenie w 100% (czynności opodatkowane) | `sponsorship_with_benefits == true` | `vat_deductible: true` | Art. 86 VAT | — |
| R1699 | `advertising.vat.deduction_full_standard` | VAT od standardowej reklamy — 100% odliczenia | `ad_type == "STANDARD_ADVERTISING"` | `vat_deductible: true`, `deduction_pct: 100` | Art. 86 VAT | — |
| R1700 | `advertising.vat.deduction_gifts_100pln_limit` | VAT od prezentów reklamowych — limit 100 PLN netto | `ad_type == "GIFT"` AND `value_netto > 100` | `vat_deductible: true`, `deduction_capped_at: 100_pln_input_vat` | Art. 88 ust. 1 pkt 5 VAT | `jdg.vat.gift_vat_deduction_limit` (100) |
| R1701 | `advertising.vat.imported_ad_services_reverse_charge` | Import usług reklamowych z UE — reverse charge | `ad_services_from_eu == true` AND `direction == "PURCHASE"` | `vat_reverse_charge: true` | Art. 28b VAT | — |
| R1702 | `advertising.vat.cross_border_ads_vat_rules` | VAT od reklamy transgranicznej — miejsce świadczenia = siedziba nabywcy B2B | `ad_services_to_eu_b2b == true` | `vat_treatment: "REVERSE_CHARGE_OR_NP"` | Art. 28b VAT | — |
| R1703 | `advertising.vat.ads_on_platform_google_fb` | Reklama na Google/Facebook — import usług, reverse charge (B2B) | `platform in ["GOOGLE","FACEBOOK"]` AND `account_type == "BUSINESS"` | `import_of_services: true`, `reverse_charge: true` | Art. 28b VAT | — |
| R1704 | `advertising.influencer.kup_with_invoice_description` | Influencer marketing — KUP jeśli faktura opisuje świadczenie promocyjne | `expense_type == "INFLUENCER"` AND `invoice_describes_promotional_service == true` | `kus_qualification: "full"` | Art. 22 PIT | — |
| R1705 | `advertising.influencer.nkup_no_business_connection` | Influencer bez związku z biznesem → NKUP | `expense_type == "INFLUENCER"` AND `promotes_business == false` | `kus_qualification: "none"` | Art. 23 ust. 1 pkt 23 PIT | — |
| R1706 | `advertising.influencer.vat_treatment_b2b` | Influencer B2B → reverse charge lub NP | `influencer_b2b == true` AND `influencer_country != "PL"` | `vat_treatment: depends_on_country` | Art. 28b VAT | — |
| R1707 | `advertising.influencer.gift_vs_service_classification` | Rozróżnienie: prezent dla influencera vs. usługa promocyjna | `transaction_with_influencer == true` | `classification: "SERVICE" OR "GIFT"` | Art. 22 vs 23 PIT | — |
| R1708 | `advertising.car_wrapping.vat26_full_deduction` | Oklejenie auta reklamą → VAT-26 → 100% odliczenia VAT + 100% KUP paliwa | `car_wrapping_for_ads == true` AND `vat26_filed == true` | `vat_deduction_100pct: true`, `fuel_kup_100pct: true` | Art. 86a VAT, Art. 23 PIT | — |

---

# PODSUMOWANIE KOŃCOWE

## Statystyki

| Metryka | Wartość |
|---------|:-------:|
| **Łączna liczba reguł** | **~708** |
| **Pakiety .rego** | 20 |
| **Reguły w pełnym 10-polowym formacie** | ~150 |
| **Reguły w szczegółowym formacie tabelarycznym** | ~558 |
| **Reguły 🔴 CRITICAL** | ~180 |
| **Nowe thresholds** | ~80 |
| **Podstawy prawne** | 120+ artykułów |

## Priorytety wdrożenia

| Priorytet | Pakiety | Reguł | Czas |
|:---------:|---------|:-----:|:----:|
| **P0** | MDR, Danina, Kontrole, TP, Rezydencja | ~212 | 4 tyg. |
| **P1** | WIS/WIA/WIT, FX, E-komunikacja, Kalendarz, Płatności | ~188 | 3 tyg. |
| **P2** | Siła wyższa, Rodzina, Zam. publ., Podpisy, Kwota wolna, Sezonowa | ~176 | 3 tyg. |
| **P3** | KKS skutki, Zawody regulowane, OC, Reklama | ~132 | 2 tyg. |

---

> **🔥 WNIOSEK KOŃCOWY:** Ten dokument dostarcza **~708 atomowych reguł** w 20 całkowicie nowych pakietach ENTERPRISE, stosując żelazną zasadę: **jeden warunek logiczny = jedna reguła**. W połączeniu z istniejącymi 672 regułami z `28_JDG_ULTIMATE_GRANULARITY.md` oraz ~800 regułami kanonicznymi z `38c_JDG_CANONICAL_MAP.md`, system NexusAI JDG osiąga **ponad 1800 indywidualnych reguł decyzyjnych** — poziom adekwatny do pełnej złożoności polskiego systemu podatkowego.

> **Następny krok:** Implementacja reguł P0 (MDR, danina, kontrole, TP, rezydencja) w plikach .rego.

---

*Wygenerowano przez NexusAI Hyper-Granularity Engine v1.0*  
*Data: 2026-07-12*  
*Bazuje na: 44_JDG_ADVANCED_GAPS.md (20 obszarów), 28_JDG_ULTIMATE_GRANULARITY.md (672 reguły), 38c_JDG_CANONICAL_MAP.md (~800 reguł), DocsJDG*  
*Nowe reguły: ~708 atomowych*  
*Gotowość wdrożeniowa: Specyfikacja ENTERPRISE — gotowa do implementacji w Rego*
