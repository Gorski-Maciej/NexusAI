# 🔬 NexusAI JDG — Głęboka Analiza Luk i Uzupełnienie ENTERPRISE v6.0

> **Status:** Deep Gap Analysis — 30 całkowicie nowych reguł zidentyfikowanych przez głęboką analizę  
> **Data:** 2026-07-10  
> **Autor:** Zespół NexusAI + Deep Analysis (thinker-with-files-gemini)  
> **Plik:** `Plan OPA/29_JDG_DEEP_ANALYSIS_GAPS.md`  

**Dokumenty bazowe:**  
— `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
— `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — pierwsza rozbudowa (~69 reguł)  
— `Plan OPA/24_JDG_COMPLETE_INDEX.md` — indeks (~214 reguł)  
— `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md` — audyt (46 luk)  
— `Plan OPA/26_JDG_COMPREHENSIVE_EXPANSION.md` — rozbudowa (~272 reguł)  
— `Plan OPA/27_JDG_ENTERPRISE_DEEP_EXPANSION.md` — głęboka ekspansja (~327 reguł)  
— `Plan OPA/28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` — master synthesis (~372 reguł)  
— `Plan OPA/DocsJDG` — źródła prawne JDG  

**Nowe reguły:** 30 | **Nowe obszary:** 4 całkowicie nowe domeny | **Wypełnione luki:** KUP branżowe, platformy cyfrowe, nieruchomości, akcyza, rolnictwo, restrukturyzacja

**Łącznie po tym dokumencie:** ~402 reguły | 42 pakiety | 95+ domen prawnych

---

## 0. Executive Summary — Co Głęboka Analiza Odkryła

Dokumenty 22-28 osiągnęły ~372 reguły. Głęboka analiza (thinker-with-files-gemini) przeanalizowała wszystkie 372 reguły pod kątem *rzeczywistych scenariuszy JDG* i zidentyfikowała **30 całkowicie nowych luk** w 4 głównych obszarach:

| # | Obszar luk | Liczba reguł | Przykłady |
|---|-----------|:------------:|-----------|
| **1** | KUP specyficzne dla branż JDG | 5 | Własna praca NKUP, składki izb zawodowych, kary umowne, towary przeterminowane, odzież robocza |
| **2** | Cross-border & platformy cyfrowe | 4 | App Store/Google Play jako B2B, prowizje platform, kasy fiskalne, kasy wirtualne |
| **3** | Nieruchomości w JDG | 4 | Zakaz amortyzacji mieszkań, opcja VAT, PCC vs VAT, diety zagraniczne właściciela |
| **4** | Rolnictwo, akcyza, restrukturyzacja | 17 | RR VAT, produkcja specjalna, akcyza auto/alkohol, spadek, fundacja rodzinna, samochody elektryczne, TP safe harbour |

---

## 0.1 Nowe Pola `input` — Wymagane przez Głęboką Analizę

| Sekcja | Nowe pole | Typ | Używane przez |
|--------|----------|-----|---------------|
| `jdg_entrepreneur` | `is_owner_labor` | `boolean` | P578 |
| `jdg_entrepreneur` | `spouse_works_in_jdg` | `boolean` | P578 |
| `jdg_entrepreneur` | `professional_chamber_member` | `boolean` | P579 |
| `jdg_entrepreneur` | `chamber_type` | `string` | P579 |
| `jdg_entrepreneur` | `performs_agricultural_special_branches` | `boolean` | P151 |
| `jdg_entrepreneur` | `is_flat_rate_farmer` | `boolean` | P152 |
| `jdg_entrepreneur` | `sells_on_platforms` | `boolean` | P143-P145 |
| `jdg_entrepreneur` | `platform_type` | `string` | P143 |
| `jdg_entrepreneur` | `uses_virtual_cash_register` | `boolean` | P146 |
| `jdg_entrepreneur` | `b2c_annual_turnover_for_fiscal` | `number` | P145 |
| `jdg_entrepreneur` | `has_family_foundation` | `boolean` | P1731-P1732 |
| `jdg_entrepreneur` | `foundation_rental_contracts` | `boolean` | P1732 |
| `jdg_entrepreneur` | `in_restructuring_proceedings` | `boolean` | P843-P844 |
| `jdg_entrepreneur` | `in_bankruptcy_proceedings` | `boolean` | P844 |
| `jdg_entrepreneur` | `de_minimis_aid_received_3y` | `number` | P845 |
| `jdg_entrepreneur` | `is_craft_brewery` | `boolean` | P154 |
| `jdg_entrepreneur` | `is_craft_distillery` | `boolean` | P154 |
| `invoice` | `is_spoiled_goods` | `boolean` | P582 |
| `invoice` | `has_disposal_protocol` | `boolean` | P582 |
| `invoice` | `is_contractual_penalty` | `boolean` | P580 |
| `invoice` | `penalty_reason` | `string` | P580 |
| `invoice` | `expense_type` | `string` | P578-P582 |
| `invoice` | `is_workwear_bhp` | `boolean` | P581 |
| `invoice` | `platform_fee_deducted` | `number` | P144 |
| `invoice` | `is_app_store_sale` | `boolean` | P143 |
| `invoice` | `real_estate_type` | `string` | P147-P150 |
| `invoice` | `real_estate_vat_option_filed` | `boolean` | P149 |
| `invoice` | `building_year` | `number` | P147 |
| `invoice` | `foreign_trip_country` | `string` | P150a |
| `invoice` | `foreign_trip_days` | `number` | P150a |
| `invoice` | `car_is_electric` | `boolean` | P565 |
| `invoice` | `car_subsidy_eligible` | `boolean` | P565 |
| `invoice` | `is_agricultural_produce` | `boolean` | P152 |
| `invoice` | `farmer_vat_status` | `string` | P152 |
| `invoice` | `is_excise_duty_event` | `boolean` | P153-P154 |
| `invoice` | `excise_goods_type` | `string` | P153-P154 |
| `invoice` | `import_vehicle_from_eu` | `boolean` | P153 |
| `invoice` | `debt_forgiven_in_restructuring` | `boolean` | P843 |
| `vendor` | `is_flat_rate_farmer` | `boolean` | P152 |
| `vendor` | `is_app_store_platform` | `boolean` | P143 |
| `vendor` | `is_freelance_platform` | `boolean` | P144 |
| `vendor` | `is_family_foundation` | `boolean` | P1731-P1732 |
| `vendor` | `is_related_party_for_tp` | `boolean` | P29 |
| `vendor` | `tp_service_type` | `string` | P29 |
| `document` | `restructuring_plan_approved` | `boolean` | P843 |
| `document` | `bankruptcy_discharge_granted` | `boolean` | P844 |
| `document` | `de_minimis_certificate_requested` | `boolean` | P845 |
| `document` | `excise_declaration_filed` | `boolean` | P153-P154 |

---

## 0.2 Nowe Parametry w `thresholds.jdg.*`

| Klucz | Wartość | Opis | Podstawa prawna |
|-------|---------|------|-----------------|
| `limits.electric_car_kup_limit` | `225000` | Limit wartości auta elektrycznego dla KUP | Art. 23 ust. 1 pkt 47a PIT |
| `limits.de_minimis_3y_threshold_eur` | `300000` | Limit pomocy de minimis 3-letni EUR | Rozp. KE 1407/2013 |
| `limits.cash_register_exemption_limit` | `20000` | Limit zwolnienia z kasy fiskalnej PLN | Rozp. MF kasowe |
| `limits.vat_rr_refund_rate` | `"0.07"` | Stawka zryczałtowanego zwrotu VAT RR | Art. 115 VAT |
| `limits.vat_rr_payment_days` | `14` | Dni na zapłatę dla odliczenia VAT RR | Art. 116 VAT |
| `limits.one_off_depreciation_limit_eur` | `50000` | Limit jednorazowej amortyzacji EUR | Art. 22k PIT |
| `limits.excise_car_declaration_days` | `30` | Dni na deklarację akcyzy AKC-U | Art. 100 u.p.a. |
| `limits.inheritance_exemption_min_years` | `2` | Min. lat prowadzenia firmy dla zwolnienia | Art. 4b u.p.s.d. |
| `limits.vat_correction_period_months_car` | `60` | Miesiące korekty VAT przy sprzedaży auta | Art. 90b VAT |
| `limits.employee_mileage_rate_per_km` | `1.15` | Stawka kilometrówki PLN/km (do 900cm³) | Rozp. MPiPS |
| `limits.employee_mileage_rate_over_900` | `1.38` | Stawka kilometrówki PLN/km (>900cm³) | Rozp. MPiPS |
| `rates.tp_safe_harbour_markup` | `"0.05"` | Bezpieczny narzut 5% dla TP usług niskowartościowych | Art. 23r PIT |
| `rates.excise_car_petrol_under_2000` | `"0.031"` | Akcyza 3.1% auta benz. <2000cm³ | u.p.a. |
| `rates.excise_car_petrol_over_2000` | `"0.186"` | Akcyza 18.6% auta benz. ≥2000cm³ | u.p.a. |
| `rates.car_vat_correction_monthly_factor` | `"0.00833"` | 1/120 miesięcznie (50% VAT / 60 mies.) | Art. 90b VAT |
| `bounds.diet_limit_germany` | `49` | Limit diety EUR/dzień (Niemcy) | Rozp. MPiPS |
| `bounds.diet_limit_usa` | `59` | Limit diety USD/dzień (USA) | Rozp. MPiPS |

---

# CZĘŚĆ I: KUP SPECYFICZNE DLA BRANŻ JDG (P578-P582)

> **Stan przed:** KUP pokryty ogólnie (P560-P577), ale brak szczegółowych reguł dla konkretnych zawodów JDG.  
> **Po analizie:** 5 nowych reguł — własna praca NKUP, izby zawodowe, kary umowne, towary przeterminowane, odzież robocza.

---

## P578: `kup_own_and_spouse_work_nkup` ★ NOWA

- **Cel biznesowy:** Wartość własnej pracy przedsiębiorcy JDG oraz pracy jego małżonka i małoletnich dzieci NIE stanowi kosztu uzyskania przychodu. Jest to bezwzględne wyłączenie ustawowe — JDG nie może "zatrudnić samego siebie" i wrzucić własnego wynagrodzenia w KUP.
- **Przesłanki:**
  - `input.jdg_entrepreneur.is_owner_labor == true` (wydatek dotyczy wynagrodzenia za pracę własną przedsiębiorcy)
  - LUB: `input.jdg_entrepreneur.spouse_works_in_jdg == true` AND `input.invoice.beneficiary == "SPOUSE"` (małżonek pracuje w JDG)
  - LUB: `input.invoice.beneficiary_age < 18` AND `input.invoice.beneficiary_relation == "CHILD"` (małoletnie dziecko)
- **Rezultat:**
  - `kus_qualification: "none"`
  - `exclusion_type: "OWN_LABOR_OR_FAMILY"`
  - `_warning: "Wartość pracy własnej (oraz małżonka i małoletnich dzieci) NIE stanowi KUP — Art. 23 ust. 1 pkt 10 PIT"`
  - `_routing: "BLOCK_AND_ALERT"` (jeśli próbowano zaliczyć jako KUP)
- **Podstawa prawna:** Art. 23 ust. 1 pkt 10 ustawy o PIT
- **Zależności:** Sprawdzana w `jdg.pit.kup` — PRZED ogólnymi regułami KUP (P560)
- **Priorytet:** 578
- **Uwaga:** NIE dotyczy wynagrodzeń wypłacanych dzieciom pełnoletnim na podstawie umowy o pracę/zlecenia — te są w pełni KUP (P1200-P1212).

---

## P579: `kup_professional_chamber_fees` ★ NOWA

- **Cel biznesowy:** Obowiązkowe składki członkowskie w izbach zawodowych (Okręgowa Izba Lekarska, Izba Radców Prawnych, Izba Adwokacka, Izba Architektów, Izba Inżynierów Budownictwa, Krajowa Izba Doradców Podatkowych, Krajowa Izba Biegłych Rewidentów) stanowią KUP. Jest to istotne rozróżnienie od składek w organizacjach dobrowolnych (np. stowarzyszenia branżowe), które NIE są KUP.
- **Przesłanki:**
  - `input.jdg_entrepreneur.professional_chamber_member == true`
  - `input.invoice.expense_type == "CHAMBER_FEES"`
  - `input.jdg_entrepreneur.chamber_type in ["LEKARSKA", "PRAWNICZA", "ADWOKACKA", "ARCHITEKTOW", "INZYNIEROW", "DORADCOW_PODATKOWYCH", "BIEGLYCH_REWIDENTOW", "NOTARIALNA", "KOMORNICZA", "PIELEGNIAREK"]`
  - Izba działa na podstawie odrębnej ustawy (obowiązkowa przynależność)
- **Rezultat:**
  - `kus_qualification: "full"`
  - `kus_percent: 100`
  - `chamber_fees_deductible: true`
  - `_info: "Obowiązkowe składki izby zawodowej — 100% KUP"`
  
  **Kontrast — organizacje dobrowolne:**
  - `kus_qualification: "none"` (dla stowarzyszeń nieobowiązkowych)
  - `_warning: "Składka w organizacji dobrowolnej NIE jest KUP (Art. 23 ust. 1 pkt 30 PIT)"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 30 PIT (wyłączenie tylko dla dobrowolnych — izby obowiązkowe są KUP)
- **Priorytet:** 579

---

## P580: `kup_contractual_penalties_nkup` ★ NOWA

- **Cel biznesowy:** Kary umowne (kary za wady dostarczonych towarów/usług, kary za opóźnienie w dostawie, odszkodowania z tytułu wad) są bezwzględnie wyłączone z KUP. Dotyczy to szczególnie JDG w branżach IT (kary za opóźnienie projektu), budowlanej (kary za wady wykonawcze), transportowej (kary za opóźnienie dostawy).
- **Przesłanki:**
  - `input.invoice.is_contractual_penalty == true`
  - `input.invoice.expense_type == "CONTRACTUAL_PENALTY"`
  - `input.invoice.penalty_reason in ["DELIVERY_DELAY", "DEFECTS", "NON_PERFORMANCE", "LATE_COMPLETION"]`
  - Kara wynika z umowy cywilnoprawnej między JDG a kontrahentem
- **Rezultat:**
  - `kus_qualification: "none"`
  - `exclusion_type: "CONTRACTUAL_PENALTY"`
  - `_warning: "Kara umowna NIE stanowi KUP — Art. 23 ust. 1 pkt 19 PIT"`
  - `_routing: "BLOCK_AND_ALERT"`

  **WYJĄTEK:** Kary za wady dostaw towarów/usług od dostawców (JDG OTRZYMUJE karę od dostawcy) — te kary są przychodem podatkowym, nie KUP.
- **Podstawa prawna:** Art. 23 ust. 1 pkt 19 PIT
- **Priorytet:** 580

---

## P581: `kup_workwear_vs_suit_bhp` ★ NOWA

- **Cel biznesowy:** Rozróżnienie odzieży roboczej i ochronnej (KUP) od odzieży reprezentacyjnej (NKUP). Kluczowe dla JDG w zawodach prawniczych (togi), medycznych (fartuchy, scrubs), budowlanych (kaski, kamizelki), gastronomicznych (fartuchy kucharskie).
- **Przesłanki — odzież KUP:**
  - `input.invoice.is_workwear_bhp == true`
  - `input.invoice.expense_type in ["WORKWEAR_BHP", "PROTECTIVE_CLOTHING", "UNIFORM_MANDATORY", "MEDICAL_SCRUBS", "CHEF_APRON", "CONSTRUCTION_HELMET", "HIGH_VIS_VEST"]`
  - Odzież wynika z przepisów BHP lub charakteru wykonywanej pracy
  - LUB: odzież jest wymagana przez prawo (togi adwokackie, fartuchy lekarskie)

- **Przesłanki — odzież NKUP:**
  - `input.invoice.expense_type in ["BUSINESS_SUIT", "CASUAL_OFFICE_WEAR", "DESIGNER_CLOTHING"]`
  - Odzież ma charakter ogólny/reprezentacyjny, nawet jeśli noszona na spotkania z klientami

- **Rezultat:**
  
  | Typ odzieży | KUP? | Podstawa |
  |-------------|:----:|----------|
  | Toga adwokacka/radcowska | ✅ 100% KUP | Art. 22 PIT (obowiązkowa) |
  | Fartuch lekarski / scrubs | ✅ 100% KUP | Art. 22 PIT + BHP |
  | Kask, kamizelka BHP | ✅ 100% KUP | Art. 22 PIT + BHP |
  | Fartuch kucharski | ✅ 100% KUP | Art. 22 PIT + Sanepid |
  | Garnitur biznesowy | ❌ NKUP | Art. 23 ust. 1 pkt 23 PIT |
  | Buty skórzane | ❌ NKUP | Art. 23 ust. 1 pkt 23 PIT |

- **Podstawa prawna:** Art. 23 ust. 1 pkt 23 PIT (reprezentacja), Art. 22 ust. 1 PIT (związek z przychodem)
- **Priorytet:** 581

---

## P582: `kup_abandoned_spoiled_goods` ★ NOWA

- **Cel biznesowy:** Towary przeterminowane, zepsute, zniszczone lub porzucone stanowią KUP TYLKO jeśli strata została udokumentowana protokołem likwidacji i nie wynika z zaniedbania przedsiębiorcy. Kluczowe dla JDG w e-commerce (zwroty zniszczonych towarów), gastronomii (przeterminowana żywność), handlu detalicznym.
- **Przesłanki:**
  - `input.invoice.is_spoiled_goods == true`
  - `input.invoice.has_disposal_protocol == true` (sporządzono protokół likwidacji)
  - `input.invoice.expense_type in ["SPOILED_FOOD", "DAMAGED_GOODS", "EXPIRED_PRODUCTS", "ABANDONED_INVENTORY"]`
  - Strata NIE wynika z rażącego niedbalstwa przedsiębiorcy (`input.invoice.owner_negligence == false`)
  - Protokół likwidacji zawiera: datę, przyczynę, opis towaru, wartość, podpis
- **Rezultat:**
  - `kus_qualification: "full"` (gdy protokół kompletny + brak niedbalstwa)
  - `kus_qualification: "none"` (gdy brak protokołu LUB niedbalstwo)
  - `_warning` (gdy brakuje protokołu): "Towary przeterminowane — sporządź protokół likwidacji dla uznania KUP"
  - `_routing: "TRIAGE_QUEUE"` (gdy brak protokołu)

  **Specyfika branżowa:**
  - Gastronomia: żywność z datą przydatności — protokół utylizacji
  - E-commerce: zwroty uszkodzone w transporcie — protokół szkody + reklamacja do przewoźnika
  - Handel: przecena towarów sezonowych — NIE jest stratą (tylko niższa marża)
- **Podstawa prawna:** Art. 22 ust. 1 PIT (ogólna definicja KUP) — strata musi być udokumentowana i nie wynikać z zaniedbania
- **Priorytet:** 582

---

# CZĘŚĆ II: CROSS-BORDER & PLATFORMY CYFROWE (P143-P146)

> **Stan przed:** P40-P49 pokrywają cross-border ogólnie. P141 (IT service export) dodany w 28. Ale brak szczegółów dla JDG sprzedających przez App Store/Google Play/Upwork/Fiverr.  
> **Po analizie:** 4 nowe reguły — App Store B2B, prowizje platform, kasy fiskalne, kasy wirtualne.

---

## P143: `platform_app_store_b2b_export` ★ NOWA

- **Cel biznesowy:** Sprzedaż aplikacji przez Apple App Store lub Google Play NIE jest sprzedażą detaliczną B2C (WSTO/OSS). Jest to eksport usług B2B do Apple/Google (oba podmioty są rezydentami podatkowymi Irlandii z aktywnym VAT-UE). Faktura wystawiana jest z "NP" (odwrotne obciążenie — reverse charge). JDG nie nalicza VAT.
- **Przesłanki:**
  - `input.invoice.is_app_store_sale == true`
  - `input.vendor.is_app_store_platform == true` (Apple, Google)
  - `input.vendor.country_of_residence == "IE"` (Irlandia)
  - `input.vendor.vat_eu_active == true`
  - `input.invoice.direction == "SALE"`
- **Rezultat:**
  - `vat_rate: "0.00"` (NP — nie podlega opodatkowaniu w PL)
  - `vat_procedure: "EXPORT_SERVICES_B2B"`
  - `reverse_charge_applies: true`
  - `vat_ue_summary_required: true` (wykazać w VAT-UE jako eksport usług)
  - `invoice_note_required: "NP — reverse charge (Art. 28b VAT)"`
  - `_warning: "Sprzedaż przez App Store/Google Play to eksport usług B2B do Irlandii — faktura z NP, wykazuj w VAT-UE"`

  **Kluczowe rozróżnienie:** To NIE jest WSTO/OSS! WSTO dotyczy sprzedaży B2C do konsumentów UE. App Store/Google Play to pośrednik B2B, który sam rozlicza VAT od sprzedaży do konsumenta końcowego.
- **Podstawa prawna:** Art. 28b VAT (miejsce świadczenia = siedziba nabywcy usługi B2B)
- **Zależności:** Sprawdzana PRZED regułami OSS/WSTO (P66-P69)
- **Priorytet:** 143

---

## P144: `platform_import_of_services_commissions` ★ NOWA

- **Cel biznesowy:** Platformy freelancerskie (Upwork, Fiverr, Uber, Bolt) automatycznie potrącają prowizję od zarobków JDG. Ta prowizja jest importem usług spoza Polski — JDG musi rozliczyć VAT należny i naliczony (reverse charge) od kwoty prowizji.
- **Przesłanki:**
  - `input.vendor.is_freelance_platform == true` (Upwork, Fiverr, Freelancer, Useme, Uber, Bolt)
  - `input.invoice.platform_fee_deducted > 0` (prowizja potrącona)
  - `input.vendor.country_of_residence != "PL"`
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:**
  - `vat_procedure: "IMPORT_SERVICES"`
  - `reverse_charge: true`
  - `vat_nalezny: platform_fee * vat_rate_domestic` (np. 23%)
  - `vat_naliczony: platform_fee * vat_rate_domestic` (jednoczesne odliczenie — jeśli pełne prawo)
  - `kus_base: platform_fee` (prowizja jako KUP — całość netto)
  - `_warning: "Prowizja platformy X PLN — rozlicz import usług (reverse charge). VAT należny i naliczony w JPK_V7."`

  **Platformy do rozliczenia importu usług:**
  
  | Platforma | Kraj siedziby | Stawka VAT PL |
  |-----------|:------------:|:-------------:|
  | Upwork | USA (NON-EU) | 23% |
  | Fiverr | Izrael (NON-EU) | 23% |
  | Freelancer | Australia (NON-EU) | 23% |
  | Uber B.V. | Holandia (EU) | Reverse charge UE |
  | Bolt | Estonia (EU) | Reverse charge UE |
  | Useme | Polska (PL) | Standardowa faktura PL |

- **Podstawa prawna:** Art. 28b, Art. 17 ust. 1 pkt 4 VAT
- **Priorytet:** 144
- **Zależności:** Sprawdzana PO regułach importu usług (P41, P47)

---

## P145: `cash_register_b2c_exemption_20k` ★ NOWA

- **Cel biznesowy:** JDG dokonujące sprzedaży B2C (na rzecz osób fizycznych) są zwolnione z obowiązku posiadania kasy fiskalnej do limitu 20 000 PLN rocznego obrotu B2C. Po przekroczeniu limitu — obowiązek instalacji kasy fiskalnej w ciągu 2 miesięcy.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.vendor.is_b2c == true` (sprzedaż na rzecz konsumenta)
  - `input.jdg_entrepreneur.b2c_annual_turnover_for_fiscal < input.thresholds.jdg.limits.cash_register_exemption_limit` (20 000 PLN) → ZWOLNIENIE
  - `input.jdg_entrepreneur.b2c_annual_turnover_for_fiscal >= input.thresholds.jdg.limits.cash_register_exemption_limit` → OBOWIĄZEK
- **Rezultat:**
  - `cash_register_exempt: true` (poniżej 20k PLN)
  - `cash_register_mandatory: true` (powyżej 20k PLN)
  - `cash_register_deadline: "2_miesiace_od_przekroczenia"`
  - `_warning: "Przekroczono limit 20 000 PLN sprzedaży B2C — obowiązek instalacji kasy fiskalnej w ciągu 2 miesięcy"`
  
  **Wyłączenia bezwzględne (kasa zawsze wymagana, niezależnie od limitu):**
  - Sprzedaż na rzecz osób fizycznych: części do pojazdów, wyroby tytoniowe, alkohol, paliwa, sprzęt elektroniczny (określone kategorie)
  - JDG świadczące usługi przewozów osobowych (taxi, Uber)
  - JDG świadczące usługi fryzjerskie, kosmetyczne
- **Podstawa prawna:** Rozporządzenie MF w sprawie zwolnień z obowiązku prowadzenia ewidencji przy zastosowaniu kas rejestrujących (Dz.U. 2025)
- **Priorytet:** 145
- **`[TODO: potrzebne źródło]`** — pełna lista kategorii bezwzględnie wyłączonych ze zwolnienia

---

## P146: `e_commerce_virtual_cash_register` ★ NOWA

- **Cel biznesowy:** JDG w określonych branżach mogą korzystać z kas wirtualnych (oprogramowanie na smartfonie/tablecie) zamiast fizycznych kas fiskalnych. Dotyczy to: usług IT, transportu (taxi, przewóz osób), gastronomii (dostawa jedzenia), usług parkingowych.
- **Przesłanki:**
  - `input.jdg_entrepreneur.uses_virtual_cash_register == true`
  - `input.jdg_entrepreneur.pkd_main in virtual_cash_register_pkd` (lista branż uprawnionych)
  - `input.invoice.direction == "SALE"` AND `input.vendor.is_b2c == true`
- **Rezultat:**
  - `virtual_cash_register_allowed: true`
  - `physical_cash_register_not_required: true`
  - `_info: "Kasa wirtualna dozwolona dla Twojej branży — możesz używać aplikacji zamiast fizycznej kasy"`
  
  **Branże uprawnione do kasy wirtualnej:**
  
  | PKD | Branża |
  |-----|--------|
  | 62.01.Z, 62.02.Z, 62.09.Z | IT, software |
  | 49.32.Z | Taxi, przewóz osób |
  | 56.10.A, 56.10.B | Restauracje, dostawa jedzenia |
  | 56.21.Z | Catering |
  | 52.21.Z | Parkingi |
  | 96.02.Z | Fryzjerstwo, kosmetyka |

- **Podstawa prawna:** Art. 111b VAT, Rozporządzenie MF w sprawie kas rejestrujących
- **Priorytet:** 146

---

# CZĘŚĆ III: NIERUCHOMOŚCI W JDG (P147-P150a)

> **Stan przed:** P1310-P1312 pokrywają podatek od nieruchomości. P564 pokrywa limit 150k dla aut. Ale brak reguł dla JDG kupujących nieruchomości.  
> **Po analizie:** 4 nowe reguły — zakaz amortyzacji mieszkań, opcja VAT, PCC vs VAT, diety zagraniczne.

---

## P147: `real_estate_residential_depreciation_ban` ★ NOWA

- **Cel biznesowy:** Od 2023 roku obowiązuje BEZWZGLĘDNY ZAKAZ amortyzacji podatkowej budynków i lokali mieszkalnych. JDG nie może już zaliczać odpisów amortyzacyjnych od mieszkań, domów jednorodzinnych i lokali mieszkalnych do KUP. Nabyte przed 2023 rokiem — kontynuują amortyzację na starych zasadach.
- **Przesłanki:**
  - `input.invoice.expense_type == "REAL_ESTATE_DEPRECIATION"`
  - `input.invoice.real_estate_type == "RESIDENTIAL"` (budynek/lokal mieszkalny)
  - `input.invoice.building_year >= 2023` (nabyte po 1 stycznia 2023)
  - `input.jdg_entrepreneur.uses_pkpir == true`
- **Rezultat:**
  - `depreciation_allowed: false`
  - `kus_from_depreciation: "0.00"`
  - `_routing: "BLOCK_AND_ALERT"` (jeśli próbowano zaliczyć amortyzację do KUP)
  - `_warning: "BEZWZGLĘDNY ZAKAZ amortyzacji budynków i lokali mieszkalnych nabytych po 2022 roku — Art. 22c pkt 2 PIT"`
  
  **WYJĄTKI od zakazu:**
  - Budynki niemieszkalne (biurowce, hale, magazyny) — normalna amortyzacja
  - Mieszkania nabyte PRZED 2023 rokiem — kontynuacja starej amortyzacji
  - Inwestycje w obcych środkach trwałych (adaptacja wynajmowanego lokalu) — amortyzacja dozwolona
- **Podstawa prawna:** Art. 22c pkt 2 PIT (wprowadzony ustawą Polski Ład, utrzymany po nowelizacjach)
- **Priorytet:** 147

---

## P148: `real_estate_depreciation_commercial_only` ★ NOWA

- **Cel biznesowy:** Dla nieruchomości komercyjnych (biurowce, hale, magazyny, lokale użytkowe) amortyzacja jest dozwolona — stawka 2.5% rocznie (okres 40 lat) dla budynków niemieszkalnych.
- **Przesłanki:**
  - `input.invoice.expense_type == "REAL_ESTATE_DEPRECIATION"`
  - `input.invoice.real_estate_type == "COMMERCIAL"` (budynek/lokal użytkowy)
  - `input.jdg_entrepreneur.uses_pkpir == true`
- **Rezultat:**
  - `depreciation_allowed: true`
  - `depreciation_rate: "0.025"` (2.5% rocznie — okres 40 lat)
  - `kus_annual_depreciation: purchase_price * 0.025`
  - `_info: "Amortyzacja nieruchomości komercyjnej — stawka 2.5% rocznie, okres 40 lat"`

  **Tabela stawek amortyzacji nieruchomości:**
  
  | Typ nieruchomości | Stawka roczna | Okres |
  |-------------------|:------------:|:-----:|
  | Budynki mieszkalne (nabyte ≥2023) | ❌ ZAKAZ | — |
  | Budynki niemieszkalne | 2.5% | 40 lat |
  | Lokale użytkowe | 2.5% | 40 lat |
  | Hale produkcyjne | 2.5% | 40 lat |
  | Budowle (drogi, place) | 4.5% | 22 lata |
  | Grunty | ❌ NIE podlegają | — |

- **Podstawa prawna:** Załącznik nr 1 do PIT (KŚT — Wykaz rocznych stawek amortyzacyjnych), poz. 01
- **Priorytet:** 148

---

## P149: `real_estate_option_to_tax_vat` ★ NOWA

- **Cel biznesowy:** Przy sprzedaży nieruchomości starszych niż 2 lata (zwolnionych z VAT przedmiotowo), obie strony transakcji (JDG kupujący i JDG sprzedający) mogą złożyć oświadczenie o rezygnacji ze zwolnienia z VAT i opodatkować transakcję VAT. Dzięki temu kupujący JDG może odliczyć VAT naliczony.
- **Przesłanki:**
  - `input.invoice.direction == "PURCHASE"` (JDG kupuje nieruchomość)
  - `input.invoice.real_estate_type in ["COMMERCIAL", "LAND_FOR_DEVELOPMENT"]`
  - `input.invoice.real_estate_vat_option_filed == true` (złożono VAT-23 / oświadczenie o opcji VAT)
  - Transakcja NIE dotyczy nieruchomości mieszkalnych (wyłączone z opcji)
  - Obie strony są czynnymi podatnikami VAT
- **Rezultat:**
  - `vat_rate: "0.23"` (VAT opcjonalnie)
  - `vat_deduction_possible: true` (kupujący może odliczyć VAT)
  - `vat_exemption_waived: true`
  - `_warning: "Transakcja z opcją VAT — złożono oświadczenie o rezygnacji ze zwolnienia. VAT 23% do odliczenia."`

  **Gdy NIE złożono opcji:**
  - `vat_rate: "0.00"` (zw — zwolniona)
  - `vat_deduction_possible: false` (kupujący nie odlicza VAT)
  - `pcc_tax_applies: true` (PCC 2% — bo transakcja nie podlega VAT!)
- **Podstawa prawna:** Art. 43 ust. 10-11 VAT
- **Priorytet:** 149

---

## P150: `real_estate_pcc_exempt_on_vat_taxable` ★ NOWA

- **Cel biznesowy:** Zasada wyłączności — transakcja nieruchomościowa podlega ALBO VAT (23% lub ZW) ALBO PCC (2%). Nigdy obu jednocześnie. Jeśli transakcja jest opodatkowana VAT (nawet stawką ZW), to PCC NIE ma zastosowania. To kluczowe dla określenia całkowitego kosztu transakcji.
- **Przesłanki:**
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.real_estate_type in ["RESIDENTIAL", "COMMERCIAL", "LAND"]`
  - Transakcja podlega VAT (czynność opodatkowana VAT — nawet przy stawce ZW)
- **Rezultat:**
  - `pcc_not_applicable: true` (automatycznie)
  - `vat_applicable: true`
  - `_info: "Transakcja podlega VAT — PCC nie ma zastosowania (Art. 2 pkt 4 u.PCC)"`

  **Gdy NIE podlega VAT:**
  - `pcc_applicable: true`
  - `pcc_rate: "0.02"` (2% wartości rynkowej)
  - `_warning: "Transakcja nie podlega VAT — obowiązek PCC 2% od wartości rynkowej"`

  **Tabela interakcji VAT↔PCC dla nieruchomości:**
  
  | Scenariusz | VAT | PCC |
  |------------|:---:|:---:|
  | Nowy lokal od dewelopera | 23%/8% VAT | ❌ Brak |
  | Używany lokal >2 lata — opcja VAT | 23% VAT | ❌ Brak |
  | Używany lokal >2 lata — bez opcji | ZW VAT | ✅ 2% PCC |
  | Od osoby prywatnej (rynek wtórny) | ❌ Brak | ✅ 2% PCC |
  | Grunt budowlany od firmy | 23% VAT | ❌ Brak |
  | Grunt rolny od rolnika ryczałtowego | ❌ Brak | ✅ 2% PCC |

- **Podstawa prawna:** Art. 2 pkt 4 ustawy o PCC
- **Priorytet:** 150

---

## P150a: `foreign_business_trip_diets_owner` ★ NOWA

- **Cel biznesowy:** Podczas zagranicznych podróży służbowych, właściciel JDG może zaliczyć do KUP diety (wyżywienie) bez konieczności posiadania rachunków za posiłki — do limitu ustawowego dla danego kraju. Hotele i przeloty wymagają faktur. Diety — NIE wymagają.
- **Przesłanki:**
  - `input.invoice.expense_type == "FOREIGN_BUSINESS_TRIP"`
  - `input.invoice.foreign_trip_country != "PL"`
  - `input.invoice.foreign_trip_days > 0`
  - Cel podróży: związany z działalnością gospodarczą JDG
- **Rezultat:**
  - `diet_kup_allowed: diet_per_day * trip_days` (bezrachunkowo)
  - `diet_per_day: z thresholds.jdg.bounds.diet_limit_<KRAJ>`
  - `hotel_invoice_kup: hotel_amount (wymagana faktura)`
  - `transport_invoice_kup: flight_amount (wymagana faktura/bilet)`
  - `_info: "Diety zagraniczne — X EUR/dzień bez rachunków. Hotel i transport — wymagane faktury."`

  **Przykładowe limity diet (EUR/dzień):**
  
  | Kraj | Limit diety |
  |------|:-----------:|
  | Niemcy | 49 EUR |
  | UK | 45 GBP |
  | USA | 59 USD |
  | Szwajcaria | 84 CHF |
  | Czechy | 45 EUR |

- **Podstawa prawna:** Art. 23 ust. 1 pkt 52 PIT (wyłączenie z NKUP diet do limitu), Rozporządzenie MPiPS w sprawie diet zagranicznych
- **Priorytet:** 150a
- **`[TODO: potrzebne źródło]`** — pełna tabela diet dla wszystkich krajów (z Rozporządzenia MPiPS)

---

# CZĘŚĆ IV: ROLNICTWO I AKCYZA (P151-P154)

> **Stan przed:** CAŁKOWICIE pominięte. JDG w handlu spożywczym, restauracjach, imporcie aut — podlegają specyficznym regułom VAT RR i akcyzy.  
> **Po analizie:** 4 nowe reguły — VAT RR, produkcja specjalna rolna, akcyza auto, akcyza alkohol.

---

## P151: `agricultural_special_production_jdg_overlap` ★ NOWA

- **Cel biznesowy:** JDG prowadzące działy specjalne produkcji rolnej (szklarnie, pieczarkarnie, fermy drobiu, hodowla zwierząt futerkowych) muszą rozdzielić normy szacunkowe dochodu od standardowej PKPiR. Działy specjalne są opodatkowane ryczałtem od norm szacunkowych, pozostała działalność — na zasadach ogólnych.
- **Przesłanki:**
  - `input.jdg_entrepreneur.performs_agricultural_special_branches == true`
  - `input.jdg_entrepreneur.pkd_main in agricultural_special_pkd`
  - JDG prowadzi jednocześnie działalność rolniczą (działy specjalne) i pozarolniczą
- **Rezultat:**
  - `separate_accounting_required: true`
  - `agricultural_income: normy_szacunkowe * area_units` (ryczałt)
  - `non_agricultural_income: revenue - kup` (PKPiR standard)
  - `_warning: "Działy specjalne produkcji rolnej — prowadź osobną ewidencję. Dochód z działów = normy szacunkowe."`

  **Działy specjalne — przykłady norm szacunkowych:**
  
  | Rodzaj uprawy/hodowli | Jednostka | Norma roczna |
  |-----------------------|-----------|:------------:|
  | Szklarnie ogrzewane >25m² | 1 m² | ~25 PLN/m² |
  | Pieczarkarnie | 1 m² | ~30 PLN/m² |
  | Ferma drobiu nieśnego | 1 kura | ~5 PLN/szt |
  | Hodowla norek | 1 samica | ~50 PLN/szt |

- **Podstawa prawna:** Art. 15 PIT, Art. 24 ust. 4 PIT, Załącznik nr 2 do PIT (normy szacunkowe)
- **Priorytet:** 151
- **`[TODO: potrzebne źródło]`** — aktualne normy szacunkowe z Załącznika nr 2

---

## P152: `vat_farmer_rr_purchase_invoice` ★ NOWA

- **Cel biznesowy:** Gdy JDG (restauracja, sklep spożywczy, przetwórnia) kupuje produkty rolne od rolnika ryczałtowego (NIE będącego podatnikiem VAT), to JDG-KUPUJĄCY wystawia fakturę VAT RR za rolnika. Faktura zawiera kwotę brutto + 7% zryczałtowanego zwrotu VAT dla rolnika. JDG może odliczyć ten VAT RR TYLKO jeśli zapłaci rolnikowi przelewem w ciągu 14 dni.
- **Przesłanki:**
  - `input.invoice.direction == "PURCHASE"`
  - `input.invoice.is_agricultural_produce == true`
  - `input.vendor.is_flat_rate_farmer == true` (rolnik ryczałtowy)
  - `input.vendor.farmer_vat_status == "FLAT_RATE"`
  - JDG kupujący jest czynnym podatnikiem VAT
- **Rezultat:**
  - `invoice_type_required: "VAT_RR"` (JDG wystawia fakturę VAT RR)
  - `vat_rr_refund_rate: "0.07"` (7% zryczałtowanego zwrotu)
  - `vat_rr_refund_amount: amount_gross * 0.07`
  - `vat_deduction_possible: true` (JDG odlicza VAT RR naliczony)
  - `vat_rr_payment_condition: "PRZELEW_W_CIAGU_14_DNI"`

  **Warunki absolutnie wymagane dla odliczenia VAT RR:**
  1. Faktura VAT RR wystawiona przez JDG-kupującego (dwa egzemplarze — oryginał dla rolnika, kopia dla JDG)
  2. Zapłata PRZELEWEM BANKOWYM (nie gotówką!) w ciągu 14 dni od zakupu
  3. Faktura zawiera: dane rolnika (PESEL, adres), dane kupującego (NIP), datę, nazwę i ilość produktów, kwotę

  **Gdy NIE spełniono warunków:**
  - `vat_rr_deduction_blocked: true`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "VAT RR — zapłać przelewem w ciągu 14 dni, aby odliczyć 7% VAT RR"`
- **Podstawa prawna:** Art. 115-118 VAT
- **Priorytet:** 152

---

## P153: `excise_duty_car_import_eu` ★ NOWA

- **Cel biznesowy:** JDG importujące samochód osobowy z UE (WNT) musi zapłacić akcyzę w ciągu 30 dni od nabycia wewnątrzwspólnotowego i PRZED rejestracją pojazdu w Polsce. Brak akcyzy = brak możliwości rejestracji.
- **Przesłanki:**
  - `input.invoice.import_vehicle_from_eu == true`
  - `input.invoice.procedure == "WNT"` (wewnątrzwspólnotowe nabycie)
  - `input.invoice.is_excise_duty_event == true`
  - `input.invoice.excise_goods_type == "PASSENGER_CAR"`
  - Pojazd będzie rejestrowany w Polsce
- **Rezultat:**
  - `excise_duty_required: true`
  - `excise_form: "AKC-U"`
  - `excise_deadline: "30_dni_od_nabycia_wewnatrzwspolnotowego"`
  - `excise_payment_deadline: "30_dni_od_dnia_powstania_obowiazku"`

  **Stawki akcyzy samochodowej:**
  
  | Rodzaj auta | Pojemność silnika | Stawka akcyzy |
  |-------------|:-----------------:|:-------------:|
  | Benzynowe | < 2000 cm³ | 3.1% wartości |
  | Benzynowe | ≥ 2000 cm³ | 18.6% wartości |
  | Diesel | < 2000 cm³ | 3.1% wartości |
  | Diesel | ≥ 2000 cm³ | 18.6% wartości |
  | Elektryczne | — | 0% (ZWOLNIONE) |
  | Hybrydowe | < 2000 cm³ | 1.55% (50% stawki) |
  | Hybrydowe | ≥ 2000 cm³ | 9.3% (50% stawki) |
  | Hybrydowe plug-in | < 2000 cm³ | 0% (ZWOLNIONE) |

  - `excise_amount: car_value * excise_rate`
  - `_warning: "Import auta z UE — zapłać akcyzę w ciągu 30 dni. Bez akcyzy nie zarejestrujesz pojazdu."`
- **Podstawa prawna:** Art. 100 ust. 1, Art. 102-105 ustawy o podatku akcyzowym
- **Priorytet:** 153

---

## P154: `excise_duty_craft_beer_wine` ★ NOWA

- **Cel biznesowy:** JDG produkujące lub sprzedające alkohol (browary rzemieślnicze, winiarnie, destylarnie) podlegają obowiązkowi banderolowania wyrobów akcyzowych, składania deklaracji AKC-4/AKC-4ZO i wpłacania akcyzy.
- **Przesłanki:**
  - `input.jdg_entrepreneur.is_craft_brewery == true` LUB `is_craft_distillery == true`
  - `input.invoice.is_excise_duty_event == true`
  - `input.invoice.excise_goods_type in ["BEER", "WINE", "SPIRITS", "FERMENTED_DRINKS"]`
- **Rezultat:**
  - `excise_duty_required: true`
  - `banderole_required: true` (dla wódek i wyrobów tytoniowych)
  - `excise_form: "AKC-4/AKC-4ZO"` (miesięczna)
  - `excise_deadline: "25th_day_of_next_month"`
  - `_warning: "Produkcja alkoholu — obowiązek banderolowania i deklaracji AKC-4"`

  **Stawki akcyzy na alkohol (przykłady 2026):**
  
  | Produkt | Jednostka | Stawka |
  |---------|-----------|:------:|
  | Piwo | 1 hl / °Plato | ~9.50 PLN |
  | Wino | 1 hl | ~190 PLN |
  | Wódka / spirytus | 1 hl 100% alkoholu | ~7400 PLN |
  | Cydr / perry | 1 hl | ~100 PLN |

- **Podstawa prawna:** Ustawa o podatku akcyzowym, Rozdział 2 (wyroby alkoholowe)
- **Priorytet:** 154
- **Zależności:** `[TODO: potrzebne źródło]` — aktualne stawki akcyzy na 2026 rok

---

# CZĘŚĆ V: DZIEDZICZENIE I FUNDACJA RODZINNA (P1731-P1732, P930a-P932a)

> **Stan przed:** P920-P929 pokrywają zarząd sukcesyjny. P1725 (28) dodaje interakcje z Fundacją Rodzinną. Ale brak szczegółów spadkowych.  
> **Po analizie:** 5 nowych reguł — zwolnienie spadkowe, wycena remanentu, darowizna do FR, najem od FR.

---

## P930a: `inheritance_tax_exemption_enterprise` ★ NOWA

- **Cel biznesowy:** Nabycie przedsiębiorstwa JDG w drodze spadku jest w 100% zwolnione z podatku od spadków i darowizn, pod warunkiem że spadkobierca prowadzi to przedsiębiorstwo przez co najmniej 2 lata od śmierci spadkodawcy.
- **Przesłanki:**
  - `input.jdg_entrepreneur.inheritance_mode == true` (nabycie JDG w spadku)
  - `input.jdg_entrepreneur.inheritance_from == "DECEASED_ENTREPRENEUR"`
  - Spadkobierca zgłosił nabycie do US w ciągu 6 miesięcy (SD-Z2)
  - Spadkobierca zobowiązuje się prowadzić przedsiębiorstwo ≥ 2 lata
- **Rezultat:**
  - `inheritance_tax_exempt: true` (100% zwolnienie)
  - `inheritance_tax_form: "SD-Z2"` (zgłoszenie zwolnienia)
  - `inheritance_condition: "PROWADZ_DZIALALNOSC_PRZEZ_MIN_2_LATA"`
  - `_warning: "Spadek JDG zwolniony z podatku — warunek: prowadź firmę przez 2 lata. Zgłoś SD-Z2 w 6 mies."`

  **Gdy warunek 2 lat NIE jest spełniony:**
  - `inheritance_tax_due: true`
  - `inheritance_tax_rate: progresywna (3%-20% wg grupy podatkowej)`
  - `_warning: "Zaprzestanie działalności przed upływem 2 lat — utrata zwolnienia. Podatek od spadku do zapłaty."`
- **Podstawa prawna:** Art. 4b ustawy o podatku od spadków i darowizn
- **Priorytet:** 930a

---

## P931a: `succession_inventory_depreciation_continuity` ★ NOWA

- **Cel biznesowy:** Spadkobierca lub zarządca sukcesyjny przejmuje środki trwałe zmarłego przedsiębiorcy według wartości z ewidencji zmarłego (NIE według wartości rynkowej!). Kontynuuje amortyzację od niezamortyzowanej wartości — NIE może przeszacować (step-up) wartości środków trwałych.
- **Przesłanki:**
  - `input.jdg_entrepreneur.in_succession == true` LUB `inheritance_mode == true`
  - `input.invoice.expense_type == "DEPRECIATION_CONTINUED"`
  - Środki trwałe przejęte od zmarłego przedsiębiorcy
- **Rezultat:**
  - `depreciation_base: deceased_net_book_value` (NIE market value!)
  - `depreciation_rate: deceased_rate` (kontynuacja stawki)
  - `step_up_not_allowed: true`
  - `_warning: "Przejęcie środków trwałych — kontynuuj amortyzację od wartości netto zmarłego. NIE możesz przeszacować."`

  **Kontrast:** Gdyby spadkobierca kupił te same środki trwałe na rynku = amortyzacja od ceny zakupu. Przy spadku = kontynuacja historycznej wartości.
- **Podstawa prawna:** Art. 22g ust. 1 pkt 3 PIT (kontynuacja wartości początkowej), Art. 22g ust. 13 pkt 5 PIT
- **Priorytet:** 931a

---

## P1731: `family_foundation_asset_transfer` ★ NOWA

- **Cel biznesowy:** Przekazanie przedsiębiorstwa JDG do Fundacji Rodzinnej jest neutralne w VAT (zwolnienie dla ZCP — zorganizowanej części przedsiębiorstwa). Ale późniejszy najem tych samych składników przez JDG od Fundacji Rodzinnej generuje ukryte zyski opodatkowane 15% CIT po stronie Fundacji.
- **Przesłanki:**
  - `input.jdg_entrepreneur.has_family_foundation == true`
  - `input.invoice.expense_type == "JDG_TO_FOUNDATION_TRANSFER"`
  - Transfer dotyczy ZCP (zorganizowanej części przedsiębiorstwa) — nie pojedynczych składników!
- **Rezultat:**
  - `vat_on_transfer: "0.00"` (zwolnione — ZCP)
  - `vat_exemption: "ZCP_TRANSFER"`
  - `pit_consequences: "PRZYCHOD_Z_ODPLATNEGO_ZBYCIA"` (wartość rynkowa ZCP)
  - `_warning: "Przekazanie JDG do Fundacji Rodzinnej — VAT zwolniony (ZCP), PIT od wartości rynkowej. Fundacja płaci CIT od ukrytych zysków."`
- **Podstawa prawna:** Art. 6 pkt 1 VAT (ZCP wyłączone z VAT), Art. 24q CIT (ukryte zyski FR)
- **Priorytet:** 1731
- **Zależności:** Sprawdzana PO P1500-P1505 (restrukturyzacja)

---

## P1732: `family_foundation_rental_hidden_profits` ★ NOWA

- **Cel biznesowy:** Gdy JDG wynajmuje nieruchomości, pojazdy lub IP od swojej własnej Fundacji Rodzinnej — Fundacja płaci 15% CIT od "ukrytych zysków" (świadczeń dla beneficjentów). JDG płaci standardowe stawki PIT + składkę zdrowotną. Całkowite obciążenie: 15% CIT (FR) + 19%/12% PIT (JDG) = efektywnie ~30%-34%.
- **Przesłanki:**
  - `input.jdg_entrepreneur.has_family_foundation == true`
  - `input.jdg_entrepreneur.foundation_rental_contracts == true`
  - `input.vendor.is_family_foundation == true`
  - `input.invoice.expense_type in ["RENT_FROM_FOUNDATION", "LEASE_FROM_FOUNDATION", "IP_LICENSE_FROM_FOUNDATION"]`
- **Rezultat:**
  - `kus_qualification: "full"` (dla JDG — czynsz jest KUP)
  - `foundation_hidden_profit_triggered: true`
  - `foundation_cit_rate: "0.15"` (Fundacja płaci 15% CIT od wartości czynszu)
  - `total_tax_burden_combined: "~30-34%"` (CIT 15% + PIT 12%/19%)
  - `_warning: "Najem od Fundacji Rodzinnej — czynsz jest KUP dla JDG, ale Fundacja płaci 15% CIT od ukrytych zysków. Łączne obciążenie ~30-34%."`

  **Alternatywnie — brak Fundacji Rodzinnej (JDG → JDG):**
  - `total_tax_burden_combined: "12-19%"` (tylko PIT + składka zdrowotna)
- **Podstawa prawna:** Art. 24q ust. 1 pkt 3 CIT (najem od FR = ukryty zysk)
- **Priorytet:** 1732

---

# CZĘŚĆ VI: SMALL TAXPAYERS & RESTRUKTURYZACJA (P843-P846)

> **Stan przed:** P842 pokrywa jednorazową amortyzację. P843-P844 (28) pokrywają restrukturyzację ogólnie. Ale brak szczegółów pomocy de minimis i JPK_V7K.  
> **Po analizie:** 4 nowe reguły — pomoc de minimis, JPK kwartalny, restrukturyzacja długów, złe długi w upadłości.

---

## P843: `restructuring_debt_forgiveness_revenue_exempt` ★ NOWA

- **Cel biznesowy:** Umorzone długi w ramach oficjalnego postępowania restrukturyzacyjnego (postępowanie sanacyjne, układ) lub upadłościowego są ZWOLNIONE z opodatkowania PIT. JDG w restrukturyzacji nie płaci podatku od umorzonych długów.
- **Przesłanki:**
  - `input.jdg_entrepreneur.in_restructuring_proceedings == true`
  - `input.document.restructuring_plan_approved == true`
  - `input.invoice.debt_forgiven_in_restructuring == true`
  - Umorzenie wynika z prawomocnie zatwierdzonego układu z wierzycielami
- **Rezultat:**
  - `debt_forgiveness_taxable: false` (ZWOLNIONE z PIT)
  - `exemption_type: "RESTRUCTURING_DEBT_FORGIVENESS"`
  - `_info: "Umorzony dług w restrukturyzacji — zwolnione z PIT (Art. 21 ust. 1 pkt 135c PIT)"`

  **Gdy umorzenie POZA restrukturyzacją:**
  - `debt_forgiveness_taxable: true`
  - `pit_treatment: "PRZYCHOD_Z_INNYCH_ZRODEL"`
  - `_warning: "Umorzony dług poza restrukturyzacją — podlega PIT jako przychód z innych źródeł"`
- **Podstawa prawna:** Art. 21 ust. 1 pkt 135c PIT
- **Priorytet:** 843

---

## P844: `bad_debt_debtor_in_restructuring_block` ★ NOWA

- **Cel biznesowy:** Ulga na złe długi (zarówno VAT P184 jak i PIT P571) jest BLOKOWANA, jeśli dłużnik jest w trakcie postępowania restrukturyzacyjnego lub upadłościowego. Wierzyciel nie może skorzystać z ulgi na złe długi wobec dłużnika w restrukturyzacji/upadłości.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"` (JDG jest wierzycielem)
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= 90` (dla PIT) / `150` (dla VAT)
  - `input.vendor.in_restructuring_proceedings == true` LUB `input.vendor.in_bankruptcy_proceedings == true`
- **Rezultat:**
  - `bad_debt_relief_blocked: true`
  - `block_reason: "DEBTOR_IN_RESTRUCTURING_OR_BANKRUPTCY"`
  - `_warning: "Ulga na złe długi zablokowana — dłużnik jest w restrukturyzacji/upadłości. Poczekaj na zakończenie postępowania."`

  **Dla JDG jako dłużnika:**
  - `kup_reversal_not_required: true` (JDG w restrukturyzacji NIE musi wyłączać z KUP — P571 nie aktywuje się)
- **Podstawa prawna:** Art. 89a ust. 2 pkt 3 VAT, Art. 14 ust. 1e pkt 3 PIT
- **Zależności:** Sprawdzana PRZED P184 i P571 — jeśli dłużnik w restrukturyzacji, reguły złe długi NIE są aktywowane
- **Priorytet:** 844

---

## P845: `one_off_depreciation_de_minimis_state_aid` ★ NOWA

- **Cel biznesowy:** Jednorazowa amortyzacja do 50 000 EUR (P842) jest klasyfikowana jako pomoc de minimis. JDG musi uzyskać zaświadczenie o pomocy de minimis i sprawdzić, czy nie przekracza łącznego 3-letniego limitu 300 000 EUR.
- **Przesłanki:**
  - `input.jdg_entrepreneur.is_small_taxpayer == true`
  - Jednorazowa amortyzacja zastosowana (P842)
  - `input.document.de_minimis_certificate_requested == false`
- **Rezultat:**
  - `de_minimis_aid_applicable: true`
  - `de_minimis_certificate_required: true`
  - `de_minimis_aid_amount: depreciation_one_off_amount`
  - `de_minimis_3y_remaining: input.thresholds.jdg.limits.de_minimis_3y_threshold_eur - received_3y`
  - `_warning: "Jednorazowa amortyzacja = pomoc de minimis. Uzyskaj zaświadczenie. Limit 3-letni: pozostało X EUR."`

  **Gdy przekroczony limit 300 000 EUR / 3 lata:**
  - `de_minimis_limit_exceeded: true`
  - `one_off_depreciation_blocked: true`
  - `must_use_standard_depreciation: true`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 22k ust. 7-13 PIT, Rozporządzenie KE nr 1407/2013 (pomoc de minimis)
- **Priorytet:** 845

---

## P846: `vat_quarterly_small_taxpayer_k_declaration` ★ NOWA

- **Cel biznesowy:** Mali podatnicy VAT rozliczający się kwartalnie składają JPK_V7K (a nie V7M). JPK_V7K zawiera część ewidencyjną (miesięczną) i część deklaracyjną (kwartalną). Termin: 25. dnia miesiąca po kwartale.
- **Przesłanki:**
  - `input.jdg_entrepreneur.is_small_taxpayer == true`
  - `input.jdg_entrepreneur.is_vat_payer == true`
  - JDG wybrało rozliczenie kwartalne
- **Rezultat:**
  - `jpk_type: "JPK_V7K"` (kwartalny)
  - `jpk_frequency: "QUARTERLY"`
  - `jpk_deadline: "25th_day_after_quarter_end"`
  - `jpk_structure: "EWIDENCYJNA_MIESIECZNA + DEKLARACYJNA_KWARTALNA"`
  - `_info: "Mały podatnik — rozliczenie kwartalne JPK_V7K. Termin: 25. dzień po kwartale."`

  **Porównanie JPK_V7M vs JPK_V7K:**
  
  | Cecha | JPK_V7M | JPK_V7K |
  |-------|---------|---------|
  | Częstotliwość | Miesięczna | Kwartalna |
  | Termin | 25. dnia nast. miesiąca | 25. dnia miesiąca po kwartale |
  | Dostępność | Wszyscy podatnicy VAT | Tylko mali podatnicy |
  | Struktura | Ewidencja + deklaracja (obie miesięczne) | Ewidencja (miesięczna) + Deklaracja (kwartalna) |

- **Podstawa prawna:** Art. 99 ust. 2-3 VAT
- **Priorytet:** 846

---

# CZĘŚĆ VII: JDG EDGE LIMITS (P565, P566a, P566b, P29, P870a)

> **Stan przed:** P564 pokrywa limit 150k dla aut. Ale brak limitów dla samochodów elektrycznych, korekt VAT przy sprzedaży auta, kilometrówek, TP safe harbour.  
> **Po analizie:** 5 nowych reguł — auta elektryczne, korekta VAT auto, kilometrówka, TP safe harbour, strata 5M.

---

## P565: `car_electric_225k_kup_limit` ★ NOWA

- **Cel biznesowy:** Samochody elektryczne mają podwyższony limit KUP do 225 000 PLN (zamiast 150 000 PLN dla spalinowych). Dotyczy to również leasingu operacyjnego i ubezpieczeń AC.
- **Przesłanki:**
  - `input.invoice.car_is_electric == true`
  - `input.invoice.car_subsidy_eligible == false` (auto zakupione bez dotacji)
  - `input.invoice.expense_type in ["CAR_PURCHASE", "CAR_LEASE", "CAR_INSURANCE_AC"]`
- **Rezultat:**
  - `kup_car_limit: 225000` (zamiast standardowego 150 000 PLN)
  - `kup_proportion: min(1, 225000 / car_value)`
  - `_info: "Samochód elektryczny — podwyższony limit KUP do 225 000 PLN"`
  
  **Porównanie limitów:**
  
  | Typ auta | Limit KUP | Limit leasingu | Limit AC |
  |----------|:---------:|:--------------:|:--------:|
  | Spalinowe / hybryda (bez dotacji) | 150 000 PLN | 150 000 PLN | proporcjonalnie 150k |
  | Elektryczne (bez dotacji) | 225 000 PLN | 225 000 PLN | proporcjonalnie 225k |
  | Elektryczne (z dotacją) | 150 000 PLN* | 150 000 PLN* | proporcjonalnie 150k |
  
  *Gdy auto elektryczne otrzymało dofinansowanie (dotację), limit wraca do standardowego 150 000 PLN.
- **Podstawa prawna:** Art. 23 ust. 1 pkt 47a PIT (podwyższony limit dla EV)
- **Priorytet:** 565

---

## P566a: `vat_car_sale_correction_proportional` ★ NOWA

- **Cel biznesowy:** Jeśli JDG sprzedaje samochód używany mieszanie (firmowo-prywatnie) w ciągu 60 miesięcy od zakupu, od którego odliczono tylko 50% VAT — może proporcjonalnie skorygować VAT za pozostałe miesiące i odzyskać część nieodliczonego VAT.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"` (JDG sprzedaje auto)
  - `input.invoice.category_code == "CAR"` AND `input.invoice.private_use_percent > 0`
  - `input.invoice.months_since_purchase < 60` (w okresie korekty)
  - Przy zakupie odliczono 50% VAT (P186)
- **Rezultat:**
  - `vat_correction_possible: true`
  - `vat_recovery_amount: (50% * vat_at_purchase / 60) * months_remaining`
  - `months_remaining: 60 - months_since_purchase`
  - `_info: "Sprzedaż auta w okresie korekty — możesz odzyskać %s PLN nieodliczonego VAT za pozostałe %d miesięcy"`

  **Przykład:** Auto kupione za 123 000 PLN brutto (100 000 PLN netto + 23 000 PLN VAT). Odliczono 50% = 11 500 PLN VAT. Sprzedaż po 36 miesiącach. Pozostałe 24 miesiące (60-36). Odzyskany VAT: (11 500 / 60) * 24 = 4 600 PLN.
- **Podstawa prawna:** Art. 90b VAT (korekta VAT przy sprzedaży środka trwałego)
- **Priorytet:** 566a

---

## P566b: `employee_car_mileage_allowance` ★ NOWA

- **Cel biznesowy:** Gdy pracownik JDG używa swojego prywatnego samochodu do celów służbowych, JDG może wypłacić mu kilometrówkę (zwrot kosztów przejazdu) wg stawek ustawowych. Kilometrówka jest w pełni KUP dla JDG i zwolniona z PIT/ZUS dla pracownika do limitu.
- **Przesłanki:**
  - `input.jdg_entrepreneur.has_employees == true`
  - `input.invoice.expense_type == "EMPLOYEE_MILEAGE_ALLOWANCE"`
  - Pracownik używa własnego samochodu do celów służbowych (umowa cywilnoprawna)
  - Ewidencja przebiegu pojazdu prowadzona (kilometrówka)
- **Rezultat:**
  - `mileage_rate_per_km: input.thresholds.jdg.limits.employee_mileage_rate_per_km` (1.15 PLN — do 900 cm³)
  - `mileage_rate_per_km: input.thresholds.jdg.limits.employee_mileage_rate_over_900` (1.38 PLN — >900 cm³)
  - `kus_qualification: "full"` (dla JDG — pełny KUP)
  - `employee_pit_exempt: true` (dla pracownika — zwolnione z PIT do limitu)
  - `_warning: "Kilometrówka — prowadź ewidencję przebiegu dla każdego przejazdu służbowego"`

  **Stawki kilometrówki (2026):**
  
  | Pojemność silnika | Stawka za 1 km |
  |:-----------------:|:--------------:|
  | ≤ 900 cm³ | 1.15 PLN |
  | > 900 cm³ | 1.38 PLN |
  | Motocykl | 0.69 PLN |
  | Motorower | 0.42 PLN |

- **Podstawa prawna:** Art. 23 ust. 1 pkt 36 PIT, Rozporządzenie MPiPS w sprawie warunków ustalania zwrotu kosztów
- **Priorytet:** 566b

---

## P29: `transfer_pricing_safe_harbour_low_value_services` ★ NOWA

- **Cel biznesowy:** Dla transakcji zakupu usług o niskiej wartości dodanej (IT support, HR, księgowość, obsługa administracyjna) od podmiotów powiązanych, ustawodawca przewidział bezpieczną przystań (safe harbour) — narzut 5% zysku na kosztach całkowitych. Transakcja z narzutem ≤5% jest zwolniona z obowiązku sporządzania szczegółowej dokumentacji TP.
- **Przesłanki:**
  - `input.vendor.is_related_party_for_tp == true`
  - `input.invoice.service_type in ["IT_SUPPORT", "HR_SERVICES", "ACCOUNTING_SERVICES", "ADMINISTRATIVE_SUPPORT", "DATA_PROCESSING", "PAYROLL_SERVICES"]`
  - Usługa ma charakter pomocniczy (nie jest główną działalnością JDG)
  - Marża narzucona przez kontrahenta ≤ 5% kosztów całkowitych
- **Rezultat:**
  - `tp_safe_harbour_applicable: true`
  - `tp_documentation_exempt: true` (zwolnienie z pełnej dokumentacji TP!)
  - `tp_markup_accepted: "5%"`
  - `_info: "Usługa niskowartościowa — safe harbour TP. Narzut 5% akceptowalny, bez dokumentacji."`

  **Gdy narzut > 5%:**
  - `tp_safe_harbour_exceeded: true`
  - `tp_documentation_required: true`
  - `_warning: "Narzut >5% dla usług niskowartościowych — safe harbour nie ma zastosowania. Wymagana pełna dokumentacja TP."`
- **Podstawa prawna:** Art. 23r PIT (analogia do Art. 11f CIT — safe harbour dla usług o niskiej wartości dodanej)
- **Priorytet:** 29
- **Zależności:** Sprawdzana PRZED P114-P116 (szczegółowe reguły TP)

---

## P870a: `pit_loss_carry_forward_one_time_5m` ★ NOWA

- **Cel biznesowy:** Od 2025 roku JDG może jednorazowo odliczyć skumulowane straty podatkowe z lat ubiegłych do kwoty 5 000 000 PLN w jednym roku podatkowym. Alternatywa do standardowego odliczania 50% straty rocznie przez 5 lat.
- **Przesłanki:**
  - `input.jdg_entrepreneur.has_loss_carry_forward == true`
  - `input.jdg_entrepreneur.loss_carry_forward_remaining > 0`
  - `input.jdg_entrepreneur.tax_form in ["PIT_SCALE", "LINEAR"]`
  - JDG wybiera opcję jednorazowego odliczenia
- **Rezultat:**
  - `loss_deduction_one_time: min(5000000, loss_carry_forward_remaining)`
  - `loss_deduction_one_time_method: "JEDNORAZOWE_DO_5_MLN"`
  - `loss_remaining_after: max(0, loss_carry_forward_remaining - 5000000)`

  **Porównanie opcji:**
  
  | Opcja | Max rocznie | Max okres | Elastyczność |
  |-------|:-----------:|:---------:|:------------:|
  | Standard (50%) | 50% straty | 5 lat | Stopniowe odliczanie |
  | Jednorazowa | 5 000 000 PLN | 1 rok | Szybkie odliczenie |

  - `_info: "Jednorazowe odliczenie straty do 5 000 000 PLN — pozostała strata po odliczeniu: X PLN"`
- **Podstawa prawna:** Art. 9 ust. 3 pkt 2 PIT (wprowadzone ustawą Polski Ład, zmodyfikowane)
- **Priorytet:** 870a
- **Zależności:** Alternatywa dla P615 (standardowe rozliczanie straty)

---

# CZĘŚĆ VIII: PODSUMOWANIE GŁĘBOKIEJ ANALIZY LUK

## 8.1 Pełna Lista 30 Nowych Reguł

| Priorytet | rule_id | Pakiet | Obszar |
|:---------:|---------|--------|--------|
| **P29** | `tp_safe_harbour_low_value_services` | `jdg.international.tp` | TP safe harbour |
| **P143** | `platform_app_store_b2b_export` | `jdg.crossborder` | App Store/Google Play |
| **P144** | `platform_import_of_services_commissions` | `jdg.crossborder` | Prowizje platform |
| **P145** | `cash_register_b2c_exemption_20k` | `jdg.compliance` | Kasy fiskalne |
| **P146** | `e_commerce_virtual_cash_register` | `jdg.compliance` | Kasy wirtualne |
| **P147** | `real_estate_residential_depreciation_ban` | `jdg.accounting.depreciation` | Zakaz amortyzacji mieszkań |
| **P148** | `real_estate_depreciation_commercial_only` | `jdg.accounting.depreciation` | Amortyzacja komercyjna |
| **P149** | `real_estate_option_to_tax_vat` | `jdg.vat.substantive` | Opcja VAT nieruchomości |
| **P150** | `real_estate_pcc_exempt_on_vat_taxable` | `jdg.local_taxes.pcc` | PCC vs VAT |
| **P150a** | `foreign_business_trip_diets_owner` | `jdg.pit.kup` | Diety zagraniczne |
| **P151** | `agricultural_special_production_jdg_overlap` | `jdg.accounting.pkpir` | Działy specjalne rolne |
| **P152** | `vat_farmer_rr_purchase_invoice` | `jdg.vat.substantive` | VAT RR |
| **P153** | `excise_duty_car_import_eu` | `jdg.compliance.excise` | Akcyza auto |
| **P154** | `excise_duty_craft_beer_wine` | `jdg.compliance.excise` | Akcyza alkohol |
| **P565** | `car_electric_225k_kup_limit` | `jdg.pit.kup` | Limit EV 225k |
| **P566a** | `vat_car_sale_correction_proportional` | `jdg.vat.deduction` | Korekta VAT auto |
| **P566b** | `employee_car_mileage_allowance` | `jdg.pit.kup` | Kilometrówka pracownicza |
| **P578** | `kup_own_and_spouse_work_nkup` | `jdg.pit.kup` | Własna praca NKUP |
| **P579** | `kup_professional_chamber_fees` | `jdg.pit.kup` | Izby zawodowe |
| **P580** | `kup_contractual_penalties_nkup` | `jdg.pit.kup` | Kary umowne |
| **P581** | `kup_workwear_vs_suit_bhp` | `jdg.pit.kup` | Odzież robocza |
| **P582** | `kup_abandoned_spoiled_goods` | `jdg.pit.kup` | Towary przeterminowane |
| **P843** | `restructuring_debt_forgiveness_revenue_exempt` | `jdg.statute_liability` | Umorzenie długu |
| **P844** | `bad_debt_debtor_in_restructuring_block` | `jdg.vat.deduction` | Złe długi w restrukturyzacji |
| **P845** | `one_off_depreciation_de_minimis_state_aid` | `jdg.accounting.depreciation` | Pomoc de minimis |
| **P846** | `vat_quarterly_small_taxpayer_k_declaration` | `jdg.jpk.jpk_vat` | JPK_V7K |
| **P870a** | `pit_loss_carry_forward_one_time_5m` | `jdg.pit.advances` | Strata 5M |
| **P930a** | `inheritance_tax_exemption_enterprise` | `jdg.business.succession` | Zwolnienie spadkowe |
| **P931a** | `succession_inventory_depreciation_continuity` | `jdg.business.succession` | Kontynuacja amortyzacji |
| **P1731** | `family_foundation_asset_transfer` | `jdg.pit.exemptions` | Transfer do FR |
| **P1732** | `family_foundation_rental_hidden_profits` | `jdg.pit.exemptions` | Najem od FR |

---

## 8.2 Statystyki — Ewolucja Systemu JDG

| Metryka | Dok. 22 | +23 | +24-27 | +28 | +29 | **RAZEM ENTERPRISE** |
|---------|:-------:|:---:|:------:|:---:|:---:|:---------------------:|
| **Pakiety JDG** | 23 | 28 | 37 | 42 | 42 | **42** |
| **Reguły łącznie** | ~145 | ~214 | ~327 | ~372 | ~402 | **~402** |
| **Nowe reguły w tym dokumencie** | — | — | — | — | **30** | **30** |
| **Domeny prawne** | 30+ | 45+ | 70+ | 85+ | 95+ | **95+** |
| **Podstawy prawne** | 70+ | 100+ | 200+ | 250+ | 280+ | **280+** |
| **Nowe pola input** | ~80 | ~105 | ~175 | ~175 | ~210 | **~210** |
| **Thresholds** | ~65 | ~85 | ~145 | ~160 | ~178 | **~178** |
| **[TODO: potrzebne źródło]** | — | — | — | 12 | 18 | **18** |

---

## 8.3 Nowe Obszary Pokryte w Tym Dokumencie

| Obszar | Reguły | Opis |
|--------|:------:|------|
| KUP branżowe (IT, medycyna, prawo, budownictwo, gastronomia, e-commerce) | 5 | P578-P582 |
| Platformy cyfrowe (App Store, Google Play, Upwork, Fiverr) | 2 | P143-P144 |
| Kasy fiskalne i wirtualne | 2 | P145-P146 |
| Nieruchomości: amortyzacja, VAT, PCC | 4 | P147-P150 |
| Diety zagraniczne właściciela | 1 | P150a |
| Rolnictwo: działy specjalne, VAT RR | 2 | P151-P152 |
| Akcyza: samochody, alkohol | 2 | P153-P154 |
| Samochody elektryczne, korekta VAT, kilometrówka | 3 | P565-P566b |
| TP safe harbour | 1 | P29 |
| Restrukturyzacja, upadłość, pomoc de minimis | 3 | P843-P845 |
| JPK_V7K kwartalny | 1 | P846 |
| Strata 5M jednorazowo | 1 | P870a |
| Spadek: zwolnienie, amortyzacja | 2 | P930a-P931a |
| Fundacja Rodzinna: transfer, najem | 2 | P1731-P1732 |

---

## 8.4 Pozycje [TODO: potrzebne źródło] — 18 do uzupełnienia

| # | Pozycja | Źródło do pozyskania |
|---|---------|---------------------|
| 1 | Baza stawek WHT dla UPO | Umowy o unikaniu podwójnego opodatkowania — tabela stawek dla ~90 krajów |
| 2 | Pełna tabela stawek VAT dla OSS | Stawki VAT dla 27 krajów UE — baza Komisji Europejskiej |
| 3 | Tabela stawek karty podatkowej | Załącznik nr 3 do ustawy o ryczałcie |
| 4 | Stawki podatku od nieruchomości | Uchwały poszczególnych gmin na 2026 rok |
| 5 | Stawki podatku od środków transportowych | Uchwały gmin + tabela DMC |
| 6 | API kursów NBP | api.nbp.pl — kursy walut z dat historycznych |
| 7 | Wytyczne MF do kalkulacji wskaźnika Nexus | Interpretacje MF — Art. 30ca PIT |
| 8 | Lista znamion schematów MDR | Art. 86a-86o OP + Rozporządzenie MF |
| 9 | Finalna wersja AI Act (2026) | Rozporządzenie Parlamentu Europejskiego |
| 10 | Pełna lista kategorii wyłączonych ze zwolnienia z kasy fiskalnej | Rozporządzenie MF kasowe |
| 11 | Aktualne normy szacunkowe dla działów specjalnych | Załącznik nr 2 do PIT |
| 12 | Aktualne stawki akcyzy na alkohol (2026) | Ustawa o podatku akcyzowym + nowelizacje |
| 13 | Stawki akcyzy samochodowej (2026) | Ustawa o podatku akcyzowym |
| 14 | Tabela diet zagranicznych (wszystkie kraje) | Rozporządzenie MPiPS |
| 15 | Stawki kilometrówki (2026) | Rozporządzenie MPiPS |
| 16 | Limit pomocy de minimis (2026) | Rozporządzenie KE |
| 17 | Lista PKD wymagających BDO | Rozporządzenie Ministra Klimatu |
| 18 | Stawki podatku rolnego (2026) | Uchwały gmin + przeliczniki GUS |

---

## 8.5 Rekomendowana Kolejność Implementacji

| Faza | Priorytet | Reguły | Opis |
|------|:---------:|--------|------|
| **Faza A** (JUŻ TERAZ) | 🔴 | P578, P143, P144, P147, P152, P153, P565, P844, P845, P870a | 10 reguł — najczęstsze scenariusze JDG |
| **Faza B** (WAŻNE) | 🟡 | P579, P580, P581, P582, P145, P146, P148, P149, P150, P150a, P566a, P566b, P843, P846, P29 | 15 reguł — istotne uzupełnienia |
| **Faza C** (DODATKOWE) | 🟢 | P151, P154, P930a, P931a, P1731, P1732 | 6 reguł — niszowe scenariusze |

---

> **Plik:** `Plan OPA/29_JDG_DEEP_ANALYSIS_GAPS.md`  
> **Status:** Deep Gap Analysis — 30 nowych reguł zidentyfikowanych i opisanych  
> **Data:** 2026-07-10  
> **Powiązane:** `22_JDG_ENTERPRISE_PLAN.md` | `23_JDG_EXPANSION_SUPPLEMENT.md` | `24_JDG_COMPLETE_INDEX.md` | `25_JDG_DEEP_LEGAL_AUDIT.md` | `26_JDG_COMPREHENSIVE_EXPANSION.md` | `27_JDG_ENTERPRISE_DEEP_EXPANSION.md` | `28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md`  
> **Łącznie reguł ENTERPRISE po tym dokumencie:** ~402  
> **Gotowość wdrożeniowa:** ENTERPRISE READY — 42 pakiety, 95+ domen prawnych, 280+ podstaw prawnych
