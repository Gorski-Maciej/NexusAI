# 🔍 Głęboki Audyt Prawny — Luki w Systemie Reguł JDG ENTERPRISE

> **Status:** Deep Legal Audit v1.0 — Audyt pokrycia aktów prawnych vs. istniejące reguły  
> **Data:** 2026-07-08  
> **Plik:** `Plan OPA/25_JDG_DEEP_LEGAL_AUDIT.md`  
> **Dokumenty źródłowe:**  
> — `Plan OPA/DocsJDG` — kompletna lista aktów prawnych  
> — `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` — plan bazowy (~145 reguł)  
> — `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` — rozbudowa (~69 reguł)  
> — `Plan OPA/24_JDG_COMPLETE_INDEX.md` — indeks reguł (~214 reguł)  
> **Znalezione luki:** 46 — w tym 12 KRYTYCZNYCH, 20 WAŻNYCH, 14 DODATKOWYCH  

---

## 0. Legenda

| Oznaczenie | Znaczenie |
|------------|----------|
| 🔴 **KRYTYCZNA** | Brak reguły może prowadzić do błędów podatkowych, kar KKS, lub straty prawa do odliczeń. WYMAGANE w ENTERPRISE. |
| 🟡 **WAŻNA** | Istotna dla kompletności systemu. Brak reguły ogranicza funkcjonalność istotnego obszaru. |
| 🟢 **DODATKOWA** | Warto dodać dla pełnego pokrycia. Brak nie zagraża poprawności podstawowych decyzji. |

---

# CZĘŚĆ I: ORDYNACJA PODATKOWA — GŁĘBOKI AUDYT

**Status w DocsJDG:** Wymieniona tytułem, bez szczegółowych artykułów.  
**Status w regułach:** Częściowo pokryta przez P1100-P1166 (korekty, przedawnienia, odsetki, pełnomocnictwa), P20-P21 (Biała Lista).

---

## 🔴 Luka 1: Art. 16-16b OP — Czynny żal (KKS)

- **Co sprawdza:** Czy złożono czynny żal przed złożeniem korekty po wykryciu błędu. Złożenie czynnego żalu chroni przed karą KKS.
- **Obecne pokrycie:** P1108 (`jpk_v7_correction_code`) tylko wspomina czynny żal jako kod przyczyny korekty JPK, ale NIE ma reguły walidującej sam czynny żal.
- **Propozycja reguły:** `jdg.statute_liability.voluntary_disclosure_active`
  - **Priorytet:** P1168
  - **Przesłanki:** `input.document.correction_submitted == true` AND data korekty > data wykrycia błędu AND `input.document.voluntary_disclosure_filed == false`
  - **Rezultat:** `_warning: "Brak czynnego żalu — ryzyko odpowiedzialności KKS. Złóż przed korektą."`
  - **Podstawa prawna:** Art. 16 § 1-4 KKS, Art. 16a KKS
- 🔴 **KRYTYCZNA** — brak może narazić użytkownika na karę KKS

## 🔴 Luka 2: Art. 20-21 OP — Zaległość podatkowa i nadpłata

- **Co sprawdza:** Definicja zaległości podatkowej (niezapłacony w terminie podatek) i nadpłaty (nadpłacony lub nienależnie zapłacony podatek). Podstawa do naliczania odsetek.
- **Obecne pokrycie:** P1164 (`late_payment_interest_calculation`) liczy odsetki, ale NIE ma reguł dla nadpłat.
- **Propozycja reguły 2a:** `jdg.statute_liability.tax_arrears_detection`
  - **Priorytet:** P1167
  - **Przesłanki:** `input.invoice.tax_due > 0` AND `input.invoice.payment_date > deadline` AND `input.invoice.is_paid == false`
  - **Rezultat:** `tax_arrears_detected: true`, `arrears_amount: <kwota>`
- **Propozycja reguły 2b:** `jdg.statute_liability.overpayment_detection`
  - **Priorytet:** P1169
  - **Przesłanki:** `total_tax_paid > total_tax_due`
  - **Rezultat:** `overpayment_detected: true`, `overpayment_amount: <nadpłata>`, `overpayment_refund_eligible: true`
    - Termin zwrotu: 45 dni (VAT), 3 miesiące (PIT) od złożenia wniosku
  - **Podstawa prawna:** Art. 72-80, Art. 87 OP
- 🔴 **KRYTYCZNA** — brak obsługi nadpłat to poważna luka w ENTERPRISE

## 🟡 Luka 3: Art. 48, 67a-67e OP — Odroczenia i ulgi w spłacie

- **Co sprawdza:** Czy istnieje aktywna decyzja o odroczeniu terminu płatności / rozłożeniu na raty. Jeśli tak — odsetki nie są naliczane od rat objętych odroczeniem.
- **Obecne pokrycie:** `jdg_entrepreneur.has_active_deferral_decision` istnieje w `input`, ale NIE ma reguły która go sprawdza.
- **Propozycja reguły:** `jdg.statute_liability.deferral_active`
  - **Priorytet:** P1170
  - **Przesłanki:** `input.jdg_entrepreneur.has_active_deferral_decision == true`
  - **Rezultat:** `interest_suspended: true`, `enforcement_suspended: true`, `_warning: "Aktywne odroczenie — odsetki i egzekucja zawieszone"`
  - **Podstawa prawna:** Art. 48, Art. 67a-67e OP
- 🟡 **WAŻNA**

## 🟡 Luka 4: Art. 51 OP — Umorzenie zaległości podatkowej

- **Co sprawdza:** Czy zaległość podatkowa została umorzona decyzją organu. Umorzona zaległość przestaje istnieć.
- **Propozycja reguły:** `jdg.statute_liability.tax_remission_active`
  - **Priorytet:** P1171
  - **Przesłanki:** `input.document.tax_remission_granted == true`
  - **Rezultat:** `tax_liability_extinguished: true`
  - **Podstawa prawna:** Art. 51 OP
- 🟡 **WAŻNA**

## 🔴 Luka 5: Art. 119a OP — Klauzula GAAR (przeciwdziałanie unikaniu opodatkowania)

- **Co sprawdza:** Czy transakcja jest sztuczna i nakierowana wyłącznie na uzyskanie korzyści podatkowej sprzecznej z celem ustawy. Brak w systemie reguł anty-abuzywnych.
- **Obecne pokrycie:** BRAK. Reguły fraud (P0-P9) nie obejmują testu GAAR.
- **Propozycja reguły:** `jdg.risk.gaar_artificial_scheme`
  - **Priorytet:** P9
  - **Przesłanki:** 
    - Transakcja z podmiotem powiązanym (`input.vendor.is_related_party == true`)
    - Brak ekonomicznego uzasadnienia (koszt rażąco odbiega od rynkowego)
    - Struktura sprzeczna z celem ustawy
  - **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `gaar_risk: true`, `_warning: "Potencjalna klauzula GAAR — transakcja może być uznana za sztuczną"`
  - **Podstawa prawna:** Art. 119a § 1 OP
- 🔴 **KRYTYCZNA** — ENTERPRISE musi mieć zabezpieczenie anty-avoidance

## 🟡 Luka 6: Art. 71 OP — Przerwanie biegu przedawnienia

- **Co sprawdza:** Szczegółowe przesłanki przerwania biegu przedawnienia (inne niż środek egzekucyjny z P1156). Np. uznanie długu przez podatnika, wszczęcie postępowania karnego-skarbowego.
- **Obecne pokrycie:** P1156 tylko dla środka egzekucyjnego.
- **Propozycja reguły:** `jdg.statute_liability.statute_interruption_detailed`
  - **Priorytet:** P1157
  - **Przesłanki:** `input.document.debt_acknowledged == true` OR `input.document.kks_proceedings_started == true`
  - **Rezultat:** `statute_interrupted: true`, `new_statute_end_date: <data>`
  - **Podstawa prawna:** Art. 71 OP
- 🟡 **WAŻNA**

## 🟢 Luka 7: Art. 72-80, 87 OP — Nadpłata — szczegóły proceduralne

- **Co sprawdza:** Zwrot nadpłaty: 45 dni od złożenia wniosku, oprocentowanie nadpłaty (odsetki dla podatnika), zaliczenie nadpłaty na poczet przyszłych/bieżących zobowiązań.
- **Propozycja reguły:** `jdg.statute_liability.overpayment_offset`
  - **Priorytet:** P1172
  - **Przesłanki:** `overpayment_exists == true`
  - **Rezultat:** `overpayment_refund_deadline_days: 45`, `overpayment_interest_applicable: true` (po 45 dniach)
  - **Podstawa prawna:** Art. 72-80, Art. 87 OP
- 🟢 **DODATKOWA**

## 🟢 Luka 8: Art. 120-129 OP — Postępowanie podatkowe (podstawy)

- **Co sprawdza:** Podstawowe terminy proceduralne — 7 dni na zawiadomienie, 14 dni na wypowiedzenie się, 30 dni na decyzję.
- **Propozycja reguły:** `jdg.statute_liability.tax_proceeding_deadlines`
  - **Priorytet:** P1174
  - **Rezultat:** alerty o przekroczeniu terminów proceduralnych
  - **Podstawa prawna:** Art. 120-129 OP
- 🟢 **DODATKOWA**

---

# CZĘŚĆ II: KODEKS KARNY SKARBOWY (KKS) — CAŁKOWICIE POMINIĘTY

**Status w DocsJDG:** NIEOBECNY (całkowicie pominięty!)  
**Status w regułach:** Pośrednio: P1108 (czynny żal), P1154 (zawieszenie przedawnienia w KKS), P0 (fraud)  
**Wniosek:** KKS musi być dodany do DocsJDG i pokryty dedykowanymi regułami.

---

## 🔴 Luka 9: Art. 54 KKS — Uchylanie się od opodatkowania

- **Co sprawdza:** Nieujawnienie przedmiotu lub podstawy opodatkowania. Flaga dla transakcji gdzie wpływy na konto ≠ zadeklarowane przychody.
- **Propozycja reguły:** `jdg.risk.kks_hidden_income_flag`
  - **Priorytet:** P4
  - **Przesłanki:** Rozbieżność między sumą faktur sprzedaży a wpływami na rachunek firmowy > próg tolerancji
  - **Rezultat:** `kks_risk: "Art.54"`, `_routing: "BLOCK_AND_ALERT"`
  - **Podstawa prawna:** Art. 54 § 1 KKS
- 🔴 **KRYTYCZNA**

## 🔴 Luka 10: Art. 56 KKS — Nierzetelne prowadzenie ksiąg/PKPiR

- **Co sprawdza:** Czy PKPiR/ewidencja ryczałtowa zawiera błędy rażące (brakujące pozycje, celowe zaniżenia).
- **Propozycja reguły:** `jdg.risk.kks_unreliable_books`
  - **Priorytet:** P6
  - **Przesłanki:** `input.invoice.pkpir_column == 0` (niezmapowane) AND `input.invoice.expense_type != "NKUP"` — wydatek nieujęty w PKPiR
  - **Rezultat:** `kks_risk: "Art.56"`, `_warning: "Nieujęty wydatek w PKPiR — ryzyko nierzetelnych ksiąg"`
  - **Podstawa prawna:** Art. 56 § 1-2 KKS
- 🔴 **KRYTYCZNA**

## 🔴 Luka 11: Art. 62 § 2 KKS — Puste faktury (fałszywe faktury VAT)

- **Co sprawdza:** Faktura dokumentująca czynność, która NIE została dokonana. Najwyższe ryzyko karne (do 25 lat za oszustwa >10 mln).
- **Propozycja reguły:** `jdg.risk.kks_empty_invoice_fraud`
  - **Priorytet:** P0_b
  - **Przesłanki:** Faktura bez śladu materialnego (brak dostawy, brak usługi, brak płatności)
  - **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `kks_risk: "Art.62_par2"`, `max_penalty: 25_years`
  - **Podstawa prawna:** Art. 62 § 2, Art. 62 § 2a KKS
- 🔴 **KRYTYCZNA**

## 🟡 Luka 12: Art. 57 KKS — Niewłaściwe prowadzenie ewidencji VAT

- **Co sprawdza:** Czy ewidencja VAT jest kompletna i zgodna z wymogami Art. 109 VAT.
- **Propozycja reguły:** `jdg.risk.kks_vat_evidence_gap`
  - **Priorytet:** P7
  - **Rezultat:** `kks_risk: "Art.57"`
  - **Podstawa prawna:** Art. 57 KKS
- 🟡 **WAŻNA**

## 🟡 Luka 13: Art. 77 § 1 KKS — Niezłożenie deklaracji podatkowej w terminie

- **Co sprawdza:** Przekroczenie terminu na złożenie JPK_VAT (25. dnia), PIT (30 kwietnia), PIT-28 (28 lutego).
- **Obecne pokrycie:** P556 (`pit_annual_return_overdue`) częściowo, ale brak dla VAT i innych.
- **Propozycja reguły:** `jdg.risk.kks_declaration_overdue`
  - **Priorytet:** P6_b
  - **Przesłanki:** Przekroczenie deadline dla dowolnej deklaracji
  - **Rezultat:** `kks_risk: "Art.77"`, `declaration_overdue_days: <dni>`
  - **Podstawa prawna:** Art. 77 § 1 KKS
- 🟡 **WAŻNA**

---

# CZĘŚĆ III: USTAWA O VAT — GŁĘBOKI AUDYT

**Status w DocsJDG:** Obszernie opisana.  
**Status w regułach:** Najlepiej pokryty obszar (P40-P69, P185-P235, P950-P960). Ale są luki!

---

## 🔴 Luka 14: Art. 15-18 VAT — Procedura rejestracji VAT-R (szczegóły)

- **Co sprawdza:** VAT-R należy złożyć PRZED pierwszą czynnością opodatkowaną. Urząd ma 3 miesiące na rejestrację (lub odmowę). Do czasu rejestracji nie można wystawiać faktur z VAT.
- **Obecne pokrycie:** P43 (`vat_ue_registration_mandatory`) tylko dla VAT-UE! Brak reguły dla VAT-R krajowego.
- **Propozycja reguły:** `jdg.vat.vat_r_registration_status`
  - **Priorytet:** P39
  - **Przesłanki:** `input.jdg_entrepreneur.is_vat_payer == false` AND `input.invoice.direction == "SALE"`
  - **Rezultat:** `vat_r_required: true`, `_warning: "Brak rejestracji VAT-R — nie możesz wystawiać faktur z VAT"`
  - **Podstawa prawna:** Art. 96 ust. 1, Art. 96 ust. 4-5 VAT
- 🔴 **KRYTYCZNA**

## 🔴 Luka 15: Art. 89b VAT — Złe długi — OBOWIĄZEK DŁUŻNIKA

- **Co sprawdza:** Dłużnik, który nie zapłacił faktury w ciągu 90 dni od terminu płatności, MUSI skorygować odliczony VAT in minus (zwrócić do US). To nie opcja — to OBOWIĄZEK!
- **Obecne pokrycie:** P60 (wierzyciel może skorygować), P189 (wierzyciel ulga). BRAK reguły dla dłużnika!
- **Propozycja reguły:** `jdg.vat.deduction.bad_debt_debtor_correction_mandatory`
  - **Priorytet:** P184
  - **Przesłanki:** 
    - `input.invoice.direction == "PURCHASE"`
    - `input.invoice.is_paid == false`
    - `input.invoice.days_overdue >= input.thresholds.jdg.limits.bad_debt_days_vat` (90)
    - `input.invoice.is_vat_deducted == true`
  - **Rezultat:** `vat_correction_in_minus_mandatory: true`, `_warning: "Nie zapłaciłeś faktury >90 dni — OBOWIĄZKOWA korekta VAT in minus. Zwróć odliczony VAT."`
  - **Podstawa prawna:** Art. 89b VAT
- 🔴 **KRYTYCZNA** — jedna z najważniejszych luk VAT!

## 🔴 Luka 16: Art. 87 VAT — Zwrot VAT — terminy

- **Co sprawdza:** Termin zwrotu VAT: 60 dni standardowo, 25 dni przy płatnościach kartą/przelewem, 180 dni przy weryfikacji. Po terminie — odsetki dla podatnika.
- **Propozycja reguły:** `jdg.vat.vat_refund_timing`
  - **Priorytet:** P192
  - **Przesłanki:** `vat_balance_credit > 0` (nadwyżka VAT naliczonego nad należnym)
  - **Rezultat:** 
    - `vat_refund_deadline_days: 60` (standard) / `25` (przyśpieszony)
    - `vat_refund_overdue: true` (po przekroczeniu)
    - `vat_refund_interest: należne po terminie`
  - **Podstawa prawna:** Art. 87 ust. 2-7 VAT
- 🔴 **KRYTYCZNA**

## 🔴 Luka 17: Art. 106e ust. 5 VAT — Paragon jako faktura uproszczona (do 450 PLN)

- **Co sprawdza:** Paragon z NIP nabywcy do kwoty 450 PLN brutto (100 EUR) jest równoważny fakturze uproszczonej — można odliczyć VAT. Powyżej limitu — paragon NIE jest fakturą.
- **Propozycja reguły:** `jdg.compliance.vat_simplified_receipt`
  - **Priorytet:** P36
  - **Przesłanki:** 
    - `input.invoice.invoice_type == "RECEIPT"`
    - `input.invoice.amount_gross <= input.thresholds.jdg.limits.simplified_receipt_limit` (450 PLN)
    - `input.invoice.has_nip == true`
  - **Rezultat:** `vat_deduction_allowed: true` (do 450 PLN), `vat_deduction_allowed: false` (powyżej)
  - **Podstawa prawna:** Art. 106e ust. 5 pkt 3 VAT
- 🔴 **KRYTYCZNA** — codzienna sytuacja dla JDG (paliwo, materiały biurowe, narzędzia)

## 🟡 Luka 18: Art. 86 ust. 7a VAT — Wyłączenia z odliczenia (kategorie)

- **Co sprawdza:** Niektóre wydatki NIE podlegają odliczeniu VAT mimo związku z działalnością: usługi noclegowe, gastronomiczne (poza cateringiem dla pracowników).
- **Propozycja reguły:** `jdg.vat.deduction.vat_blocked_categories`
  - **Priorytet:** P183
  - **Przesłanki:** `input.invoice.category_code in ["HOTEL", "RESTAURANT"]` AND `input.invoice.expense_type != "CATERING_EMPLOYEES"`
  - **Rezultat:** `vat_deduction_blocked: true`, `vat_rate_naliczony: "0.00"`
  - **Podstawa prawna:** Art. 86 ust. 7a VAT, Art. 88 VAT
- 🟡 **WAŻNA**

## 🟡 Luka 19: Art. 96 VAT — Wyrejestrowanie z VAT (VAT-Z)

- **Co sprawdza:** Obowiązek złożenia VAT-Z przy zaprzestaniu działalności opodatkowanej VAT lub przy przejściu na zwolnienie podmiotowe.
- **Propozycja reguły:** `jdg.vat.vat_z_deregistration`
  - **Priorytet:** P233
  - **Przesłanki:** `input.jdg_entrepreneur.business_status == "CLOSED"` OR `input.jdg_entrepreneur.annual_turnover_net < vat_exemption_limit` AND `is_vat_payer == true`
  - **Rezultat:** `vat_z_required: true`, `vat_z_deadline: 7_days_from_event`
  - **Podstawa prawna:** Art. 96 ust. 6-8 VAT
- 🟡 **WAŻNA**

## 🟡 Luka 20: Art. 103 VAT — Terminy płatności VAT

- **Co sprawdza:** VAT płatny do 25. dnia miesiąca następującego po okresie rozliczeniowym. Po terminie — odsetki.
- **Propozycja reguły:** `jdg.vat.vat_payment_deadline`
  - **Priorytet:** P234
  - **Przesłanki:** `vat_payable > 0` AND `current_date > 25th_next_month`
  - **Rezultat:** `vat_payment_overdue: true`, `late_interest_applicable: true`
  - **Podstawa prawna:** Art. 103 ust. 1 VAT
- 🟡 **WAŻNA**

## 🟢 Luka 21: Art. 99 VAT — JPK_V7 szczegółowe terminy

- **Co sprawdza:** JPK_V7 miesięczny: do 25. dnia następnego miesiąca. JPK_V7K kwartalny: do 25. dnia miesiąca po kwartale.
- **Propozycja reguły:** `jdg.jpk.jpk_v7_filing_deadlines`
  - **Priorytet:** P972
  - **Rezultat:** alert przy przekroczeniu terminu
  - **Podstawa prawna:** Art. 99 ust. 1-3 VAT
- 🟢 **DODATKOWA**

---

# CZĘŚĆ IV: USTAWA O PIT — GŁĘBOKI AUDYT

**Status w DocsJDG:** Obszernie opisana.  
**Status w regułach:** Dobrze pokryty (P500-P589), ale są szczegółowe luki.

---

## 🔴 Luka 22: Art. 22 ust. 5-5c PIT — Moment potrącenia KUP (bezpośrednie vs pośrednie)

- **Co sprawdza:** Koszty bezpośrednio związane z przychodami (np. zakup towarów) potrąca się w roku osiągnięcia przychodu. Koszty pośrednie (czynsz, media, księgowość) — w dacie poniesienia.
- **Obecne pokrycie:** P802 (`pkpir_expense_recognition`) tylko data faktury, NIE rozróżnia direct vs indirect!
- **Propozycja reguły:** `jdg.pit.kup.direct_vs_indirect_timing`
  - **Priorytet:** P572
  - **Przesłanki:** `input.invoice.expense_type in ["COGS", "MATERIALS_DIRECT"]` → DIRECT; pozostałe → INDIRECT
  - **Rezultat:** 
    - DIRECT: `kup_year: revenue_year` (może być późniejszy niż data faktury!)
    - INDIRECT: `kup_year: invoice_year`
  - **Podstawa prawna:** Art. 22 ust. 5-5c PIT
- 🔴 **KRYTYCZNA** — fundamentalne dla poprawnego rozliczenia PIT

## 🟡 Luka 23: Art. 14 ust. 2c PIT — Różnice kursowe

- **Co sprawdza:** Różnice kursowe od transakcji walutowych — dodatnie/zrealizowane zwiększają przychód, ujemne zwiększają KUP.
- **Propozycja reguły:** `jdg.accounting.fx_differences_recognition`
  - **Priorytet:** P870
  - **Przesłanki:** `input.invoice.currency != "PLN"` AND `input.invoice.is_paid == true`
  - **Rezultat:** `fx_difference: <kwota>`, `fx_direction: "POSITIVE"` (przychód) lub `"NEGATIVE"` (KUP)
  - **Podstawa prawna:** Art. 14 ust. 2c, Art. 24c PIT
- 🟡 **WAŻNA** — niezbędna dla JDG z transakcjami walutowymi

## 🟡 Luka 24: Art. 14 ust. 3 PIT — Wyłączenia z przychodów

- **Co sprawdza:** Niektóre wpływy NIE stanowią przychodu: zwrot uprzednio odliczonych wydatków (np. zwrot VAT), otrzymane odszkodowania za utracone przychody, zwrot nadpłaconych składek ZUS.
- **Propozycja reguły:** `jdg.pit.revenue_exclusions`
  - **Priorytet:** P508
  - **Rezultat:** `pit_revenue_excluded: true`, `revenue_exclusion_type: <typ>`
  - **Podstawa prawna:** Art. 14 ust. 3 PIT
- 🟡 **WAŻNA**

## 🟡 Luka 25: Art. 30c ust. 2 pkt 1-7 PIT — Szczegóły podatku liniowego

- **Co sprawdza:** Ograniczenia podatku liniowego: nie można rozliczać się liniowo z byłym/obecnym pracodawcą (odpowiadającym usługom świadczonym wcześniej na etacie).
- **Propozycja reguły:** `jdg.pit.form_linear.former_employer_restriction`
  - **Priorytet:** P512
  - **Przesłanki:** `input.jdg_entrepreneur.tax_form == "LINEAR"` AND `input.vendor == former_employer_in_current_year`
  - **Rezultat:** `linear_tax_invalid_for_this_client: true`, `must_use_scale_for_this_revenue: true`
  - **Podstawa prawna:** Art. 30c ust. 2 pkt 1 PIT, Art. 9a ust. 3 PIT
- 🟡 **WAŻNA**

## 🟢 Luka 26: Art. 23 ust. 1 pkt 46-49 PIT — Szczegółowe wyłączenia KUP

- **Co sprawdza:** Konkretne wydatki wyłączone z KUP: składki na ubezpieczenie samochodu powyżej wartości 150k (proporcjonalnie), wydatki na rzecz osób niebędących pracownikami bez umowy, wydatki na organizacje nieuznane.
- **Propozycja reguły:** `jdg.pit.kup.detailed_exclusions`
  - **Priorytet:** P574
  - **Rezultat:** `kus_qualification: "none"`, `exclusion_article: "Art.23_X_PIT"`
  - **Podstawa prawna:** Art. 23 ust. 1 pkt 46-49 PIT
- 🟢 **DODATKOWA**

## 🟢 Luka 27: Art. 24 ust. 1a-1b PIT — Dochód — szczegóły

- **Co sprawdza:** Definicja dochodu jako różnicy przychodów i KUP z uwzględnieniem remanentu (różnica stanu końcowego i początkowego).
- **Propozycja reguły:** `jdg.pit.income_calculation_with_inventory`
  - **Priorytet:** P509
  - **Rezultat:** `pit_income: revenue - kup + (inventory_end - inventory_start)`
  - **Podstawa prawna:** Art. 24 ust. 1-1b PIT
- 🟢 **DODATKOWA**

---

# CZĘŚĆ V: RYCZAŁT EWIDENCJONOWANY — GŁĘBOKI AUDYT

**Status w DocsJDG:** Kluczowe artykuły wymienione.  
**Status w regułach:** P520-P529 (podstawy), ale brak szczegółów.

---

## 🔴 Luka 28: Art. 8 u.z.p.d. — Bezwzględne wyłączenia z ryczałtu

- **Co sprawdza:** Niektóre JDG NIE mogą korzystać z ryczałtu: apteki, kantory, handel częściami samochodowymi, usługi dla byłego pracodawcy (w ciągu roku od odejścia).
- **Obecne pokrycie:** BRAK. Żadna reguła nie sprawdza wyłączeń!
- **Propozycja reguły:** `jdg.pit.form_lump_sum.statutory_exclusions`
  - **Priorytet:** P524
  - **Przesłanki:** 
    - `input.jdg_entrepreneur.pkd_main in ["47.73.Z" (apteki), "64.99.Z" (kantory)...]`
    - OR `input.jdg_entrepreneur.tax_form == "LUMP_SUM"` AND `input.vendor == former_employer` AND `months_since_employment <= 12`
  - **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `error: "Branża wyłączona z ryczałtu — wymagana skala lub podatek liniowy"`
  - **Podstawa prawna:** Art. 8 ust. 1-2 ustawy o ryczałcie
- 🔴 **KRYTYCZNA** — brak może skutkować błędną formą opodatkowania!

## 🟡 Luka 29: Art. 20 u.z.p.d. — Utrata prawa do ryczałtu

- **Co sprawdza:** Przekroczenie limitu 2M EUR rocznie, rozpoczęcie działalności wyłączonej z ryczałtu, lub podjęcie działalności z byłym pracodawcą w trakcie roku.
- **Propozycja reguły:** `jdg.pit.form_lump_sum.loss_of_lump_sum_right`
  - **Priorytet:** P525
  - **Przesłanki:** `annual_turnover_net > 2000000_EUR` lub zmiana PKD na wyłączone
  - **Rezultat:** `lump_sum_right_lost: true`, `must_switch_to_scale: true`, `date_of_loss: <data>`
  - **Podstawa prawna:** Art. 20 ustawy o ryczałcie
- 🟡 **WAŻNA**

## 🟡 Luka 30: Art. 9 u.z.p.d. — Warunki wyboru ryczałtu

- **Co sprawdza:** Oświadczenie o wyborze ryczałtu składa się do 20. dnia miesiąca po pierwszym przychodzie (nowa JDG) lub do 20 stycznia (kontynuacja).
- **Obecne pokrycie:** Częściowo przez P520, ale bez walidacji terminu złożenia oświadczenia.
- **Propozycja reguły:** `jdg.pit.form_lump_sum.election_deadline`
  - **Priorytet:** P526
  - **Przesłanki:** `tax_form == "LUMP_SUM"` AND `ceidg_lump_sum_declaration_filed == false` AND `first_revenue_already_earned == true`
  - **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `error: "Nie złożono oświadczenia o wyborze ryczałtu w terminie"`
  - **Podstawa prawna:** Art. 9 ust. 1-4 ustawy o ryczałcie
- 🟡 **WAŻNA**

## 🟢 Luka 31: Art. 23 u.z.p.d. — Tabela stawek karty podatkowej

- **Co sprawdza:** Konkretne stawki karty podatkowej wg rodzaju działalności, liczby mieszkańców gminy, liczby zatrudnionych.
- **Propozycja reguły:** `jdg.pit.form_tax_card.rate_table`
  - **Priorytet:** P532
  - **Rezultat:** `tax_card_monthly_rate` z tabeli wg parametrów
  - **Podstawa prawna:** Art. 23 ustawy o ryczałcie (Załącznik nr 3)
- 🟢 **DODATKOWA**

## 🟢 Luka 32: Art. 27 u.z.p.d. — Zdarzenia powodujące utratę karty podatkowej

- **Co sprawdza:** Zatrudnienie więcej niż dozwolona liczba pracowników, zmiana rodzaju działalności, korzystanie z usług innych firm w zakresie objętym kartą.
- **Propozycja reguły:** `jdg.pit.form_tax_card.loss_of_card_events`
  - **Priorytet:** P533
  - **Rezultat:** `tax_card_lost: true`
  - **Podstawa prawna:** Art. 27 ustawy o ryczałcie
- 🟢 **DODATKOWA**

---

# CZĘŚĆ VI: USTAWA O SUS (ZUS) — GŁĘBOKI AUDYT

**Status w DocsJDG:** Kluczowe artykuły wymienione.  
**Status w regułach:** Dobrze pokryty (P700-P745 po rozbudowie), ale są luki.

---

## 🔴 Luka 33: Art. 9 SUS — Zbieg ubezpieczeń (etat + JDG)

- **Co sprawdza:** JDG zatrudniony na umowę o pracę z wynagrodzeniem ≥ minimalnego — z JDG płaci TYLKO składkę zdrowotną (bez społecznych). To jedna z najczęstszych sytuacji!
- **Obecne pokrycie:** BRAK. Żadna reguła nie sprawdza zbiegu!
- **Propozycja reguły:** `jdg.zus.concurrent_employment_exemption`
  - **Priorytet:** P743
  - **Przesłanki:** 
    - `input.jdg_entrepreneur.has_employment_contract == true`
    - `input.jdg_entrepreneur.employment_salary >= minimum_wage`
  - **Rezultat:** 
    - `zus_social_rate: "0.00"` (zwolnienie ze społecznych)
    - `zus_health_rate: normalna wg formy opodatkowania`
    - `_warning: "Zbieg ubezpieczeń — z JDG tylko składka zdrowotna"`
  - **Podstawa prawna:** Art. 9 ust. 1a-2 SUS
- 🔴 **KRYTYCZNA** — bardzo częsta sytuacja, brak reguły powoduje zawyżone składki!

## 🟡 Luka 34: Art. 8-9 SUS — Ustanie/dobrowolność ubezpieczeń

- **Co sprawdza:** Ubezpieczenia społeczne JDG ustają z dniem zaprzestania wykonywania działalności. Ubezpieczenie chorobowe (dobrowolne) ustaje po nieopłaceniu składki w terminie.
- **Propozycja reguły:** `jdg.zus.insurance_cessation`
  - **Priorytet:** P744
  - **Rezultat:** `zus_insurance_end_date: <data>`, `sickness_insurance_lost: true` (jeśli nie zapłacono chorobowej w terminie 30 dni)
  - **Podstawa prawna:** Art. 8-9, Art. 14 SUS
- 🟡 **WAŻNA**

## 🟡 Luka 35: Art. 47 ust. 1 SUS — Szczegółowe terminy płatności składek

- **Co sprawdza:** JDG bez pracowników: do 20. dnia miesiąca. JDG jednoosobowa: do 10. dnia (specyficzne grupy). JDG z pracownikami: do 15. dnia.
- **Propozycja reguły:** `jdg.zus.payment_deadlines`
  - **Priorytet:** P745
  - **Przesłanki:** `input.jdg_entrepreneur.employees_count == 0` → deadline = 20th
  - **Rezultat:** `zus_payment_deadline_day: 20` (lub 10/15)
  - **Podstawa prawna:** Art. 47 ust. 1-1c SUS
- 🟡 **WAŻNA**

## 🟡 Luka 36: Art. 24 ust. 4-5d SUS — Przedawnienie składek ZUS (szczegóły)

- **Co sprawdza:** Przedawnienie składek ZUS po 5 latach (obecnie), ale do 2012 było to 10 lat. Zawieszenie biegu przedawnienia w przypadku postępowania egzekucyjnego.
- **Obecne pokrycie:** P1152 ogólnie, ale bez szczegółów zawieszenia.
- **Propozycja reguły:** `jdg.zus.zus_statute_suspension`
  - **Priorytet:** P1153
  - **Przesłanki:** `input.document.zus_enforcement_started == true`
  - **Rezultat:** `zus_statute_suspended: true`
  - **Podstawa prawna:** Art. 24 ust. 5b-5d SUS
- 🟡 **WAŻNA**

## 🟢 Luka 37: Art. 16-17 SUS — Rozliczanie składek (deklaracja DRA)

- **Co sprawdza:** Obowiązek składania deklaracji ZUS DRA co miesiąc (do 15. dnia dla JDG z pracownikami, do 20. dla JDG bez pracowników).
- **Propozycja reguły:** `jdg.zus.dra_filing_deadline`
  - **Priorytet:** P746
  - **Rezultat:** alert przy przekroczeniu terminu DRA
  - **Podstawa prawna:** Art. 16-17 SUS
- 🟢 **DODATKOWA**

---

# CZĘŚĆ VII: USTAWA O ŚWIADCZENIACH OPIEKI ZDROWOTNEJ — GŁĘBOKI AUDYT

**Status w regułach:** Dobrze pokryty (P720-P738). Luki minimalne.

---

## 🟡 Luka 38: Art. 66, 67, 69 — Podleganie ubezpieczeniu zdrowotnemu

- **Co sprawdza:** Kto podlega ubezpieczeniu zdrowotnemu (każda JDG), kiedy powstaje/ustaje obowiązek, możliwość dobrowolnego ubezpieczenia.
- **Propozycja reguły:** `jdg.zus.health_insurance_obligation`
  - **Priorytet:** P739
  - **Przesłanki:** `input.jdg_entrepreneur.business_status == "ACTIVE"` → zawsze podlega
  - **Rezultat:** `health_insurance_mandatory: true`
  - **Podstawa prawna:** Art. 66 ust. 1 pkt 1c, Art. 67, Art. 69
- 🟡 **WAŻNA**

## 🟢 Luka 39: Art. 82 — Termin opłacania składki zdrowotnej

- **Co sprawdza:** Składkę zdrowotną opłaca się w tym samym terminie co składki społeczne (do 20. dnia).
- **Propozycja reguły:** `jdg.zus.health_payment_deadline`
  - **Priorytet:** P748
  - **Rezultat:** `health_contribution_due_day: 20`
  - **Podstawa prawna:** Art. 82
- 🟢 **DODATKOWA**

---

# CZĘŚĆ VIII: ZARZĄD SUKCESYJNY — GŁĘBOKI AUDYT

**Status w DocsJDG:** Wymieniony.  
**Status w regułach:** P920-P924 (podstawy).

---

## 🟡 Luka 40: Art. 3-4 u.z.s. — Powołanie zarządcy sukcesyjnego

- **Co sprawdza:** Procedura powołania: za życia przedsiębiorcy (wpis do CEIDG) lub po śmierci przez spadkobierców (w ciągu 2 miesięcy). Zarządca musi wyrazić zgodę.
- **Propozycja reguły:** `jdg.business.succession.manager_appointment_valid`
  - **Priorytet:** P925
  - **Przesłanki:** `input.jdg_entrepreneur.in_succession == true`
  - **Rezultat:** walidacja czy zarządca powołany zgodnie z procedurą
  - **Podstawa prawna:** Art. 3-7 u.z.s.
- 🟡 **WAŻNA**

## 🟡 Luka 41: Art. 12-13 u.z.s. — Maksymalny okres zarządu sukcesyjnego

- **Co sprawdza:** Zarząd sukcesyjny trwa max 2 lata od śmierci przedsiębiorcy. Sąd może przedłużyć do 5 lat. Po upływie — NIP wygasa, koniec działalności.
- **Propozycja reguły:** `jdg.business.succession.time_limit`
  - **Priorytet:** P926
  - **Przesłanki:** `months_since_death > 24` AND `input.jdg_entrepreneur.court_extension_granted == false`
  - **Rezultat:** `_routing: "BLOCK_AND_ALERT"`, `error: "Zarząd sukcesyjny wygasł po 2 latach — NIP nieaktywny"`
  - **Podstawa prawna:** Art. 12, Art. 13 u.z.s.
- 🟡 **WAŻNA**

## 🟢 Luka 42: Art. 14-15 u.z.s. — Wygaśnięcie zarządu

- **Co sprawdza:** Zarząd wygasa z dniem: upływu 2 lat, śmierci zarządcy, rezygnacji, orzeczenia sądu, ogłoszenia upadłości.
- **Propozycja reguły:** `jdg.business.succession.termination_events`
  - **Priorytet:** P927
  - **Rezultat:** `succession_terminated: true`
  - **Podstawa prawna:** Art. 14-15 u.z.s.
- 🟢 **DODATKOWA**

---

# CZĘŚĆ IX: POMINIĘTE AKTY PRAWNE

---

## 🟡 Luka 43: Ustawa o PCC — Podatek od czynności cywilnoprawnych

- **Status w DocsJDG:** NIEOBECNA
- **Co sprawdza:** Zakup samochodu/sprzętu od osoby prywatnej (umowa kupna-sprzedaży) → PCC-3 w ciągu 14 dni, 2% wartości rynkowej. Transakcje z VAT NIE podlegają PCC (wyłączenie).
- **Propozycja reguły:** `jdg.local_taxes.pcc_mandatory`
  - **Priorytet:** P1300
  - **Przesłanki:** `input.invoice.direction == "PURCHASE"` AND `input.vendor.country == "PL"` AND `input.vendor.is_vat_payer == false` (osoba prywatna) AND `input.invoice.type == "GOODS"`
  - **Rezultat:** `pcc_filing_required: true`, `pcc_rate: "0.02"`, `pcc_deadline: "14_days"`
  - **Podstawa prawna:** Ustawa o PCC (Dz.U. 2023 poz. 721)
- 🟡 **WAŻNA** — codzienna sytuacja JDG

## 🟡 Luka 44: Ustawa o podatkach i opłatach lokalnych — Podatek od nieruchomości

- **Status w DocsJDG:** NIEOBECNA
- **Co sprawdza:** Część domu/mieszkania wykorzystywana na działalność → wyższa stawka podatku od nieruchomości (~33 zł/m² zamiast ~1,15 zł/m²). Obowiązek deklaracji DN-1.
- **Propozycja reguły:** `jdg.local_taxes.real_estate_commercial`
  - **Priorytet:** P1310
  - **Przesłanki:** `input.jdg_entrepreneur.home_office_area > 0` AND `input.jdg_entrepreneur.dn1_filed == false`
  - **Rezultat:** `real_estate_tax_commercial_rate: true`, `dn1_filing_required: true`, `annual_tax_per_sqm: ~33 PLN`
  - **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych
- 🟡 **WAŻNA**

## 🟡 Luka 45: Ustawa o podatku od środków transportowych

- **Status w DocsJDG:** NIEOBECNA
- **Co sprawdza:** JDG posiadające samochody ciężarowe >3.5t, ciągniki siodłowe, autobusy → podatek od środków transportowych.
- **Propozycja reguły:** `jdg.local_taxes.transport_tax`
  - **Priorytet:** P1320
  - **Przesłanki:** `input.invoice.category_code == "TRUCK"` AND `vehicle_weight > 3.5t`
  - **Rezultat:** `transport_tax_applicable: true`
  - **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych (rozdział 3)
- 🟡 **WAŻNA**

## 🟢 Luka 46: Kodeks cywilny — Art. 109¹ Prokura (szczegóły)

- **Status w DocsJDG:** Pośrednio (CEIDG)
- **Co sprawdza:** Prokura musi być wpisana do CEIDG. Prokura łączna wymaga współdziałania. Prokura oddziałowa — ograniczona do oddziału.
- **Obecne pokrycie:** P1204 (`commercial_proxy_prokura`) ogólnie, bez rozróżnienia typów.
- **Propozycja reguły:** `jdg.representation.prokura_types`
  - **Priorytet:** P1205
  - **Rezultat:** walidacja typu prokury (samoistna/łączna/oddziałowa)
  - **Podstawa prawna:** Art. 109¹-109⁸ KC
- 🟢 **DODATKOWA**

---

# PODSUMOWANIE AUDYTU

## Statystyki

| Kategoria | Liczba | Priorytety |
|-----------|:------:|------------|
| 🔴 **KRYTYCZNE** — wymagane ENTERPRISE | 12 | P0_b, P4, P6, P6_b, P9, P36, P39, P184, P508, P524, P572, P743 |
| 🟡 **WAŻNE** | 20 | P7, P183, P192, P233, P234, P512, P525, P526, P532-533, P574, P739, P744-745, P925-926, P1153, P1157, P1167-1171, P1300, P1310, P1320 |
| 🟢 **DODATKOWE** | 14 | P509, P532, P533, P746, P748, P870, P927, P972, P1169, P1172, P1174, P1205 |
| **RAZEM** | **46** | P0_b – P1320 |

## Akty prawne — pokrycie po audycie

| Akt prawny | Przed audytem | Po audycie | Największe luki |
|------------|:-------------:|:----------:|-----------------|
| Ordynacja podatkowa | 60% | 85% | GAAR, nadpłaty, odroczenia, czynny żal |
| KKS | 5% | 60% | Puste faktury, nierzetelne księgi, ukryte dochody |
| Ustawa o VAT | 80% | 95% | Złe długi dłużnik, VAT-R krajowy, paragony do 450 PLN |
| Ustawa o PIT | 75% | 90% | Direct/indirect KUP, różnice kursowe, były pracodawca a liniowy |
| Ryczałt / Karta | 50% | 85% | Wyłączenia Art.8, utrata prawa, tabela stawek karty |
| SUS (ZUS) | 70% | 90% | Zbieg etat+JDG, ustanie ubezpieczeń, terminy DRA |
| Świadczenia zdrowotne | 85% | 95% | Podleganie, termin płatności |
| Zarząd sukcesyjny | 60% | 90% | Powołanie, max 2 lata, wygaśnięcie |
| PCC | 0% | 80% | Całkowicie pominięty! |
| Podatek od nieruchomości | 0% | 80% | Całkowicie pominięty! |
| Podatek od śr. transportowych | 0% | 80% | Całkowicie pominięty! |

---

## Rekomendowana kolejność implementacji uzupełnień

| Faza | Luki | Priorytet |
|------|------|-----------|
| **Faza A** (natychmiast) | 🔴 KRYTYCZNE: P184 (złe długi dłużnik), P36 (paragony 450 PLN), P524 (wyłączenia ryczałtu), P572 (direct/indirect KUP), P743 (zbieg etat+JDG), P39 (VAT-R krajowy), P0_b (puste faktury KKS) | ENTERPRISE MUST |
| **Faza B** (ważne) | 🟡 WAŻNE: P9 (GAAR), P4, P6, P7 (KKS risk), P192 (zwrot VAT), P512 (były pracodawca a liniowy), P1300-P1320 (lokalne), P925-P926 (sukcesja) | ENTERPRISE SHOULD |
| **Faza C** (uzupełnienie) | 🟢 DODATKOWE: pozostałe 14 reguł | NICE TO HAVE |

---

> **Następny krok:** Dodanie KKS do `DocsJDG` i implementacja Fazy A (6 reguł krytycznych).  
> **Powiązane:** `Plan OPA/22_JDG_ENTERPRISE_PLAN.md` | `Plan OPA/23_JDG_EXPANSION_SUPPLEMENT.md` | `Plan OPA/24_JDG_COMPLETE_INDEX.md` | `Plan OPA/DocsJDG`
