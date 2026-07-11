# 🔬 NexusAI Spółka Cywilna — ULTIMATE GAPS: 8 Wysoko Specjalistycznych Obszarów ENTERPRISE v1.0

> **Status:** AUDYT EKSTREMALNY — uzupełnia `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md`, `Plan OPA/SC_EXPANSION_14_AREAS.md` i `Plan OPA/35_SPOLKA_CYWILNA_ADVANCED_GAPS.md`
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md`
> **Cel:** Wypełnienie 17 całkowicie nowych pod-obszarów w 8 kategoriach — poziom absolutnej dojrzałości ENTERPRISE
> **Dokumenty nadrzędne:** `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` (~550 reguł), `Plan OPA/SC_EXPANSION_14_AREAS.md` (~85 reguł), `Plan OPA/35_SPOLKA_CYWILNA_ADVANCED_GAPS.md` (~69 reguł)
> **Nowe reguły:** ~85 | **Nowe pakiety:** 5 (`sc.customs`, `sc.fx`, `sc.factoring`, `sc.derivatives`, `sc.environmental`) | **Rozbudowane pakiety:** 7

---

## 📑 Spis Treści

- [Metodologia — co już jest, a czego naprawdę brakuje](#metodologia)
- [Obszar 1: Podatki i opłaty lokalne — luki](#obszar-1-podatki-i-opłaty-lokalne--luki)
- [Obszar 2: Obrót zagraniczny i dewizowy](#obszar-2-obrót-zagraniczny-i-dewizowy)
- [Obszar 3: Nowe technologie i ochrona danych](#obszar-3-nowe-technologie-i-ochrona-danych)
- [Obszar 4: Specyficzne formy finansowania i zabezpieczeń](#obszar-4-specyficzne-formy-finansowania-i-zabezpieczeń)
- [Obszar 5: Odpowiedzialność i ubezpieczenia](#obszar-5-odpowiedzialność-i-ubezpieczenia)
- [Obszar 6: Obowiązki statystyczne i sprawozdawcze](#obszar-6-obowiązki-statystyczne-i-sprawozdawcze)
- [Obszar 7: Regulacje administracyjne i środowiskowe](#obszar-7-regulacje-administracyjne-i-środowiskowe)
- [Obszar 8: Specyfika zatrudnienia](#obszar-8-specyfika-zatrudnienia)
- [Diagram integracji](#diagram-integracji)
- [Cross-Reference](#cross-reference)

---

## Metodologia

Poniższe 8 obszarów (rozbitych na 17 pod-obszarów) zostało zidentyfikowanych jako **systematycznie pomijane nawet w zaawansowanych systemach ENTERPRISE**. Są to regulacje wyspecjalizowane, często spoza głównego nurtu prawa podatkowego, ale krytyczne dla pełnej zgodności.

**Klucz:** ★ = luka krytyczna, ★★ = absolutnie fundamentalna, [TODO] = potrzebne dodatkowe źródło, ✓ = już pokryte (pomijamy).

---

## Obszar 1: Podatki i opłaty lokalne — luki

> **Już pokryte:** Podatek od nieruchomości (P1194-P1197 w 35_...)
> **Brakuje:** Podatek od środków transportowych, opłata targowa/reklamowa/uzdrowiskowa

### P1256: `sc_transport_tax_liability_sc` ★
- **Cel biznesowy:** Spółka cywilna posiadająca środki transportu (ciężarówki >3.5t, autobusy, ciągniki siodłowe) → podatek od środków transportowych. Stawki zależne od DMC, rodzaju pojazdu, roku produkcji, normy EURO.
- **Przesłanki:**
  - `input.partnership.owns_vehicles == true`
  - `input.partnership.vehicle_type` w `["TRUCK", "BUS", "TRACTOR_UNIT"]`
  - `input.invoice.vehicle_gvw_kg > 3500`
- **Oczekiwany rezultat:**
  - `transport_tax_due: vehicle_count * applicable_rate(gvw, euro_norm, year)`
  - `transport_tax_declaration: "DT-1"` — deklaracja roczna
  - `transport_tax_deadline: "15 lutego"` (deklaracja), raty: 15.02 i 15.09
  - `transport_tax_kup: "FULL"` — podatek jest KUP
- **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych, Art. 8-14
- **Zależności:** Przed P560 (KUP).
- **Przypadki brzegowe:** Pojazd zarejestrowany w trakcie roku → podatek proporcjonalny od 1. dnia miesiąca po rejestracji. Pojazd wyrejestrowany → obowiązek do końca miesiąca wyrejestrowania. Przyczepa → osobna stawka.
- **Priorytet:** 1256

### P1257: `sc_transport_tax_exemptions_sc` ★
- **Cel biznesowy:** Zwolnienia z podatku od środków transportowych — pojazdy zabytkowe, elektryczne, wodorowe, hybrydowe plug-in.
- **Przesłanki:**
  - `input.invoice.vehicle_type` w `["ELECTRIC", "HYDROGEN", "PLUG_IN_HYBRID", "HISTORIC"]`
  - `input.invoice.vehicle_has_exemption_certificate == true`
- **Oczekiwany rezultat:**
  - `transport_tax_rate: 0` — zwolnienie
  - `transport_tax_exemption_type: odpowiedni typ`
  - `_info: "Pojazd ekologiczny/zabytkowy — zwolnienie z podatku"`
- **Podstawa prawna:** Art. 12 ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Hybryda plug-in → zwolnienie tylko jeśli zasięg elektryczny ≥ 50 km.
- **Priorytet:** 1257

### P1258: `sc_market_fee_sc` ★
- **Cel biznesowy:** Spółka prowadząca sprzedaż na targowisku → opłata targowa. Stawka dzienna od m² lub od rodzaju towaru.
- **Przesłanki:**
  - `input.invoice.sales_channel == "MARKETPLACE_PHYSICAL"`
  - Gmina pobiera opłatę targową
- **Oczekiwany rezultat:**
  - `market_fee_due: stall_area_m2 * daily_rate * trading_days`
  - `market_fee_collection: "BY_MUNICIPALITY"` — pobiera gmina, nie US
  - `market_fee_kup: "FULL"` — opłata jest KUP
- **Podstawa prawna:** Art. 15-17 ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Sprzedaż okazjonalna (do 7 dni w roku) → stawka obniżona. Sprzedaż na targowisku stałym vs sezonowym → różne stawki.
- **Priorytet:** 1258

### P1259: `sc_advertising_fee_sc` ★
- **Cel biznesowy:** Opłata reklamowa — spółka umieszczająca reklamy w przestrzeni publicznej (bilbordy, szyldy powyżej limitu). Pobierana przez niektóre gminy.
- **Przesłanki:**
  - `input.invoice.category_code == "OUTDOOR_ADVERTISING"`
  - `input.invoice.ad_area_m2 > input.thresholds.sc.bounds.ad_fee_exempt_area` (zwykle 0 m² — każda reklama płatna)
  - Gmina posiada uchwałę o opłacie reklamowej
- **Oczekiwany rezultat:**
  - `ad_fee_due: ad_area_m2 * daily_rate * display_days`
  - `ad_fee_kup: "FULL"`
  - `_info: "Opłata reklamowa — sprawdź uchwałę gminy"`
- **Podstawa prawna:** Art. 17a-17d ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Szyld informacyjny (nie reklama) → zwolniony. Reklama na własnym budynku → może podlegać.
- **Priorytet:** 1259

### P1260: `sc_spa_fee_sc` ★
- **Cel biznesowy:** Opłata uzdrowiskowa (klimatyczna) — jeśli spółka prowadzi działalność w miejscowości uzdrowiskowej i przyjmuje gości (hotel, pensjonat).
- **Przesłanki:**
  - `input.partnership.location_type == "SPA_TOWN"`
  - `input.partnership.has_guests == true`
  - `input.invoice.guest_stay_days > 0`
- **Oczekiwany rezultat:**
  - `spa_fee_per_guest_per_day: input.thresholds.sc.bounds.spa_fee_rate`
  - `spa_fee_total: guest_count * stay_days * spa_fee_rate`
  - `spa_fee_collector: "PARTNERSHIP"` — spółka pobiera od gości i odprowadza do gminy
  - `spa_fee_kup_for_guest: "FULL"` — KUP dla gościa
- **Podstawa prawna:** Art. 18-19 ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Pobyt służbowy (delegacja) → zwolnienie z opłaty. Dzieci do lat 7 → zwolnione.
- **Priorytet:** 1260

---

## Obszar 2: Obrót zagraniczny i dewizowy

> **Już pokryte:** Akcyza (P1198-P1201), WHT podstawowy (P1232)
> **Brakuje:** Cło, prawo dewizowe, WHT rozszerzony

### P1261: `sc_import_duty_sc` ★★
- **Cel biznesowy:** Import towarów spoza UE — dług celny. Stawka zależna od kodu TARIC, kraju pochodzenia, preferencji celnych. Podstawa: wartość celna (CIF).
- **Przesłanki:**
  - `input.vendor.country NOT IN input.thresholds.sc.eu_countries`
  - `input.invoice.direction == "PURCHASE"` — import
  - `input.invoice.import_declaration_required == true`
- **Oczekiwany rezultat:**
  - `customs_duty_rate: taric_rate(country_of_origin, hs_code)`
  - `customs_duty_base: cif_value_pln`
  - `customs_duty_due: cif_value * customs_duty_rate`
  - `customs_declaration: "SAD"` (Jednolity Dokument Administracyjny)
  - `_warning: "Import spoza UE — cło + VAT importowy"`
- **Podstawa prawna:** Unijny Kodeks Celny (UKC) — Rozporządzenie Parlamentu Europejskiego i Rady (UE) nr 952/2013, Wspólna Taryfa Celna (TARIC)
- **Zależności:** Przed P50 (VAT importowy naliczany od podstawy zawierającej cło).
- **Przypadki brzegowe:** Preferencje celne (kraj FTA) → stawka 0% lub obniżona. Kontyngenty celne → limitowana ilość po stawce preferencyjnej. Wartość celna ≠ wartość faktury (dolicza się transport + ubezpieczenie).
- **Priorytet:** 1261

### P1262: `sc_import_vat_sc` ★★
- **Cel biznesowy:** VAT importowy — podstawa = wartość celna + cło + akcyza (jeśli dotyczy). Płatny na granicy lub w deklaracji VAT.
- **Przesłanki:**
  - `customs_duty_due != null`
  - `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:**
  - `import_vat_base: cif_value + customs_duty + excise_if_applicable`
  - `import_vat_due: import_vat_base * applicable_vat_rate`
  - `import_vat_deductible: "IMMEDIATE"` — odliczenie w tym samym JPK co należny
  - `import_vat_settlement: "VIA_CUSTOMS_OR_JPK"` — opcja uproszczona (art. 33a VAT)
- **Podstawa prawna:** Art. 30a, Art. 33a VAT
- **Przypadki brzegowe:** Uproszczenie Art. 33a → VAT importowy w deklaracji (nie na granicy). Spółka bez VAT → VAT importowy płatny na granicy, nieodliczalny.
- **Priorytet:** 1262

### P1263: `sc_customs_simplified_procedure_sc` ★
- **Cel biznesowy:** Procedury uproszczone celne — zgłoszenie uproszczone (art. 166 UKC), wpis do rejestru zgłaszającego, procedura w miejscu (AEO).
- **Przesłanki:**
  - `input.partnership.has_aeo_certificate == true` LUB `input.partnership.has_simplified_declaration_permit == true`
  - Import spoza UE
- **Oczekiwany rezultat:**
  - `customs_procedure: "SIMPLIFIED"`
  - `customs_declaration_type: "SIMPLIFIED_SAD"` — zgłoszenie uproszczone
  - `customs_supplementary_declaration_due: "4th_business_day_of_next_week"` — deklaracja uzupełniająca
  - `customs_guarantee_required: true` — zabezpieczenie celne
- **Podstawa prawna:** Art. 166-167, Art. 182 UKC, Art. 38-39 UKC (AEO)
- **Przypadki brzegowe:** AEO → mniej kontroli, szybsza odprawa. Procedura w miejscu → odprawa w siedzibie firmy, nie na granicy.
- **Priorytet:** 1263

### P1264: `sc_fx_law_reporting_pu1_sc` ★
- **Cel biznesowy:** Prawo dewizowe — raportowanie do NBP transakcji z nierezydentami powyżej określonych progów. Formularz PU-1 (płatności).
- **Przesłanki:**
  - `input.vendor.tax_residence != "PL"` — kontrahent zagraniczny
  - `input.invoice.amount_pln > input.thresholds.sc.bounds.fx_reporting_threshold` (domyślnie: 500 000 PLN)
  - `input.invoice.is_bank_transfer == true`
- **Oczekiwany rezultat:**
  - `fx_report_required: true`
  - `fx_report_form: "PU-1"` — płatności zagraniczne
  - `fx_report_deadline: "15. dnia miesiąca po transakcji"`
  - `_warning: "Transakcja z nierezydentem >500k PLN — obowiązek raportowania NBP"`
- **Podstawa prawna:** Art. 15, 21 Prawa dewizowego (tekst jednolity: Dz.U. 2025 poz. 345), Rozporządzenie MF w sprawie sprawozdawczości dewizowej
- **Przypadki brzegowe:** Próg to 500k PLN POJEDYNCZA transakcja. Transakcje poniżej progu → dobrowolne. Niewypełnienie → kara do 50 000 PLN.
- **Priorytet:** 1264

### P1265: `sc_fx_law_reporting_pu2_sc` ★
- **Cel biznesowy:** Formularz PU-2 — raportowanie należności i zobowiązań wobec nierezydentów (stan na koniec okresu).
- **Przesłanki:**
  - `input.partnership.has_foreign_receivables == true` LUB `input.partnership.has_foreign_payables == true`
  - Koniec kwartału
- **Oczekiwany rezultat:**
  - `fx_report_form: "PU-2"` — należności/zobowiązania
  - `fx_report_frequency: "QUARTERLY"`
  - `fx_report_deadline: "20. dnia po zakończeniu kwartału"`
  - `fx_report_content: per_country_breakdown`
- **Podstawa prawna:** Prawo dewizowe, Rozporządzenie MF
- **Przypadki brzegowe:** Tylko transakcje handlowe (usługi, towary) — nie dotyczy pożyczek (osobny próg).
- **Priorytet:** 1265

### P1266: `sc_wht_royalties_license_sc` ★
- **Cel biznesowy:** Rozszerzenie WHT — opłaty licencyjne, prawa autorskie, znaki towarowe wypłacane nierezydentom. Stawka 20% (lub UPO).
- **Przesłanki:**
  - `input.invoice.category_code` w `["ROYALTIES", "LICENSE_FEES", "TRADEMARK", "PATENT"]`
  - `input.vendor.tax_residence != "PL"`
  - `input.invoice.direction == "PURCHASE"` — spółka płaci licencję
- **Oczekiwany rezultat:**
  - `wht_rate: 20%` (lub stawka UPO, zwykle 5-10%)
  - `wht_due: gross_amount * wht_rate` (lub gross-up jeśli umowa net-of-tax)
  - `wht_declaration: "IFT-2R"`
  - `_warning: "Opłaty licencyjne dla nierezydenta — WHT"`
- **Podstawa prawna:** Art. 29 ust. 1 PIT, Art. 21 ust. 1 CIT (odpowiednio), Umowy UPO
- **Przypadki brzegowe:** Dyrektywa Interest-Royalty → stawka 0% między podmiotami powiązanymi w UE (warunki: min. 25% udziałów, min. 2 lata).
- **Priorytet:** 1266

### P1267: `sc_wht_dividend_constructive_sc` ★
- **Cel biznesowy:** Ukryta dywidenda — nadmierne wynagrodzenie wspólnika-nierezydenta może być przekwalifikowane na dywidendę i opodatkowane WHT 19%.
- **Przesłanki:**
  - `input.invoice.beneficiary_is_partner == true`
  - `p.tax_residence != "PL"`
  - `input.invoice.partner_service_amount > input.thresholds.sc.bounds.arm_s_length_threshold * 1.5` — 150% ceny rynkowej
  - `input.invoice.is_arm_s_length == false`
- **Oczekiwany rezultat:**
  - `constructive_dividend_risk: "HIGH"`
  - `excess_amount: actual_payment - arm_s_length_price`
  - `wht_on_excess: excess_amount * 0.19` — 19% WHT
  - `_warning: "Nadmierne wynagrodzenie nierezydenta — ryzyko ukrytej dywidendy"`
- **Podstawa prawna:** Art. 29 PIT, Art. 22 CIT, Art. 23m PIT (ceny transferowe), Art. 119a OP (GAAR)
- **Przypadki brzegowe:** Analiza porównawcza (benchmarking) → wykazuje cenę rynkową.
- **Priorytet:** 1267

---

## Obszar 3: Nowe technologie i ochrona danych

> **Już pokryte:** Kryptowaluty (P1246-P1250), RODO (P1225-P1229)
> **Brakuje:** Cyberbezpieczeństwo (KSC)

### P1268: `sc_nis2_cybersecurity_sc` ★★
- **Cel biznesowy:** Dyrektywa NIS2 — spółka może być uznana za operatora usług kluczowych (OIK) lub podmiot ważny, jeśli działa w sektorach: energetyka, transport, bankowość, infrastruktura cyfrowa, ochrona zdrowia, IT.
- **Przesłanki:**
  - `input.partnership.sector` w `["ENERGY", "TRANSPORT", "DIGITAL_INFRA", "HEALTH", "IT_SERVICES"]`
  - `input.partnership.employee_count > 50` LUB `input.partnership.revenue_annual > 10_000_000_EUR`
- **Oczekiwany rezultat:**
  - `nis2_applicable: true` — podlega NIS2
  - `nis2_requirements: ["RISK_MANAGEMENT", "INCIDENT_REPORTING", "SUPPLY_CHAIN_SECURITY", "BOARD_OVERSIGHT"]`
  - `nis2_incident_report_deadline: "24h_early_warning + 72h_full_report"`
  - `_warning: "Podlega NIS2 — obowiązki cyberbezpieczeństwa"`
- **Podstawa prawna:** Ustawa o krajowym systemie cyberbezpieczeństwa (nowelizacja NIS2, 2025), Dyrektywa UE 2022/2555
- **Przypadki brzegowe:** Podmiot ważny vs kluczowy → różne poziomy wymogów. Mikroprzedsiębiorca w IT → NIE podlega NIS2.
- **Priorytet:** 1268

### P1269: `sc_nis2_incident_response_sc` ★
- **Cel biznesowy:** Obowiązek zgłaszania incydentów cyberbezpieczeństwa do CSIRT NASK w ciągu 24h (wczesne ostrzeżenie) i 72h (pełny raport).
- **Przesłanki:**
  - `input.partnership.cyber_incident_detected == true`
  - `input.partnership.cyber_incident_severity` w `["SIGNIFICANT", "CRITICAL"]`
  - `input.partnership.cyber_incident_reported == false`
- **Oczekiwany rezultat:**
  - `incident_early_warning_deadline: "24_hours"`
  - `incident_full_report_deadline: "72_hours"`
  - `_routing: "BLOCK_AND_ALERT"` — jeśli niezgłoszone
  - `_warning: "Incydent cyberbezpieczeństwa — obowiązek zgłoszenia CSIRT NASK"`
- **Podstawa prawna:** Art. 12 ustawy o KSC (nowelizacja NIS2)
- **Przypadki brzegowe:** Incydent nieznaczący → nie wymaga zgłoszenia. Atak ransomware na dane kontrahentów → zgłoszenie OBOWIĄZKOWE.
- **Priorytet:** 1269

### P1270: `sc_ict_supply_chain_sc` ★
- **Cel biznesowy:** Zarządzanie ryzykiem łańcucha dostaw ICT — spółka musi weryfikować cyberbezpieczeństwo dostawców IT (chmura, hosting, software).
- **Przesłanki:**
  - `input.invoice.category_code` w `["IT_SERVICES", "CLOUD", "HOSTING", "SOFTWARE"]`
  - `input.invoice.vendor_has_iso27001 == false` AND `input.invoice.vendor_has_soc2 == false`
  - `input.partnership.nis2_applicable == true`
- **Oczekiwany rezultat:**
  - `supplier_risk: "HIGH"`
  - `_warning: "Dostawca IT bez certyfikacji bezpieczeństwa — ryzyko łańcucha dostaw"`
  - `supplier_due_diligence_required: true`
- **Podstawa prawna:** Art. 21 Dyrektywy NIS2, Art. 8 ustawy o KSC
- **Przypadki brzegowe:** AWS/Azure/Google → certyfikowani (ISO 27001, SOC 2). Lokalny hosting bez certyfikacji → ryzyko.
- **Priorytet:** 1270


---

## Obszar 4: Specyficzne formy finansowania i zabezpieczeń

> **Już pokryte:** Leasing (P1241-P1245)
> **Brakuje:** Faktoring, instrumenty pochodne

### P1271: `sc_factoring_full_recourse_sc` ★★
- **Cel biznesowy:** Faktoring pełny (z regresem) — spółka sprzedaje wierzytelność faktorowi, ale nadal odpowiada za niewypłacalność dłużnika. Przychód powstaje w momencie otrzymania środków od faktora, KUP to nominalna wartość wierzytelności.
- **Przesłanki:**
  - `input.invoice.category_code == "FACTORING"`
  - `input.invoice.factoring_type == "FULL_RECOURSE"`
  - `input.invoice.direction == "SALE_OF_RECEIVABLES"` — spółka sprzedaje należność
- **Oczekiwany rezultat:**
  - `revenue_recognition: "ON_FACTOR_PAYMENT"` — przychód gdy faktor przeleje środki
  - `kup_recognition: nominal_value_of_receivable` — KUP = wartość nominalna wierzytelności
  - `factoring_fee_kup: true` — prowizja faktora jest KUP
  - `vat_on_factoring_fee: 23%` — usługa faktoringu podlega VAT
  - `_warning: "Faktoring z regresem — ryzyko niewypłacalności pozostaje po stronie spółki"`
- **Podstawa prawna:** Art. 14 PIT (przychód), Art. 22 PIT (KUP), Art. 5 VAT, Art. 28b VAT
- **Zależności:** Przed P560 (KUP).
- **Przypadki brzegowe:** Jeśli dłużnik nie płaci → faktor żąda zwrotu od spółki (regres). Zwrot faktorowi → korekta przychodu. Faktoring cichy (bez cesji) → inny reżim.
- **Priorytet:** 1271

### P1272: `sc_factoring_non_recourse_sc` ★
- **Cel biznesowy:** Faktoring niepełny (bez regresu) — faktor przejmuje ryzyko niewypłacalności. Przychód w momencie cesji wierzytelności.
- **Przesłanki:**
  - `input.invoice.category_code == "FACTORING"`
  - `input.invoice.factoring_type == "NON_RECOURSE"`
- **Oczekiwany rezultat:**
  - `revenue_recognition: "ON_ASSIGNMENT"` — przychód w dniu cesji
  - `revenue_amount: factor_payment`
  - `kup_amount: nominal_value_of_receivable`
  - `gain_loss_on_sale: factor_payment - nominal_value` (zwykle strata = prowizja)
  - `vat_on_factoring_fee: 23%`
  - `_info: "Faktoring bez regresu — ryzyko niewypłacalności przechodzi na faktora"`
- **Podstawa prawna:** Art. 14 PIT, Art. 22 PIT, Art. 509-518 KC (cesja wierzytelności)
- **Przypadki brzegowe:** Strata na sprzedaży wierzytelności → KUP (bo to cena rynkowa). Sprzedaż wierzytelności przeterminowanej → ulga na złe długi (P170-P175).
- **Priorytet:** 1272

### P1273: `sc_factoring_vat_impact_sc` ★
- **Cel biznesowy:** Cesja wierzytelności własnych NIE podlega VAT (czynność neutralna). Ale usługa faktoringu (prowizja) podlega VAT 23%.
- **Przesłanki:**
  - `input.invoice.category_code == "FACTORING"`
  - `input.invoice.factoring_service == "ASSIGNMENT"` — sama cesja
- **Oczekiwany rezultat:**
  - `vat_on_receivable_sale: "EXEMPT"` — cesja wierzytelności wyłączona z VAT
  - `vat_on_factoring_fee: "0.23"` — prowizja faktora podlega VAT 23%
  - `vat_deductible_for_partnership: true` — VAT od prowizji podlega odliczeniu
- **Podstawa prawna:** Art. 6 pkt 1 VAT (wyłączenie z VAT — transakcje dotyczące wierzytelności), Art. 43 VAT
- **Przypadki brzegowe:** Faktoring odwrotny (spółka płaci faktury kontrahentów przez faktora) → inna usługa (finansowanie).
- **Priorytet:** 1273

### P1274: `sc_fx_forward_valuation_sc` ★
- **Cel biznesowy:** Spółka zawiera kontrakt forward walutowy (zabezpieczenie kursu) — wycena na dzień bilansowy i skutki podatkowe.
- **Przesłanki:**
  - `input.invoice.category_code == "FX_FORWARD"` — kontrakt forward
  - `input.partnership.accounting_method == "FULL"` — pełna księgowość
  - Koniec okresu sprawozdawczego
- **Oczekiwany rezultat:**
  - `forward_mtm_valuation: (forward_rate - spot_rate) * notional_amount`
  - `forward_mtm_positive -> unrealized_gain: mtm_value` (rozliczenia międzyokresowe)
  - `forward_mtm_negative -> unrealized_loss: abs(mtm_value)` (rezerwa)
  - `pit_effect: "NONE"` — niezrealizowany wynik NIE jest podatkowy
  - `pit_effect_on_settlement: realized_gain_loss` — dopiero przy rozliczeniu kontraktu
- **Podstawa prawna:** Art. 28 UoR (wycena), Art. 24c PIT (różnice kursowe — tylko zrealizowane)
- **Zależności:** Przed P806 (różnice kursowe).
- **Przypadki brzegowe:** Kontrakt spekulacyjny (nie hedging) → może podlegać innym zasadom. Opcje walutowe → analogiczna wycena (Black-Scholes).
- **Priorytet:** 1274

### P1275: `sc_fx_option_hedge_accounting_sc` ★
- **Cel biznesowy:** Spółka stosuje rachunkowość zabezpieczeń (hedge accounting) dla opcji walutowych — inny moment ujęcia w rachunku zysków i strat.
- **Przesłanki:**
  - `input.invoice.category_code == "FX_OPTION"`
  - `input.invoice.hedge_designated == true` — powiązanie z pozycją zabezpieczaną
  - `input.partnership.hedge_accounting_applied == true`
- **Oczekiwany rezultat:**
  - `option_valuation: fair_value`
  - `effective_portion: "TO_OTHER_COMPREHENSIVE_INCOME"` — skuteczna część do kapitałów
  - `ineffective_portion: "TO_PL"` — nieskuteczna część do RZiS
  - `pit_effect: "ON_SETTLEMENT"` — podatkowo tylko zrealizowane
  - `_info: "Rachunkowość zabezpieczeń — różne momenty ujęcia bilansowego i podatkowego"`
- **Podstawa prawna:** Art. 28 UoR, Rozporządzenie MF o instrumentach finansowych, Art. 24c PIT
- **Przypadki brzegowe:** Hedge accounting wymaga formalnej dokumentacji. Brak dokumentacji → full fair value through P&L.
- **Priorytet:** 1275

### P1276: `sc_derivatives_disclosure_sc` ★
- **Cel biznesowy:** Obowiązek ujawnienia instrumentów pochodnych w sprawozdaniu finansowym (wartość godziwa, ryzyko, polityka).
- **Przesłanki:**
  - `input.partnership.has_derivatives == true`
  - `input.partnership.accounting_method == "FULL"`
  - Koniec roku obrotowego
- **Oczekiwany rezultat:**
  - `derivatives_disclosure: ["FAIR_VALUE", "RISK_MANAGEMENT_POLICY", "SENSITIVITY_ANALYSIS"]`
  - `disclosure_in_financial_statements: "ADDITIONAL_NOTES"`
  - `_warning: "Instrumenty pochodne wymagają ujawnienia w informacji dodatkowej"`
- **Podstawa prawna:** Art. 28 UoR, KSR nr 5, MSSF 7 (jeśli dotyczy)
- **Przypadki brzegowe:** Poniżej progu istotności → uproszczone ujawnienia.
- **Priorytet:** 1276

---

## Obszar 5: Odpowiedzialność i ubezpieczenia

> **Już pokryte:** Upadłość konsumencka (P1251-P1255)
> **Brakuje:** Ubezpieczenia gospodarcze, odpowiedzialność za produkt/rękojmia

### P1277: `sc_insurance_business_liability_sc` ★
- **Cel biznesowy:** Składki OC zawodowego / OC działalności — KUP dla spółki. Odszkodowanie otrzymane → przychód. Odszkodowanie wypłacone → KUP (jeśli związane z działalnością).
- **Przesłanki:**
  - `input.invoice.category_code` w `["INSURANCE_LIABILITY", "INSURANCE_PROPERTY"]`
  - `input.invoice.direction == "PURCHASE"` — spółka kupuje ubezpieczenie
- **Oczekiwany rezultat:**
  - `insurance_premium_kup: "FULL"` — składka ubezpieczeniowa jest KUP
  - `insurance_premium_vat: "EXEMPT"` — ubezpieczenia zwolnione z VAT
  - `insurance_premium_allocation: "SPREAD_OVER_PERIOD"` — rozliczenie w czasie (jeśli polisa roczna)
- **Podstawa prawna:** Art. 22 ust. 1 PIT (KUP), Art. 43 ust. 1 pkt 37 VAT (zwolnienie z VAT)
- **Zależności:** Przed P560 (KUP).
- **Przypadki brzegowe:** Ubezpieczenie OC zawodowe adwokata/lekarza-wspólnika → KUP spółki. Ubezpieczenie na życie wspólnika → NKUP (cel prywatny).
- **Priorytet:** 1277

### P1278: `sc_insurance_claim_sc` ★
- **Cel biznesowy:** Otrzymane odszkodowanie z ubezpieczenia — przychód podatkowy (lub zmniejszenie straty). VAT: odszkodowanie za szkodę w mieniu NIE podlega VAT.
- **Przesłanki:**
  - `input.invoice.category_code == "INSURANCE_CLAIM"`
  - `input.invoice.direction == "SALE"` — spółka otrzymuje odszkodowanie
- **Oczekiwany rezultat:**
  - `claim_revenue: odszkodowanie` — przychód podatkowy
  - `claim_vat: "NOT_APPLICABLE"` — odszkodowanie nie podlega VAT
  - `claim_offset: "AGAINST_DAMAGE_COST"` — jeśli odszkodowanie pokrywa szkodę, netto = strata
  - `_info: "Odszkodowanie — przychód, ale kompensuje koszt szkody"`
- **Podstawa prawna:** Art. 14 PIT (przychód), Art. 5 VAT (poza VAT)
- **Przypadki brzegowe:** Odszkodowanie za utracone zyski → przychód bez kosztu (czysty zysk). Odszkodowanie przewyższające szkodę → nadwyżka opodatkowana.
- **Priorytet:** 1278

### P1279: `sc_warranty_provision_sc` ★
- **Cel biznesowy:** Rezerwy na naprawy gwarancyjne i rękojmie — obowiązek dla pełnej księgowości (UoR). PIT: rezerwy NIE są KUP do momentu faktycznej wypłaty.
- **Przesłanki:**
  - `input.invoice.category_code == "WARRANTY_SERVICE"`
  - `input.partnership.has_warranty_obligations == true`
  - `input.partnership.accounting_method == "FULL"`
- **Oczekiwany rezultat:**
  - `warranty_provision: estimated_repair_cost * probability` — rezerwa bilansowa
  - `warranty_provision_pit: "NOT_KUP"` — rezerwa nie jest kosztem podatkowym
  - `warranty_actual_cost_pit: "FULL_KUP"` — faktyczna naprawa gwarancyjna to KUP
  - `warranty_vat_on_repair: 23%` — usługa naprawy podlega VAT
- **Podstawa prawna:** Art. 35d UoR (rezerwy), Art. 22 PIT (KUP — tylko faktycznie poniesione), Art. 5 VAT
- **Przypadki brzegowe:** Przedłużona gwarancja wykupiona przez klienta → przychód rozliczany w czasie.
- **Priorytet:** 1279

### P1280: `sc_product_liability_sc` ★
- **Cel biznesowy:** Odpowiedzialność za produkt niebezpieczny (Art. 449¹-449¹¹ KC) — spółka odpowiada za szkodę wyrządzoną przez wadliwy produkt.
- **Przesłanki:**
  - `input.invoice.category_code == "PRODUCT_LIABILITY_CLAIM"`
  - `input.invoice.product_defect == true`
  - Szkoda na osobie lub mieniu konsumenta
- **Oczekiwany rezultat:**
  - `liability_triggered: true` — spółka odpowiada
  - `damages_kup: "FULL"` — odszkodowanie dla poszkodowanego jest KUP
  - `recourse_to_manufacturer: true` — spółka może żądać regresu od producenta (jeśli nie jest producentem)
  - `joint_partner_liability: true` — solidarna odpowiedzialność wspólników
  - `_warning: "Odpowiedzialność za produkt — solidarna odpowiedzialność wspólników"`
- **Podstawa prawna:** Art. 449¹-449¹¹ KC (odpowiedzialność za produkt niebezpieczny), Art. 864 KC
- **Przypadki brzegowe:** Szkoda na mieniu przedsiębiorcy → NIE podlega pod Art. 449¹ (tylko konsumenci). Przedawnienie: 3 lata od szkody.
- **Priorytet:** 1280

### P1281: `sc_warranty_repair_vat_sc` ★
- **Cel biznesowy:** Nieodpłatna naprawa gwarancyjna → czy podlega VAT? TAK — przekazanie towarów/usług na cele gwarancyjne to odpłatna dostawa (podstawa = koszt wytworzenia).
- **Przesłanki:**
  - `input.invoice.category_code == "WARRANTY_REPAIR"`
  - `input.invoice.charged_to_customer == false` — bezpłatna naprawa
  - `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:**
  - `vat_due: true` — nieodpłatna naprawa podlega VAT
  - `vat_base: cost_of_repair_parts_and_labor` — koszt wytworzenia
  - `vat_rate: normalna stawka`
  - `_warning: "Nieodpłatna naprawa gwarancyjna — podlega VAT od kosztu wytworzenia"`
- **Podstawa prawna:** Art. 7 ust. 2, Art. 8 ust. 2 VAT (nieodpłatne przekazanie towarów/usług)
- **Przypadki brzegowe:** Naprawa w ramach rękojmi (nie gwarancji) → również podlega VAT. Części zużyte do naprawy gwarancyjnej → VAT od ich wartości.
- **Priorytet:** 1281

---

## Obszar 6: Obowiązki statystyczne i sprawozdawcze

> **Już pokryte:** BRAK — to całkowicie nowy obszar
> **Nowe reguły:** P1282-P1289

### P1282: `sc_gus_sp_report_sc` ★
- **Cel biznesowy:** Sprawozdanie statystyczne GUS SP — roczna ankieta przedsiębiorstwa. Obowiązek dla spółek >9 pracowników.
- **Przesłanki:**
  - `input.partnership.employee_count >= 10`
  - Rok sprawozdawczy zakończony
  - `input.partnership.gus_sp_reported == false`
- **Oczekiwany rezultat:**
  - `gus_sp_required: true`
  - `gus_sp_form: "SP"` — roczne sprawozdanie o działalności przedsiębiorstwa
  - `gus_sp_deadline: "31 marca"` (lub wg wezwania GUS)
  - `_warning: "Brak sprawozdania GUS SP — kara grzywny do 50 000 PLN"`
- **Podstawa prawna:** Ustawa o statystyce publicznej, Program Badań Statystycznych
- **Przypadki brzegowe:** Dla mikroprzedsiębiorstw (<10 pracowników) → badanie reprezentacyjne (tylko wylosowani). Sprawozdanie przez portal sprawozdawczy GUS.
- **Priorytet:** 1282

### P1283: `sc_gus_f01_sc` ★
- **Cel biznesowy:** Sprawozdanie F-01 — kwartalne sprawozdanie o przychodach, kosztach i wyniku finansowym. Obowiązek dla spółek >49 pracowników.
- **Przesłanki:**
  - `input.partnership.employee_count >= 50`
  - Koniec kwartału
- **Oczekiwany rezultat:**
  - `gus_f01_required: true`
  - `gus_f01_frequency: "QUARTERLY"`
  - `gus_f01_deadline: "25. dnia po kwartale"`
- **Podstawa prawna:** Ustawa o statystyce publicznej, PBSSP
- **Przypadki brzegowe:** F-01/I za I kwartał, F-02 za I półrocze (skumulowane).
- **Priorytet:** 1283

### P1284: `sc_nbp_bop_reporting_sc` ★
- **Cel biznesowy:** Sprawozdawczość bilansu płatniczego do NBP — jeśli spółka ma transakcje zagraniczne. Formularz BP. [TODO: potrzebne źródło — szczegółowe progi NBP]
- **Przesłanki:**
  - `input.partnership.has_foreign_transactions == true`
  - `input.partnership.foreign_transaction_volume > input.thresholds.sc.bounds.nbp_bop_threshold`
- **Oczekiwany rezultat:**
  - `nbp_bop_report_required: true`
  - `nbp_bop_frequency: "MONTHLY"` (lub kwartalnie dla mniejszych)
  - `nbp_bop_deadline: "15. dnia miesiąca"`
- **Podstawa prawna:** Prawo dewizowe, Rozporządzenie MF w sprawie sprawozdawczości NBP
- **Przypadki brzegowe:** Eksport usług IT → obowiązek raportowania NBP.
- **Priorytet:** 1284

### P1285: `sc_bdo_registration_sc` ★★
- **Cel biznesowy:** Baza Danych Odpadowych (BDO) — każda spółka wytwarzająca odpady (nawet biurowe!) musi być zarejestrowana w BDO. Obowiązek od 2020 r.
- **Przesłanki:**
  - `input.partnership.generates_waste == true`
  - `input.partnership.bdo_registered == false`
- **Oczekiwany rezultat:**
  - `bdo_registration_required: true`
  - `bdo_registration_number: "XXXXXXXXX"`
  - `bdo_fee_annual: input.thresholds.sc.bounds.bdo_annual_fee` (ok. 100-300 PLN)
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Brak wpisu w BDO — kara do 1 000 000 PLN"`
- **Podstawa prawna:** Ustawa o odpadach, Art. 49-54 (BDO)
- **Przypadki brzegowe:** Odpady komunalne (biurowe) → TAK, wymagany wpis (ale uproszczona ewidencja). Odpady niebezpieczne → ewidencja szczegółowa.
- **Priorytet:** 1285

### P1286: `sc_bdo_waste_record_sc` ★
- **Cel biznesowy:** Ewidencja odpadów w BDO — karta przekazania odpadów (KPO), karta ewidencji odpadów (KEO). Generowanie kodów QR dla transportu.
- **Przesłanki:**
  - `input.invoice.category_code == "WASTE_DISPOSAL"`
  - `input.invoice.waste_code != null` — kod odpadu
  - `input.invoice.bdo_documented == false`
- **Oczekiwany rezultat:**
  - `bdo_kpo_required: true` — karta przekazania odpadów
  - `bdo_qr_code: generated`
  - `bdo_record_deadline: "IMMEDIATE"`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 66-76 ustawy o odpadach
- **Przypadki brzegowe:** Odbiór odpadów od firmy zewnętrznej → KPO generowane przez odbierającego. Spółka jako wytwórca → generuje KPO.
- **Priorytet:** 1286

### P1287: `sc_bdo_annual_report_sc` ★
- **Cel biznesowy:** Roczne sprawozdanie o wytwarzanych odpadach i gospodarowaniu odpadami — składane do 15 marca.
- **Przesłanki:**
  - `input.partnership.bdo_registered == true`
  - Rok kalendarzowy zakończony
- **Oczekiwany rezultat:**
  - `bdo_annual_report_required: true`
  - `bdo_annual_report_deadline: "15 marca"`
  - `bdo_annual_report_content: ["WASTE_TYPES", "WASTE_AMOUNTS", "WASTE_TREATMENT"]`
  - `_warning: "Brak rocznego sprawozdania BDO — kara administracyjna"`
- **Podstawa prawna:** Art. 75 ustawy o odpadach
- **Przypadki brzegowe:** Brak odpadów w danym roku → sprawozdanie zerowe.
- **Priorytet:** 1287

### P1288: `sc_bdo_recycling_fee_sc` ★
- **Cel biznesowy:** Opłata recyklingowa za opakowania — jeśli spółka wprowadza towary w opakowaniach na rynek.
- **Przesłanki:**
  - `input.invoice.category_code == "PACKAGING"`
  - `input.invoice.packaging_weight_kg > 0`
  - `input.partnership.is_packaging_introducer == true`
- **Oczekiwany rezultat:**
  - `recycling_fee_due: packaging_weight * recycling_rate_per_kg`
  - `recycling_obligation: "RECYCLE_OR_PAY_FEE"` — recykling własny lub opłata
  - `_warning: "Opakowania — obowiązek recyklingu lub opłaty produktowej"`
- **Podstawa prawna:** Ustawa o gospodarce opakowaniami i odpadami opakowaniowymi
- **Przypadki brzegowe:** Opakowania wielokrotnego użytku → niższa stawka.
- **Priorytet:** 1288

### P1289: `sc_co2_emission_report_sc` ★
- **Cel biznesowy:** Raportowanie emisji CO2 — obowiązek dla spółek objętych EU ETS (emisje powyżej progu) lub sprawozdawczość niefinansowa ESG (dyrektywa CSRD).
- **Przesłanki:**
  - `input.partnership.annual_co2_tonnes > input.thresholds.sc.bounds.co2_reporting_threshold` (25 000 t dla ETS)
  - `input.partnership.csrd_applicable == true`
- **Oczekiwany rezultat:**
  - `co2_emission_report_required: true`
  - `co2_allowance_purchase: emissions * allowance_price`
  - `co2_allowance_kup: "FULL"` — zakup uprawnień do emisji to KUP
- **Podstawa prawna:** Ustawa o systemie handlu uprawnieniami do emisji gazów cieplarnianych (EU ETS), Dyrektywa CSRD 2022/2464
- **Przypadki brzegowe:** Małe SC rzadko >25k ton CO2 (chyba że produkcja). CSRD dotyczy od 2026 dużych spółek (>250 pracowników).
- **Priorytet:** 1289


---

## Obszar 7: Regulacje administracyjne i środowiskowe

> **Już pokryte:** BRAK — to całkowicie nowy obszar
> **Nowe reguły:** P1290-P1296

### P1290: `sc_construction_permit_sc` ★★
- **Cel biznesowy:** Spółka prowadząca inwestycję budowlaną → obowiązek uzyskania pozwolenia na budowę (lub zgłoszenia) przed rozpoczęciem prac. Koszty budowy bez pozwolenia → NKUP (samowola budowlana).
- **Przesłanki:**
  - `input.invoice.category_code` w `["CONSTRUCTION", "BUILDING_WORKS"]`
  - `input.invoice.construction_permit_required == true`
  - `input.invoice.construction_permit_obtained == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `construction_legal_risk: "SAMOWOLA_BUDOWLANA"`
  - `construction_costs_kup: "NOT_KUP"` — wydatki na samowolę NKUP
  - `_warning: "Brak pozwolenia na budowę — koszty NKUP + ryzyko rozbiórki"`
- **Podstawa prawna:** Art. 28-35 Prawa budowlanego, Art. 48-49b Prawa budowlanego (samowola), Art. 23 PIT (NKUP)
- **Zależności:** Przed P560 (KUP).
- **Przypadki brzegowe:** Zgłoszenie zamiast pozwolenia (Art. 29-30 Pb) → wystarczy zgłoszenie + brak sprzeciwu w ciągu 21 dni. Remont (nie przebudowa) → bez pozwolenia.
- **Priorytet:** 1290

### P1291: `sc_construction_journal_sc` ★
- **Cel biznesowy:** Obowiązek prowadzenia dziennika budowy dla inwestycji wymagających pozwolenia na budowę. Brak dziennika → wstrzymanie budowy.
- **Przesłanki:**
  - `input.invoice.construction_permit_required == true`
  - `input.invoice.construction_journal_established == false`
- **Oczekiwany rezultat:**
  - `construction_journal_required: true`
  - `construction_journal_inspections: ["GEODETIC", "STRUCTURAL", "FINAL"]`
  - `_warning: "Brak dziennika budowy — wstrzymanie robót przez PINB"`
- **Podstawa prawna:** Art. 42-45 Prawa budowlanego
- **Przypadki brzegowe:** Małe obiekty (do 35m²) → nie wymagają dziennika.
- **Priorytet:** 1291

### P1292: `sc_construction_completion_sc` ★
- **Cel biznesowy:** Zakończenie budowy → obowiązek uzyskania pozwolenia na użytkowanie (lub zgłoszenia zakończenia). Bez tego → obiekt nie może być użytkowany ani amortyzowany.
- **Przesłanki:**
  - `input.invoice.category_code == "CONSTRUCTION_COMPLETION"`
  - `input.invoice.occupancy_permit_obtained == false`
- **Oczekiwany rezultat:**
  - `occupancy_permit_required: true`
  - `depreciation_start: "ON_OCCUPANCY_PERMIT"` — amortyzacja dopiero po pozwoleniu na użytkowanie
  - `construction_asset_registration: "AFTER_PERMIT"`
  - `_warning: "Brak pozwolenia na użytkowanie — obiekt nie może być użytkowany"`
- **Podstawa prawna:** Art. 54-59 Prawa budowlanego, Art. 22a PIT (środek trwały — musi być kompletny i zdatny do użytku)
- **Przypadki brzegowe:** Zgłoszenie zakończenia (nie pozwolenie) → dla obiektów nie wymagających pozwolenia na użytkowanie.
- **Priorytet:** 1292

### P1293: `sc_environmental_decision_sc` ★
- **Cel biznesowy:** Decyzja środowiskowa — wymagana dla przedsięwzięć mogących znacząco oddziaływać na środowisko (np. budowa hali >2ha, ferma, zakład przetwórczy).
- **Przesłanki:**
  - `input.invoice.category_code == "ENVIRONMENTAL_INVESTMENT"`
  - `input.invoice.environmental_decision_required == true`
  - `input.invoice.environmental_decision_obtained == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `environmental_decision_mandatory: true`
  - `_warning: "Brak decyzji środowiskowej — inwestycja nie może być realizowana"`
- **Podstawa prawna:** Ustawa o udostępnianiu informacji o środowisku (OOŚ), Art. 71-72
- **Przypadki brzegowe:** Przedsięwzięcia I vs II grupy → różne procedury. II grupa → screening (czy potrzebny pełny OOŚ).
- **Priorytet:** 1293

### P1294: `sc_emission_fee_sc` ★
- **Cel biznesowy:** Opłaty za korzystanie ze środowiska — emisja pyłów, gazów, ścieki, pobór wody. Roczne sprawozdanie do marszałka województwa.
- **Przesłanki:**
  - `input.partnership.emits_pollutants == true`
  - `input.partnership.annual_emission_volume > 0`
- **Oczekiwany rezultat:**
  - `emission_fee_due: emission_volume * rate_per_kg` (stawki z obwieszczenia MŚ)
  - `emission_fee_deadline: "31 marca"` — roczna opłata
  - `emission_fee_kup: "FULL"`
  - `emission_report: "DO MARSZAŁKA WOJEWÓDZTWA"`
- **Podstawa prawna:** Prawo ochrony środowiska, Art. 273-286
- **Przypadki brzegowe:** Opłaty poniżej 800 PLN/rok → nie wnosi się (próg bagatelności).
- **Priorytet:** 1294

### P1295: `sc_water_permitsc` ★
- **Cel biznesowy:** Pozwolenie wodnoprawne — wymagane dla poboru wody >5m³/dobę lub odprowadzania ścieków. Brak → kara + opłata podwyższona 500%.
- **Przesłanki:**
  - `input.partnership.water_usage_m3_per_day > 5`
  - `input.partnership.water_permit_obtained == false`
- **Oczekiwany rezultat:**
  - `water_permit_required: true`
  - `water_fee_elevated: standard_rate * 5` — 500% stawki za brak pozwolenia
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Prawo wodne, Art. 389-397
- **Przypadki brzegowe:** Pobór własny ze studni → też wymaga pozwolenia (powyżej 5m³/d).
- **Priorytet:** 1295

### P1296: `sc_waste_management_plan_sc` ★
- **Cel biznesowy:** Plan gospodarki odpadami — spółki wytwarzające >1 Mg odpadów niebezpiecznych lub >5000 Mg innych → obowiązek posiadania planu.
- **Przesłanki:**
  - `input.partnership.waste_hazardous_tonnes > 1` LUB `input.partnership.waste_other_tonnes > 5000`
  - `input.partnership.waste_management_plan_exists == false`
- **Oczekiwany rezultat:**
  - `waste_management_plan_required: true`
  - `waste_plan_horizon: "5_LAT"`
  - `_warning: "Brak planu gospodarki odpadami — obowiązek dla dużych wytwórców"`
- **Podstawa prawna:** Ustawa o odpadach, Art. 18-19
- **Przypadki brzegowe:** Większość małych SC nie przekracza progów.
- **Priorytet:** 1296

---

## Obszar 8: Specyfika zatrudnienia

> **Już pokryte:** Podstawowe obowiązki pracodawcy (P1202-P1216)
> **Brakuje:** Praca zdalna, delegowanie pracowników za granicę (A1)

### P1297: `sc_remote_work_agreement_sc` ★★
- **Cel biznesowy:** Praca zdalna — wymagana umowa lub porozumienie regulujące warunki (miejsce, BHP, ekwiwalent). Brak → naruszenie KP.
- **Przesłanki:**
  - `input.partnership.has_remote_workers == true`
  - `input.partnership.remote_work_agreement_signed == false`
- **Oczekiwany rezultat:**
  - `remote_work_agreement_required: true`
  - `remote_work_elements: ["WORKPLACE_ADDRESS", "BHP_RULES", "EQUIPMENT", "CONTROL_RULES"]`
  - `_warning: "Praca zdalna bez umowy — naruszenie Kodeksu Pracy"`
- **Podstawa prawna:** Art. 67¹⁸-67³² Kodeksu Pracy (nowelizacja 2023)
- **Zależności:** Przed P1202 (obowiązki pracodawcy).
- **Przypadki brzegowe:** Praca zdalna okazjonalna (do 24 dni/rok) → nie wymaga umowy (wniosek pracownika).
- **Priorytet:** 1297

### P1298: `sc_remote_work_equivalentsc` ★
- **Cel biznesowy:** Ekwiwalent za prąd, internet i inne koszty pracy zdalnej — ryczałt lub zwrot na podstawie faktur. KUP dla spółki, zwolniony z PIT i ZUS dla pracownika.
- **Przesłanki:**
  - `input.invoice.category_code == "REMOTE_WORK_EQUIVALENT"`
  - `input.invoice.remote_work_employee_id != null`
  - `input.invoice.equivalent_amount > 0`
- **Oczekiwany rezultat:**
  - `equivalent_kup: "FULL"` — KUP dla spółki
  - `equivalent_pit_employee: "EXEMPT"` — zwolniony z PIT (do limitu)
  - `equivalent_zus_employee: "EXEMPT"` — nie podlega składkom ZUS
  - `equivalent_limit_monthly: input.thresholds.sc.bounds.remote_work_equivalent_limit` (ok. 200-300 PLN)
- **Podstawa prawna:** Art. 67²⁴-67²⁵ KP, Art. 21 ust. 1 pkt 152a PIT (zwolnienie)
- **Przypadki brzegowe:** Ekwiwalent powyżej limitu → nadwyżka opodatkowana PIT + ZUS. Ryczałt vs refundacja → różne limity.
- **Priorytet:** 1298

### P1299: `sc_remote_work_bhp_sc` ★
- **Cel biznesowy:** Obowiązki BHP przy pracy zdalnej — szkolenie, ocena stanowiska (oświadczenie pracownika), ochrona danych.
- **Przesłanki:**
  - `input.partnership.has_remote_workers == true`
  - `input.partnership.remote_bhp_training_completed == false`
- **Oczekiwany rezultat:**
  - `remote_bhp_required: ["INITIAL_TRAINING", "WORKSTATION_SELF_ASSESSMENT", "ERGONOMICS_INFO"]`
  - `remote_bhp_documentation: "EMPLOYEE_STATEMENT"` — oświadczenie pracownika
  - `_warning: "Brak szkolenia BHP dla pracy zdalnej — ryzyko wypadku"`
- **Podstawa prawna:** Art. 67²¹, 67²³ KP
- **Przypadki brzegowe:** Pracownik musi potwierdzić, że stanowisko spełnia wymogi BHP (oświadczenie).
- **Priorytet:** 1299

### P1300: `sc_a1_delegation_sc` ★★
- **Cel biznesowy:** Delegowanie pracownika za granicę (UE/EFTA) → obowiązek uzyskania formularza A1 (poświadczenie podlegania polskiemu ZUS). Bez A1 → podleganie ZUS kraju wykonywania pracy.
- **Przesłanki:**
  - `input.invoice.category_code == "EMPLOYEE_DELEGATION"`
  - `input.invoice.delegation_country` w `input.thresholds.sc.eu_countries`
  - `input.invoice.delegation_duration_days > 7` (krótkoterminowe delegacje zwolnione)
  - `input.invoice.a1_obtained == false`
- **Oczekiwany rezultat:**
  - `a1_required: true`
  - `a1_application_to: "ZUS"`
  - `a1_validity: max_24_months`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Delegowanie bez A1 — pracownik podlega ZUS za granicą"`
- **Podstawa prawna:** Rozporządzenie Parlamentu Europejskiego i Rady (WE) nr 883/2004, Art. 12 (delegowanie), Rozporządzenie wykonawcze 987/2009
- **Przypadki brzegowe:** Delegowanie do 7 dni → bez A1 (krótkoterminowe). Delegowanie >24 miesiące → ZUS kraju pracy (wyjątek: zgoda na przedłużenie).
- **Priorytet:** 1300

### P1301: `sc_a1_pit_consequences_sc` ★
- **Cel biznesowy:** Delegowanie >183 dni → pracownik staje się rezydentem podatkowym kraju wykonywania pracy. Spółka musi dostosować obowiązki płatnika.
- **Przesłanki:**
  - `input.invoice.delegation_duration_days > 183`
  - `input.invoice.delegation_country` w `input.thresholds.sc.eu_countries`
- **Oczekiwany rezultat:**
  - `employee_tax_residence_change: true` — pracownik rezydentem za granicą
  - `pl_wht_on_salary: 0` — Polska rezygnuje z opodatkowania wynagrodzenia
  - `foreign_tax_obligation: "PAYROLL_IN_HOST_COUNTRY"` — spółka musi rejestrować się jako płatnik za granicą
  - `_warning: "Delegowanie >183 dni — pracownik rezydentem podatkowym za granicą"`
- **Podstawa prawna:** Art. 3 PIT (rezydencja), Art. 15 Umowy Modelowej OECD (artykuł o pracy najemnej), Umowy UPO
- **Przypadki brzegowe:** Praca zdalna z zagranicy (digital nomad) → też może zmienić rezydencję. Split-year treatment → podział roku na część PL i zagraniczną.
- **Priorytet:** 1301

### P1302: `sc_posted_workers_directive_sc` ★
- **Cel biznesowy:** Dyrektywa o pracownikach delegowanych — obowiązek zgłoszenia delegowania do systemu IMI, zapewnienie minimalnych warunków zatrudnienia kraju przyjmującego.
- **Przesłanki:**
  - `input.invoice.category_code == "POSTED_WORKER"` — delegowanie w ramach usługi
  - `input.invoice.posted_worker_country` w `input.thresholds.sc.eu_countries`
  - `input.invoice.imi_notification_sent == false`
- **Oczekiwany rezultat:**
  - `imi_notification_required: true`
  - `host_country_labour_law: "APPLY"` — minimalne warunki kraju przyjmującego
  - `posted_worker_documentation: ["A1", "EMPLOYMENT_CONTRACT", "WORKING_TIME_RECORDS"]`
  - `_warning: "Delegowanie pracowników — obowiązek zgłoszenia IMI + prawo pracy kraju przyjmującego"`
- **Podstawa prawna:** Dyrektywa 2018/957/UE (nowelizacja dyrektywy o pracownikach delegowanych), Ustawa o delegowaniu pracowników
- **Przypadki brzegowe:** Delegowanie w ramach własnej działalności (nie usługi) → inne zasady.
- **Priorytet:** 1302

### P1303: `sc_remote_work_control_sc` ★
- **Cel biznesowy:** Kontrola pracownika zdalnego — spółka ma prawo kontroli (za zgodą), ale z poszanowaniem prywatności. Monitoring IT → zgoda + informacja.
- **Przesłanki:**
  - `input.partnership.remote_monitoring_enabled == true`
  - `input.partnership.employee_monitoring_notice_given == false`
- **Oczekiwany rezultat:**
  - `monitoring_notice_required: true` — pracownik musi być poinformowany
  - `monitoring_scope_limit: "WORK_RELATED_ONLY"` — tylko aktywność zawodowa
  - `gdpr_implications: true` — monitoring to przetwarzanie danych osobowych
  - `_warning: "Monitoring pracy zdalnej bez zgody — naruszenie RODO + KP"`
- **Podstawa prawna:** Art. 67²² KP, Art. 22² KP, Art. 6 RODO
- **Zależności:** Łączy się z P1225-P1229 (RODO).
- **Przypadki brzegowe:** Kamera w domu pracownika → NIEDOZWOLONA. Monitoring aktywności komputera → dozwolony za zgodą.
- **Priorytet:** 1303

---

## Diagram integracji — gdzie nowe reguły wpinają się w łańcuch

```
SC_DEFINITIVE_REGO_PLAN.md + SC_EXPANSION_14_AREAS.md + 35_ADVANCED_GAPS.md
|
+- BLOK 0: RISK
|   +-- P1268-P1270 (NIS2 cybersecurity) [NOWY]
|   +-- P1285-P1288 (BDO waste) [NOWY]
|   +-- P1290-P1293 (construction permits) [NOWY]
|
+- BLOK 3: CROSSBORDER — ROZBUDOWANY
|   +-- P1261-P1263 (customs duty) [NOWY]
|   +-- P1264-P1265 (FX reporting) [NOWY]
|   +-- P1266-P1267 (WHT extended) [NOWY]
|
+- BLOK 6: VAT
|   +-- P1262 (import VAT) [NOWY]
|   +-- P1273 (factoring VAT) [NOWY]
|   +-- P1281 (warranty repair VAT) [NOWY]
|
+- BLOK 12: ULGI / LOCAL TAXES
|   +-- P1256-P1260 (transport tax, market/ad/spa fees) [NOWY]
|
+- BLOK 14: KSIĘGOWOŚĆ — ROZBUDOWANY
|   +-- P1274-P1276 (derivatives) [NOWY]
|   +-- P1279 (warranty provisions) [NOWY]
|
+- BLOK 15: ODPOWIEDZIALNOŚĆ — ROZBUDOWANY
|   +-- P1280 (product liability) [NOWY]
|
+- BLOK 16: PRACODAWCA — ROZBUDOWANY
|   +-- P1297-P1303 (remote work, delegation, A1) [NOWY]
|
+- BLOK 17A: CUSTOMS — NOWY BLOK
|   +-- P1261-P1263 (import duty, import VAT, simplified procedures) [NOWY]
|
+- BLOK 17B: FACTORING — NOWY BLOK
|   +-- P1271-P1273 (full/non-recourse, VAT) [NOWY]
|
+- BLOK 17C: DERIVATIVES — NOWY BLOK
|   +-- P1274-P1276 (forward, option hedge, disclosure) [NOWY]
|
+- BLOK 17D: INSURANCE — NOWY BLOK (zintegrowany z liability)
|   +-- P1277-P1278 (liability insurance, claims) [NOWY]
|
+- BLOK 17E: STATISTICS — NOWY BLOK
|   +-- P1282-P1284 (GUS SP, GUS F-01, NBP BOP) [NOWY]
|
+- BLOK 17F: ENVIRONMENTAL — NOWY BLOK
|   +-- P1285-P1289, P1293-P1296 (BDO, CO2, construction, emission fees, water) [NOWY]
```

---

## Cross-Reference: Nowe reguły → Podstawa prawna

| Reguła | Obszar | Podstawa prawna |
|--------|--------|-----------------|
| P1256-P1257 | Podatek transportowy | Ustawa o podatkach i opłatach lokalnych, Art. 8-14 |
| P1258-P1260 | Opłaty lokalne (targowa/reklamowa/uzdrowiskowa) | Art. 15-19 ustawy o podatkach i opłatach lokalnych |
| P1261-P1263 | Cło i procedury celne | Unijny Kodeks Celny (UKC 952/2013), TARIC, Art. 30a, 33a VAT |
| P1264-P1265 | Prawo dewizowe (PU-1, PU-2) | Prawo dewizowe, Rozporządzenie MF |
| P1266-P1267 | WHT rozszerzone (royalties, ukryta dywidenda) | Art. 29 PIT, Art. 21 CIT, Umowy UPO |
| P1268-P1270 | Cyberbezpieczeństwo NIS2 | Dyrektywa NIS2 2022/2555, Ustawa o KSC |
| P1271-P1273 | Faktoring | Art. 14 PIT, Art. 22 PIT, Art. 6 pkt 1, Art. 43 VAT, Art. 509-518 KC |
| P1274-P1276 | Instrumenty pochodne | Art. 28 UoR, Art. 24c PIT, Rozporządzenie MF o IF |
| P1277-P1278 | Ubezpieczenia gospodarcze | Art. 22 PIT, Art. 14 PIT, Art. 43 VAT |
| P1279-P1281 | Rękojmia / gwarancja / odpowiedzialność za produkt | Art. 35d UoR, Art. 7-8 VAT, Art. 449¹-449¹¹ KC, Art. 864 KC |
| P1282-P1284 | GUS / NBP statystyka | Ustawa o statystyce publicznej, Prawo dewizowe, Rozp. MF |
| P1285-P1288 | BDO (odpady) | Ustawa o odpadach, Art. 49-54, 66-76 |
| P1289 | CO2 / ETS / CSRD | EU ETS, Dyrektywa CSRD 2022/2464 |
| P1290-P1292 | Prawo budowlane | Art. 28-59 Prawa budowlanego, Art. 23 PIT |
| P1293-P1296 | Ochrona środowiska / woda / emisje | Prawo ochrony środowiska, Prawo wodne, OOŚ |
| P1297-P1303 | Praca zdalna / delegowanie / A1 | Art. 67¹⁸-67³² KP, Rozp. 883/2004, Dyrektywa 2018/957 |

---

> **Koniec dokumentu.** Ten plik uzupełnia SC_DEFINITIVE_REGO_PLAN.md, SC_EXPANSION_14_AREAS.md i 35_SPOLKA_CYWILNA_ADVANCED_GAPS.md o 8 ekstremalnie specjalistycznych obszarów.
> **Łącznie nowych reguł:** ~48 szczegółowo opisanych ze wszystkimi elementami.
> **Nowe pakiety:** `sc.customs`, `sc.fx`, `sc.factoring`, `sc.derivatives`, `sc.environmental`.
> **Łączny stan SC po połączeniu:** ~550 (oryginalne) + ~85 (ekspansja 14) + ~69 (advanced gaps) + ~48 (ultimate gaps) = **~752 reguły ENTERPRISE**.
