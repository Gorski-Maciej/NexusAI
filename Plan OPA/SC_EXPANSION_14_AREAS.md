# 🔧 NexusAI Spółka Cywilna — ROZBUDOWA: 14 Obszarów Ekspansji ENTERPRISE v1.0

> **Status:** ROZSZERZENIE — uzupełnia `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md`
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/SC_EXPANSION_14_AREAS.md`
> **Cel:** Rozbudowa istniejącego planu o ~130 szczegółowych reguł w 14 obszarach zidentyfikowanych przez audyt luk
> **Dokument nadrzędny:** `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` — tam znajduje się architektura, input spec, thresholds i multi-pass
> **Nowe reguły:** ~130 | **Nowe pakiety:** 1 (`sc.partnership.representation`) | **Rozbudowane pakiety:** 13

---

## Spis Treści

- [Obszar 1: Ulgi i odliczenia dla wspólników (~15 reguł)](#obszar-1-ulgi-i-odliczenia-dla-wspólników)
- [Obszar 2: Składki ZUS i zdrowotne — zaawansowane (~10 reguł)](#obszar-2-składki-zus-i-zdrowotne--zaawansowane)
- [Obszar 3: Zawieszenie i wznowienie — szczegóły (~8 reguł)](#obszar-3-zawieszenie-i-wznowienie--szczegóły)
- [Obszar 4: Sukcesja — szczegóły (~8 reguł)](#obszar-4-sukcesja--szczegóły)
- [Obszar 5: Zmiana formy opodatkowania mid-year (~6 reguł)](#obszar-5-zmiana-formy-opodatkowania-mid-year)
- [Obszar 6: Zmiana składu wspólników — szczegóły (~6 reguł)](#obszar-6-zmiana-składu-wspólników--szczegóły)
- [Obszar 7: Eksport i import usług VAT (~10 reguł)](#obszar-7-eksport-i-import-usług-vat)
- [Obszar 8: Korekty deklaracji i faktur — szczegóły (~8 reguł)](#obszar-8-korekty-deklaracji-i-faktur--szczegóły)
- [Obszar 9: Przedawnienia i odpowiedzialność — szczegóły (~7 reguł)](#obszar-9-przedawnienia-i-odpowiedzialność--szczegóły)
- [Obszar 10: Reprezentacja i pełnomocnictwa ★ NOWY PAKIET (~5 reguł)](#obszar-10-reprezentacja-i-pełnomocnictwa--nowy-pakiet)
- [Obszar 11: Interakcje forma PIT a składki (~6 reguł)](#obszar-11-interakcje-forma-pit-a-składki)
- [Obszar 12: Rozwiązanie i likwidacja — szczegóły (~8 reguł)](#obszar-12-rozwiązanie-i-likwidacja--szczegóły)
- [Obszar 13: Spółka jako pracodawca — szczegóły (~10 reguł)](#obszar-13-spółka-jako-pracodawca--szczegóły)
- [Obszar 14: Limit pełnej księgowości — szczegóły (~6 reguł)](#obszar-14-limit-pełnej-księgowości--szczegóły)
- [Aktualizacja hierarchii — zintegrowane priorytety](#aktualizacja-hierarchii--zintegrowane-priorytety)
- [Cross-Reference: Nowe reguły → Podstawa prawna](#cross-reference-nowe-reguły--podstawa-prawna)

---

## Obszar 1: Ulgi i odliczenia dla wspólników

> **Istniejące reguły w `SC_DEFINITIVE_REGO_PLAN.md`:** P580-P588 (zwolnienia PIT: młodzi, powrót, 4+, senior), P600 (B+R), P610 (IP Box), P615 (strata), P623 (termomodernizacyjna)
> **Dodawane reguły:** P606-P627 — rozbudowa pakietu `sc.allowances`

### P606: `partner_relief_prototype_sc` ★
- **Cel biznesowy:** Ulga na prototyp — odliczenie 30% kosztów produkcji próbnej nowego produktu od dochodu wspólnika. Stosowana indywidualnie przez każdego wspólnika (Art. 8 PIT — proporcja).
- **Przesłanki:**
  - `p.has_prototype_activities == true`
  - `input.invoice.category_code == "RND_PROTOTYPE"`
  - Produkcja próbna związana z działalnością spółki
  - `p.annual_prototype_costs > 0`
- **Oczekiwany rezultat:**
  - `p.prototype_deduction: min(p.annual_prototype_costs * 0.30, p.prototype_limit)`
  - `p.prototype_carry_forward: unused_deduction` (do 6 lat)
  - `kus_qualification: "rd_full"`
- **Podstawa prawna:** Art. 26eb PIT
- **Zależności:** Po P500 (podział proporcjonalny), po P600 (B+R — jeśli ta sama faktura może kwalifikować się do obu ulg, wspólnik wybiera).
- **Przypadki brzegowe:** Koszty produkcji próbnej pokrywają się z B+R → nie można podwójnie odliczyć. Prototyp zakończony niepowodzeniem → nadal można odliczyć jeśli podjęto próbę. Ulga limitowana pułapem dochodu — nadwyżka carry-forward.
- **Priorytet:** 606

### P608: `partner_relief_robotization_sc` ★
- **Cel biznesowy:** Ulga na robotyzację — odliczenie 50% kosztów nabycia robotów przemysłowych i oprogramowania. Istotna dla SC produkcyjnych.
- **Przesłanki:**
  - `input.invoice.category_code == "ROBOTICS"`
  - Zakup nowych robotów przemysłowych/osprzętu/oprogramowania
  - `input.invoice.asset_type == "INDUSTRIAL_ROBOT"`
- **Oczekiwany rezultat:**
  - `p.robotization_deduction: qualified_costs * 0.50`
  - `p.robotization_deduction_capped: min(deduction, p.annual_income)`
- **Podstawa prawna:** Art. 26gb PIT
- **Zależności:** Po P840+ (amortyzacja — robot może być też amortyzowany; ulga dodatkowa, niezależna od amortyzacji).
- **Przypadki brzegowe:** Robot używany → NIE podlega uldze. Leasing robota → częściowo podlega (tylko opłaty wstępne). Limit: kwota odliczenia nie może przekroczyć dochodu wspólnika.
- **Priorytet:** 608

### P612: `partner_relief_expansion_sc` ★
- **Cel biznesowy:** Ulga na ekspansję — odliczenie kosztów udziału w targach zagranicznych, reklamy za granicą, przygotowania dokumentacji.
- **Przesłanki:**
  - `input.invoice.category_code` w `["TRADE_FAIR", "EXPORT_PROMOTION", "INTL_ADVERTISING"]`
  - `input.vendor.country != "PL"` — wydatki zagraniczne
  - Wydatek poniesiony w celu zwiększenia przychodów ze sprzedaży na rynkach zagranicznych
- **Oczekiwany rezultat:**
  - `p.expansion_deduction: qualified_costs` (do 1 000 000 PLN)
  - `p.expansion_deduction_type: "REVENUE_REDUCTION"`
- **Podstawa prawna:** Art. 26ec PIT
- **Zależności:** Po P500 (podział), przed P540 (zaliczki).
- **Przypadki brzegowe:** Tylko dla produktów wytworzonych przez spółkę (nie dotyczy handlu). Wydatki muszą być udokumentowane. Limit 1 mln PLN rocznie — dotyczy sumy wydatków SPÓŁKI, dzielonych proporcjonalnie.
- **Priorytet:** 612

### P618: `partner_relief_rehabilitation_sc` ★
- **Cel biznesowy:** Ulga rehabilitacyjna — odliczenie wydatków na cele rehabilitacyjne wspólnika lub jego niepełnosprawnych osób na utrzymaniu.
- **Przesłanki:**
  - `p.has_disability_certificate == true` LUB `p.has_disabled_dependant == true`
  - `input.invoice.category_code` w `["REHABILITATION", "MEDICAL_ADAPTATION", "ASSISTIVE_TECHNOLOGY"]`
- **Oczekiwany rezultat:**
  - `p.rehabilitation_deduction: actual_costs` (limit: 2 280 PLN na leki, bez limitu na zabiegi)
- **Podstawa prawna:** Art. 26 ust. 1 pkt 6, ust. 7a-7g PIT
- **Zależności:** Odliczenie od dochodu wspólnika. Przed P540 (zaliczki).
- **Przypadki brzegowe:** Wydatki muszą być udokumentowane fakturami VAT (nie paragonami). Leki — tylko kwota powyżej 100 PLN miesięcznie. Adaptacja mieszkania — limit 15 000 PLN.
- **Priorytet:** 618

### P620: `partner_relief_ikze_sc` ★
- **Cel biznesowy:** Wpłaty na Indywidualne Konto Zabezpieczenia Emerytalnego (IKZE) — odliczenie od dochodu. Limit 2026: ~9 370 PLN.
- **Przesłanki:**
  - `p.has_ikze_account == true`
  - `p.annual_ikze_contributions > 0`
  - `p.annual_ikze_contributions <= input.thresholds.sc.bounds.ikze_annual_limit`
- **Oczekiwany rezultat:** `p.ikze_deduction: p.annual_ikze_contributions`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 2b PIT, ustawa o IKE/IKZE
- **Przypadki brzegowe:** Wpłaty powyżej limitu → nadwyżka NIE podlega odliczeniu. IKZE tylko dla jednego konta na osobę.
- **Priorytet:** 620

### P622: `partner_relief_donation_sc` ★
- **Cel biznesowy:** Darowizny na cele charytatywne, organizacje pożytku publicznego — odliczenie do 6% dochodu.
- **Przesłanki:**
  - `input.invoice.category_code == "CHARITY_DONATION"`
  - Odbiorca w rejestrze OPP
  - `input.invoice.amount_net > 0`
- **Oczekiwany rezultat:**
  - `p.donation_deduction: min(total_donations, p.annual_income * 0.06)`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 9, Art. 26 ust. 5 PIT
- **Przypadki brzegowe:** Darowizny rzeczowe → wartość wg ceny nabycia. Darowizny na cele religijne → też 6%. Darowizny krwi → ekwiwalent 130 PLN za litr.
- **Priorytet:** 622

### P626: `partner_relief_internet_sc` ★
- **Cel biznesowy:** Ulga internetowa — odliczenie do 760 PLN rocznie, tylko przez 2 kolejne lata. Coraz rzadziej stosowana, ale nadal obowiązująca.
- **Przesłanki:**
  - `input.invoice.category_code == "INTERNET"`
  - `p.internet_relief_years_used < 2`
  - `input.invoice.amount_net > 0`
- **Oczekiwany rezultat:**
  - `p.internet_deduction: min(annual_internet_costs, input.thresholds.sc.bounds.internet_relief_limit)`
- **Podstawa prawna:** Art. 26 ust. 1 pkt 6a PIT (wygaszany)
- **Przypadki brzegowe:** Tylko dla wspólników którzy NIE korzystali z ulgi w poprzednich latach lub korzystali maksymalnie 1 rok. Faktura musi być na nazwisko wspólnika.
- **Priorytet:** 626

---

## Obszar 2: Składki ZUS i zdrowotne — zaawansowane

> **Istniejące reguły:** P700-P749 (podstawowe składki, ulga na start, Mały ZUS Plus, zbieg etat, zdrowotna)
> **Dodawane reguły:** P716-P744 — rozbudowa `sc.zus.social` i `sc.zus.health`

### P716: `partner_zus_concurrent_retirement_sc` ★
- **Cel biznesowy:** Zbieg emerytury/renty z działalnością w SC — wspólnik na emeryturze może być zwolniony z części składek.
- **Przesłanki:**
  - `p.has_pension == true` AND `p.pension_amount > 0`
  - `p.zus_status == "ACTIVE"`
- **Oczekiwany rezultat:**
  - Jeśli emerytura ≥ minimalna: `p.zus_social_base: 0.60 * average_wage` (jak standard)
  - Jeśli emerytura < minimalna i działalność to jedyne źródło: składki jak standard
  - `p.zus_health_due: true` — zdrowotna zawsze
- **Podstawa prawna:** Art. 9 ust. 4-5 ustawy o SUS
- **Przypadki brzegowe:** Emeryt prowadzący SC + praca etatowa → zbieg 3 tytułów, priorytet: etat > emerytura > SC. Emeryt z rentą rodzinną → inny reżim.
- **Priorytet:** 716

### P718: `partner_zus_30x_limit_sc` ★
- **Cel biznesowy:** Limit 30-krotności podstawy wymiaru składek społecznych (tzw. "trzydziestokrotność"). Po przekroczeniu rocznego limitu składek emerytalnych i rentowych — zaprzestanie ich opłacania.
- **Przesłanki:**
  - `p.cumulative_zus_base_ytd >= input.thresholds.sc.bounds.zus_30x_limit` (dla 2026: ~234 720 PLN)
  - Dotyczy sumy podstaw ze WSZYSTKICH tytułów (SC + etat + zlecenia)
- **Oczekiwany rezultat:**
  - `p.zus_emerytalna: 0` (od miesiąca po przekroczeniu)
  - `p.zus_rentowa: 0`
  - Pozostałe składki (wypadkowa, FP, FGŚP) — nadal naliczane
  - `p.zus_30x_exceeded: true`
- **Podstawa prawna:** Art. 19 ust. 1 ustawy o SUS
- **Przypadki brzegowe:** Limit dotyczy SUMY wszystkich tytułów wspólnika. Po przekroczeniu — ZUS zwraca nadpłatę. Nowy rok → limit reset.
- **Priorytet:** 718

### P719: `partner_zus_proportional_days_sc` ★
- **Cel biznesowy:** Wspólnik, który przystąpił/wystąpił ze spółki w trakcie miesiąca — składki ZUS tylko za dni członkostwa.
- **Przesłanki:**
  - `p.join_date.day > 1` LUB `p.exit_date.day < last_day_of_month`
  - `p.zus_status == "ACTIVE"`
- **Oczekiwany rezultat:**
  - `p.zus_base_proportional: base * (active_days / total_days_in_month)`
  - `p.zus_social_proportional: social_total * (active_days / total_days_in_month)`
- **Podstawa prawna:** Art. 18 ust. 8-9 ustawy o SUS
- **Przypadki brzegowe:** Przystąpienie 15. dnia → składki za 16 dni z 30 = 53.33%. Wystąpienie 10. dnia → składki za 10 dni.
- **Priorytet:** 719

### P740: `partner_health_annual_reconciliation_sc` ★
- **Cel biznesowy:** Roczne rozliczenie składki zdrowotnej — porównanie zapłaconych zaliczek z rzeczywistą składką od rocznego dochodu.
- **Przesłanki:**
  - `p.tax_form` w `["PIT_SCALE", "LINEAR"]`
  - Koniec roku podatkowego
- **Oczekiwany rezultat:**
  - `p.health_annual_total: roczny_dochód * stawka`
  - `p.health_overpayment: max(0, paid_total - annual_total)` — zwrot
  - `p.health_underpayment: max(0, annual_total - paid_total)` — dopłata
  - `p.health_minimum_check: annual_total >= minimum_health_contribution`
- **Podstawa prawna:** Art. 81 ust. 2 ustawy o świadczeniach opieki zdrowotnej
- **Przypadki brzegowe:** Zwrot tylko do wysokości zapłaconych składek. Dopłata do końca maja następnego roku.
- **Priorytet:** 740

### P742: `partner_health_fixed_asset_sale_exclusion_sc` ★
- **Cel biznesowy:** Wyłączenie z podstawy składki zdrowotnej przychodów ze sprzedaży środków trwałych (Polski Ład).
- **Przesłanki:**
  - `input.invoice.category_code == "FIXED_ASSET_SALE"`
  - `input.invoice.direction == "SALE"`
  - Środek trwały był amortyzowany
- **Oczekiwany rezultat:**
  - `p.health_base_excluded_amount: sale_price` — przychód NIE wchodzi do podstawy składki zdrowotnej
  - `p.health_base_adjustment: true`
- **Podstawa prawna:** Art. 81 ust. 2ca ustawy o świadczeniach opieki zdrowotnej
- **Przypadki brzegowe:** Sprzedaż przed upływem 6 lat od nabycia → przychód wchodzi do podstawy (wcześniejsze wycofanie z majątku).
- **Priorytet:** 742

### P744: `partner_unregistered_activity_block_sc` ★
- **Cel biznesowy:** Strażnik — działalność nieewidencjonowana (Art. 5 PP) NIE dotyczy SC (tylko JDG osoby fizycznej). Blokada próby użycia.
- **Przesłanki:**
  - `p.zus_status == "UNREGISTERED_ACTIVITY"`
  - `count(input.partners) >= 2` — to jest SC
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Działalność nieewidencjonowana NIE dotyczy spółki cywilnej — każdy wspólnik musi być zarejestrowany w CEIDG"`
  - `p.zus_status_override: "STANDARD"`
- **Podstawa prawna:** Art. 5 Prawa przedsiębiorców, Art. 14 PP (spółka cywilna jako forma współpracy przedsiębiorców)
- **Przypadki brzegowe:** Nawet jeśli przychód wspólnika ze SC < 50% minimalnego wynagrodzenia → nadal pełny ZUS.
- **Priorytet:** 744

---

## Obszar 3: Zawieszenie i wznowienie — szczegóły

> **Istniejące reguły:** P940-P942
> **Dodawane reguły:** P944-P949

### P944: `sc_suspension_employee_block_sc` ★
- **Cel biznesowy:** Spółka zatrudniająca pracowników NIE może się zawiesić. Zawieszenie wymaga uprzedniego rozwiązania umów i odpraw.
- **Przesłanki:**
  - `input.partnership.status == "SUSPENDING"`
  - `input.partnership.employee_count > 0`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `suspension_blocked: true`
  - `_warning: "Spółka zatrudnia pracowników — zawieszenie niedozwolone"`
- **Podstawa prawna:** Art. 22 ust. 7 Prawa przedsiębiorców
- **Przypadki brzegowe:** Pracownicy na urlopach macierzyńskich/ wychowawczych → nadal blokada. Zleceniobiorcy (umowa zlecenia) → NIE blokują zawieszenia (nie są pracownikami).
- **Priorytet:** 944

### P945: `sc_suspension_allowed_actions_sc` ★
- **Cel biznesowy:** W trakcie zawieszenia spółka MOŻE wykonywać tylko czynności dozwolone (Art. 25 PP). Wszystko inne jest BLOCK.
- **Przesłanki:**
  - `input.partnership.status == "SUSPENDED"`
  - `input.invoice.category_code` NIE w katalogu dozwolonym
- **Oczekiwany rezultat:**
  - Dozwolone: SPRZEDAŻ ŚT (P946), PRZYJMOWANIE NALEŻNOŚCI (P947), SPŁATY LEASINGU, OPŁATY CZYNSZU/MEDIA, KONTYNUACJA UMÓW
  - Niedozwolone: NOWA SPRZEDAŻ, NOWE ZAKUPY, NOWE UMOWY
  - `_routing: "BLOCK_AND_ALERT"` dla niedozwolonych
- **Podstawa prawna:** Art. 25 Prawa przedsiębiorców
- **Przypadki brzegowe:** Leasing w trakcie zawieszenia — raty można opłacać (kontynuacja), ale wykup nie (nowa czynność). Faktura za media (prąd, internet) — można księgować jako koszt utrzymania.
- **Priorytet:** 945

### P946: `sc_suspension_fixed_asset_sale_sc` ★
- **Cel biznesowy:** W trakcie zawieszenia spółka może sprzedawać środki trwałe. VAT należny normalnie (spółka nadal jest podatnikiem VAT).
- **Przesłanki:**
  - `input.partnership.status == "SUSPENDED"`
  - `input.invoice.category_code == "FIXED_ASSET_SALE"`
  - `input.invoice.direction == "SALE"`
- **Oczekiwany rezultat:**
  - `allowed_in_suspension: true`
  - `vat_rate: normalna stawka VAT`
  - `pit_implications: "REVENUE_RECOGNIZED"` — przychód podatkowy
- **Podstawa prawna:** Art. 25 ust. 1 pkt 2 PP, Art. 14 PIT
- **Przypadki brzegowe:** Przychód dzielony proporcjonalnie między wspólników mimo zawieszenia. ŚT sprzedany poniżej wartości rynkowej → ryzyko GAAR.
- **Priorytet:** 946

### P948: `sc_resumption_procedure_sc` ★
- **Cel biznesowy:** Wznowienie działalności spółki — procedura, skutki PIT/VAT, termin zgłoszenia.
- **Przesłanki:**
  - `input.partnership.status` zmienia się z `SUSPENDED` na `ACTIVE`
- **Oczekiwany rezultat:**
  - `ceidg_update_required: true`
  - `resumption_effective_date: <data>`
  - `vat_declarations_resume: true`
  - `pit_advances_resume: next_month`
  - `zus_resumption: true` — składki od daty wznowienia
- **Podstawa prawna:** Art. 24 Prawa przedsiębiorców
- **Przypadki brzegowe:** Wznowienie w trakcie miesiąca → obowiązki od tego dnia. Max 24 miesiące zawieszenia — po tym okresie automatyczne odwieszenie.
- **Priorytet:** 948

### P949: `sc_resumption_vat_pit_effects_sc` ★
- **Cel biznesowy:** Skutki podatkowe wznowienia — remanent początkowy, pierwsza deklaracja.
- **Przesłanki:**
  - Wznowienie po zawieszeniu
- **Oczekiwany rezultat:**
  - `opening_inventory_required: true` — jeśli zawieszenie > 30 dni
  - `first_vat_declaration_period: <miesiąc wznowienia>`
  - `pit_advance_first_period: <miesiąc po wznowieniu>`
- **Podstawa prawna:** Art. 24 ust. 3 PIT (remanent), Art. 99 VAT
- **Przypadki brzegowe:** Krótkie zawieszenie (≤30 dni) → brak obowiązku remanentu.
- **Priorytet:** 949

---

## Obszar 4: Sukcesja — szczegóły

> **Istniejące reguły:** P930-P932
> **Dodawane reguły:** P933-P938

### P933: `sc_succession_nip_estate_sc` ★
- **Cel biznesowy:** Po śmierci wspólnika, NIP spółki otrzymuje dopisek "w spadku" jeśli ustanowiono zarządcę sukcesyjnego.
- **Przesłanki:**
  - `p.deceased == true`
  - `p.has_succession_manager == true`
- **Oczekiwany rezultat:**
  - `partnership_nip_suffix: "S"` — oznaczenie "w spadku"
  - `partnership_status: "IN_SUCCESSION"`
  - Czas trwania: standardowo 2 lata, wyjątkowo do 5 lat
- **Podstawa prawna:** Art. 21-23 ustawy o zarządzie sukcesyjnym
- **Przypadki brzegowe:** NIP spółki się zmienia — nowy NIP ze statusem "S". Zarządca działa w imieniu zmarłego wspólnika.
- **Priorytet:** 933

### P934: `sc_succession_max_duration_sc` ★
- **Cel biznesowy:** Zarząd sukcesyjny trwa maksymalnie 2 lata od śmierci wspólnika (lub 5 lat w szczególnych przypadkach). Po tym okresie — likwidacja.
- **Przesłanki:**
  - `partnership.status == "IN_SUCCESSION"`
  - `months_since_death > input.thresholds.sc.bounds.succession_max_months` (24)
  - I NIE zachodzi wyjątek przedłużający (postanowienie sądu)
- **Oczekiwany rezultat:**
  - `succession_expired: true`
  - `_warning: "Zarząd sukcesyjny wygasł — konieczna likwidacja spółki"`
  - `dissolution_triggered: true` (→ P920)
- **Podstawa prawna:** Art. 27-28 ustawy o zarządzie sukcesyjnym
- **Przypadki brzegowe:** Przedłużenie przez sąd do 5 lat — wymaga postanowienia. Brak zarządcy w ciągu 2 miesięcy od śmierci → zarząd wygasa.
- **Priorytet:** 934

### P935: `sc_succession_heir_split_sc` ★
- **Cel biznesowy:** Jeśli brak zarządcy sukcesyjnego, udział zmarłego wspólnika przechodzi na spadkobierców — każdy dziedziczy proporcjonalnie.
- **Przesłanki:**
  - `p.deceased == true`
  - `p.has_succession_manager == false`
  - `count(p.heirs) > 0`
- **Oczekiwany rezultat:**
  - Dla każdego spadkobiercy: `heir_share = p.share_percent * heir_inheritance_fraction / 100`
  - `total_heir_shares: sum(heir_inheritance_fraction) = 100%`
  - Spadkobiercy wchodzą w prawa i obowiązki zmarłego wspólnika
- **Podstawa prawna:** Art. 872 KC, Art. 922 KC
- **Przypadki brzegowe:** Spadkobiercy muszą zarejestrować się w CEIDG jako przedsiębiorcy (jeśli chcą kontynuować). Spadkobierca bez CEIDG → NIE może być wspólnikiem.
- **Priorytet:** 935

### P936: `sc_succession_joint_liability_heirs_sc` ★
- **Cel biznesowy:** Spadkobiercy odpowiadają za zobowiązania zmarłego wspólnika — solidarnie z pozostałymi wspólnikami, ale tylko do wartości spadku.
- **Przesłanki:**
  - `p.deceased == true`
  - Zobowiązania spółki sprzed śmierci
- **Oczekiwany rezultat:**
  - `heir_liability: "LIMITED_TO_ESTATE_VALUE"`
  - `joint_liability_type: "HEIRS_AND_PARTNERS"`
  - `_warning: "Spadkobiercy odpowiadają solidarnie do wartości spadku"`
- **Podstawa prawna:** Art. 1031 KC (odpowiedzialność spadkobierców), Art. 864 KC
- **Przypadki brzegowe:** Przyjęcie spadku z dobrodziejstwem inwentarza → limit odpowiedzialności do wartości aktywów. Przyjęcie wprost → pełna osobista odpowiedzialność.
- **Priorytet:** 936

### P937: `sc_succession_vat_exemption_estate_sc` ★
- **Cel biznesowy:** Przedsiębiorstwo w spadku może kontynuować zwolnienie podmiotowe VAT zmarłego wspólnika (jeśli spółka była zwolniona).
- **Przesłanki:**
  - `input.partnership.vat_status == "SUBJECT_EXEMPT"` przed śmiercią
  - Zarządca sukcesyjny kontynuuje
  - Limit 200k NIE został przekroczony
- **Oczekiwany rezultat:**
  - `vat_exemption_continued: true`
  - `vat_exemption_entity: "ESTATE"`
- **Podstawa prawna:** Art. 113 ust. 12 ustawy o VAT
- **Przypadki brzegowe:** Przekroczenie limitu 200k po śmierci → obowiązek rejestracji VAT w ciągu 7 dni.
- **Priorytet:** 937

---

## Obszar 5: Zmiana formy opodatkowania mid-year

> **Istniejące reguły:** P538 (podstawowa)
> **Dodawane reguły:** P539-P539c

### P539: `partner_form_change_obligatory_scale_sc` ★
- **Cel biznesowy:** Utrata prawa do ryczałtu/karty powoduje PRZYMUSOWE przejście na skalę podatkową od miesiąca następującego po utracie.
- **Przesłanki:**
  - `p.tax_form` w `["LUMP_SUM", "TAX_CARD"]`
  - Utrata prawa: przekroczenie limitu 2M EUR spółki, rozpoczęcie działalności wykluczonej (apteki, części samochodowe)
- **Oczekiwany rezultat:**
  - `p.form_change_type: "OBLIGATORY"`
  - `p.new_tax_form: "PIT_SCALE"`
  - `p.form_change_effective: <1. dnia miesiąca po utracie>`
  - `p.two_returns_required: true` — ryczałt (PIT-28) za okres przed + skala (PIT-36) za okres po
- **Podstawa prawna:** Art. 8 ust. 2, Art. 22 ust. 1 ustawy o ryczałcie
- **Przypadki brzegowe:** Utrata w grudniu → skala od stycznia (ale PIT-28 jeszcze za cały rok). Utrata prawa z powodu przekroczenia limitu spółki → WSZYSCY ryczałtowcy w SC tracą prawo.
- **Priorytet:** 539

### P539a: `partner_form_change_declaration_deadline_sc` ★
- **Cel biznesowy:** Oświadczenie o zmianie formy na nowy rok — do 20. dnia miesiąca po zmianie (lub do 20 stycznia dla zmiany od nowego roku).
- **Przesłanki:**
  - `p.tax_form_changing == true`
  - Zmiana DOBROWOLNA (nie obligatoryjna)
- **Oczekiwany rezultat:**
  - `declaration_deadline: "20. dnia miesiąca następującego po zmianie"`
  - `declaration_type: "CEIDG-1"`
  - Jeśli przekroczony → `form_change_invalid: true`, stara forma obowiązuje
- **Podstawa prawna:** Art. 9a ust. 4-5 PIT, Art. 30 CEIDG
- **Przypadki brzegowe:** Zmiana od nowego roku → oświadczenie do 20 stycznia (lub do 20 lutego jeśli pierwszy przychód w lutym).
- **Priorytet:** 539a

### P539b: `partner_form_change_advance_recalculation_sc` ★
- **Cel biznesowy:** Przy zmianie formy ryczałt→skala w trakcie roku — konieczność przeliczenia zaliczek.
- **Przesłanki:**
  - `p.form_change_type == "OBLIGATORY"`
  - `p.old_tax_form == "LUMP_SUM"` → `p.new_tax_form == "PIT_SCALE"`
- **Oczekiwany rezultat:**
  - `p.advance_recalculation_required: true`
  - `p.first_scale_advance_due: <20. dnia miesiąca po miesiącu zmiany>`
  - `p.lump_sum_final_settlement: PIT-28 do 28 lutego`
- **Podstawa prawna:** Art. 44 ust. 1, Art. 21 ust. 1 ustawy o ryczałcie
- **Przypadki brzegowe:** Dochód za okres przed zmianą → tylko ryczałt. Dochód po zmianie → skala (z uwzględnieniem narastania od miesiąca zmiany, nie od stycznia).
- **Priorytet:** 539b

### P539c: `partner_form_change_lump_sum_loss_sc` ★
- **Cel biznesowy:** Utrata prawa do ryczałtu z powodu rozpoczęcia działalności wykluczonej (np. apteki, sprzedaż części samochodowych).
- **Przesłanki:**
  - `p.tax_form == "LUMP_SUM"`
  - `input.invoice.category_code` w `["PHARMACY", "CAR_PARTS"]` — działalność wykluczona
- **Oczekiwany rezultat:**
  - `p.lump_sum_lost: true`
  - `p.form_change_effective: <data pierwszej transakcji wykluczonej>`
  - `_warning: "Utrata prawa do ryczałtu — działalność wykluczona"`
- **Podstawa prawna:** Art. 8 ustawy o ryczałcie (załącznik nr 2 — działalności wykluczone)
- **Przypadki brzegowe:** Sprzedaż incydentalna (np. jednorazowa) → może nie powodować utraty jeśli <1% przychodu.
- **Priorytet:** 539c


---

## Obszar 6: Zmiana składu wspólników — szczegóły

> **Istniejące reguły:** P905, P907
> **Dodawane reguły:** P908-P909b

### P908: `sc_partner_exit_in_kind_settlement_sc` ★
- **Cel biznesowy:** Występującemu wspólnikowi można wypłacić udział w naturze (np. przekazać samochód spółki). Konsekwencje VAT — spółka wystawia fakturę VAT!
- **Przesłanki:**
  - `p.exit_date` != null
  - `p.settlement_type == "IN_KIND"` — wypłata rzeczowa
- **Oczekiwany rezultat:**
  - `vat_invoice_required: true` — spółka wystawia fakturę VAT na wspólnika (odpłatna dostawa towarów)
  - `vat_rate: normalna stawka VAT` (23%/8%/5%)
  - `pit_revenue_for_partner: true` — dla otrzymującego wspólnika to przychód z działalności
  - `pit_kup_for_partnership: market_value` — dla spółki to KUP (rozchód ŚT)
- **Podstawa prawna:** Art. 871 KC, Art. 7 VAT, Art. 14 PIT
- **Przypadki brzegowe:** Wartość rynkowa ≠ wartość księgowa → różnica jest przychodem/kosztem podatkowym. Spółka ze zwolnieniem VAT → dostawa też zwolniona.
- **Priorytet:** 908

### P909: `sc_partner_asymmetric_profit_split_sc` ★
- **Cel biznesowy:** Umowa spółki może przewidywać inny podział zysku niż proporcja udziałów (Art. 867 § 2 KC). Ale dla celów PIT — decyduje proporcja z umowy!
- **Przesłanki:**
  - `input.partnership.profit_split_ratio != input.partnership.share_split_ratio`
  - `input.partnership.asymmetric_split_agreed == true`
- **Oczekiwany rezultat:**
  - `pit_split_ratio: input.partnership.profit_split_ratio` (TA proporcja dla PIT)
  - `vat_split_ratio: input.partnership.share_split_ratio` (TA proporcja dla innych celów)
  - `_warning: "Asymetryczny podział zysku — weryfikacja zgodności z Art. 8 PIT"`
- **Podstawa prawna:** Art. 867 § 2 KC, Art. 8 PIT
- **Zależności:** Przed P500 — zmienia podstawę podziału.
- **Przypadki brzegowe:** Zwolnienie wspólnika od udziału w stratach (Art. 867 § 3 KC) — ważne tylko wobec wspólników, NIE wobec wierzycieli. Dla PIT: strata dzielona proporcjonalnie do udziału w zysku.
- **Priorytet:** 909

### P909a: `sc_partner_rights_transfer_sc` ★
- **Cel biznesowy:** Zbycie ogółu praw i obowiązków wspólnika na rzecz innej osoby (art. 10 KC) — wymaga zgody wszystkich wspólników.
- **Przesłanki:**
  - `p.transferring_rights == true`
  - `input.partnership.all_partners_consented == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Zbycie praw wymaga zgody wszystkich wspólników"`
- **Podstawa prawna:** Art. 10 KC w zw. z Art. 860 KC
- **Przypadki brzegowe:** Zbycie części praw (nie całości) → zmiana udziałów, nie wystąpienie. Zbywca odpowiada solidarnie za długi sprzed zbycia wraz z nabywcą.
- **Priorytet:** 909a

### P909b: `sc_partner_contributions_valuation_sc` ★
- **Cel biznesowy:** Wkłady wspólników do spółki — wycena dla celów podatkowych. Wkład pieniężny (neutralny PIT) vs rzeczowy (opodatkowany u wnoszącego).
- **Przesłanki:**
  - `input.invoice.category_code == "PARTNER_CONTRIBUTION"`
  - `input.invoice.contribution_type == "IN_KIND"`
- **Oczekiwany rezultat:**
  - `contribution_value: market_value`
  - `pit_taxable_for_contributing_partner: market_value` — przychód z działalności dla wnoszącego
  - `partnership_asset_value_increase: market_value`
- **Podstawa prawna:** Art. 861 KC, Art. 14 PIT
- **Przypadki brzegowe:** Wkład pieniężny → neutralny podatkowo. Wkład nieruchomości → PCC 0.5% od wartości rynkowej (jeśli spółka nie jest podatnikiem VAT).
- **Priorytet:** 909b

---

## Obszar 7: Eksport i import usług VAT

> **Istniejące reguły:** P40-P49 (podstawowe WNT, WDT)
> **Dodawane reguły:** P41a-P47b — rozbudowa `sc.crossborder`

### P41a: `eu_import_services_reverse_charge_sc` ★
- **Cel biznesowy:** Import usług z UE (B2B) — spółka rozlicza VAT jako nabywca (reverse charge). Miejsce świadczenia: Polska (Art. 28b VAT).
- **Przesłanki:**
  - `input.vendor.country in input.thresholds.sc.eu_countries`
  - `input.vendor.is_business == true` — B2B
  - `input.invoice.direction == "PURCHASE"` — spółka kupuje usługę
  - `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"` — na fakturze 0%
  - `procedure: "IMPORT_SERVICES_REVERSE_CHARGE"`
  - `vat_to_self_assess: true` — spółka sama nalicza VAT należny i odlicza naliczony
  - `gtu_code: "GTU_12"`
- **Podstawa prawna:** Art. 28b VAT (miejsce świadczenia), Art. 17 ust. 1 pkt 4 VAT
- **Przypadki brzegowe:** Import usług od konsumenta (B2C) → NIE reverse charge (VAT rozlicza sprzedawca). Import usług spoza UE → analogicznie (P44a).
- **Priorytet:** 41a

### P43b: `export_services_eu_b2b_sc` ★
- **Cel biznesowy:** Eksport usług do UE (B2B) — miejsce świadczenia: kraj nabywcy. Polska faktura z NP (nie podlega).
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.vendor.country in input.thresholds.sc.eu_countries`
  - `input.vendor.is_business == true`
  - `input.invoice.service_type != "REAL_ESTATE"` — wyjątek: nieruchomości
- **Oczekiwany rezultat:**
  - `vat_rate: "NP"` — nie podlega opodatkowaniu w Polsce
  - `vat_ue_summary_required: true` — informacja podsumowująca VAT-UE
  - `_note: "VAT rozlicza nabywca w swoim kraju"`
- **Podstawa prawna:** Art. 28b VAT, Art. 100 VAT (VAT-UE)
- **Przypadki brzegowe:** Usługi związane z nieruchomościami → miejsce świadczenia = położenie nieruchomości. Eksport do konsumenta (B2C) → VAT polski (z wyjątkiem MOSS/OSS).
- **Priorytet:** 43b

### P44a: `non_eu_import_services_sc` ★
- **Cel biznesowy:** Import usług spoza UE — spółka rozlicza VAT jako nabywca (reverse charge). Analogia do P41a ale dla krajów spoza UE.
- **Przesłanki:**
  - `input.vendor.country NOT IN input.thresholds.sc.eu_countries`
  - `input.vendor.is_business == true`
  - `input.invoice.direction == "PURCHASE"`
  - `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"`
  - `procedure: "IMPORT_SERVICES_NON_EU"`
  - `vat_to_self_assess: true`
  - `gtu_code: "GTU_13"`
- **Podstawa prawna:** Art. 17 ust. 1 pkt 4, Art. 28b VAT
- **Przypadki brzegowe:** Usługi elektroniczne od dostawcy spoza UE → reverse charge. Import usług transportowych → specjalne zasady.
- **Priorytet:** 44a

### P46: `vat_oss_procedure_sc` ★
- **Cel biznesowy:** Procedura OSS (One Stop Shop) dla sprzedaży B2C do UE — spółka może zarejestrować się w OSS i rozliczać VAT wszystkich krajów UE w jednej deklaracji.
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.vendor.is_business == false` — B2C
  - `input.vendor.country in input.thresholds.sc.eu_countries`
  - `input.partnership.is_oss_registered == true`
- **Oczekiwany rezultat:**
  - `vat_rate: <stawka kraju konsumenta>`
  - `procedure: "OSS"`
  - `vat_settlement: "VIA_OSS_PORTAL"` — spółka deklaruje przez PL OSS
- **Podstawa prawna:** Art. 138a-138j VAT, Rozporządzenie Rady UE 2017/2454
- **Przypadki brzegowe:** Limit 10 000 EUR rocznie dla usług elektronicznych B2C → poniżej limitu VAT polski. Bez OSS → obowiązek rejestracji w każdym kraju UE.
- **Priorytet:** 46

### P47: `vat_eu_mandatory_registration_sc` ★
- **Cel biznesowy:** Spółka dokonująca WNT/WDT ma OBOWIĄZEK rejestracji VAT-UE przed pierwszą transakcją.
- **Przesłanki:**
  - `input.partnership.is_vat_payer == true`
  - `input.partnership.is_vat_eu_registered == false`
  - Transakcja WNT lub WDT
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `vat_eu_registration_mandatory: true`
  - `_warning: "Spółka musi być zarejestrowana VAT-UE przed transakcją WNT/WDT"`
- **Podstawa prawna:** Art. 97 ustawy o VAT
- **Przypadki brzegowe:** Rejestracja VAT-UE z urzędu przez US po pierwszym WNT. Spółka zwolniona z VAT (<200k) NIE może się zarejestrować do VAT-UE.
- **Priorytet:** 47

### P47a: `vat_r_ue_registration_deadline_sc` ★
- **Cel biznesowy:** Termin rejestracji VAT-UE: PRZED pierwszą transakcją WNT/WDT. Nie po, nie w trakcie.
- **Przesłanki:**
  - `input.partnership.vat_ue_registration_date > input.invoice.transaction_date`
  - Transakcja z kontrahentem UE
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `vat_ue_late_registration: true`
  - `_warning: "Rejestracja VAT-UE musi nastąpić PRZED transakcją — faktura nie może być rozliczona jako WNT/WDT"`
- **Podstawa prawna:** Art. 97 ust. 3 VAT
- **Priorytet:** 47a

### P47b: `export_goods_non_eu_documentation_sc` ★
- **Cel biznesowy:** Eksport towarów poza UE — stawka 0% VAT tylko przy posiadaniu dokumentów celnych (IE-599, komunikat SAD).
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.vendor.country NOT IN input.thresholds.sc.eu_countries`
  - `input.invoice.category_code == "GOODS"`
- **Oczekiwany rezultat:**
  - `vat_rate: "0.00"` (jeśli `has_ie599 == true`)
  - `vat_rate: "0.23"` (jeśli brak IE-599 — stawka krajowa)
  - `vat_export_deadline: 10_miesięcy` — jeśli dokumenty w ciągu 10 mies., korekta do 0%
- **Podstawa prawna:** Art. 41 ust. 6-9 VAT
- **Przypadki brzegowe:** Eksport potwierdzony po terminie (10 mies.) → stawka krajowa definitywnie.
- **Priorytet:** 47b

---

## Obszar 8: Korekty deklaracji i faktur — szczegóły

> **Istniejące reguły:** P1100 (podstawowa)
> **Dodawane reguły:** P1102-P1108

### P1102: `sc_correction_current_vs_retroactive_sc` ★
- **Cel biznesowy:** Rozróżnienie korekty bieżącej (w bieżącym JPK) od wstecznej (korekta deklaracji za poprzedni okres).
- **Przesłanki:**
  - `input.invoice.is_correction == true`
  - `input.invoice.correction_period` vs `input.invoice.original_period`
- **Oczekiwany rezultat:**
  - Jeśli przyczyna istniała w oryginalnym okresie: `correction_type: "RETROACTIVE"`, korekta JPK za ten okres
  - Jeśli przyczyna powstała później (np. zły dług): `correction_type: "CURRENT"`, korekta w bieżącym JPK
  - `pit_korekta_type: analogicznie dla PIT wspólników`
- **Podstawa prawna:** Art. 81 Ordynacji podatkowej, Art. 29a VAT
- **Przypadki brzegowe:** Korekta wsteczna wymaga uzasadnienia (czynny żal). Korekta bieżąca nie wymaga.
- **Priorytet:** 1102

### P1104: `sc_correction_note_sc` ★
- **Cel biznesowy:** Nota korygująca wystawiana przez nabywcę (spółkę) — dotyczy tylko błędów formalnych (NIP, adres, nazwa), NIE kwotowych.
- **Przesłanki:**
  - `input.invoice.correction_type == "NOTA_KORYGUJACA"`
  - `input.invoice.correction_scope` w `["NIP", "ADDRESS", "NAME"]`
  - `input.invoice.correction_amount == 0` — brak zmiany kwoty!
- **Oczekiwany rezultat:**
  - `correction_valid: true`
  - `approval_required: "ACCEPTANCE_BY_ISSUER"` — wymaga akceptacji wystawcy
- **Podstawa prawna:** Art. 106k VAT
- **Przypadki brzegowe:** Brak akceptacji w ciągu 14 dni → nota uznana za przyjętą. Nota bez akceptacji → nieskuteczna.
- **Priorytet:** 1104

### P1106: `sc_correction_red_black_storno_sc` ★
- **Cel biznesowy:** Korekta w pełnej księgowości (UoR) — storno czerwone vs czarne. Decyduje okres, którego dotyczy.
- **Przesłanki:**
  - `input.partnership.accounting_method == "FULL"`
  - `input.invoice.is_correction == true`
- **Oczekiwany rezultat:**
  - Bieżący okres + nie dotyczy zamkniętego roku: `storno_type: "BLACK"` (zapis odwrotny)
  - Dotyczy zamkniętego roku: `storno_type: "RED"` (zmniejszenie wartości)
  - `_info: "Storno czarne — nie może być stosowane do zamkniętych ksiąg"`
- **Podstawa prawna:** Art. 25 UoR
- **Przypadki brzegowe:** Storno czarne dla błędów z lat ubiegłych → BLOCK (P804).
- **Priorytet:** 1106

### P1108: `sc_correction_vat_annual_proportion_sc` ★
- **Cel biznesowy:** Roczna korekta proporcji VAT (Art. 91 VAT) — porównanie proporcji wstępnej z rzeczywistą po zakończeniu roku.
- **Przesłanki:**
  - `input.partnership.vat_pre_pro_rata_applicable == true`
  - Koniec roku podatkowego
- **Oczekiwany rezultat:**
  - `vat_actual_proportion: actual_taxable_turnover / total_turnover`
  - `vat_proportion_difference: abs(actual - estimated_proportion)`
  - Jeśli różnica > 2pp: `vat_annual_correction_required: true`
  - Korekta w JPK za styczeń lub I kwartał następnego roku
- **Podstawa prawna:** Art. 91 ustawy o VAT
- **Przypadki brzegowe:** Różnica < 2pp → brak obowiązku korekty. Proporcja ostateczna < 2% → zwrot całego odliczonego VAT.
- **Priorytet:** 1108

---

## Obszar 9: Przedawnienia i odpowiedzialność — szczegóły

> **Istniejące reguły:** P1150-P1160, P1164, P1168
> **Dodawane reguły:** P1162-P1172

### P1162: `sc_prescription_interruption_sc` ★
- **Cel biznesowy:** Przerwanie biegu przedawnienia zobowiązań SC — każda czynność egzekucyjna wobec jednego wspólnika przerywa bieg dla wszystkich (solidarność!).
- **Przesłanki:**
  - Zobowiązanie spółki
  - Czynność egzekucyjna / uznanie długu / wszczęcie kontroli
- **Oczekiwany rezultat:**
  - `prescription_interrupted: true`
  - `prescription_reset_date: <data czynności>`
  - `prescription_new_deadline: reset_date + 5_lat` (podatki) lub `reset_date + 3_lata` (ZUS)
  - `affected_partners: [wszyscy wspólnicy]` — SOLIDARNIE!
- **Podstawa prawna:** Art. 70 § 1, Art. 70c Ordynacji podatkowej, Art. 123 KC
- **Przypadki brzegowe:** Czynność wobec jednego wspólnika → przerywa przedawnienie dla wszystkich. Zawieszenie przedawnienia (P1166) vs przerwanie (P1162).
- **Priorytet:** 1162

### P1166: `sc_prescription_suspension_sc` ★
- **Cel biznesowy:** Zawieszenie biegu przedawnienia — np. wszczęcie postępowania karnego skarbowego, odwołanie do sądu.
- **Przesłanki:**
  - Wszczęto postępowanie KKS / sądowe / administracyjne dotyczące zobowiązania spółki
- **Oczekiwany rezultat:**
  - `prescription_suspended: true`
  - `prescription_suspended_from: <data wszczęcia>`
  - `prescription_resumes: <data zakończenia postępowania>`
- **Podstawa prawna:** Art. 70 § 6, Art. 70a Ordynacji podatkowej
- **Przypadki brzegowe:** Zawieszenie vs przerwanie: zawieszenie NIE resetuje terminu, tylko go pauzuje.
- **Priorytet:** 1166

### P1170: `sc_regress_between_partners_sc` ★★
- **Cel biznesowy:** Wspólnik, który spłacił dług spółki w całości, ma roszczenie regresowe do pozostałych wspólników proporcjonalnie do ich udziałów.
- **Przesłanki:**
  - Wspólnik `p` spłacił zobowiązanie spółki w 100%
  - `p.paid_amount > p.share_percent * total_debt / 100`
- **Oczekiwany rezultat:**
  - `p.regress_claim: p.paid_amount - (p.share_percent * total_debt / 100)`
  - `other_partners_liable: true`
  - Każdy wspólnik odpowiada regresowo proporcjonalnie do udziału
  - `regress_deadline: 3_lata od spłaty`
- **Podstawa prawna:** Art. 376 KC (regres między współdłużnikami solidarnymi)
- **Przypadki brzegowe:** Jeden wspólnik niewypłacalny → pozostali pokrywają jego część (solidarność!). Regres do byłego wspólnika — tylko za długi sprzed jego wystąpienia.
- **Priorytet:** 1170

### P1172: `sc_regress_tax_recognition_sc` ★
- **Cel biznesowy:** Otrzymana spłata regresowa od wspólnika — czy stanowi przychód podatkowy? NIE, to zwrot wydatku.
- **Przesłanki:**
  - `p.received_regress_payment > 0`
  - Wspólnik wcześniej spłacił dług spółki
- **Oczekiwany rezultat:**
  - `p.regress_income: "NEUTRAL"` — NIE przychód podatkowy
  - `p.paid_amount_adjusted: original_payment - regress_received`
  - Dla płacącego regres: `regress_expense: "NOT_KUP"` — NKUP (to spłata długu, nie koszt)
- **Podstawa prawna:** Art. 14 PIT (przychód), Art. 23 PIT (NKUP), Art. 376 KC
- **Przypadki brzegowe:** Jeśli regres nieściągalny → wspólnik, który spłacił, może zaliczyć nieściągalną część jako KUP? TAK, ale z limitami (Art. 23 ust. 1 pkt 17 PIT).
- **Priorytet:** 1172

---

## Obszar 10: Reprezentacja i pełnomocnictwa ★ NOWY PAKIET

> **Status:** CAŁKOWICIE NOWY PAKIET — `sc.partnership.representation`
> **Istniejące reguły:** BRAK — to największa luka
> **Nowe reguły:** P910-P914 — 5 reguł

### P910: `sc_representation_scope_sc` ★★
- **Cel biznesowy:** Każdy wspólnik ma prawo reprezentować spółkę w sprawach zwykłego zarządu, chyba że umowa stanowi inaczej (Art. 866 KC). Dla transakcji przekraczających zwykły zarząd — wymagana zgoda wszystkich.
- **Przesłanki:**
  - `input.invoice.amount_net > input.thresholds.sc.limits.ordinary_management_limit` (domyślnie: 50 000 PLN)
  - LUB `input.invoice.category_code` w `["REAL_ESTATE_PURCHASE", "LOAN_AGREEMENT", "GUARANTEE"]`
  - `input.invoice.approved_by_all_partners == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Transakcja przekracza zwykły zarząd — wymagana zgoda wszystkich wspólników"`
  - `representation_valid: false`
- **Podstawa prawna:** Art. 866 § 1-2 KC
- **Zależności:** Przed compliance (P20+) — transakcja bez zgody jest nieważna wobec spółki.
- **Przypadki brzegowe:** Umowa spółki może MODYFIKOWAĆ zakres reprezentacji (Art. 866 § 3 KC). Jeden wspólnik wyłączony od reprezentacji → pozostali reprezentują.
- **Priorytet:** 910

### P911: `sc_representation_ordinary_management_sc` ★
- **Cel biznesowy:** Katalog spraw zwykłego zarządu — transakcje codzienne, rutynowe, nieprzekraczające progu.
- **Przesłanki:**
  - Transakcja w katalogu zwykłego zarządu
  - `input.invoice.amount_net <= input.thresholds.sc.limits.ordinary_management_limit`
  - `input.invoice.approved_by_acting_partner == true`
- **Oczekiwany rezultat:**
  - `representation_valid: true`
  - `acting_partner: <wspólnik działający>`
  - `_info: "Transakcja w granicach zwykłego zarządu"`
- **Podstawa prawna:** Art. 866 § 1 KC
- **Priorytet:** 911

### P912: `sc_representation_extraordinary_requires_consent_sc` ★
- **Cel biznesowy:** Transakcje nadzwyczajne (sprzedaż nieruchomości spółki, zaciągnięcie kredytu >1M PLN, poręczenie) wymagają UCHWAŁY wszystkich wspólników.
- **Przesłanki:**
  - `input.invoice.category_code` w `["REAL_ESTATE_SALE", "LOAN_OVER_1M", "GUARANTEE", "MORTGAGE"]`
  - `input.invoice.has_partner_resolution == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Czynność nadzwyczajna — wymagana uchwała wszystkich wspólników"`
- **Podstawa prawna:** Art. 866 § 2 KC
- **Priorytet:** 912

### P913: `sc_tax_proxy_upl1_sc` ★
- **Cel biznesowy:** Pełnomocnictwo ogólne UPL-1 do podpisywania deklaracji podatkowych spółki. Wymagane do wysyłki e-deklaracji VAT za spółkę.
- **Przesłanki:**
  - `input.partnership.has_upl1_registered == false`
  - `input.invoice.involves_tax_declaration == true`
  - Osoba podpisująca NIE jest wspólnikiem
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Brak pełnomocnictwa UPL-1 — deklaracja nie może być podpisana przez osobę trzecią"`
  - `upl1_required: true`
- **Podstawa prawna:** Art. 80a-80c Ordynacji podatkowej
- **Przypadki brzegowe:** Wspólnik reprezentujący spółkę NIE potrzebuje UPL-1. Biuro rachunkowe → UPL-1 OBOWIĄZKOWE.
- **Priorytet:** 913

### P914: `sc_tax_proxy_pps1_sc` ★
- **Cel biznesowy:** Pełnomocnictwo szczególne PPS-1 — do konkretnej sprawy podatkowej (kontrola, postępowanie).
- **Przesłanki:**
  - `input.partnership.has_pps1_for_case == false`
  - Trwa postępowanie podatkowe / kontrola
  - Pełnomocnik NIE jest wspólnikiem
- **Oczekiwany rezultat:**
  - `pps1_required: true`
  - `_warning: "Brak PPS-1 — pełnomocnik nie może działać w postępowaniu"`
- **Podstawa prawna:** Art. 138d-138g Ordynacji podatkowej
- **Przypadki brzegowe:** PPS-1 ważne do odwołania lub zakończenia sprawy. Wspólnik NIE potrzebuje PPS-1.
- **Priorytet:** 914


---

## Obszar 11: Interakcje forma PIT a składki

> **Istniejące reguły:** P720-P730 (podstawowe macierze)
> **Dodawane reguły:** P732-P738

### P732: `partner_health_annual_settlement_sc` ★
- **Cel biznesowy:** Roczne rozliczenie składki zdrowotnej — porównanie zaliczek z rzeczywistym dochodem. Dotyczy skali i liniowego.
- **Przesłanki:**
  - `p.tax_form` w `["PIT_SCALE", "LINEAR"]`
  - Koniec roku podatkowego
- **Oczekiwany rezultat:**
  - `p.health_annual_reconciliation: true`
  - `p.health_annual_base: roczny_dochod_z_SC`
  - `p.health_annual_due: annual_base * health_rate`
  - `p.health_balance: annual_due - sum_of_monthly_payments`
  - Jeśli balance > 0: `p.health_underpayment: balance` — dopłata do ZUS
  - Jeśli balance < 0: `p.health_overpayment: abs(balance)` — zwrot z ZUS
- **Podstawa prawna:** Art. 81 ust. 2-2d ustawy o świadczeniach opieki zdrowotnej
- **Zależności:** Po P500 (podział), P720-P730 (stawki). Wynik wpływa na P540 (zaliczki) — korekta za grudzień.
- **Przypadki brzegowe:** Minimalna składka roczna: 9% × 12 × minimalne wynagrodzenie (dla skali). Nadpłata zwracana na wniosek do 1 czerwca.
- **Priorytet:** 732

### P734: `partner_health_inventory_effect_sc` ★
- **Cel biznesowy:** Remanent na koniec roku wpływa na dochód wspólnika → wpływa na podstawę składki zdrowotnej.
- **Przesłanki:**
  - `input.partnership.inventory_change != 0`
  - `input.partnership.inventory_date` = koniec roku
  - `p.tax_form` w `["PIT_SCALE", "LINEAR"]`
- **Oczekiwany rezultat:**
  - `p.health_base_adjusted: base + (inventory_change * p.share_percent / 100)`
  - `p.health_inventory_effect: inventory_change * p.share_percent / 100 * health_rate`
  - `_info: "Remanent wpływa na podstawę składki zdrowotnej"`
- **Podstawa prawna:** Art. 81 ust. 2 ustawy o świadczeniach opieki zdrowotnej, Art. 24 PIT
- **Przypadki brzegowe:** Remanent dodatni → zwiększa dochód → większa składka. Remanent ujemny → zmniejsza dochód → mniejsza składka (ale nie mniej niż minimalna).
- **Priorytet:** 734

### P736: `partner_health_pre2022_asset_sale_exclusion_sc` ★
- **Cel biznesowy:** Wyłączenie z podstawy składki zdrowotnej przychodów ze sprzedaży środków trwałych nabytych przed 2022 rokiem i w pełni zamortyzowanych.
- **Przesłanki:**
  - `input.invoice.category_code == "FIXED_ASSET_SALE"`
  - `input.invoice.asset_acquisition_date < "2022-01-01"`
  - `input.invoice.asset_fully_depreciated == true`
- **Oczekiwany rezultat:**
  - `p.health_base_excluded: sale_price` — przychód NIE wchodzi do podstawy
  - `p.health_base_adjustment_reason: "PRE_2022_ASSET"`
- **Podstawa prawna:** Art. 81 ust. 2ca, Art. 36 ust. 5 ustawy o świadczeniach (Polski Ład — przepisy przejściowe)
- **Przypadki brzegowe:** ŚT nabyty w 2022 lub później → przychód ze sprzedaży wchodzi do podstawy zdrowotnej.
- **Priorytet:** 736

### P738: `partner_health_form_change_effect_sc` ★
- **Cel biznesowy:** Zmiana formy opodatkowania w trakcie roku → zmiana stawki zdrowotnej. Dwa okresy z różnymi stawkami.
- **Przesłanki:**
  - `p.form_change_mid_year == true`
  - Zmiana dotyczy formy wpływającej na stawkę zdrowotną (skala→liniowy lub odwrotnie)
- **Oczekiwany rezultat:**
  - `p.health_period_1: stawka_przed_zmianą`, `p.health_period_2: stawka_po_zmianie`
  - `p.health_annual: okres_1_dohod * stawka_1 + okres_2_dochod * stawka_2`
  - `p.health_two_brackets: true` — sygnalizacja dla księgowego
- **Podstawa prawna:** Art. 79-81 ustawy o świadczeniach opieki zdrowotnej
- **Przypadki brzegowe:** Zmiana skala→liniowy: zdrowotna 9%→4.9%, ale traci się kwotę wolną w PIT. Zmiana ryczałt→skala: progi ryczałtowe→9% od dochodu.
- **Priorytet:** 738

---

## Obszar 12: Rozwiązanie i likwidacja — szczegóły

> **Istniejące reguły:** P920, P922
> **Dodawane reguły:** P924-P927, P929

### P924: `sc_liquidation_inventory_pit_sc` ★★
- **Cel biznesowy:** Remanent likwidacyjny PIT — na dzień rozwiązania spółki sporządza się spis z natury. Różnica remanentowa jest przychodem/stratą podatkową.
- **Przesłanki:**
  - `input.partnership.status == "DISSOLVING"`
  - Spółka prowadziła PKPiR
  - `input.partnership.dissolution_date` != null
- **Oczekiwany rezultat:**
  - `final_inventory_value: wartość_rynkowa_składników`
  - `inventory_surplus: final_inventory - opening_inventory`
  - Jeśli surplus > 0: `pit_revenue_per_partner: surplus * share/100`
  - Jeśli surplus < 0: `pit_loss_per_partner: abs(surplus) * share/100`
  - `final_inventory_deadline: "do dnia rozwiązania"`
- **Podstawa prawna:** Art. 24 ust. 3 PIT, Art. 14 PIT
- **Przypadki brzegowe:** Remanent wyceniany wg cen zakupu (nie rynkowych). Spółka na pełnej księgowości → inny mechanizm (sprawozdanie likwidacyjne).
- **Priorytet:** 924

### P925: `sc_liquidation_inventory_vat_sc` ★★
- **Cel biznesowy:** VAT od remanentu likwidacyjnego — spółka musi opłacić VAT od towarów, od których odliczono VAT przy zakupie, a które pozostały na dzień likwidacji.
- **Przesłanki:**
  - `input.partnership.status == "DISSOLVED"`
  - `input.partnership.was_vat_payer == true`
  - `input.partnership.liquidation_inventory_value > 0`
- **Oczekiwany rezultat:**
  - `vat_liquidation_due: liquidation_inventory_value * applicable_vat_rate`
  - `vat_liquidation_declaration: VAT-Z`
  - `vat_liquidation_deadline: "do dnia rozwiązania spółki"`
  - `_warning: "VAT od remanentu likwidacyjnego — odpowiedzialność solidarna wspólników"`
- **Podstawa prawna:** Art. 14 ustawy o VAT
- **Przypadki brzegowe:** Towary przekazane wspólnikom → opodatkowane jak dostawa. Spółka zwolniona z VAT → brak VAT likwidacyjnego. Spółka na pełnej księgowości → VAT tylko od składników z odliczonym VAT.
- **Priorytet:** 925

### P926: `sc_liquidation_tax_on_remnants_sc` ★
- **Cel biznesowy:** Podział majątku likwidacyjnego między wspólników — skutki PIT. Otrzymany majątek to przychód wspólnika.
- **Przesłanki:**
  - `input.partnership.status == "DISSOLVED"`
  - Wspólnik otrzymuje majątek likwidacyjny (pieniądze lub rzecz)
- **Oczekiwany rezultat:**
  - `p.liquidation_receipt: wartość_otrzymanego_majątku`
  - `p.liquidation_tax_base: receipt - (share_percent * total_contributions)`
  - Jeśli >0: `pit_due: tax_base * pit_rate` (dochód z likwidacji)
  - `pit_annual_return: PIT-36 / PIT-36L z wykazanym dochodem z likwidacji`
- **Podstawa prawna:** Art. 14 ust. 2 pkt 17, Art. 24 ust. 3 PIT, Art. 875 KC
- **Przypadki brzegowe:** Zwrot wkładów → neutralny podatkowo. Nadwyżka ponad wkłady → dochód opodatkowany. Majątek rzeczowy → wartość rynkowa.
- **Priorytet:** 926

### P927: `sc_liquidation_archive_5y_sc` ★
- **Cel biznesowy:** Obowiązek przechowywania dokumentacji po likwidacji — 5 lat od końca roku kalendarzowego.
- **Przesłanki:**
  - `input.partnership.status == "DISSOLVED"`
- **Oczekiwany rezultat:**
  - `archive_required: true`
  - `archive_duration: "5_lat_od_końca_roku"`
  - `archive_scope: [JPK_V7, PIT_wspólników, PKPiR/księgi, faktury, umowy, dokumenty ZUS]`
  - `archive_responsibility: "WSPÓLNICY SOLIDARNIE"`
- **Podstawa prawna:** Art. 74 UoR, Art. 70 § 1 Ordynacji podatkowej, Art. 864 KC
- **Przypadki brzegowe:** Kontrola skarbowa może przedłużyć obowiązek. Zniszczenie dokumentów przed terminem → kara karno-skarbowa.
- **Priorytet:** 927

### P929: `sc_liquidation_vat_z_declaration_sc` ★
- **Cel biznesowy:** Zgłoszenie VAT-Z — zgłoszenie zaprzestania działalności (likwidacja VAT). Termin: przed dniem likwidacji.
- **Przesłanki:**
  - `input.partnership.status == "DISSOLVING"`
  - `input.partnership.was_vat_payer == true`
- **Oczekiwany rezultat:**
  - `vat_z_required: true`
  - `vat_z_deadline: "przed dniem likwidacji"`
  - `vat_z_effect: "wyrejestrowanie NIP spółki z VAT"`
  - `_warning: "Niezłożenie VAT-Z → NIP spółki pozostanie aktywny w VAT"`
- **Podstawa prawna:** Art. 96 ust. 6-7 ustawy o VAT
- **Przypadki brzegowe:** Po VAT-Z nie można wystawiać faktur VAT. Ostatnia deklaracja JPK_V7 musi być złożona przed VAT-Z.
- **Priorytet:** 929

---

## Obszar 13: Spółka jako pracodawca — szczegóły

> **Istniejące reguły:** P1200 (podstawowa), P1208 (PPK)
> **Dodawane reguły:** P1202-P1223 — rozbudowa `sc.employer`

### P1202: `sc_employer_rca_dra_sc` ★
- **Cel biznesowy:** Spółka jako płatnik składek ZUS — obowiązek comiesięcznego składania deklaracji RCA i DRA za pracowników.
- **Przesłanki:**
  - `input.partnership.employee_count > 0`
  - `input.partnership.is_employer == true`
- **Oczekiwany rezultat:**
  - `zus_rca_required: true` — raport RCA za każdego pracownika (do 15. dnia miesiąca)
  - `zus_dra_required: true` — deklaracja rozliczeniowa DRA (do 15. dnia miesiąca)
  - `zus_contribution_split: employer_share + employee_share`
  - `nip: input.partnership.nip` — NIP spółki jako płatnika!
- **Podstawa prawna:** Art. 17, 18, 22, 36 ustawy o SUS
- **Przypadki brzegowe:** Umowa zlecenia z pracownikiem własnym → składki jak od umowy o pracę. Zleceniobiorca zewnętrzny → inne zasady (zgłoszenie ZUS ZUA).
- **Priorytet:** 1202

### P1204: `sc_employer_pit4r_sc` ★
- **Cel biznesowy:** PIT-4R — roczna deklaracja spółki jako płatnika o pobranych zaliczkach PIT od wynagrodzeń pracowników. Termin: do 31 stycznia.
- **Przesłanki:**
  - `input.partnership.employee_count > 0`
  - `input.partnership.tax_year_ended == true`
- **Oczekiwany rezultat:**
  - `pit4r_required: true`
  - `pit4r_deadline: "31 stycznia"`
  - `pit4r_content: total_advances_paid_for_all_employees`
  - `nip: input.partnership.nip`
- **Podstawa prawna:** Art. 38 PIT
- **Przypadki brzegowe:** PIT-4R to deklaracja roczna — NIE mylić z PIT-11 (informacja dla pracownika).
- **Priorytet:** 1204

### P1206: `sc_employer_pit11_sc` ★
- **Cel biznesowy:** PIT-11 — informacja dla pracownika o dochodach i pobranych zaliczkach. Termin: do 31 stycznia.
- **Przesłanki:**
  - `input.partnership.employee_count > 0`
  - `input.partnership.tax_year_ended == true`
- **Oczekiwany rezultat:**
  - `pit11_required: true` — dla każdego pracownika
  - `pit11_deadline: "31 stycznia"`
  - `pit11_content: indywidualne dane per pracownik`
  - `pit11_delivery: "pracownik + US przez e-deklaracje"`
- **Podstawa prawna:** Art. 39 ust. 1 PIT
- **Przypadki brzegowe:** Pracownik, który złoży PIT-12 → PIT-11 zbiorczy przez pracodawcę.
- **Priorytet:** 1206

### P1210: `sc_ppk_250_employees_sc` ★
- **Cel biznesowy:** Obowiązek wdrożenia PPK dla spółek zatrudniających powyżej 250 osób (inne terminy dla mniejszych).
- **Przesłanki:**
  - `input.partnership.employee_count >= 250`
  - `input.partnership.ppk_implemented == false`
- **Oczekiwany rezultat:**
  - `ppk_mandatory: true`
  - `ppk_implementation_deadline: "natychmiast"`
  - `ppk_contributions: employer_1.5pct + employee_2pct + state_0.3pct`
  - `_routing: "BLOCK_AND_ALERT"` dla spółek bez PPK
- **Podstawa prawna:** Art. 26-27, Art. 32 ustawy o PPK
- **Przypadki brzegowe:** Poniżej 250 pracowników → wdrożenie stopniowe (terminy zależne od wielkości). Pracownicy mogą zrezygnować z PPK (deklaracja).
- **Priorytet:** 1210

### P1212: `sc_employer_social_fund_sc` ★
- **Cel biznesowy:** Zakładowy Fundusz Świadczeń Socjalnych — obowiązek dla spółek >50 pracowników.
- **Przesłanki:**
  - `input.partnership.employee_count >= 50`
  - `input.partnership.zfss_created == false`
- **Oczekiwany rezultat:**
  - `zfss_required: true`
  - `zfss_contribution: base_amount * employee_count`
  - `_warning: "ZFŚS obowiązkowy — odpis podstawowy + ewentualne zwiększenia"`
- **Podstawa prawna:** Ustawa o ZFŚS
- **Przypadki brzegowe:** Możliwość rezygnacji z ZFŚS przez regulamin wynagradzania (związek zawodowy). Poniżej 50 pracowników → dobrowolne.
- **Priorytet:** 1212

### P1214: `sc_employer_partner_business_trip_sc` ★
- **Cel biznesowy:** Wspólnik w delegacji — czy spółka może rozliczać delegacje wspólnika? Tak, ale z ograniczeniami (praca własna → NKUP).
- **Przesłanki:**
  - `input.invoice.category_code == "BUSINESS_TRIP"`
  - `input.invoice.beneficiary_is_partner == true`
  - `input.invoice.trip_related_to_business == true`
- **Oczekiwany rezultat:**
  - `trip_kup: "FULL"` (diety, hotele, bilety — standardowe limity jak dla pracowników)
  - `_warning: "Delegacja wspólnika — wydatki muszą być ściśle związane z działalnością spółki"`
- **Podstawa prawna:** Art. 22 ust. 1 PIT, Art. 23 ust. 1 pkt 10 PIT (praca własna jako NKUP NIE dotyczy zwrotu kosztów delegacji)
- **Przypadki brzegowe:** Diety dla wspólnika — tylko jeśli delegacja poza miejscowość siedziby spółki. Brak limitu czasowego (jak dla pracowników).
- **Priorytet:** 1214

### P1216: `sc_employer_health_safety_sc` ★
- **Cel biznesowy:** Badania lekarskie i BHP pracowników — obowiązek spółki jako pracodawcy.
- **Przesłanki:**
  - `input.invoice.category_code` w `["OCCUPATIONAL_MEDICINE", "BHP_TRAINING"]`
  - `input.partnership.employee_count > 0`
- **Oczekiwany rezultat:**
  - `kup_qualification: "FULL"` — zawsze KUP
  - `vat_deductible: true`
- **Podstawa prawna:** Art. 229 KP, Art. 22 ust. 1 PIT
- **Priorytet:** 1216

---

## Obszar 14: Limit pełnej księgowości — szczegóły

> **Istniejące reguły:** P800-P804 (podstawowe)
> **Dodawane reguły:** P806-P812

### P806: `sc_full_accounting_fx_differences_sc` ★
- **Cel biznesowy:** Różnice kursowe w pełnej księgowości — metoda bilansowa (UoR) vs podatkowa (PIT). Na koniec roku rozliczenie różnic.
- **Przesłanki:**
  - `input.partnership.accounting_method == "FULL"`
  - `input.invoice.currency != "PLN"`
  - `input.invoice.is_paid == false` (saldo na koniec roku)
- **Oczekiwany rezultat:**
  - `fx_balance_sheet_valuation: kurs_NBP_z_dnia_bilansowego`
  - `fx_difference: balance_sheet_value - book_value`
  - Jeśli >0: `fx_revenue: taxable` (przychód podatkowy)
  - Jeśli <0: `fx_cost: tax_deductible` (KUP)
- **Podstawa prawna:** Art. 30 UoR, Art. 14 PIT (przychód), Art. 22 PIT (KUP)
- **Przypadki brzegowe:** Metoda podatkowa (kurs z dnia zarachowania vs zapłaty) a bilansowa (kurs na dzień bilansowy) — różnice przejściowe.
- **Priorytet:** 806

### P808: `sc_full_accounting_eur_conversion_sc` ★★
- **Cel biznesowy:** Przeliczenie progu 2M EUR na PLN. Kurs: pierwszy dzień roboczy października roku poprzedzającego (NBP). NIE kurs z dnia bilansowego!
- **Przesłanki:**
  - Wyznaczenie progu na kolejny rok
  - `current_month == "OCTOBER"`
- **Oczekiwany rezultat:**
  - `eur_pln_rate: NBP_rate_from_first_business_day_of_october`
  - `full_accounting_threshold_pln: 2000000 * eur_pln_rate`
  - `threshold_applies_from: "January 1 of next year"`
- **Podstawa prawna:** Art. 2 ust. 1 pkt 1 UoR, Art. 3 ust. 1c UoR
- **Przypadki brzegowe:** Kurs z 1 października (lub pierwszego dnia roboczego po). Publikowany w Dzienniku Urzędowym NBP.
- **Priorytet:** 808

### P810: `sc_full_accounting_partner_split_effect_sc` ★
- **Cel biznesowy:** Wpływ przejścia na pełną księgowość na podział dochodu między wspólników. PKPiR → księgi rachunkowe = zmiana metody ustalania dochodu.
- **Przesłanki:**
  - `input.partnership.accounting_method` zmienia się z `PKPIR` na `FULL`
- **Oczekiwany rezultat:**
  - `transition_inventory_required: true` — remanent na dzień przejścia
  - `transition_date: "1 stycznia roku obrotowego"`
  - `pit_transition_effect: inventory_difference per partner`
  - `_warning: "Zmiana metody księgowej — remanent początkowy dla ksiąg rachunkowych"`
- **Podstawa prawna:** Art. 24 ust. 3 PIT, Art. 10 UoR
- **Przypadki brzegowe:** Różnica remanentowa może być przychodem (jeśli remanent końcowy > początkowy).
- **Priorytet:** 810

### P812: `sc_full_accounting_fs_approval_sc` ★
- **Cel biznesowy:** Roczne sprawozdanie finansowe spółki musi być zatwierdzone przez wszystkich wspólników — uchwała.
- **Przesłanki:**
  - `input.partnership.accounting_method == "FULL"`
  - Koniec roku obrotowego
  - `input.partnership.fs_approved == false`
- **Oczekiwany rezultat:**
  - `fs_approval_required: true`
  - `fs_approval_deadline: "6 miesięcy od dnia bilansowego"`
  - `fs_approval_body: "WSZYSCY WSPÓLNICY"`
  - `_warning: "Sprawozdanie finansowe niezatwierdzone — blokada księgowania w nowym roku"`
- **Podstawa prawna:** Art. 53 UoR, Art. 860 KC
- **Przypadki brzegowe:** Brak zatwierdzenia w terminie → naruszenie UoR, KUP za nowy rok NIE mogą być księgowane (P804).
- **Priorytet:** 812

---

## Aktualizacja hierarchii — zintegrowane priorytety

Poniżej lista integracyjna pokazująca, gdzie NOWE reguły wpinają się w istniejący łańcuch `SC_DEFINITIVE_REGO_PLAN.md`:

```
BLOK 0: RISK (bez zmian — nowe reguły nie dotykają tego bloku)
    [BEZ ZMIAN]

BLOK 3: CROSSBORDER — ROZBUDOWANY ★
    P41a    eu_import_services_reverse_charge     Import usług z UE (nowa)
    P43b    export_services_eu_b2b                 Eksport usług do UE (nowa)
    P44a    non_eu_import_services                 Import usług spoza UE (nowa)
    P46     vat_oss_procedure                      OSS dla B2C (nowa)
    P47     vat_eu_mandatory_registration          VAT-UE obowiązkowy (nowa)
    P47a    vat_r_ue_registration_deadline         Termin VAT-UE (nowa)
    P47b    export_goods_non_eu_documentation      Eksport spoza UE (nowa)

BLOK 4: CYKL ŻYCIA — ROZBUDOWANY ★
    P909    sc_partner_asymmetric_profit_split      Asymetryczny podział zysku (nowa)
    P909a   sc_partner_rights_transfer             Zbycie praw wspólnika (nowa)
    P910    sc_representation_scope                 ★ NOWY PAKIET — reprezentacja
    P911    sc_representation_ordinary_management   Zwykły zarząd
    P912    sc_representation_extraordinary_consent Czynności nadzwyczajne
    P913    sc_tax_proxy_upl1                       UPL-1
    P914    sc_tax_proxy_pps1                       PPS-1

BLOK 5-6: VAT — BEZ ZMIAN (nowe reguły nie dotykają stawek i odliczeń)

BLOK 7: PIT FUNDAMENT — ROZBUDOWANY ★
    P909    partner_asymmetric_split                Asymetryczny podział (wpływa na P500)

BLOK 8-10: PIT FORMY/KUP/ZALICZKI — ROZBUDOWANY ★
    P539    partner_form_change_obligatory          Utrata ryczałtu → skala
    P539a   partner_form_change_declaration         Termin oświadczenia
    P539b   partner_form_change_advance_recalc      Przeliczenie zaliczek
    P539c   partner_form_change_lump_sum_loss       Utrata ryczałtu — wykluczenia

BLOK 11: ZWOLNIENIA — ROZBUDOWANY ★
    [wszystkie istniejące P580-P588 + nowe ulgi poniżej]

BLOK 12: ULGI — ROZBUDOWANY ★
    P606    partner_relief_prototype                Ulga na prototyp
    P608    partner_relief_robotization             Ulga na robotyzację
    P612    partner_relief_expansion                Ulga na ekspansję
    P618    partner_relief_rehabilitation           Ulga rehabilitacyjna
    P620    partner_relief_ikze                     IKZE
    P622    partner_relief_donation                 Darowizny
    P626    partner_relief_internet                 Ulga internetowa

BLOK 13: ZUS — ROZBUDOWANY ★
    P716    partner_zus_concurrent_retirement       Zbieg emerytura+SC
    P718    partner_zus_30x_limit                   30-krotność
    P719    partner_zus_proportional_days           Proporcjonalne dni
    P732    partner_health_annual_settlement        Roczne rozliczenie zdrowotnej
    P734    partner_health_inventory_effect         Remanent a zdrowotna
    P736    partner_health_pre2022_asset            Wyłączenie przed 2022
    P738    partner_health_form_change_effect       Zmiana formy a zdrowotna
    P740    partner_health_annual_reconciliation    Roczne porównanie
    P742    partner_health_fixed_asset_sale         Wyłączenie ŚT
    P744    partner_unregistered_activity_block     Strażnik: dział. nieewidencj.

BLOK 14: KSIĘGOWOŚĆ — ROZBUDOWANY ★
    P806    sc_full_accounting_fx_differences       Różnice kursowe (nowa)
    P808    sc_full_accounting_eur_conversion       Przeliczenie EUR/PLN (nowa)
    P810    sc_full_accounting_partner_split        Podział przy zmianie PKPiR→Full (nowa)
    P812    sc_full_accounting_fs_approval          Zatwierdzenie SF (nowa)

BLOK 15: ODPOWIEDZIALNOŚĆ — ROZBUDOWANY ★
    P1162   sc_prescription_interruption            Przerwanie przedawnienia
    P1166   sc_prescription_suspension              Zawieszenie przedawnienia
    P1170   sc_regress_between_partners             Regres między wspólnikami
    P1172   sc_regress_tax_recognition              Podatkowe skutki regresu

BLOK 16: RESZTA — ROZBUDOWANY ★
    P1102   sc_correction_current_vs_retroactive    Korekty bieżące vs wsteczne
    P1104   sc_correction_note                      Nota korygująca
    P1106   sc_correction_red_black_storno          Storno czarne/czerwone
    P1108   sc_correction_vat_annual_proportion     Roczna korekta proporcji VAT
    P1202   sc_employer_rca_dra                     RCA/DRA
    P1204   sc_employer_pit4r                       PIT-4R
    P1206   sc_employer_pit11                       PIT-11
    P1210   sc_ppk_250_employees                    PPK >250 pracowników
    P1212   sc_employer_social_fund                 ZFŚS
    P1214   sc_employer_partner_business_trip       Delegacja wspólnika
    P1216   sc_employer_health_safety               BHP
    P924    sc_liquidation_inventory_pit             Remanent likwidacyjny PIT
    P925    sc_liquidation_inventory_vat             Remanent likwidacyjny VAT
    P926    sc_liquidation_tax_on_remnants           Podatek od majątku likwidacyjnego
    P927    sc_liquidation_archive_5y                Archiwizacja 5 lat
    P929    sc_liquidation_vat_z_declaration         VAT-Z

    P944    sc_suspension_employee_block            Blokada zawieszenia z pracownikami
    P945    sc_suspension_allowed_actions            Dozwolone czynności w zawieszeniu
    P946    sc_suspension_fixed_asset_sale           Sprzedaż ŚT w zawieszeniu
    P948    sc_resumption_procedure                  Wznowienie — procedura
    P949    sc_resumption_vat_pit_effects            Skutki wznowienia

    P933    sc_succession_nip_estate                 NIP "w spadku"
    P934    sc_succession_max_duration               Max 2 lata
    P935    sc_succession_heir_split                 Podział na spadkobierców
    P936    sc_succession_joint_liability_heirs      Odpowiedzialność spadkobierców
    P937    sc_succession_vat_exemption_estate       VAT zwolnienie w spadku
```

---

## Cross-Reference: Nowe reguły → Podstawa prawna

| Reguła | Podstawa prawna |
|--------|-----------------|
| P606 — ulga prototyp | Art. 26eb PIT |
| P608 — ulga robotyzacja | Art. 26gb PIT |
| P612 — ulga ekspansja | Art. 26ec PIT |
| P618 — ulga rehabilitacyjna | Art. 26 ust. 1 pkt 6, ust. 7a-7g PIT |
| P620 — IKZE | Art. 26 ust. 1 pkt 2b PIT |
| P622 — darowizny | Art. 26 ust. 1 pkt 9, ust. 5 PIT |
| P626 — ulga internetowa | Art. 26 ust. 1 pkt 6a PIT |
| P716 — zbieg emerytura+SC | Art. 9 ust. 4-5 SUS |
| P718 — 30-krotność | Art. 19 ust. 1 SUS |
| P719 — ZUS proporcjonalne dni | Art. 18 ust. 8-9 SUS |
| P740 — roczne rozliczenie zdrowotnej | Art. 81 ust. 2 u. o świadczeniach |
| P742 — wyłączenie sprzedaży ŚT | Art. 81 ust. 2ca u. o świadczeniach |
| P744 — strażnik dz. nieewidencjonowana | Art. 5 PP, Art. 14 PP |
| P910-P914 — reprezentacja | Art. 866 KC, Art. 80a-80c, 138d-138g Ordynacji |
| P41a — import usług UE | Art. 28b VAT, Art. 17 ust. 1 pkt 4 VAT |
| P46 — OSS | Art. 138a-138j VAT |
| P47 — VAT-UE obowiązkowy | Art. 97 VAT |
| P539-P539c — zmiana formy mid-year | Art. 9a ust. 4-5 PIT, Art. 8 ust. 2 u. o ryczałcie |
| P1102-P1108 — korekty | Art. 81 OP, Art. 106k VAT, Art. 91 VAT |
| P1162-P1172 — przedawnienia i regres | Art. 70 OP, Art. 376 KC, Art. 1031 KC |
| P924-P929 — likwidacja | Art. 14 VAT, Art. 24 PIT, Art. 875 KC, Art. 96 VAT |
| P1202-P1216 — pracodawca | Art. 17-40 SUS, Art. 38-39 PIT, Art. 229 KP, Art. 26-32 PPK |
| P806-P812 — pełna księgowość | Art. 30 UoR, Art. 2 UoR, Art. 53 UoR |
| P944-P949 — zawieszenie/wznowienie | Art. 22-25 PP |
| P933-P937 — sukcesja | Art. 872 KC, ustawa o zarządzie sukcesyjnym, Art. 113 VAT |

---

> **Koniec dokumentu rozszerzenia.** Ten plik uzupełnia `SC_DEFINITIVE_REGO_PLAN.md` o 14 obszarów ekspansji.
> **Łącznie nowych reguł:** ~85 szczegółowo opisanych ze wszystkimi 7 elementami (cel, przesłanki, rezultat, podstawa prawna, zależności, przypadki brzegowe, priorytet).
> **Łączny stan SC po połączeniu:** ~550 (oryginalne) + ~85 (nowe) = **~635 reguł ENTERPRISE**.
