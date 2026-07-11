# 🚨 JDG Critical Gaps Closure — 12 Krytycznych Luk Prawnych (Ready for Implementation)

> **Status:** ENTERPRISE v1.0 — Pełny 10-polowy format dla 12 reguł KRYTYCZNYCH z Doc 25
> **Data:** 2026-07-11
> **Źródło:** `25_JDG_DEEP_LEGAL_AUDIT.md` — 12 luk oznaczonych 🔴 KRYTYCZNA
> **Reguł:** **12** | **Pakiety:** 7 (risk, compliance, vat, pit, zus, allowances, statute_liability)
> **Format:** Każda reguła = pełny 10-polowy opis ENTERPRISE: cel biznesowy, przesłanki szczegółowe, rezultat, podstawa prawna, edge cases, zależności, thresholds, przykład pozytywny i negatywny
>
> **Powiązane:** `38_JDG_QUALITY_AUDIT.md` (audyt jakości), `36_JDG_GAP_IMPLEMENTATION_PLAN.md` (pseudokod Rego)

---

## ⚡ QUICK INDEX — 12 Krytycznych Reguł

| # | P-ID | Reguła | Pakiet | Art. | Ryzyko braku |
|---|:----:|--------|--------|------|-------------|
| 1 | **P0_b** | `kks_empty_invoice_fraud` | `jdg.risk` | Art. 62 § 2 KKS | Odpowiedzialność karna do 25 lat |
| 2 | **P4** | `kks_hidden_income_flag` | `jdg.risk` | Art. 54 KKS | Nieujawnione dochody |
| 3 | **P6** | `kks_unreliable_books` | `jdg.risk` | Art. 56 KKS | Nierzetelna PKPiR |
| 4 | **P9** | `gaar_artificial_scheme` | `jdg.risk` | Art. 119a OP | Klauzula anty-avoidance |
| 5 | **P36** | `vat_simplified_receipt_450pln` | `jdg.compliance` | Art. 106e ust. 5 VAT | Utrata odliczenia VAT z paragonów |
| 6 | **P39** | `vat_r_registration_mandatory` | `jdg.vat` | Art. 96 VAT | Faktury VAT bez rejestracji |
| 7 | **P184** | `bad_debt_debtor_correction` | `jdg.vat.deduction` | Art. 89b VAT | Sankcja 30% za brak korekty |
| 8 | **P192** | `vat_refund_timing` | `jdg.vat` | Art. 87 VAT | Przegapiony zwrot / odsetki |
| 9 | **P508** | `pit_revenue_exclusions` | `jdg.pit` | Art. 14 ust. 3 PIT | Zawyżony przychód |
| 10 | **P524** | `lump_sum_exclusions` | `jdg.pit.form_lump_sum` | Art. 8 u.z.p.d. | Błędna forma opodatkowania |
| 11 | **P572** | `kup_direct_vs_indirect` | `jdg.pit.kup` | Art. 22 ust. 5-5c PIT | KUP w złym roku podatkowym |
| 12 | **P743** | `concurrent_etat_jdg_zus` | `jdg.zus` | Art. 9 SUS | Zawyżone składki ZUS |

---

## 📐 STRUKTURA 10-POLOWA (KAŻDA REGUŁA)

| # | Pole | Znaczenie |
|---|------|-----------|
| 1 | **P-ID** | Identyfikator priorytetu P0_b–P743 |
| 2 | **Nazwa** | `jdg.<pakiet>.<nazwa_reguly>` — angielska, zgodna z konwencją Rego |
| 3 | **Cel biznesowy** | 2–4 zdania: co reguła sprawdza i dlaczego jest krytyczna dla ENTERPRISE |
| 4 | **Przesłanki** | Rozbite warunki logiczne (każdy w osobnej linii) z konkretnymi `input.*` polami |
| 5 | **Rezultat** | Co zwraca: `matched`, `_routing`, konkretne pola decyzyjne |
| 6 | **Podstawa prawna** | Dokładny artykuł, ustęp, punkt + Dz.U. |
| 7 | **Edge cases** | Scenariusze brzegowe i jak reguła na nie reaguje |
| 8 | **Zależności** | Które reguły muszą być sprawdzone przed/po |
| 9 | **Thresholds** | Parametry z `input.thresholds.jdg.*` |
| 10 | **Przykład ±** | Konkretny liczbowy przykład pozytywny i negatywny |

---

## 1. P0_b: `jdg.risk.kks_empty_invoice_fraud`

- **Cel biznesowy:** Wykrywa fakturę dokumentującą czynność, która NIE została dokonana (pusta faktura / fałszywa faktura VAT). To przestępstwo skarbowe zagrożone karą do 25 lat pozbawienia wolności przy wartościach przekraczających 10 mln PLN. Reguła musi działać NATYCHMIAST po wykryciu — blokada faktury i alert do compliance officer.
- **Przesłanki szczegółowe:**
  - `input.vendor.fraud_flag == true` (kontrahent w sieci fraudowej)
  - `input.invoice.delivery_confirmed == false` (brak potwierdzenia dostawy towaru lub wykonania usługi)
  - `input.invoice.amount_gross > 0` (faktura niezerowa)
  - `input.invoice.direction == "PURCHASE"` (zakup — próba wyłudzenia VAT)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `kks_risk:"Art.62_par2"`, `max_penalty:"25_lat"`, `_warnings:["PUSTA FAKTURA — czynność nie została dokonana. Ryzyko KKS Art. 62 § 2."]`
- **Podstawa prawna:** Art. 62 § 2 i § 2a KKS (Dz.U. 2024 poz. 1455)
- **Edge cases:**
  - (a) Faktura zaliczkowa przed dostawą → `delivery_confirmed == false`, ale `is_advance == true` → NIE matchuje (dostawa oczekiwana w przyszłości)
  - (b) Faktura korygująca in minus → `is_correction == true` → NIE matchuje (korekta = zmiana istniejącej faktury, nie nowa)
  - (c) Faktura pro forma → `amount_gross == 0` → NIE matchuje (dokument informacyjny)
  - (d) Usługa niematerialna (konsulting zdalny) → `delivery_confirmed` może być trudne do zweryfikowania → użyj `SemanticGuard` + `vendor.trust_score`
- **Zależności:** R0001 `fraud_graph_match` (P0) — **ta reguła jest wywoływana PRZED P0** w else-chainie, ponieważ jest bardziej szczegółowa (fraud + brak dostawy). Jeśli P0_b matchuje (pusta faktura), P0 nie jest już sprawdzane (first-match-wins). Implementacja: `else := { } { fraud AND no_delivery }` → jeśli nie matchuje → next `else := { } { fraud }` (P0).
- **Thresholds:** brak (reguła binarna)
- **Przykład +:** Kontrahent z fraud_flag=true, faktura 50k PLN za "usługi doradcze", brak umowy, brak potwierdzenia wykonania, brak płatności → BLOCK + alert KKS Art. 62 § 2
- **Przykład −:** Kontrahent z fraud_flag=false → NIE matchuje; kontrahent z fraud_flag=true, ale dostawa potwierdzona dokumentem WZ → NIE matchuje

---

## 2. P4: `jdg.risk.kks_hidden_income_flag`

- **Cel biznesowy:** Wykrywa rozbieżność między wpływami na rachunek firmowy a zadeklarowanymi przychodami JDG. Jeśli wpływy przekraczają deklarowane przychody o >30%, istnieje ryzyko ukrywania dochodów (Art. 54 KKS). Reguła generuje alert TRIAGE i flaguje JDG do manualnej weryfikacji.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.bank_deposits_ytd > 0` (suma wpływów na konto firmowe w roku)
  - `input.jdg_entrepreneur.declared_revenue_ytd > 0` (suma zadeklarowanych przychodów)
  - `ABS(bank_deposits_ytd - declared_revenue_ytd) / declared_revenue_ytd > input.thresholds.jdg.limits.kks_discrepancy_threshold` (domyślnie 0.30)
  - `bank_deposits_ytd > declared_revenue_ytd` (wpływy większe niż deklarowane)
- **Rezultat:** `matched:true`, `_routing:"TRIAGE_QUEUE"`, `kks_risk:"Art.54"`, `discrepancy_percent:<obliczona wartość>`, `_warnings:["Rozbieżność między wpływami a deklarowanymi przychodami >30% — ryzyko ukrytych dochodów KKS Art. 54"]`
- **Podstawa prawna:** Art. 54 § 1 KKS
- **Edge cases:**
  - (a) Duży przelew prywatny (np. sprzedaż samochodu prywatnego) → fałszywy alarm → wymaga oddzielenia kont firmowych od prywatnych w `input`
  - (b) Dotacja / subwencja → NIE jest przychodem z JDG → powinna być wyłączona z `bank_deposits_ytd`
  - (c) Kredyt firmowy → wpływa na konto, ale NIE jest przychodem → wyłączyć
  - (d) JDG na ryczałcie → przychód = podstawa opodatkowania → łatwiejsza weryfikacja
- **Zależności:** BankAggregator (wpływy) + RevenueAggregator (deklarowane przychody). Poprzedza P6 (nierzetelne księgi).
- **Thresholds:** `jdg.limits.kks_discrepancy_threshold` (0.30)
- **Przykład +:** Wpływy na konto 500k PLN, deklarowany przychód 200k PLN → rozbieżność 150% > 30% → TRIAGE + alert KKS
- **Przykład −:** Wpływy 210k PLN, deklarowane 200k PLN → rozbieżność 5% < 30% → NIE matchuje

---

## 3. P6: `jdg.risk.kks_unreliable_books`

- **Cel biznesowy:** Wykrywa nierzetelnie prowadzoną PKPiR lub ewidencję ryczałtową. Jeśli integrity score spada poniżej progu, reguła blokuje dalsze księgowanie i generuje alert KKS. Nierzetelność ksiąg to przestępstwo skarbowe (Art. 56 KKS) zagrożone grzywną do 720 stawek dziennych.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.uses_pkpir == true` (prowadzi PKPiR)
  - `input.accounting.pkpir_integrity_score < input.thresholds.jdg.limits.pkpir_integrity_min` (domyślnie 0.70)
  - `input.accounting.pkpir_entry_count > 0` (PKPiR nie jest pusta)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `kks_risk:"Art.56"`, `pkpir_integrity_score:<wartość>`, `_warnings:["Nierzetelna PKPiR — integrity score < 70%. Ryzyko KKS Art. 56. Skoryguj ewidencję."]`
- **Podstawa prawna:** Art. 56 § 1-2 KKS, Art. 24a PIT
- **Edge cases:**
  - (a) Nowa PKPiR (pusta, pierwszy miesiąc) → `entry_count == 0` → NIE matchuje
  - (b) Pierwszy miesiąc roku → niższy próg akceptacji (np. 0.50 zamiast 0.70) — użyj `is_january`
  - (c) Ewidencja ryczałtowca zamiast PKPiR → osobna reguła (ta dotyczy tylko PKPiR)
  - (d) Luki w numeracji + braki dat + niespójności kwotowe = niski integrity score
- **Zależności:** PKPiRIntegrityChecker musi wcześniej obliczyć `pkpir_integrity_score`. Po R0010 (płytka wersja) — ta reguła jest głębsza.
- **Thresholds:** `jdg.limits.pkpir_integrity_min` (0.70)
- **Przykład +:** PKPiR z 50 wpisami: 15 braków numeracji, 8 niespójności kwotowych → score=0.35 < 0.70 → BLOCK + alert KKS
- **Przykład −:** PKPiR z 200 wpisami, pełna numeracja, spójne kwoty → score=0.95 > 0.70 → NIE matchuje

---

## 4. P9: `jdg.risk.gaar_artificial_scheme`

- **Cel biznesowy:** Wykrywa transakcje, które mogą być uznane za sztuczne struktury unikania opodatkowania w rozumieniu klauzuli GAAR (Art. 119a Ordynacji podatkowej). GAAR pozwala US pominąć skutki podatkowe sztucznych czynności dokonanych wyłącznie dla korzyści podatkowej. ENTERPRISE musi mieć zabezpieczenie anty-avoidance.
- **Przesłanki szczegółowe:**
  - `input.vendor.is_related_party == true` (podmiot powiązany)
  - `ABS(input.invoice.amount_net - input.invoice.market_price) / input.invoice.market_price > input.thresholds.jdg.limits.gaar_price_deviation` (domyślnie 0.50 — cena odbiega o >50% od rynkowej)
  - `input.invoice.amount_gross >= input.thresholds.jdg.limits.gaar_materiality` (transakcja powyżej progu istotności)
  - `input.invoice.has_economic_substance == false` (brak uzasadnienia ekonomicznego poza podatkowym)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `gaar_risk_level:"HIGH"`, `gaar_triggered:true`, `_warnings:["Potencjalna klauzula GAAR — transakcja może być uznana za sztuczną strukturę unikania opodatkowania (Art. 119a OP)"]`
- **Podstawa prawna:** Art. 119a § 1 Ordynacji podatkowej (Dz.U. 2024 poz. 481)
- **Edge cases:**
  - (a) Uzasadniona ekonomicznie cena promocyjna (np. wyprzedaż) → `has_economic_substance == true` → NIE matchuje
  - (b) Transakcja z podmiotem powiązanym, ale cena rynkowa (dokumentacja TP) → NIE matchuje
  - (c) Cena odbiega o 49% (poniżej progu 50%) → NIE matchuje
  - (d) Transakcja < progu materialności (np. 50k PLN) → NIE matchuje
- **Zależności:** MarketDataService do `market_price`. R0008 `related_party_transaction` (TP) — reguła GAAR ma wyższy priorytet.
- **Thresholds:** `jdg.limits.gaar_price_deviation` (0.50), `jdg.limits.gaar_materiality` (50 000)
- **Przykład +:** Podmiot powiązany (brat JDG), cena rynkowa usługi 100k PLN, faktura na 5k PLN (95% poniżej rynku), brak uzasadnienia ekonomicznego → GAAR HIGH → BLOCK
- **Przykład −:** Podmiot powiązany, cena rynkowa 100k, faktura 95k (5% odchylenia) → NIE matchuje

---

## 5. P36: `jdg.compliance.vat_simplified_receipt_450pln`

- **Cel biznesowy:** Paragon fiskalny z NIP nabywcy do kwoty 450 PLN brutto (równowartość 100 EUR) jest traktowany jak faktura uproszczona — można od niego odliczyć VAT naliczony. Powyżej 450 PLN paragon NIE jest fakturą i NIE uprawnia do odliczenia. Reguła jest krytyczna dla JDG — codzienne zakupy paliwa, materiałów biurowych, narzędzi.
- **Przesłanki szczegółowe:**
  - `input.invoice.invoice_type == "RECEIPT"` (paragon, nie faktura)
  - `input.invoice.has_nip == true` (na paragonie jest NIP nabywcy — JDG)
  - `input.invoice.amount_gross <= input.thresholds.jdg.limits.simplified_receipt_limit` (450 PLN)
  - `input.jdg_entrepreneur.is_vat_payer == true`
- **Rezultat:** `matched:true`, `vat_deduction_allowed:true`, `invoice_type_equivalent:"SIMPLIFIED_INVOICE"`, `_warnings:["Paragon z NIP do 450 PLN = faktura uproszczona — możesz odliczyć VAT"]`
- **Podstawa prawna:** Art. 106e ust. 5 pkt 3 VAT
- **Edge cases:**
  - (a) Paragon bez NIP nabywcy → NIE matchuje (brak prawa do odliczenia — zwykły paragon B2C)
  - (b) Paragon 451 PLN → przekroczony limit o 1 PLN → NIE matchuje (brak odliczenia VAT!)
  - (c) Paragon za paliwo 300 PLN z NIP → odliczenie VAT 23% = 69 PLN
  - (d) Paragon w walucie obcej → przeliczenie wg kursu NBP z dnia wystawienia → limit 100 EUR
- **Zależności:** Po R0029 (whitelist), przed regułami odliczeń VAT (R0111+). Niezależna od R0113 `deduction_invoice_possession` — paragon ZASTĘPUJE fakturę.
- **Thresholds:** `jdg.limits.simplified_receipt_limit` (450)
- **Przykład +:** Paragon za olej silnikowy 380 PLN brutto z NIP JDG → odliczenie VAT 71 PLN → reguła matchuje, allow
- **Przykład −:** Paragon 600 PLN z NIP → powyżej 450 PLN → NIE matchuje, brak odliczenia VAT

---

## 6. P39: `jdg.vat.vat_r_registration_mandatory`

- **Cel biznesowy:** Blokada wystawiania faktur VAT przez JDG, który NIE złożył zgłoszenia rejestracyjnego VAT-R. Rejestracja VAT musi nastąpić PRZED pierwszą czynnością opodatkowaną. Faktura VAT wystawiona przed rejestracją jest wadliwa — kontrahent nie może odliczyć VAT, a JDG naraża się na sankcje.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.is_vat_payer == true` (chce być czynnym podatnikiem)
  - `input.jdg_entrepreneur.vat_r_submitted == false` (NIE złożył VAT-R)
  - `input.invoice.direction == "SALE"` (próba wystawienia faktury sprzedaży)
  - `input.invoice.vat_rate != "0.00"` (faktura z VAT)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `vat_r_required:true`, `_warnings:["Brak zgłoszenia VAT-R — nie możesz wystawiać faktur z VAT. Złóż VAT-R przed pierwszą czynnością opodatkowaną."]`
- **Podstawa prawna:** Art. 96 ust. 1, ust. 4-5 VAT
- **Edge cases:**
  - (a) JDG na zwolnieniu podmiotowym → `is_vat_payer == false` → NIE matchuje
  - (b) VAT-R złożony, ale US jeszcze nie przetworzył → `vat_r_submitted == true, vat_r_processed == false` → NIE matchuje (zgłoszenie złożone — oczekiwanie na decyzję to ryzyko JDG)
  - (c) ⚠️ Faktura z 0% VAT (np. eksport, WDT) → `vat_rate == "0.00"` ALE `vat_treatment == "TAXABLE"` → **reguła NIE matchuje tylko jeśli `vat_treatment == "EXEMPT"` (zwolnienie przedmiotowe). 0% stawka (eksport/WDT) nadal wymaga VAT-R!**
  - (d) Ponowna rejestracja po wykreśleniu → `vat_r_submitted` resetuje się
- **Zależności:** Przed R0038 (ogólna reguła VAT-R compliance). Wywoływana po R0546 (breach detection) przy przekroczeniu limitu zwolnienia.
- **Thresholds:** brak
- **Przykład +:** JDG przekroczył limit zwolnienia 200k, NIE złożył VAT-R, próbuje wystawić fakturę 23% na 50k PLN → BLOCK
- **Przykład −:** JDG czynny VAT, VAT-R złożony → NIE matchuje

---

## 7. P184: `jdg.vat.deduction.bad_debt_debtor_correction`

- **Cel biznesowy:** **OBOWIĄZEK dłużnika:** jeśli JDG (jako nabywca) nie zapłacił faktury w ciągu 90 dni od terminu płatności, MUSI skorygować odliczony VAT in minus (zwrócić do US). To NIE jest opcja — to obowiązek ustawowy. Brak korekty = sankcja 30% VAT. Reguła wykrywa przekroczenie 90 dni i generuje alert z datą graniczną.
- **Przesłanki szczegółowe:**
  - `input.invoice.direction == "PURCHASE"` (JDG jest dłużnikiem/nabywcą)
  - `input.invoice.is_paid == false`
  - `input.invoice.days_overdue >= input.thresholds.jdg.limits.bad_debt_days_cit_pit` (90 dni od terminu płatności)
  - `input.invoice.is_vat_deducted == true` (VAT został wcześniej odliczony)
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `vat_correction_mandatory:true`, `vat_to_return:<odliczony VAT>`, `days_overdue:<wartość>`, `sanction_if_not_corrected:"30%_VAT"`, `_warnings:["NIE ZAPŁACIŁEŚ FAKTURY >90 DNI — OBOWIĄZKOWA korekta VAT in minus. Zwróć odliczony VAT. Sankcja 30% za brak korekty."]`
- **Podstawa prawna:** Art. 89b ust. 1 i ust. 2 VAT
- **Edge cases:**
  - (a) 90. dzień wypada w weekend → termin NIE przesuwa się (to data zdarzenia, nie termin urzędowy)
  - (b) Częściowa zapłata → korekta proporcjonalna do niezapłaconej części
  - (c) Dłużnik w restrukturyzacji/upadłości → NIE ma obowiązku korekty (Art. 89b ust. 3)
  - (d) Faktura opłacona po korekcie → ponowne odliczenie VAT w okresie zapłaty
- **Zależności:** R0178 `bad_debt_debtor_90_days_mandatory` (bardziej szczegółowa), R0180 `bad_debt_debtor_30pct_sanction` (sankcja). Ta reguła jest nadrzędna — wykrywa przekroczenie.
- **Thresholds:** `jdg.limits.bad_debt_days_cit_pit` (90)
- **Przykład +:** Faktura zakupu 50k PLN netto + 11.5k VAT, termin płatności 01.03.2026, dziś 01.06.2026 (92 dni) → OBOWIĄZEK zwrotu 11.5k PLN VAT → BLOCK do czasu korekty
- **Przykład −:** Faktura 45 dni po terminie → NIE matchuje (jeszcze 45 dni do obowiązku)

---

## 8. P192: `jdg.vat.vat_refund_timing`

- **Cel biznesowy:** Monitoruje terminy zwrotu VAT i nalicza odsetki należne JDG od US za opóźnienia. Standardowy zwrot: 60 dni. Przyśpieszony (płatności kartą/przelewem za wszystkie faktury): 25 dni. Przedłużony (weryfikacja): do 180 dni. Po terminie US płaci odsetki podatnikowi. Reguła śledzi, który termin obowiązuje i czy został przekroczony.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.vat_balance_credit > 0` (nadwyżka VAT naliczonego nad należnym — kwota do zwrotu)
  - `input.jdg_entrepreneur.vat_return_requested == true`
  - `input.document.days_since_vat_return_request > 0`
- **Rezultat:** `matched:true`, `vat_refund_deadline_days:<25 | 60 | 180>`, `vat_refund_overdue:<bool>`, `vat_refund_interest_due:<kwota odsetek od US>`, `_warnings:["Zwrot VAT — termin: X dni. Po terminie US płaci odsetki."]`
- **Podstawa prawna:** Art. 87 ust. 2-7 VAT
- **Edge cases:**
  - (a) Zwrot na konto bankowe → US ma numer konta z VAT-R → bezproblemowo
  - (b) Zwrot w ratach → możliwe przy dużych kwotach
  - (c) Przedłużenie do 180 dni → US musi zawiadomić podatnika
  - (d) Odsetki od US → stawka = `input.thresholds.jdg.rates.tax_interest_rate` (stopa lombardowa NBP + 2%, nie mniej niż 8%) — **parametryzowane przez thresholds**
- **Zależności:** Po R0270 `annual_return_overpayment_refund_45days` (dla PIT). Dla VAT: osobny mechanizm, inne terminy.
- **Thresholds:** `jdg.vat.refund_standard_days` (60), `jdg.vat.refund_accelerated_days` (25), `jdg.vat.refund_extended_days` (180), `jdg.rates.tax_interest_rate` (dla odsetek od US)
- **Przykład +:** Zwrot VAT 50k PLN, wszystkie faktury opłacone kartą, wniosek 01.03 → termin 25 dni → 26.03. Jeśli dziś 01.04 (31 dni) → reguła matchuje: 6 dni opóźnienia, odsetki od US
- **Przykład −:** Zwrot 10k PLN, standard, wniosek 01.01, dziś 15.02 (45 dni < 60) → NIE matchuje

---

## 9. P508: `jdg.pit.pit_revenue_exclusions`

> ⚠️ **UWAGA — Konflikt numeracji P:** Doc 22 przypisuje zakres **P500-P509 do `jdg.pit.form_scale`** (skala podatkowa). P508 `pit_revenue_exclusions` dotyczy **obliczania dochodu**, nie formy opodatkowania. **Rekomendowane przenumerowanie na P504** (zakres dochodu/obliczeń) przy następnej wersji planu. Na czas implementacji pozostaje P508 z tą adnotacją.

- **Cel biznesowy:** Nie wszystkie wpływy na konto stanowią przychód podatkowy JDG. Art. 14 ust. 3 PIT wyłącza z przychodów m.in. zwrócone uprzednio odliczone wydatki (np. zwrot VAT), otrzymane odszkodowania za utracone przychody, zwrot nadpłaconych składek ZUS. Bez tej reguły JDG zapłaci podatek od kwot, które NIE są przychodem.
- **Przesłanki szczegółowe:**
  - `input.invoice.direction == "SALE"` lub `input.invoice.type == "INFLOW"`
  - `input.invoice.category_code in ["VAT_REFUND", "ZUS_OVERPAYMENT_REFUND", "INSURANCE_COMPENSATION", "DAMAGES_AWARD"]`
  - `input.invoice.is_revenue_excluded == false` (nieoznaczone jako wyłączone)
- **Rezultat:** `matched:true`, `pit_revenue_excluded:true`, `revenue_exclusion_type:<kategoria>`, `pkpir_excluded:true`, `_warnings:["Ten wpływ NIE stanowi przychodu podatkowego — wyłączony na podstawie Art. 14 ust. 3 PIT"]`
- **Podstawa prawna:** Art. 14 ust. 3 pkt 1-4 PIT
- **Edge cases:**
  - (a) Zwrot VAT → wpływa na konto, ale NIE jest przychodem (VAT był wcześniej kosztem)
  - (b) Zwrot nadpłaconych składek ZUS → NIE przychód (składki były KUP)
  - (c) Odszkodowanie za utracony kontrakt → JEST przychodem (zastępuje utracony przychód) — inna kategoria!
  - (d) Dotacja z PUP → może być zwolniona z PIT na podstawie innych przepisów
- **Zależności:** Po P802 `pkpir_expense_recognition`. Przed regułami KUP i zaliczek. Wykluczone kwoty NIE wchodzą do `cumulative_income_current_year`.
- **Thresholds:** `jdg.pit.revenue_exclusion_categories` (lista kategorii wyłączonych)
- **Przykład +:** Zwrot VAT 8k PLN z US → NIE jest przychodem → reguła matchuje, wyłącza z podstawy PIT
- **Przykład −:** Faktura sprzedaży 50k PLN → normalny przychód → NIE matchuje

---

## 10. P524: `jdg.pit.form_lump_sum.lump_sum_exclusions`

- **Cel biznesowy:** Niektóre JDG NIE mogą korzystać z ryczałtu ewidencjonowanego — bezwzględny zakaz ustawowy (Art. 8 u.z.p.d.). Dotyczy to m.in. aptek, kantorów, handlu częściami samochodowymi, usług dla byłego pracodawcy w ciągu roku od odejścia. Reguła blokuje wybór ryczałtu dla wykluczonych branż.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` (wybrany ryczałt)
  - `input.jdg_entrepreneur.pkd_main in input.thresholds.jdg.lump_sum_excluded_pkd` (PKD wykluczone)
  - LUB `input.vendor.nip == lookup_former_employer_nip(input.jdg_entrepreneur.nip)` AND `months_since_employment_ended < 12`
> ⚠️ **UWAGA IMPLEMENTACYJNA:** `former_employer_nip` nie istnieje w `input.jdg_entrepreneur` (Doc 22 §2.1). Należy dodać pole `jdg_entrepreneur.previous_employer_nip` i `jdg_entrepreneur.employment_end_date` lub wyprowadzić z historii zatrudnienia (ZUS RCA).
- **Rezultat:** `matched:true`, `_routing:"BLOCK_AND_ALERT"`, `lump_sum_excluded:true`, `tax_form_must_be:"SCALE_OR_LINEAR"`, `_warnings:["Branża WYKLUCZONA z ryczałtu (Art. 8 u.z.p.d.). Wybierz skalę PIT lub podatek liniowy."]`
- **Podstawa prawna:** Art. 8 ust. 1-2 ustawy o zryczałtowanym podatku dochodowym (Dz.U. 2025 poz. 234)
- **Edge cases:**
  - (a) JDG ma kilka PKD, tylko jedno wykluczone → jeśli przychody z wykluczonego PKD > 0 → NIE może być na ryczałcie
  - (b) Były pracodawca po 13 miesiącach → można ryczałt (ograniczenie mija po 12 miesiącach)
  - (c) JDG zmienia PKD w trakcie roku na wykluczone → traci prawo do ryczałtu od następnego miesiąca
  - (d) Apteka → bezwzględnie wykluczona, niezależnie od innych PKD
- **Zależności:** R0211 `pit_form_lump_sum` (wybór ryczałtu). R0525 `lump_sum_loss_of_right` (utrata prawa w trakcie roku).
- **Thresholds:** `jdg.lump_sum_excluded_pkd` (lista PKD), `jdg.lump_sum_exclusion_former_employer_months` (12)
- **Przykład +:** JDG z PKD 47.73.Z (apteka) wybiera ryczałt → BLOCK — apteki bezwzględnie wykluczone
- **Przykład −:** JDG IT z PKD 62.01.Z → NIE na liście wykluczeń → OK, NIE matchuje

---

## 11. P572: `jdg.pit.kup.kup_direct_vs_indirect_timing`

- **Cel biznesowy:** Rozróżnienie momentu potrącenia KUP: koszty BEZPOŚREDNIO związane z przychodami (np. zakup towarów handlowych) potrąca się w roku osiągnięcia odpowiadającego im przychodu (nawet jeśli przychód jest w kolejnym roku!). Koszty POŚREDNIE (czynsz, media, księgowość) — w dacie poniesienia. Bez tej reguły KUP trafia w zły rok podatkowy.
- **Przesłanki szczegółowe:**
  - `input.invoice.expense_type in input.thresholds.jdg.pit.direct_expense_categories` → DIRECT
  - `input.invoice.expense_type in input.thresholds.jdg.pit.indirect_expense_categories` → INDIRECT
  - `input.invoice.direction == "PURCHASE"`
- **Rezultat:** `matched:true`, `kup_timing_type:<"DIRECT" | "INDIRECT">`, `kup_year:<revenue_year dla DIRECT | invoice_year dla INDIRECT>`, `_warnings:["KUP bezpośredni — potrącany w roku przychodu. Jeśli sprzedaż towaru w 2027, KUP w 2027 (nie 2026!)."]`
- **Podstawa prawna:** Art. 22 ust. 5, 5a, 5b, 5c PIT
- **Edge cases:**
  - (a) Towar kupiony w grudniu 2026, sprzedany w styczniu 2027 → KUP w 2027 (rok przychodu)
  - (b) Czynsz za grudzień 2026 zapłacony w styczniu 2027 → KUP w 2026 (data poniesienia)
  - (c) Towar kupiony, ale NIESPRZEDANY w ogóle → KUP w roku zbycia lub likwidacji
  - (d) Koszty, których nie można jednoznacznie przypisać → traktowane jako pośrednie
- **Zależności:** Po P560 `kup_full_deductible` (kwalifikacja ogólna). Przed P802 `pkpir_expense_recognition` (data wpisu do PKPiR).
- **Thresholds:** `jdg.pit.direct_expense_categories` (lista kategorii DIRECT), `jdg.pit.indirect_expense_categories` (lista INDIRECT)
- **Przykład +:** Zakup towaru 100k PLN 15.11.2026, sprzedany 20.02.2027 → DIRECT → KUP w 2027 (rok przychodu ze sprzedaży)
- **Przykład −:** Czynsz za biuro 2k PLN za grudzień 2026 → INDIRECT → KUP w 2026 (rok poniesienia)

---

## 12. P743: `jdg.zus.concurrent_etat_jdg_zus`

- **Cel biznesowy:** **Zbieg ubezpieczeń — najczęstsza sytuacja dla ~30% JDG.** Jeśli przedsiębiorca jest jednocześnie zatrudniony na etacie z wynagrodzeniem ≥ minimalnego, z JDG płaci TYLKO składkę zdrowotną. Społeczne (emerytalne, rentowe, chorobowe, wypadkowe, FP) są w całości opłacane z etatu. Bez tej reguły JDG płaci podwójne składki społeczne.
- **Przesłanki szczegółowe:**
  - `input.jdg_entrepreneur.has_employment_contract == true` (ma etat)
  - `input.jdg_entrepreneur.employment_monthly_salary >= input.thresholds.jdg.bounds.minimum_wage_gross` (4666 PLN w 2026)
  - `input.jdg_entrepreneur.tax_form != null` (aktywna JDG)
> ⚠️ **UWAGA IMPLEMENTACYJNA:** Pole `employment_monthly_salary` nie istnieje w `input` (Doc 22 §2.1). Należy dodać do `jdg_entrepreneur`: `has_employment_contract` (bool) i `employment_monthly_salary` (number). Alternatywnie — wyprowadzić z deklaracji ZUS RCA pracownika.
- **Rezultat:** `matched:true`, `zus_social_exemption:"FULL"`, `zus_health_only:true`, `zus_social_rate:"0.00"`, `zus_health_rate:<wg formy opodatkowania>`, `_warnings:["Zbieg etat+JDG — z JDG płacisz TYLKO składkę zdrowotną. Społeczne opłaca etat."]`
- **Podstawa prawna:** Art. 9 ust. 1a-2 SUS (Dz.U. 2025 poz. 123)
- **Edge cases:**
  - (a) Etat z pensją < minimalna (np. ½ etatu za 2300 PLN) → JDG płaci społeczne NA RÓWNI z etatem (proporcjonalnie)
  - (b) Kilka etatów → suma pensji z wszystkich etatów ≥ min. → zwolnienie z JDG
  - (c) Etat + zlecenie + JDG → etat ma pierwszeństwo, potem zlecenie, JDG ostatnie
  - (d) Utrata etatu w trakcie miesiąca → od następnego miesiąca społeczne z JDG
- **Zależności:** R0357 `zus_concurrent_employment_only_health` (lżejsza wersja). R0577 `edge_zus_concurrent_jdg_and_mandate` (dla zleceń). Ta reguła jest dla ETATU.
- **Thresholds:** `jdg.bounds.minimum_wage_gross` (4666), `jdg.zus.health_rates` (wg formy)
- **Przykład +:** JDG liniowy + etat 8000 PLN brutto → z JDG TYLKO zdrowotna 4.9% od dochodu, społeczne = 0 PLN
- **Przykład −:** JDG bez etatu → NIE matchuje (standardowe składki); etat 3000 PLN (< 4666) → NIE matchuje (społeczne z JDG)

---

## 📊 STATYSTYKI KOŃCOWE

| Metryka | Wartość |
|---|---|
| **Reguły krytyczne** | **12** |
| **Pakiety** | 7 (risk, compliance, vat, vat.deduction, pit, pit.kup, pit.form_lump_sum, zus) |
| **Artykuły prawne** | 12 unikalnych (KKS × 3, OP × 1, VAT × 4, PIT × 2, u.z.p.d. × 1, SUS × 1) |
| **Edge cases** | 48 (średnio 4 na regułę) |
| **Przykłady pozytywne** | 12 |
| **Przykłady negatywne** | 12 |
| **Thresholds** | 24 unikalnych parametrów |

### Mapa priorytetów:

| Priorytet | Reguły | Pakiet docelowy |
|:---------:|--------|-----------------|
| **P0_b** | `kks_empty_invoice_fraud` | `policies/jdg/risk.rego` (rozszerzenie) |
| **P4** | `kks_hidden_income_flag` | `policies/jdg/risk.rego` (rozszerzenie) |
| **P6** | `kks_unreliable_books` | `policies/jdg/risk.rego` (rozszerzenie) |
| **P9** | `gaar_artificial_scheme` | `policies/jdg/risk.rego` (rozszerzenie) |
| **P36** | `vat_simplified_receipt_450pln` | `policies/jdg/compliance.rego` (rozszerzenie) |
| **P39** | `vat_r_registration_mandatory` | `policies/jdg/vat/substantive.rego` (rozszerzenie) |
| **P184** | `bad_debt_debtor_correction` | `policies/jdg/vat/deductions.rego` (rozszerzenie) |
| **P192** | `vat_refund_timing` | `policies/jdg/vat/procedures.rego` (rozszerzenie) |
| **P508** | `pit_revenue_exclusions` | `policies/jdg/pit/forms.rego` (rozszerzenie) |
| **P524** | `lump_sum_exclusions` | `policies/jdg/pit/transitions.rego` (rozszerzenie) |
| **P572** | `kup_direct_vs_indirect` | `policies/jdg/pit/kup.rego` (rozszerzenie) |
| **P743** | `concurrent_etat_jdg_zus` | `policies/jdg/zus.rego` (rozszerzenie) |

---

> **🔥 READY FOR IMPLEMENTATION:** Te 12 reguł zamyka najpoważniejsze luki prawne zidentyfikowane w `25_JDG_DEEP_LEGAL_AUDIT.md`. Każda reguła ma kompletny 10-polowy opis ENTERPRISE, przykład liczbowy ±, i może być natychmiast przekształcona w `else := { } { }` w Rego.
>
> **Następny krok:** Implementacja w `policies/jdg/` — rozszerzenie 7 istniejących plików `.rego` o 12 nowych `else` bloków. Szacowany czas: ~3-4 godziny dla doświadczonego inżyniera Rego.

---

*Wygenerowano przez NexusAI Critical Gaps Closure Engine v1.0 — 12 reguł × 10 pól ENTERPRISE.*
*Data: 2026-07-11*
*Źródło: 25_JDG_DEEP_LEGAL_AUDIT.md + 38_JDG_QUALITY_AUDIT.md*
