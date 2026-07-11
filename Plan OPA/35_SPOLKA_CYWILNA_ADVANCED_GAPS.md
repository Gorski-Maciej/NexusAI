# 🔍 NexusAI Spółka Cywilna — ZAAWANSOWANE LUKI: 15 Pomijanych Obszarów ENTERPRISE v1.0

> **Status:** AUDYT LUK — uzupełnia `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` i `Plan OPA/SC_EXPANSION_14_AREAS.md`
> **Data:** 2026-07-11
> **Autor:** Zespół NexusAI
> **Plik:** `Plan OPA/35_SPOLKA_CYWILNA_ADVANCED_GAPS.md`
> **Cel:** Wypełnienie 15 zaawansowanych, często pomijanych obszarów krytycznych dla bezpieczeństwa, zgodności i zaufania
> **Dokumenty nadrzędne:** `Plan OPA/SC_DEFINITIVE_REGO_PLAN.md` (architektura, ~550 reguł), `Plan OPA/SC_EXPANSION_14_AREAS.md` (rozszerzenia, ~85 reguł)
> **Nowe reguły:** ~80 | **Nowe pakiety:** 3 (`sc.enforcement`, `sc.aml`, `sc.gdpr`) | **Rozbudowane pakiety:** 8

---

## 📑 Spis Treści

- [Metodologia — dlaczego te obszary są pomijane](#metodologia)
- [Obszar 1: Odpowiedzialność solidarna i regres — luki](#obszar-1-odpowiedzialność-solidarna-i-regres--luki)
- [Obszar 2: Transakcje między wspólnikiem a spółką](#obszar-2-transakcje-między-wspólnikiem-a-spółką)
- [Obszar 3: Wspólnik jako konsument](#obszar-3-wspólnik-jako-konsument)
- [Obszar 4: Małżonek wspólnika](#obszar-4-małżonek-wspólnika)
- [Obszar 5: Spółka w trakcie kontroli skarbowej](#obszar-5-spółka-w-trakcie-kontroli-skarbowej)
- [Obszar 6: Zajęcie udziału przez komornika](#obszar-6-zajęcie-udziału-przez-komornika)
- [Obszar 7: Podatek od nieruchomości](#obszar-7-podatek-od-nieruchomości)
- [Obszar 8: Akcyza](#obszar-8-akcyza)
- [Obszar 9: AML — przeciwdziałanie praniu pieniędzy](#obszar-9-aml--przeciwdziałanie-praniu-pieniędzy)
- [Obszar 10: RODO — ochrona danych osobowych](#obszar-10-rodo--ochrona-danych-osobowych)
- [Obszar 11: Cudzoziemiec jako wspólnik](#obszar-11-cudzoziemiec-jako-wspólnik)
- [Obszar 12: Fundusze unijne i dotacje](#obszar-12-fundusze-unijne-i-dotacje)
- [Obszar 13: Leasing operacyjny i finansowy](#obszar-13-leasing-operacyjny-i-finansowy)
- [Obszar 14: Kryptowaluty](#obszar-14-kryptowaluty)
- [Obszar 15: Upadłość konsumencka wspólnika](#obszar-15-upadłość-konsumencka-wspólnika)
- [Diagram integracji — gdzie nowe reguły wpinają się w łańcuch](#diagram-integracji)
- [Cross-Reference: Nowe reguły → Podstawa prawna](#cross-reference-nowe-reguły--podstawa-prawna)

---

## Metodologia

Poniższe 15 obszarów zostało zidentyfikowanych jako **systematycznie pomijane** w standardowych systemach reguł podatkowych, mimo że są **krytyczne dla bezpieczeństwa prawnego** spółki cywilnej. Każda reguła zawiera:
- Nazwę (EN), cel biznesowy, przesłanki szczegółowe, oczekiwany rezultat, podstawę prawną, zależności i przypadki brzegowe.
- Oznaczenia: ★ = krytyczna luka, ★★ = fundamentalna dla bezpieczeństwa, [TODO] = potrzebne dodatkowe źródło.

---

## Obszar 1: Odpowiedzialność solidarna i regres — luki

> **Istniejące:** P1150-P1174 (solidarna), P1170-P1172 (regres)
> **Brakuje:** egzekucji z majątku konkretnego wspólnika, kolejności egzekucji, subsydiarnej odpowiedzialności, regresu od byłych wspólników

### P1174: `sc_enforcement_order_sc` ★★
- **Cel biznesowy:** Kolejność egzekucji zobowiązań spółki — najpierw z majątku spółki, dopiero potem z majątków osobistych wspólników (subsydiarność).
- **Przesłanki:**
  - Zobowiązanie spółki wymagalne
  - `input.partnership.assets_value < debt_amount` — majątek spółki niewystarczający
- **Oczekiwany rezultat:**
  - `enforcement_stage_1: "PARTNERSHIP_ASSETS"` — najpierw majątek spółki
  - `enforcement_stage_2: "PARTNER_PERSONAL_ASSETS"` — subsydiarnie majątki wspólników
  - `partner_liability_proportion: debt_remainder * p.share_percent / 100`
  - `_warning: "Egzekucja z majątku osobistego — solidarna odpowiedzialność"`
- **Podstawa prawna:** Art. 864 KC, Art. 778¹ KPC, Art. 26-27 ustawy o komornikach sądowych
- **Zależności:** Po P1150 (solidarna), przed P1170 (regres).
- **Przypadki brzegowe:** Jeśli jeden wspólnik spłaci całość → regres do pozostałych (P1170). Wierzyciel może wybrać, którego wspólnika pozywa (solidarność bierna).
- **Priorytet:** 1174

### P1175: `sc_enforcement_ex_partner_sc` ★
- **Cel biznesowy:** Były wspólnik odpowiada za zobowiązania powstałe PRZED jego wystąpieniem — nawet po latach. Bez limitu czasowego (inaczej niż spółki kapitałowe!).
- **Przesłanki:**
  - `p.exit_date != null`
  - `debt_incurred_date < p.exit_date`
- **Oczekiwany rezultat:**
  - `ex_partner_liable: true` — nadal odpowiada!
  - `ex_partner_liability_scope: "DEBTS_ BEFORE_EXIT"`
  - `_warning: "Były wspólnik odpowiada za zobowiązania sprzed wystąpienia — bezterminowo"`
- **Podstawa prawna:** Art. 869 KC, Art. 864 KC
- **Przypadki brzegowe:** Nowy wspólnik NIE odpowiada za długi sprzed przystąpienia (chyba że przejmie je umową). Były wspólnik a regres — może żądać od obecnych wspólników zwrotu.
- **Priorytet:** 1175

### P1176: `sc_partner_asset_protection_limit_sc` ★
- **Cel biznesowy:** Ograniczenia egzekucji z majątku osobistego — kwota wolna od zajęcia, ochrona wynagrodzenia minimalnego, ochrona mieszkania (jeśli nie jest zastawione).
- **Przesłanki:**
  - Egzekucja z majątku osobistego wspólnika
  - `p.personal_income < input.thresholds.sc.bounds.garnishment_protection_limit`
- **Oczekiwany rezultat:**
  - `protected_income: min(p.personal_income, garnishment_protection_limit)`
  - `garnishable_amount: p.personal_income - protected_income`
  - `_info: "Kwota wolna od zajęcia — ochrona minimum socjalnego"`
- **Podstawa prawna:** Art. 87-87¹ Kodeksu pracy (stosowane odpowiednio), Art. 829-833 KPC
- **Przypadki brzegowe:** Egzekucja z nieruchomości (dom wspólnika) — możliwa, chyba że to jedyne mieszkanie (ochrona z art. 829¹ KPC).
- **Priorytet:** 1176

### P1178: `sc_regress_insolvent_partner_sc` ★★
- **Cel biznesowy:** Jeśli jeden wspólnik jest niewypłacalny (jego część regresu nieściągalna), pozostali wspólnicy pokrywają jego część proporcjonalnie do swoich udziałów.
- **Przesłanki:**
  - Wspólnik X spłacił dług, ma regres do Y i Z
  - `y.is_insolvent == true` — Y nie może zapłacić
- **Oczekiwany rezultat:**
  - `y_shortfall: y.regress_share`
  - `z.additional_liability: y_shortfall * (z.share_percent / (100 - x.share_percent - y.share_percent))`
  - `x.additional_liability: y_shortfall - z.additional_liability`
  - `_warning: "Niewypłacalność współdłużnika — pozostali pokrywają jego część"`
- **Podstawa prawna:** Art. 376 KC, Art. 864 KC
- **Przypadki brzegowe:** Niewypłacalność formalna (upadłość) vs faktyczna (brak majątku). Regres limitowany do wartości spadku (przy dziedziczeniu).
- **Priorytet:** 1178

---

## Obszar 2: Transakcje między wspólnikiem a spółką

> **Istniejące:** P561 (KUP ZUS wspólnika), P1214 (delegacja wspólnika)
> **Brakuje:** kompleksowych reguł dla świadczenia usług przez wspólnika na rzecz własnej spółki

### P562: `sc_partner_self_service_vat_sc` ★★
- **Cel biznesowy:** Gdy wspólnik świadczy usługi na rzecz własnej spółki (np. wspólnik-programista pisze kod dla spółki) — czy podlega VAT? TAK — wspólnik i spółka to odrębni podatnicy VAT!
- **Przesłanki:**
  - `input.invoice.category_code == "PARTNER_SERVICE"`
  - `input.invoice.provider_nip == p.nip` — wspólnik świadczy usługę spółce
  - `input.invoice.recipient_nip == input.partnership.nip`
- **Oczekiwany rezultat:**
  - `vat_invoice_required: true` — wspólnik wystawia fakturę VAT na spółkę
  - `vat_rate: normalna stawka` (23%/8%/5%)
  - `spółka_odlicza_VAT: true` — jeśli spółka jest czynnym podatnikiem VAT
  - `_warning: "Wspólnik i spółka to odrębni podatnicy VAT — transakcja podlega VAT"`
- **Podstawa prawna:** Art. 15 VAT, Art. 5 VAT (odrębność podatkowa), interpretacja KIS 0112-KDIL1-1.4012.465.2022.2
- **Zależności:** Przed P50 (VAT stawki), po P900 (walidacja spółki).
- **Przypadki brzegowe:** Wspólnik na ryczałcie VAT (zwolnienie <200k) → faktura bez VAT. Wspólnik nieprowadzący JDG poza SC → umowa cywilnoprawna, nie faktura.
- **Priorytet:** 562

### P563: `sc_partner_self_service_pit_kup_sc` ★
- **Cel biznesowy:** Czy wynagrodzenie wypłacone wspólnikowi za usługi świadczone na rzecz własnej spółki jest KUP dla spółki? TAK — jeśli usługi są związane z przychodem spółki. Dla wspólnika: przychód z pozarolniczej działalności.
- **Przesłanki:**
  - `input.invoice.category_code == "PARTNER_SERVICE"`
  - `input.invoice.beneficiary_is_partner == true`
  - Usługa związana z działalnością spółki (nie prywatna)
- **Oczekiwany rezultat:**
  - `kup_for_partnership: "FULL"` — KUP dla spółki
  - `pit_revenue_for_partner: invoice_net` — przychód wspólnika (z JDG lub z innych źródeł)
  - `pit_split_effect: "NONE"` — ta transakcja NIE jest dzielona proporcjonalnie (to przychód tylko tego wspólnika)
  - `_warning: "Przychód wspólnika spoza proporcji — odrębny przychód JDG"`
- **Podstawa prawna:** Art. 22 PIT (KUP), Art. 10 ust. 1 pkt 3 PIT (pozarolnicza działalność), Art. 14 PIT
- **Przypadki brzegowe:** Wynagrodzenie wspólnika > wartość rynkowa → nadwyżka NKUP (Art. 23m PIT — ceny transferowe!). Wspólnik bez JDG → umowa zlecenie (przychód z działalności wykonywanej osobiście).
- **Priorytet:** 563

### P564: `sc_partner_self_service_transfer_pricing_sc` ★
- **Cel biznesowy:** Transakcje między wspólnikiem a spółką podlegają regulacjom cen transferowych (Art. 23m-23zf PIT) jeśli przekraczają progi dokumentacyjne.
- **Przesłanki:**
  - `input.partnership.revenue_annual > input.thresholds.sc.bounds.transfer_pricing_revenue_limit` (2 mln EUR)
  - `input.invoice.partner_service_amount_annual > input.thresholds.sc.bounds.transfer_pricing_transaction_limit` (500 000 PLN)
  - `input.invoice.is_arm_s_length == false` LUB `input.invoice.has_transfer_pricing_documentation == false`
- **Oczekiwany rezultat:**
  - `transfer_pricing_documentation_required: true`
  - `_warning: "Transakcja wspólnik-spółka przekracza progi TP — obowiązek dokumentacji cen transferowych"`
  - `_routing: "BLOCK_AND_ALERT"`
- **Podstawa prawna:** Art. 23m-23zf PIT, Rozporządzenie MF w sprawie cen transferowych
- **Przypadki brzegowe:** Transakcje <500k PLN zwolnione z dokumentacji (ale nadal muszą być rynkowe). Mikroprzedsiębiorca → wyższy próg.
- **Priorytet:** 564

### P565: `sc_partner_self_service_profit_shift_sc` ★
- **Cel biznesowy:** Wykrywanie próby unikania opodatkowania przez przepychanie zysków spółki na wspólnika z niższą stawką PIT (np. spółka generuje stratę, wspólnik duży przychód).
- **Przesłanki:**
  - `p.tax_form == "LUMP_SUM"` — wspólnik na ryczałcie (niższa stawka)
  - `p.partner_service_income > 0.50 * input.partnership.total_revenue` — ponad 50% przychodu spółki trafia do wspólnika
  - `input.partnership.net_profit < 0` — spółka wykazuje stratę
- **Oczekiwany rezultat:**
  - `profit_shift_risk: "HIGH"` — ryzyko unikania opodatkowania
  - `_warning: "Potencjalny shifting dochodów do wspólnika na ryczałcie — GAAR risk"`
  - `_flag: "GAAR_SCRUTINY_RECOMMENDED"`
- **Podstawa prawna:** Art. 119a-119f Ordynacji podatkowej (GAAR), Art. 23m PIT (ceny transferowe)
- **Przypadki brzegowe:** Niewielkie wynagrodzenie (<10% przychodu spółki) — niskie ryzyko. Brak JDG u wspólnika → dochód z innych źródeł (20% ryczałt), nie z działalności.
- **Priorytet:** 565

---

## Obszar 3: Wspólnik jako konsument

> **Istniejące:** P563 powyżej (częściowo)
> **Brakuje:** szczegółowych skutków VAT i PIT przy zakupie towarów od własnej spółki

### P566: `sc_partner_as_consumer_vat_sc` ★
- **Cel biznesowy:** Wspólnik kupuje towar od własnej spółki jako osoba prywatna — skutki VAT. Spółka wystawia fakturę (lub paragon) jak każdemu klientowi. Cena musi być rynkowa!
- **Przesłanki:**
  - `input.invoice.direction == "SALE"`
  - `input.invoice.recipient_is_partner == true`
  - `input.invoice.recipient_type == "PRIVATE_PERSON"` (nie firma)
- **Oczekiwany rezultat:**
  - `vat_rate: standard_rate` — spółka nalicza VAT jak od każdej sprzedaży
  - `vat_recorded: true` — ujęte w JPK_V7 spółki
  - `partner_vat_deduction: false` — wspólnik jako konsument NIE odlicza VAT
  - `_warning: "Sprzedaż wspólnikowi-konsumentowi — cena rynkowa obowiązkowa"`
- **Podstawa prawna:** Art. 5 VAT, Art. 29a VAT (podstawa opodatkowania = wartość rynkowa), Art. 23m PIT
- **Zależności:** Przed P50 (VAT stawki), po P20 (compliance).
- **Przypadki brzegowe:** Cena poniżej rynkowej → podstawa VAT = wartość rynkowa (Art. 29a). Rabat jak dla innych klientów → OK, jeśli polityka rabatowa jest spójna.
- **Priorytet:** 566

### P567: `sc_partner_as_consumer_pit_implicit_dividend_sc` ★
- **Cel biznesowy:** Zakup towaru przez wspólnika poniżej ceny rynkowej → różnica traktowana jako ukryty zysk (nieodliczalny dla spółki, opodatkowany u wspólnika).
- **Przesłanki:**
  - `input.invoice.sale_price < input.invoice.market_value`
  - `input.invoice.recipient_is_partner == true`
  - Różnica > 500 PLN rocznie (próg istotności)
- **Oczekiwany rezultat:**
  - `implicit_profit: market_value - sale_price`
  - `pit_for_partner: implicit_profit` — przychód wspólnika
  - `nkup_for_partnership: implicit_profit` — NKUP dla spółki
  - `_warning: "Transfer poniżej wartości rynkowej — ukryty zysk"`
- **Podstawa prawna:** Art. 23m PIT (ceny transferowe), Art. 14 PIT (wartość rynkowa)
- **Przypadki brzegowe:** Rabat do 10% wartości rynkowej → akceptowalny (standardowe odchylenie).
- **Priorytet:** 567

---

## Obszar 4: Małżonek wspólnika

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1179-P1183 — nowy blok w `sc.partnership.liability`

### P1179: `sc_partner_spouse_liability_sc` ★★
- **Cel biznesowy:** Wspólność majątkowa małżeńska a odpowiedzialność za zobowiązania spółki. Wierzyciel może prowadzić egzekucję z majątku wspólnego małżonków, chyba że małżonek wyraził sprzeciw.
- **Przesłanki:**
  - `p.marital_regime == "COMMUNITY"` — wspólność majątkowa
  - `p.spouse_opposed_to_activity == false` — małżonek nie wyraził sprzeciwu
  - Zobowiązanie spółki
- **Oczekiwany rezultat:**
  - `spouse_assets_exposed: true` — majątek wspólny podlega egzekucji
  - `spouse_personal_assets_protected: true` — majątek osobisty małżonka chroniony
  - `_warning: "Małżonek odpowiada majątkiem wspólnym — sprzeciw w CEIDG chroni tylko na przyszłość"`
- **Podstawa prawna:** Art. 31 § 1, Art. 41 Kodeksu rodzinnego i opiekuńczego (KRO), Art. 36¹ KRO, Art. 787¹ KPC
- **Zależności:** Przed P1174 (egzekucja).
- **Przypadki brzegowe:** Rozdzielność majątkowa (intercyza) → pełna ochrona majątku małżonka. Sprzeciw w CEIDG → ochrona od daty wpisu, nie wstecz. Długi sprzed ślubu → tylko z majątku osobistego wspólnika.
- **Priorytet:** 1179

### P1180: `sc_partner_spouse_income_split_sc` ★
- **Cel biznesowy:** Wspólne opodatkowanie małżonków — dochód wspólnika ze SC może być opodatkowany łącznie z dochodem małżonka (PIT-36 wspólny). Ulga: podwójna kwota wolna.
- **Przesłanki:**
  - `p.tax_form == "PIT_SCALE"`
  - `p.marital_status == "MARRIED"`
  - `p.filing_jointly == true`
  - `p.spouse_income > 0` LUB `p.spouse_no_income == true`
- **Oczekiwany rezultat:**
  - `joint_filing_allowed: true`
  - `joint_tax_base: (p.sc_income + p.spouse_income) / 2`
  - `joint_tax_due: tax_on_joint_base * 2`
  - `joint_tax_benefit: solo_tax - joint_tax` (dodatnia = oszczędność)
- **Podstawa prawna:** Art. 6 ust. 2 PIT
- **Przypadki brzegowe:** Wspólnik na liniowym (19%) → NIE może rozliczać się wspólnie. Wspólnik na ryczałcie → NIE może. Ślub w trakcie roku → wspólne rozliczenie za cały rok.
- **Priorytet:** 1180

### P1181: `sc_partner_spouse_pit_impact_sc` ★
- **Cel biznesowy:** Małżonek wspólnika jako współpracownik — przychód dzielony na obojga małżonków. Dotyczy tylko JDG, NIE SC (ale może być współpracownikiem dla części JDG wspólnika).
- **Przesłanki:**
  - `p.spouse_is_cooperator == true`
  - `p.has_jdg_outside_sc == true`
- **Oczekiwany rezultat:**
  - `spouse_cooperation_applies_to: "JDG_ONLY"`
  - `spouse_income_from_cooperation: JDG_income / 2`
  - `sc_income_unaffected: true` — dochód ze SC NIE jest dzielony na małżonka
- **Podstawa prawna:** Art. 8 ust. 2 PIT (współpraca przy JDG)
- **Przypadki brzegowe:** Współpraca tylko dla JDG (nie SC!). Dochód małżonka ze współpracy opodatkowany jak działalność.
- **Priorytet:** 1181

### P1182: `sc_partner_spouse_vat_private_use_sc` ★
- **Cel biznesowy:** Prywatny użytek małżonka wspólnika ze składników majątku spółki (np. samochód osobowy) — skutki VAT. VAT naliczony od wydatków na ten składnik podlega ograniczeniu.
- **Przesłanki:**
  - `input.invoice.category_code` w `["VEHICLE", "REAL_ESTATE"]`
  - `input.invoice.private_use_by_spouse_percent > 0`
  - `input.partnership.is_vat_payer == true`
- **Oczekiwany rezultat:**
  - `vat_deductible_percent: max(50, 100 - private_use_by_spouse_percent)` (dla samochodów: max 50%)
  - `vat_non_deductible: total_vat * (1 - vat_deductible_percent/100)`
  - `_warning: "Prywatny użytek małżonka → ograniczenie odliczenia VAT"`
- **Podstawa prawna:** Art. 86a VAT (pojazdy samochodowe), Art. 86 ust. 1 VAT (związek z działalnością)
- **Przypadki brzegowe:** Samochód ciężarowy → pełne odliczenie VAT (nie dotyczy ograniczenie 50%).
- **Priorytet:** 1182

### P1183: `sc_partner_spouse_succession_sc` ★
- **Cel biznesowy:** Po śmierci wspólnika, małżonek dziedziczy udział w spółce (w ramach spadku) — ale sam udział NIE wchodzi do wspólności majątkowej (to prawo udziałowe).
- **Przesłanki:**
  - `p.deceased == true`
  - `p.spouse_is_heir == true`
  - `p.surviving_spouse_alive == true`
- **Oczekiwany rezultat:**
  - `spouse_inherits_share: p.share_percent * inheritance_fraction`
  - `spouse_ceidg_required: true` — małżonek musi zarejestrować JDG by kontynuować
  - `_warning: "Małżonek dziedziczy udział — konieczność rejestracji CEIDG"`
- **Podstawa prawna:** Art. 872 KC, Art. 922 KC, Art. 31 KRO
- **Przypadki brzegowe:** Małżonek bez CEIDG → nie może być wspólnikiem → udział spieniężony lub przekazany zarządcy sukcesyjnemu.
- **Priorytet:** 1183

---

## Obszar 5: Spółka w trakcie kontroli skarbowej

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1184-P1189 — nowy blok `sc.audit`

### P1184: `sc_audit_rights_sc` ★★
- **Cel biznesowy:** Prawa spółki podczas kontroli skarbowej — prawo do obecności przy czynnościach, nagrywania, składania wyjaśnień, odmowy odpowiedzi na pytania inkryminujące.
- **Przesłanki:**
  - `input.partnership.audit_status == "IN_PROGRESS"`
  - `input.audit.rights_violated == true`
- **Oczekiwany rezultat:**
  - `audit_right_protection_active: true`
  - `allowed_actions: ["LEGAL_REPRESENTATIVE", "RECORDING", "WRITTEN_EXPLANATIONS", "RIGHT_TO_SILENCE"]`
  - `_warning: "Kontrola w toku — dokumentuj wszystkie czynności"`
- **Podstawa prawna:** Art. 80-83 Ordynacji podatkowej, Art. 281-292 Ordynacji podatkowej
- **Przypadki brzegowe:** Brak zawiadomienia o kontroli z 7-dniowym wyprzedzeniem → wada formalna. Kontrola bez upoważnienia → czynności nieważne.
- **Priorytet:** 1184

### P1185: `sc_audit_suspension_effect_sc` ★
- **Cel biznesowy:** Wszczęcie kontroli skarbowej zawiesza bieg przedawnienia zobowiązań za okres kontrolowany — ważne dla kalkulacji ryzyka.
- **Przesłanki:**
  - `input.partnership.audit_status == "IN_PROGRESS"`
  - `input.audit.period_audited` — okres objęty kontrolą
- **Oczekiwany rezultat:**
  - `prescription_suspended_from: input.audit.start_date`
  - `prescription_suspended_until: input.audit.end_date`
  - `prescription_new_deadline: original_deadline + suspension_duration`
  - `_info: "Bieg przedawnienia zawieszony na czas kontroli"`
- **Podstawa prawna:** Art. 70c Ordynacji podatkowej
- **Zależności:** Łączy się z P1166 (zawieszenie przedawnienia).
- **Przypadki brzegowe:** Przedawnienie może być wielokrotnie zawieszane (kontrola + postępowanie podatkowe + postępowanie sądowe).
- **Priorytet:** 1185

### P1186: `sc_audit_representation_sc` ★
- **Cel biznesowy:** Reprezentacja spółki podczas kontroli — wspólnicy mogą działać osobiście lub przez pełnomocnika (PPS-1). Decyzje w trakcie kontroli wymagają zgody wszystkich wspólników.
- **Przesłanki:**
  - `input.partnership.audit_status == "IN_PROGRESS"`
  - `input.audit.decision_requires_consent == true`
  - `input.audit.all_partners_consented == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Decyzja w trakcie kontroli wymaga zgody wszystkich wspólników"`
  - `representation_mode: "ALL_PARTNERS_OR_JOINT_PROXY"`
- **Podstawa prawna:** Art. 866 KC, Art. 138d-138g Ordynacji podatkowej
- **Zależności:** Łączy się z P910-P914 (reprezentacja).
- **Przypadki brzegowe:** Jeden wspólnik może być pełnomocnikiem pozostałych (PPS-1). Brak porozumienia między wspólnikami → blokada decyzji.
- **Priorytet:** 1186

### P1187: `sc_audit_deadline_sc` ★
- **Cel biznesowy:** Maksymalny czas trwania kontroli — zasadniczo 2 miesiące (przedłużane z ważnych powodów). Po przekroczeniu terminu bez wyniku → kontrola nieskuteczna.
- **Przesłanki:**
  - `input.partnership.audit_status == "IN_PROGRESS"`
  - `input.audit.elapsed_days > input.thresholds.sc.bounds.audit_max_duration_days` (60 dni)
  - `input.audit.extension_granted == false`
- **Oczekiwany rezultat:**
  - `audit_time_exceeded: true`
  - `_warning: "Kontrola przekroczyła maksymalny czas — rozważ wniosek o zakończenie"`
  - `audit_ineffective_risk: "HIGH"`
- **Podstawa prawna:** Art. 83 Ordynacji podatkowej
- **Przypadki brzegowe:** Przedłużenie z powodu skomplikowania sprawy — do 6 miesięcy. Opóźnienie z winy kontrolowanego → nie wlicza się do terminu.
- **Priorytet:** 1187

### P1188: `sc_audit_correction_window_sc` ★
- **Cel biznesowy:** Podczas kontroli spółka może składać korekty deklaracji (czynny żal) — ale tylko w zakresie nieobjętym jeszcze ustaleniami kontroli.
- **Przesłanki:**
  - `input.partnership.audit_status == "IN_PROGRESS"`
  - `input.invoice.is_correction == true`
  - `input.invoice.correction_period IN input.audit.period_audited`
- **Oczekiwany rezultat:**
  - `correction_allowed: "PARTIALLY"` — tylko zakres nieustalony
  - `correction_blocked_scope: input.audit.findings_confirmed_scope`
  - `_warning: "Korekta w trakcie kontroli — tylko w zakresie nieustalonym"`
- **Podstawa prawna:** Art. 81 Ordynacji podatkowej, Art. 56 KKS (czynny żal)
- **Przypadki brzegowe:** Złożenie korekty po zakończeniu kontroli → pełna swoboda (ale odsetki od pierwotnego terminu).
- **Priorytet:** 1188

### P1189: `sc_audit_consequences_sc` ★
- **Cel biznesowy:** Po zakończeniu kontroli — domiar podatku, odsetki (12,5% rocznie), kara KKS, odpowiedzialność solidarna wspólników za domiar.
- **Przesłanki:**
  - `input.partnership.audit_status == "COMPLETED"`
  - `input.audit.findings.tax_underpayment > 0`
- **Oczekiwany rezultat:**
  - `tax_assessment: findings.tax_underpayment`
  - `interest: underpayment * 0.125 * (days_late / 365)`
  - `penalty_kks: "25%_TO_100%_OF_UNDERPAYMENT"` (zależne od skali i winy)
  - `liable_parties: "ALL_PARTNERS_JOINTLY"` — solidarna odpowiedzialność
  - `_warning: "Domiar podatku — odpowiedzialność solidarna wszystkich wspólników"`
- **Podstawa prawna:** Art. 21-25 Ordynacji podatkowej, Art. 53-56 KKS, Art. 864 KC
- **Przypadki brzegowe:** Czynny żal przed kontrolą → brak kary KKS. Wspólnik, który nie zgadza się z ustaleniami → odwołanie do SKO/WSA.
- **Priorytet:** 1189


---

## Obszar 6: Zajęcie udziału przez komornika

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1190-P1193 — nowy blok `sc.enforcement`

### P1190: `sc_bailiff_share_seizure_sc` ★★
- **Cel biznesowy:** Komornik może zająć udział wspólnika w spółce cywilnej — ale NIE może przejąć praw do prowadzenia spraw spółki (tylko prawa majątkowe). Spółka działa dalej.
- **Przesłanki:**
  - `p.bailiff_seizure_active == true` — zajęcie udziału
  - `p.bailiff_seizure_date != null`
- **Oczekiwany rezultat:**
  - `seized_rights: ["PROFIT_SHARE", "LIQUIDATION_SHARE"]` — tylko prawa majątkowe
  - `unseized_rights: ["MANAGEMENT_RIGHTS", "VOTING_RIGHTS", "REPRESENTATION"]` — prawa korporacyjne
  - `partnership_continues: true` — spółka działa dalej
  - `profit_flow: "TO_BAILIFF"` — zyski wspólnika trafiają do komornika
- **Podstawa prawna:** Art. 870 KC, Art. 831 § 2 KPC, Art. 895-909 KPC
- **Zależności:** Przed P1174 (egzekucja).
- **Przypadki brzegowe:** Komornik NIE może rozwiązać spółki — tylko wspólnicy. Pozostali wspólnicy mogą spłacić wierzyciela i zwolnić udział.
- **Priorytet:** 1190

### P1191: `sc_bailiff_share_valuation_sc` ★
- **Cel biznesowy:** Wycena udziału wspólnika na potrzeby egzekucji — wartość rynkowa majątku spółki × udział wspólnika.
- **Przesłanki:**
  - `p.bailiff_seizure_active == true`
  - Wycena udziału wymagana
- **Oczekiwany rezultat:**
  - `partnership_net_assets_market: assets_market_value - liabilities`
  - `partner_share_value: net_assets_market * p.share_percent / 100`
  - `seizable_value: partner_share_value`
  - `_info: "Wycena udziału wg wartości rynkowej majątku spółki"`
- **Podstawa prawna:** Art. 870 KC, Art. 948 KPC
- **Przypadki brzegowe:** Trudność wyceny → biegły sądowy. Wartość firmy (goodwill) może być uwzględniona.
- **Priorytet:** 1191

### P1192: `sc_bailiff_partner_exit_forced_sc` ★
- **Cel biznesowy:** Pozostali wspólnicy mogą wypowiedzieć udział zajętemu wspólnikowi (Art. 870 KC) — spłata udziału, a nie jego sprzedaż na licytacji.
- **Przesłanki:**
  - `p.bailiff_seizure_duration > 6_months` — zajęcie trwa ponad 6 mies.
  - Pozostali wspólnicy decydują o wypowiedzeniu
- **Oczekiwany rezultat:**
  - `forced_exit_allowed: true`
  - `settlement_payment: partner_share_value` — spłata do rąk komornika
  - `partner_exit_effective: <data wypowiedzenia>`
  - `remaining_partners_shares: przeliczone proporcjonalnie`
- **Podstawa prawna:** Art. 870 KC, Art. 869 KC
- **Przypadki brzegowe:** Spłata niższa niż wartość rynkowa → odpowiedzialność wspólników. Brak środków na spłatę → udział podlega licytacji.
- **Priorytet:** 1192

### P1193: `sc_bailiff_profit_interception_sc` ★
- **Cel biznesowy:** W trakcie zajęcia, zyski wspólnika ze spółki trafiają bezpośrednio do komornika (nie mogą być wypłacane wspólnikowi).
- **Przesłanki:**
  - `p.bailiff_seizure_active == true`
  - `p.monthly_profit_share > 0`
- **Oczekiwany rezultat:**
  - `profit_redirection: "TO_BAILIFF_ACCOUNT"`
  - `partner_receives: 0` — wspólnik nie dostaje zysków
  - `bailiff_receives: p.monthly_profit_share` (do wysokości długu)
  - `_warning: "Zyski wspólnika przekazywane komornikowi — do spłaty długu"`
- **Podstawa prawna:** Art. 831 § 1 KPC, Art. 870 KC
- **Przypadki brzegowe:** Po spłacie długu → zyski wracają do wspólnika. Zajęcie tylko części zysków (np. 50%) → możliwe na wniosek.
- **Priorytet:** 1193

---

## Obszar 7: Podatek od nieruchomości

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1194-P1197 — nowy blok `sc.local_taxes`

### P1194: `sc_property_tax_liability_sc` ★
- **Cel biznesowy:** Spółka cywilna jako właściciel/użytkownik wieczysty nieruchomości → podatek od nieruchomości. Stawki: gruntowe, budynkowe, budowlane.
- **Przesłanki:**
  - `input.partnership.owns_real_estate == true`
  - `input.partnership.real_estate_usage == "BUSINESS"`
- **Oczekiwany rezultat:**
  - `property_tax_due: area_m2 * applicable_rate`
  - `property_tax_declaration: DN-1` — deklaracja na podatek od nieruchomości
  - `property_tax_deadline: "31 stycznia"` (deklaracja), raty: 15.03, 15.05, 15.09, 15.11
  - `property_tax_deductibility: "KUP_FULL"` — podatek jest KUP
- **Podstawa prawna:** Ustawa o podatkach i opłatach lokalnych (tekst jednolity: Dz.U. 2025 poz. 234), Art. 2-6
- **Zależności:** Przed P560 (KUP).
- **Przypadki brzegowe:** Nieruchomość mieszkalna wynajmowana → stawka jak dla działalności (wyższa). Grunt rolny → podatek rolny (nie od nieruchomości). Współwłasność → podatek proporcjonalny.
- **Priorytet:** 1194

### P1195: `sc_property_tax_exemptions_sc` ★
- **Cel biznesowy:** Zwolnienia z podatku od nieruchomości — np. nieruchomości w specjalnych strefach ekonomicznych, zabytki, infrastruktura kolejowa.
- **Przesłanki:**
  - `input.partnership.real_estate_type` w `["SSE", "MONUMENT", "RAILWAY"]`
  - `input.partnership.has_exemption_certificate == true`
- **Oczekiwany rezultat:**
  - `property_tax_rate: 0` — zwolnienie
  - `property_tax_exemption_basis: odpowiedni przepis`
  - `_info: "Zwolnienie z podatku od nieruchomości"`
- **Podstawa prawna:** Art. 7 ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Zwolnienie warunkowe (np. utworzenie nowych miejsc pracy) → cofnięcie przy niespełnieniu warunków.
- **Priorytet:** 1195

### P1196: `sc_property_tax_shared_ownership_sc` ★
- **Cel biznesowy:** Nieruchomość jest współwłasnością spółki i osoby trzeciej → podatek proporcjonalny do udziału.
- **Przesłanki:**
  - `input.partnership.real_estate_share < 100`
  - Współwłasność z osobą spoza spółki
- **Oczekiwany rezultat:**
  - `property_tax_share: partnership_ownership_percent / 100`
  - `property_tax_due: total_tax * property_tax_share`
  - `co_owner_tax_due: total_tax * (1 - property_tax_share)`
- **Podstawa prawna:** Art. 3 ustawy o podatkach i opłatach lokalnych
- **Przypadki brzegowe:** Solidarna odpowiedzialność współwłaścicieli za podatek.
- **Priorytet:** 1196

### P1197: `sc_property_tax_vat_interaction_sc` ★
- **Cel biznesowy:** Podatek od nieruchomości stanowi KUP dla spółki i wpływa na cenę usługi (jeśli nieruchomość wynajmowana). Nie podlega VAT.
- **Przesłanki:**
  - Nieruchomość wykorzystywana w działalności
  - `input.partnership.property_tax_paid > 0`
- **Oczekiwany rezultat:**
  - `property_tax_kup: "FULL"` — zawsze KUP
  - `property_tax_vat: "NOT_APPLICABLE"` — podatek nie podlega VAT
  - `property_tax_in_invoice: "MAY_BE_REFACTURED"` — można przerzucić na najemcę
- **Podstawa prawna:** Art. 22 PIT (KUP), Art. 5 VAT (poza VAT)
- **Priorytet:** 1197

---

## Obszar 8: Akcyza

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1198-P1201 — nowy blok `sc.excise`
> **[TODO: potrzebne źródło — szczegółowe rozporządzenia akcyzowe dla 2026]**

### P1198: `sc_excise_trigger_sc` ★
- **Cel biznesowy:** Czy spółka cywilna obracająca towarami akcyzowymi (alkohol, tytoń, paliwa, energia) podlega akcyzie? TAK — spółka jako podmiot gospodarczy.
- **Przesłanki:**
  - `input.invoice.category_code` w `["ALCOHOL", "TOBACCO", "FUEL", "ENERGY_ELECTRICITY"]`
  - `input.invoice.excise_code != null` — kod CN towaru akcyzowego
- **Oczekiwany rezultat:**
  - `excise_applicable: true`
  - `excise_registration_required: true` — rejestracja AKC-R
  - `excise_declaration: AKC-4` (miesięczna)
  - `excise_deadline: "25. dnia miesiąca następnego"`
- **Podstawa prawna:** Ustawa o podatku akcyzowym (tekst jednolity: Dz.U. 2025 poz. 567), Art. 8, 10, 13, 21
- **Zależności:** Przed P50 (VAT — akcyza wchodzi do podstawy VAT).
- **Przypadki brzegowe:** Akcyza w składzie podatkowym (zawieszona) vs poza składem (płatna). Sprzedaż konsumentowi → akcyza w cenie.
- **Priorytet:** 1198

### P1199: `sc_excise_vat_base_effect_sc` ★
- **Cel biznesowy:** Akcyza wchodzi do podstawy opodatkowania VAT — podatek od podatku (efekt kaskadowy).
- **Przesłanki:**
  - `excise_applicable == true`
  - `input.invoice.direction == "SALE"`
- **Oczekiwany rezultat:**
  - `vat_base: net_price + excise_amount` — akcyza zwiększa podstawę VAT
  - `vat_amount: vat_base * vat_rate`
  - `_warning: "Akcyza w podstawie VAT — efekt kaskadowy"`
- **Podstawa prawna:** Art. 29a VAT
- **Przypadki brzegowe:** Import towarów akcyzowych → akcyza płatna na granicy + VAT w deklaracji.
- **Priorytet:** 1199

### P1200: `sc_excise_warehouse_sc` ★
- **Cel biznesowy:** Skład podatkowy — procedura zawieszenia akcyzy. Spółka może magazynować towary akcyzowe bez płacenia akcyzy do momentu wyprowadzenia ze składu.
- **Przesłanki:**
  - `input.partnership.has_excise_warehouse == true`
  - `input.invoice.excise_status == "SUSPENDED"`
- **Oczekiwany rezultat:**
  - `excise_due: 0` — zawieszona
  - `excise_guarantee_required: true` — zabezpieczenie akcyzowe
  - `excise_trigger_on_release: true` — płatna przy wyprowadzeniu
- **Podstawa prawna:** Art. 40-50 ustawy o podatku akcyzowym
- **Przypadki brzegowe:** Wyprowadzenie ze składu bez akcyzy → przemyt, sankcja karno-skarbowa.
- **Priorytet:** 1200

### P1201: `sc_excise_energy_sc` ★
- **Cel biznesowy:** Akcyza od energii elektrycznej — spółka jako odbiorca końcowy. Obowiązek deklaracji i zapłaty.
- **Przesłanki:**
  - `input.invoice.category_code == "ENERGY_ELECTRICITY"`
  - `input.partnership.is_energy_end_user == true`
- **Oczekiwany rezultat:**
  - `energy_excise_rate: 5_PLN_per_MWh` (stawka 2026)
  - `energy_excise_due: consumption_mwh * rate`
  - `energy_excise_exempt_renewables: true` — OZE zwolnione
- **Podstawa prawna:** Art. 88-89 ustawy o podatku akcyzowym
- **Przypadki brzegowe:** Spółka z własną instalacją PV → energia zużyta na własne potrzeby bez akcyzy (do 1 MW).
- **Priorytet:** 1201

---

## Obszar 9: AML — przeciwdziałanie praniu pieniędzy

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1220-P1224 — NOWY PAKIET `sc.aml`

### P1220: `sc_aml_15k_eur_threshold_sc` ★★
- **Cel biznesowy:** Spółka przyjmująca płatność gotówkową powyżej 15 000 EUR (lub równowartości) od jednego kontrahenta → obowiązek raportowania do GIIF (Generalny Inspektor Informacji Finansowej).
- **Przesłanki:**
  - `input.invoice.is_cash_payment == true`
  - `input.invoice.amount_pln > input.thresholds.sc.bounds.aml_cash_threshold_pln` (15 000 EUR × kurs NBP)
  - `input.invoice.direction == "SALE"` — spółka przyjmuje gotówkę
- **Oczekiwany rezultat:**
  - `aml_report_required: true`
  - `aml_report_form: "GIIF_CASH_TRANSACTION"`
  - `aml_report_deadline: "7_dni_od_transakcji"`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Transakcja gotówkowa >15k EUR — obowiązek AML"`
- **Podstawa prawna:** Art. 35, 72 ustawy o AML (tekst jednolity: Dz.U. 2025 poz. 890)
- **Zależności:** Przed P0 (risk).
- **Przypadki brzegowe:** Limit dotyczy POJEDYNCZEJ transakcji, nie sumy. Transakcje powiązane (strukturyzacja) → agregowane. Przelew bankowy → NIE podlega raportowaniu.
- **Priorytet:** 1220

### P1221: `sc_aml_beneficial_owner_sc` ★
- **Cel biznesowy:** Obowiązek zgłoszenia beneficjentów rzeczywistych spółki do Centralnego Rejestru Beneficjentów Rzeczywistych (CRBR). W SC: każdy wspólnik >25% udziałów jest beneficjentem.
- **Przesłanki:**
  - `p.share_percent > 25` — wspólnik posiada >25% udziałów
  - `input.partnership.crbr_reported == false`
- **Oczekiwany rezultat:**
  - `crbr_report_required: true`
  - `crbr_beneficial_owners: [lista wspólników z >25%]`
  - `crbr_deadline: "7_dni_od_rejestracji"`
  - `_warning: "Brak zgłoszenia CRBR — obowiązek AML"`
- **Podstawa prawna:** Art. 55-66 ustawy o AML
- **Przypadki brzegowe:** Dwóch wspólników po 50% → obaj beneficjentami. Brak wspólnika >25% → beneficjentem jest osoba zarządzająca.
- **Priorytet:** 1221

### P1222: `sc_aml_suspicious_transaction_sc` ★
- **Cel biznesowy:** Wykrywanie transakcji podejrzanych (strukturyzacja, nietypowe wzorce) i obowiązek zgłoszenia do GIIF.
- **Przesłanki:**
  - `input.invoice.amount_pln > input.thresholds.sc.bounds.aml_suspicious_threshold` (1 mln PLN)
  - `input.invoice.has_economic_justification == false` — brak uzasadnienia ekonomicznego
  - LUB `input.invoice.structuring_pattern_detected == true` — dzielenie transakcji
- **Oczekiwany rezultat:**
  - `aml_sar_required: true` — Suspicious Activity Report
  - `aml_sar_deadline: "niezwłocznie"`
  - `_routing: "BLOCK_AND_ALERT"`
  - `_flag: "AML_SAR_FILING_REQUIRED"`
- **Podstawa prawna:** Art. 74-77 ustawy o AML
- **Przypadki brzegowe:** Fałszywy alarm → zgłoszenie i tak wymagane (GIIF ocenia). Brak zgłoszenia → kara do 1 mln EUR.
- **Priorytet:** 1222

### P1223: `sc_aml_15k_transfer_whitelist_sc` ★
- **Cel biznesowy:** Obowiązek weryfikacji Białej Listy VAT przed przelewem >15 000 PLN na konto kontrahenta (mechanizm podzielonej płatności opcjonalny).
- **Przesłanki:**
  - `input.invoice.is_bank_transfer == true`
  - `input.invoice.amount_gross > 15000`
  - `input.invoice.whitelist_verified == false`
- **Oczekiwany rezultat:**
  - `_routing: "BLOCK_AND_ALERT"`
  - `whitelist_verification_required: true`
  - `_warning: "Przelew >15k PLN — obowiązek weryfikacji Białej Listy VAT"`
  - Jeśli konto NIE na białej liście: `joint_liability_risk: true` — solidarna odpowiedzialność za VAT!
- **Podstawa prawna:** Art. 96b VAT, Art. 117ba-117bd Ordynacji podatkowej
- **Przypadki brzegowe:** Przelew na rachunek spoza białej listy → solidarna odpowiedzialność spółki za VAT kontrahenta. Zgłoszenie do US w ciągu 7 dni → zwolnienie z odpowiedzialności.
- **Priorytet:** 1223

### P1224: `sc_aml_risk_assessment_sc` ★
- **Cel biznesowy:** Okresowa ocena ryzyka AML — spółka powinna oceniać ryzyko prania pieniędzy w swojej działalności (szczególnie branże wysokiego ryzyka: paliwa, złom, budowlanka, IT z zagranicznymi klientami).
- **Przesłanki:**
  - Roczne / półroczne przeglądy
  - `input.partnership.aml_risk_score > input.thresholds.sc.bounds.aml_risk_threshold`
- **Oczekiwany rezultat:**
  - `aml_risk_level: "HIGH"`
  - `aml_measures_required: ["ENHANCED_DUE_DILIGENCE", "TRANSACTION_MONITORING", "STAFF_TRAINING"]`
  - `_warning: "Podwyższone ryzyko AML — wymagane środki zaradcze"`
- **Podstawa prawna:** Art. 33, 43 ustawy o AML
- **Przypadki brzegowe:** Spółka w branży niskiego ryzyka (np. księgarnia) → uproszczone środki.
- **Priorytet:** 1224

---

## Obszar 10: RODO — ochrona danych osobowych

> **Istniejące:** BRAK — całkowicie nowy obszar
> **Nowe reguły:** P1225-P1229 — NOWY PAKIET `sc.gdpr`

### P1225: `sc_gdpr_processor_status_sc` ★
- **Cel biznesowy:** Spółka cywilna przetwarzająca dane osobowe kontrahentów i pracowników → status administratora danych (ADO). Obowiązek rejestracji czynności przetwarzania.
- **Przesłanki:**
  - `input.partnership.processes_personal_data == true`
  - `input.partnership.has_gdpr_register == false`
- **Oczekiwany rezultat:**
  - `gdpr_register_required: true` — rejestr czynności przetwarzania
  - `gdpr_dpo_required: false` — IOD nie jest obowiązkowy dla małych SC (chyba że dane wrażliwe)
  - `gdpr_breach_notification_deadline: "72_hours"`
  - `_warning: "Brak rejestru RCP — naruszenie RODO"`
- **Podstawa prawna:** Art. 30 RODO, Art. 33-34 RODO
- **Zależności:** Przed P0 (risk).
- **Przypadki brzegowe:** Spółka <250 pracowników i przetwarzanie okazjonalne → zwolnienie z rejestru RCP (ale nadal zgoda na przetwarzanie).
- **Priorytet:** 1225

### P1226: `sc_gdpr_employee_data_sc` ★
- **Cel biznesowy:** Przetwarzanie danych pracowników przez spółkę — podstawa prawna: obowiązek prawny (Kodeks pracy), nie zgoda.
- **Przesłanki:**
  - `input.partnership.employee_count > 0`
  - `input.partnership.has_employee_data_policy == false`
- **Oczekiwany rezultat:**
  - `gdpr_processing_basis: "LEGAL_OBLIGATION"` — nie zgoda
  - `gdpr_employee_policy_required: true`
  - `gdpr_data_retention: "10_lat_od_ustania_zatrudnienia"`
  - `_warning: "Brak polityki ochrony danych pracowników"`
- **Podstawa prawna:** Art. 6 ust. 1 lit. c RODO, Art. 22¹-22³ Kodeksu pracy
- **Przypadki brzegowe:** Monitoring wizyjny → dodatkowa zgoda i oznaczenie. Dane biometryczne → dane wrażliwe (Art. 9 RODO), wymagana wyraźna zgoda.
- **Priorytet:** 1226

### P1227: `sc_gdpr_tax_data_retention_sc` ★
- **Cel biznesowy:** Okres przechowywania danych podatkowych (faktury, umowy z kontrahentami) — 5 lat od końca roku (ORD + UoR). Po tym okresie → obowiązek anonimizacji/usunięcia.
- **Przesłanki:**
  - Dane kontrahentów przechowywane dłużej niż 5 lat od końca roku
  - Brak uzasadnienia (np. trwający spór sądowy)
- **Oczekiwany rezultat:**
  - `gdpr_data_retention: "5_LAT"`
  - `gdpr_deletion_deadline: "po_upływie_5_lat"`
  - `gdpr_anonymization_possible: true` — dla celów statystycznych
  - `_warning: "Dane przechowywane ponad okres wymagany — naruszenie RODO"`
- **Podstawa prawna:** Art. 5 ust. 1 lit. e RODO, Art. 70 Ordynacji podatkowej, Art. 74 UoR
- **Przypadki brzegowe:** Trwający spór sądowy → uzasadnione przedłużenie. Dane archiwalne (historyczne) → mogą być przechowywane bezterminowo.
- **Priorytet:** 1227

### P1228: `sc_gdpr_cross_border_data_sc` ★
- **Cel biznesowy:** Transfer danych osobowych poza EOG (np. serwer w USA, usługi Google/AWS) — wymagane dodatkowe zabezpieczenia (SCC, TIA).
- **Przesłanki:**
  - `input.partnership.uses_non_eu_processors == true`
  - `input.partnership.has_scc_or_tia == false` — brak standardowych klauzul umownych
- **Oczekiwany rezultat:**
  - `gdpr_scc_required: true` — Standardowe Klauzule Umowne
  - `gdpr_tia_required: true` — Ocena Skutków Transferu
  - `_routing: "BLOCK_AND_ALERT"`
  - `_warning: "Transfer danych poza EOG bez zabezpieczeń — naruszenie RODO"`
- **Podstawa prawna:** Art. 44-49 RODO, decyzja KE 2021/914 (SCC)
- **Przypadki brzegowe:** Kraje z decyzją o adekwatności (Japonia, Kanada, UK) → transfer dozwolony bez SCC.
- **Priorytet:** 1228

### P1229: `sc_gdpr_fines_sc` ★
- **Cel biznesowy:** Naruszenie RODO → kara do 20 mln EUR lub 4% rocznego światowego obrotu. Odpowiedzialność solidarna wspólników.
- **Przesłanki:**
  - Stwierdzone naruszenie RODO
  - `input.gdpr.violation_severity` w `["SERIOUS", "CRITICAL"]`
- **Oczekiwany rezultat:**
  - `gdpr_fine_max: max(20_000_000 * EUR_PLN, partnership_annual_revenue * 0.04)`
  - `gdpr_fine_liability: "ALL_PARTNERS_JOINTLY"` — solidarna
  - `_warning: "Ryzyko kary RODO — odpowiedzialność solidarna"`
- **Podstawa prawna:** Art. 83 RODO, Art. 864 KC
- **Przypadki brzegowe:** Pierwsze naruszenie + dobrowolne zgłoszenie → kara niższa. Naruszenie umyślne → kara maksymalna.
- **Priorytet:** 1229


---

## Obszar 11: Cudzoziemiec jako wspolnik

> **Istniejace:** BRAK — calkowicie nowy obszar
> **Nowe reguly:** P1230-P1235 — nowy blok `sc.crossborder`

### P1230: `sc_non_resident_partner_limited_tax_sc` ★★
- **Cel biznesowy:** Wspolnik bedacy nierezydentem podatkowym (ograniczony obowiazek podatkowy) — opodatkowaniu w Polsce podlega tylko dochod osiagniety w Polsce (dochod ze SC).
- **Przeslanki:**
  - `p.tax_residence != "PL"` — wspolnik nie jest polskim rezydentem
  - `p.has_pl_tax_obligation == true` — ma dochod z polskiej SC
- **Oczekiwany rezultat:**
  - `tax_scope: "LIMITED"` — ograniczony obowiazek podatkowy
  - `taxable_in_pl: p.sc_income` — tylko dochod ze SC opodatkowany w PL
  - `double_taxation_treaty: "APPLY"` — sprawdz umowe o unikaniu podwojnego opodatkowania
  - `withholding_tax: "NOT_APPLICABLE"` — SC nie pobiera podatku u zrodla od udzialu w zysku
- **Podstawa prawna:** Art. 3 ust. 2a PIT, Art. 4a PIT, Umowy o UPO
- **Zaleznosci:** Przed P500 (podzial proporcjonalny).
- **Przypadki brzegowe:** Rezydent kraju bez UPO z Polska → pelny podatek w PL. Certyfikat rezydencji → wymagany do zastosowania UPO.
- **Priorytet:** 1230

### P1231: `sc_non_resident_partner_tax_form_sc` ★
- **Cel biznesowy:** Nierezydent moze wybrac forme opodatkowania tak jak polski wspolnik — skala, liniowy, ryczalt (o ile spelnia warunki).
- **Przeslanki:**
  - `p.tax_residence != "PL"`
  - `p.tax_form` w `["PIT_SCALE", "LINEAR", "LUMP_SUM"]`
- **Oczekiwany rezultat:**
  - `tax_form_allowed: true` — te same formy co dla rezydentow
  - `tax_form_restriction: "NO_LUMP_SUM_IF_NO_PL_ADDRESS"` [TODO: sprawdzic]
  - `pit_return: PIT-36 / PIT-36L / PIT-28`
- **Podstawa prawna:** Art. 3 ust. 2a, Art. 27, Art. 30c, Art. 6 ustawy o ryczalcie
- **Przypadki brzegowe:** Nierezydent bez polskiego adresu → obowiazek posiadania pelnomocnika w PL.
- **Priorytet:** 1231

### P1232: `sc_non_resident_partner_withholding_sc` ★
- **Cel biznesowy:** Czy SC musi pobierac podatek u zrodla (WHT) od zysku naleznego nierezydentowi? NIE — dochod z udzialu w SC to dochod z dzialalnosci, nie dywidenda. Ale uwaga: uslugi swiadczone przez nierezydenta SC → WHT!
- **Przeslanki:**
  - `input.invoice.category_code == "PARTNER_SERVICE"`
  - `input.invoice.service_provider_tax_residence != "PL"`
  - `input.invoice.service_type` w `["CONSULTING", "IT", "LEGAL", "ROYALTIES"]`
- **Oczekiwany rezultat:**
  - `wht_applicable: true` — 20% (lub stawka z UPO)
  - `wht_base: invoice_amount`
  - `wht_due: base * wht_rate`
  - `wht_declaration: IFT-2R`
  - `_warning: "WHT od uslug nierezydenta — sprawdz UPO"`
- **Podstawa prawna:** Art. 29 PIT, Art. 21 CIT (odpowiednio), Umowy UPO
- **Przypadki brzegowe:** Certyfikat rezydencji → obnizona stawka WHT (np. 5% zamiast 20%). Uslugi materialne (budowlane) → brak WHT.
- **Priorytet:** 1232

### P1233: `sc_cfc_rules_sc` ★
- **Cel biznesowy:** Controlled Foreign Corporation (CFC) — jesli nierezydent kontroluje polska SC a SC ma dochod z zagranicznej spolki kontrolowanej → opodatkowanie CFC w PL.
- **Przeslanki:**
  - `input.partnership.owns_foreign_entity == true`
  - `input.partnership.foreign_entity_tax_rate < 14.25` — niskopodatkowa jurysdykcja
  - `input.partnership.foreign_entity_income > 0`
- **Oczekiwany rezultat:**
  - `cfc_rules_triggered: true` — dochod zagranicznej CFC opodatkowany w PL
  - `cfc_tax_rate: 19%`
  - `cfc_income_per_partner: cfc_income * p.share_percent / 100`
- **Podstawa prawna:** Art. 30f PIT, Art. 24a CIT (odpowiednio)
- **Przypadki brzegowe:** CFC w UE z substancja ekonomiczna → zwolnienie. CFC pasywna (tylko holding) → zawsze opodatkowana.
- **Priorytet:** 1233

### P1234: `sc_non_eu_partner_vat_sc` ★
- **Cel biznesowy:** Wspolnik spoza UE jako klient/kontrahent spolki — transakcje zagraniczne a VAT. Eksport uslug poza UE → NP (nie podlega).
- **Przeslanki:**
  - `input.vendor.country NOT IN input.thresholds.sc.eu_countries`
  - `input.vendor.is_partner == true`
  - `input.invoice.direction == "SALE"`
- **Oczekiwany rezultat:**
  - `vat_rate: "NP"` — nie podlega polskiemu VAT
  - `vat_territoriality: "COUNTRY_OF_RECIPIENT"`
  - `_info: "Transakcja poza terytorium UE — VAT rozliczany w kraju odbiorcy"`
- **Podstawa prawna:** Art. 28b VAT, Art. 5 VAT (terytorialnosc)
- **Priorytet:** 1234

### P1235: `sc_foreign_partner_ceidg_sc` ★
- **Cel biznesowy:** Cudzoziemiec (spoza UE) jako wspolnik SC — obowiazek rejestracji w CEIDG na tych samych zasadach co obywatel PL (chyba ze posiada zezwolenie na pobyt).
- **Przeslanki:**
  - `p.citizenship NOT IN ["PL"] AND p.citizenship NOT IN input.thresholds.sc.eu_countries`
  - `p.registered_in_ceidg == false`
- **Oczekiwany rezultat:**
  - `ceidg_registration_required: true`
  - `ceidg_requirements: ["PESEL_OR_NIP", "PL_ADDRESS_FOR_SERVICE"]`
  - `_warning: "Cudzoziemiec jako wspolnik SC — obowiazek rejestracji CEIDG"`
- **Podstawa prawna:** Art. 5, 14 Prawa przedsiebiorcow, Ustawa o CEIDG
- **Przypadki brzegowe:** Obywatel UE → rejestracja jak Polak (na podstawie swobody przedsiebiorczosci). Spozywca spoza UE → wymaga zezwolenia na prace/pobyt.
- **Priorytet:** 1235

---

## Obszar 12: Fundusze unijne i dotacje

> **Istniejace:** BRAK — calkowicie nowy obszar
> **Nowe reguly:** P1236-P1240

### P1236: `sc_eu_grant_revenue_recognition_sc` ★
- **Cel biznesowy:** Dotacja unijna otrzymana przez spolke — czy stanowi przychod podatkowy? Dotacje na srodki trwale → NIE (zwolnione). Dotacje operacyjne → TAK (przychod).
- **Przeslanki:**
  - `input.invoice.category_code == "EU_GRANT"`
  - `input.invoice.grant_type` w `["INVESTMENT", "OPERATIONAL"]`
- **Oczekiwany rezultat:**
  - Dla INVESTMENT: `pit_revenue: 0` (zwolnione) — ale srodek trwaly NIE amortyzowany od czesci sfinansowanej dotacja
  - Dla OPERATIONAL: `pit_revenue: grant_amount` — opodatkowane
  - Dla obu: `vat_exempt: false` — dotacja NIE zwieksza podstawy VAT
  - `_info: "Dotacje inwestycyjne zwolnione z PIT — ograniczenie amortyzacji"`
- **Podstawa prawna:** Art. 14 ust. 2 pkt 2 PIT, Art. 21 ust. 1 pkt 46-47c PIT, Art. 29a VAT
- **Zaleznosci:** Przed P840 (amortyzacja), po P500 (podzial).
- **Przypadki brzegowe:** Dotacja zwrocona → korekta przychodu w okresie zwrotu. Dotacja z budzetu panstwa vs budzetu UE → rozne podstawy zwolnienia.
- **Priorytet:** 1236

### P1237: `sc_eu_grant_vat_impact_sc` ★
- **Cel biznesowy:** Dotacja NIE wchodzi do podstawy VAT (chyba ze jest doplata do ceny — np. dotacja do biletu komunikacji miejskiej).
- **Przeslanki:**
  - `input.invoice.category_code == "EU_GRANT"`
  - `input.invoice.grant_type == "INVESTMENT"` — ogolna, nie do ceny
- **Oczekiwany rezultat:**
  - `vat_base_increase: 0` — dotacja nie zwieksza podstawy VAT
  - `vat_deduction_limitation: true` — VAT od wydatkow sfinansowanych dotacja NIE podlega odliczeniu
  - `_warning: "VAT od wydatkow sfinansowanych dotacja — brak odliczenia"`
- **Podstawa prawna:** Art. 29a ust. 1 VAT, Art. 86 ust. 2 pkt 1 VAT
- **Przypadki brzegowe:** Dotacja do ceny (np. doplata do czynszu) → wchodzi do podstawy VAT.
- **Priorytet:** 1237

### P1238: `sc_eu_grant_depreciation_exclusion_sc` ★
- **Cel biznesowy:** Srodek trwaly sfinansowany dotacja → odpisy amortyzacyjne od czesci sfinansowanej NIE sa KUP.
- **Przeslanki:**
  - `input.invoice.asset_financed_by_grant == true`
  - `input.invoice.grant_coverage_percent > 0`
- **Oczekiwany rezultat:**
  - `depreciation_kup_percent: 100 - grant_coverage_percent`
  - `depreciation_non_kup: total_depreciation * grant_coverage_percent / 100`
  - `_info: "Amortyzacja od czesci dotowanej — NKUP"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 45 PIT
- **Przypadki brzegowe:** Dotacja pokrywajaca 100% srodka trwalego → cala amortyzacja NKUP. Srodki trwale <10k PLN → jednorazowa amortyzacja — analogiczne ograniczenie.
- **Priorytet:** 1238

### P1239: `sc_eu_grant_return_sc` ★
- **Cel biznesowy:** Zwrot dotacji (np. z powodu niespelnienia warunkow) — korekta kosztow/przychodow z lat ubieglych.
- **Przeslanki:**
  - `input.invoice.category_code == "GRANT_RETURN"`
  - `input.invoice.original_grant_year < current_year`
- **Oczekiwany rezultat:**
  - `return_treatment: "PRIOR_YEAR_ADJUSTMENT"` — korekta lat ubieglych
  - `pit_effect: return_amount * p.share_percent / 100` — zmniejszenie dochodu wspolnika
  - `vat_effect: "NONE"` — zwrot dotacji nie podlega VAT
  - `_warning: "Zwrot dotacji — korekta zeznan za rok otrzymania"`
- **Podstawa prawna:** Art. 14 ust. 2 pkt 2 PIT, Art. 81 Ordynacji podatkowej
- **Przypadki brzegowe:** Zwrot w tym samym roku → korekta biezaca. Zwrot z odsetkami → odsetki jako KUP.
- **Priorytet:** 1239

### P1240: `sc_eu_grant_reporting_sc` ★
- **Cel biznesowy:** Obowiazek sprawozdawczy z wykorzystania dotacji — terminy, kontrole, sankcje.
- **Przeslanki:**
  - `input.partnership.has_active_grant == true`
  - `input.partnership.grant_reporting_due == true`
- **Oczekiwany rezultat:**
  - `grant_report_deadline: <zgodnie z umowa dotacji>`
  - `grant_audit_risk: "HIGH"` — dotacje sa czesto kontrolowane
  - `_warning: "Termin sprawozdania z dotacji — ryzyko utraty finansowania"`
- **Podstawa prawna:** Umowa o dofinansowanie, Art. 207 ustawy o finansach publicznych
- **Priorytet:** 1240

---

## Obszar 13: Leasing operacyjny i finansowy

> **Istniejace:** BRAK — calkowicie nowy obszar
> **Nowe reguly:** P1241-P1245

### P1241: `sc_leasing_operational_kup_sc` ★★
- **Cel biznesowy:** Leasing operacyjny — raty leasingowe KUP dla spolki. Warunki: umowa min. 40% normatywnego okresu amortyzacji (lub min. 3 lata dla ruchomosci), suma rat rowna lub wieksza od wartosci poczatkowej.
- **Przeslanki:**
  - `input.invoice.category_code == "LEASING_OPERATIONAL"`
  - `input.invoice.leasing_term_months >= input.thresholds.sc.bounds.leasing_min_term_months` (36 dla ruchomosci)
  - `input.invoice.total_lease_payments >= input.invoice.asset_initial_value`
- **Oczekiwany rezultat:**
  - `kup_qualification: "FULL"` — cale raty KUP
  - `vat_deductible_portion: 1.0` (lub 0.5 dla samochodow osobowych)
  - `initial_fee_kup: "SPREAD_OVER_LEASE_TERM"` — oplate wstepna rozlicza sie proporcjonalnie
- **Podstawa prawna:** Art. 23b PIT (leasing operacyjny), Art. 23a PIT
- **Zaleznosci:** Przed P560 (KUP).
- **Przypadki brzegowe:** Leasing samochodu osobowego > 150 000 PLN → raty powyzej limitu NKUP. Umowa krotsza niz wymagana → traktowana jak leasing finansowy.
- **Priorytet:** 1241

### P1242: `sc_leasing_finance_kup_sc` ★
- **Cel biznesowy:** Leasing finansowy — KUP stanowi tylko odsetkowa czesc raty + amortyzacja srodka trwalego (leasingobiorca amortyzuje). Czesc kapitalowa NIE jest KUP.
- **Przeslanki:**
  - `input.invoice.category_code == "LEASING_FINANCE"`
  - Umowa nie spelnia warunkow leasingu operacyjnego
- **Oczekiwany rezultat:**
  - `kup_interest: interest_portion_of_installment` — tylko odsetki KUP
  - `kup_depreciation: asset_value * depreciation_rate` — amortyzacja KUP
  - `kup_principal: 0` — czesc kapitalowa NKUP
  - `asset_balance_sheet: true` — srodek trwaly w bilansie spolki
- **Podstawa prawna:** Art. 23f-23j PIT (leasing finansowy), Art. 22a-22o PIT (amortyzacja)
- **Przypadki brzegowe:** Wykup po leasingu finansowym → cena niska (1-5% wartosci) → wydatek jednorazowy KUP.
- **Priorytet:** 1242

### P1243: `sc_leasing_car_limit_sc` ★
- **Cel biznesowy:** Limit 150 000 PLN dla leasingu samochodow osobowych — raty powyzej limitu sa NKUP (proporcjonalnie). Dotyczy zarowno operacyjnego jak i finansowego.
- **Przeslanki:**
  - `input.invoice.category_code` w `["LEASING_OPERATIONAL", "LEASING_FINANCE"]`
  - `input.invoice.asset_type == "PASSENGER_CAR"`
  - `input.invoice.asset_value > 150000`
- **Oczekiwany rezultat:**
  - `kup_portion: 150000 / asset_value` — tylko proporcja KUP
  - `nkup_portion: 1 - kup_portion`
  - `vat_deductible_portion: 0.5` — 50% VAT
  - `_warning: "Limit 150k PLN dla samochodu osobowego — raty czesciowo NKUP"`
- **Podstawa prawna:** Art. 23 ust. 1 pkt 47a PIT, Art. 86a VAT
- **Przypadki brzegowe:** Samochod elektryczny > 150k → limit wyzszy (225k PLN). Samochod ciezarowy → bez limitu.
- **Priorytet:** 1243

### P1244: `sc_leasing_buyout_sc` ★
- **Cel biznesowy:** Wykup przedmiotu leasingu po zakonczeniu umowy — operacyjny (do majatku prywatnego lub firmowego) vs finansowy (juz w majatku).
- **Przeslanki:**
  - `input.invoice.category_code == "LEASING_BUYOUT"`
  - `input.invoice.leasing_type` w `["OPERATIONAL", "FINANCE"]`
- **Oczekiwany rezultat:**
  - Dla operacyjnego: `asset_registration: "NEW_FIXED_ASSET"` — nowy srodek trwaly (wartosc wykupu)
  - Dla finansowego: `asset_registration: "ALREADY_REGISTERED"` — wykup z majatku wlasnego
  - `vat_on_buyout: buyout_price * vat_rate`
  - `kup_on_buyout: "DEPRECIATION"` — amortyzacja od wartosci wykupu (dla operacyjnego)
- **Podstawa prawna:** Art. 22g PIT (wartosc poczatkowa), Art. 23b PIT
- **Przypadki brzegowe:** Wykup do majatku prywatnego wspolnika (nie spolki) → NIE KUP dla spolki. Wykup niska cena → OK jesli rynkowa.
- **Priorytet:** 1244

### P1245: `sc_leasing_vendor_leaseback_sc` ★
- **Cel biznesowy:** Leasing zwrotny (spolka sprzedaje swoj srodek trwaly leasingodawcy, nastepnie bierze go w leasing) — ryzyko obejscia limitu 150k PLN.
- **Przeslanki:**
  - `input.invoice.category_code == "LEASEBACK"`
  - `input.invoice.original_owner == input.partnership.nip` — spolka sprzedala swoj skladnik
- **Oczekiwany rezultat:**
  - `kup_restriction: "STANDARD_LIMITS_APPLY"` — limity 150k jak dla zwyklego leasingu
  - `_warning: "Leasing zwrotny — transakcja pod szczegolnym nadzorem US"`
  - `gaar_risk: "MEDIUM"` — ryzyko unikania opodatkowania
- **Podstawa prawna:** Art. 23b PIT, Art. 119a Ordynacji podatkowej (GAAR)
- **Przypadki brzegowe:** Sprzedaz ponizej wartosci rynkowej → dodatkowy przychod. Leasing zwrotny jako sposob na uwolnienie gotowki → dopuszczalny.
- **Priorytet:** 1245

---

## Obszar 14: Kryptowaluty

> **Istniejace:** BRAK — calkowicie nowy obszar
> **Nowe reguly:** P1246-P1250
> **[TODO: potrzebne zrodlo — projekt ustawy o kryptoaktywach 2026]**

### P1246: `sc_crypto_payment_received_sc` ★★
- **Cel biznesowy:** Spolka przyjmuje platnosc w kryptowalucie (Bitcoin, USDT) od kontrahenta — jak ujac w PKPiR/ksiegach? Przychod wg kursu z dnia transakcji.
- **Przeslanki:**
  - `input.invoice.currency == "CRYPTO"`
  - `input.invoice.direction == "SALE"` — spolka otrzymuje krypto
- **Oczekiwany rezultat:**
  - `revenue_recognition_date: transaction_date`
  - `revenue_amount_pln: crypto_amount * crypto_rate_on_transaction_date`
  - `vat_treatment: "STANDARD"` — platnosc krypto to platnosc w naturze, podlega VAT na normalnych zasadach
  - `pit_treatment: "REVENUE"` — przychod podatkowy
  - `_warning: "Platnosc w krypto — przychod wg kursu z dnia transakcji"`
- **Podstawa prawna:** Art. 14 PIT (przychod w naturze), Art. 29a VAT (podstawa opodatkowania)
- **Zaleznosci:** Przed P50 (VAT).
- **Przypadki brzegowe:** Stablecoiny (USDT) → kurs 1:1 z USD, przeliczane przez USD/PLN. Bitcoin → kurs z gieldy (np. Binance, Kanga) z godziny transakcji.
- **Priorytet:** 1246

### P1247: `sc_crypto_payment_made_sc` ★
- **Cel biznesowy:** Spolka placi kryptowaluta za fakture — koszt wg wartosci krypto z dnia transakcji. Roznica miedzy cena nabycia krypto a wartoscia w dniu wydania → przychod/koszt.
- **Przeslanki:**
  - `input.invoice.currency == "CRYPTO"`
  - `input.invoice.direction == "PURCHASE"` — spolka placi krypto
- **Oczekiwany rezultat:**
  - `cost_amount_pln: crypto_spent * crypto_rate_on_transaction_date`
  - `fx_result_crypto: (crypto_rate_on_payment_date - crypto_rate_on_acquisition_date) * crypto_spent`
  - Jesli > 0: `fx_revenue: fx_result_crypto`
  - Jesli < 0: `fx_cost: abs(fx_result_crypto)` — KUP
  - `_warning: "Platnosc krypto — roznica kursowa jako przychod/koszt"`
- **Podstawa prawna:** Art. 14 PIT (przychod), Art. 22 PIT (KUP), Art. 24c PIT (roznice kursowe)
- **Przypadki brzegowe:** Krypto kupione za PLN specjalnie do zaplaty → podwojna roznica kursowa (PLN→krypto→PLN).
- **Priorytet:** 1247

### P1248: `sc_crypto_holding_sc` ★
- **Cel biznesowy:** Spolka trzyma kryptowaluty jako lokate kapitalu — wycena bilansowa na dzien bilansowy (dla pelnej ksiegowosci). Niezrealizowane zyski/straty.
- **Przeslanki:**
  - `input.partnership.holds_crypto == true`
  - `input.partnership.accounting_method == "FULL"`
  - Koniec roku obrotowego
- **Oczekiwany rezultat:**
  - `crypto_balance_sheet_valuation: crypto_balance * crypto_rate_on_balance_date`
  - `unrealized_gain: max(0, balance_sheet_value - book_value)`
  - `unrealized_loss: max(0, book_value - balance_sheet_value)` — ostrozna wycena
  - `pit_effect: "NONE"` — niezrealizowane zyski/straty NIE sa podatkowe
- **Podstawa prawna:** Art. 28 UoR (wycena), Art. 7 UoR (ostroznosc)
- **Przypadki brzegowe:** Krypto jako srodek trwaly → amortyzacja? NIE (krypto nie jest ST). Krypto jako wartosci niematerialne i prawne → moze byc, jesli token uzyteczny.
- **Priorytet:** 1248

### P1249: `sc_crypto_exchange_sc` ★
- **Cel biznesowy:** Wymiana krypto na inne krypto (BTC→ETH) — zdarzenie podatkowe! Roznica miedzy wartoscia oddawanego a otrzymywanego to przychod/koszt.
- **Przeslanki:**
  - `input.invoice.category_code == "CRYPTO_EXCHANGE"`
  - `input.invoice.crypto_from != input.invoice.crypto_to`
- **Oczekiwany rezultat:**
  - `taxable_event: true` — wymiana krypto-krypto to zdarzenie podatkowe
  - `revenue_from_exchange: value_of_crypto_received`
  - `cost_of_exchange: acquisition_cost_of_crypto_given`
  - `exchange_gain: max(0, revenue_from_exchange - cost_of_exchange)` — przychod
  - `exchange_loss: max(0, cost_of_exchange - revenue_from_exchange)` — KUP
- **Podstawa prawna:** Art. 14 PIT, Art. 22 PIT, interpretacja KIS 0112-KDIL2-1.4011.136.2022.2
- **Przypadki brzegowe:** Exchange na stablecoina → nie konczy obowiazku podatkowego (dalej krypto). Exchange na FIAT → zakonczenie inwestycji, rozliczenie.
- **Priorytet:** 1249

### P1250: `sc_crypto_tax_reporting_sc` ★
- **Cel biznesowy:** Raportowanie transakcji krypto do US — PIT-38 (nie PIT-36!) dla zyskow ze zbycia krypto. Dotyczy wspolnika, nie spolki.
- **Przeslanki:**
  - `p.has_crypto_transactions == true`
  - Rok podatkowy zakonczony
- **Oczekiwany rezultat:**
  - `crypto_tax_form: "PIT-38"` — odrebne zeznanie od PIT z dzialalnosci
  - `crypto_tax_rate: 19%` — jednolita stawka
  - `crypto_loss_carry_forward: "5_LAT"` — strata z krypto do odliczenia w kolejnych latach
  - `_info: "Zyski z krypto — PIT-38, nie PIT-36"`
- **Podstawa prawna:** Art. 30b ust. 1 pkt 1 (zbycie krypto), Art. 45 ust. 1a pkt 1 PIT
- **Przypadki brzegowe:** Wydatki na gieldzie (prowizje) → KUP. Mining w ramach SC → przychod z dzialalnosci (PIT-36), nie z krypto (PIT-38).
- **Priorytet:** 1250

---

## Obszar 15: Upadlosc konsumencka wspolnika

> **Istniejace:** BRAK — calkowicie nowy obszar
> **Nowe reguly:** P1251-P1255

### P1251: `sc_partner_consumer_bankruptcy_sc` ★★
- **Cel biznesowy:** Ogloszenie upadlosci konsumenckiej przez wspolnika — czy powoduje rozwiazanie spolki? TAK — Art. 874 pkt 2 KC. Upadly NIE moze byc przedsiebiorca.
- **Przeslanki:**
  - `p.bankruptcy_status == "CONSUMER_BANKRUPTCY"`
  - `p.bankruptcy_date != null`
- **Oczekiwany rezultat:**
  - `partnership_dissolution_triggered: true` — rozwiazanie spolki
  - `dissolution_date: <data upadlosci>`
  - `bankrupt_partner_rights: "TRANSFERRED_TO_TRUSTEE"` — prawa majatkowe wspolnika przechodza na syndyka
  - `joint_liability_remaining: true` — pozostali wspolnicy odpowiadaja za dlugi spolki
- **Podstawa prawna:** Art. 874 pkt 2 KC, Art. 185-186, Art. 491 ustawy Prawo upadlosciowe
- **Zaleznosci:** Aktywuje caly blok P920-P929 (likwidacja).
- **Przypadki brzegowe:** Upadlosc jednego wspolnika → spolka rozwiazana (chyba ze umowa mowi inaczej — ale tylko do 2 wspolnikow). Upadlosc z mozliwoscia zawarcia ukladu → spolka moze trwac.
- **Priorytet:** 1251

### P1252: `sc_bankruptcy_trustee_share_sc` ★★
- **Cel biznesowy:** Syndyk przejmuje udzial upadlego wspolnika — zarzadza jego prawami majatkowymi, ale NIE moze prowadzic spraw spolki.
- **Przeslanki:**
  - `p.bankruptcy_status == "CONSUMER_BANKRUPTCY"`
  - `p.bankruptcy_trustee_appointed == true`
- **Oczekiwany rezultat:**
  - `trustee_controls: ["PROFIT_RIGHTS", "LIQUIDATION_SHARE"]` — tylko majatkowe
  - `trustee_cannot: ["DAY_TO_DAY_MANAGEMENT", "NEW_CONTRACTS"]` — bez prowadzenia spraw
  - `partnership_operations: "FROZEN"` — spolka nie moze normalnie dzialac
  - `_warning: "Syndyk zarzadza udzialem — spolka w likwidacji"`
- **Podstawa prawna:** Art. 173-175, 185 Prawa upadlosciowego, Art. 870 KC
- **Przypadki brzegowe:** Syndyk moze sprzedac udzial upadlego osobie trzeciej — za zgoda s Sadu.
- **Priorytet:** 1252

### P1253: `sc_bankruptcy_discharge_effect_sc` ★
- **Cel biznesowy:** Po zakonczeniu upadlosci i umorzeniu dlugow (tzw. "oddluzenie") — czy byly wspolnik moze ponownie zostac przedsiebiorca? TAK, po uprawomocnieniu.
- **Przeslanki:**
  - `p.bankruptcy_status == "DISCHARGED"`
  - `p.bankruptcy_discharge_date != null`
- **Oczekiwany rezultat:**
  - `ceidg_eligibility: "RESTORED"` — moze ponownie zarejestrowac JDG
  - `sc_eligibility: "RESTORED"` — moze ponownie byc wspolnikiem
  - `prior_partnership_debts: "DISCHARGED"` — dlugi spolki sprzed upadlosci umorzone wzgledem upadlego
  - `_warning: "Oddluzenie nie zwalnia pozostalych wspolnikow z dlugow spolki"`
- **Podstawa prawna:** Art. 369-370¹ Prawa upadlosciowego
- **Przypadki brzegowe:** Oddluzenie tylko wzgledem upadlego — pozostali wspolnicy nadal odpowiadaja solidarnie.
- **Priorytet:** 1253

### P1254: `sc_bankruptcy_employee_impact_sc` ★
- **Cel biznesowy:** Upadlosc wspolnika → rozwiazanie spolki → zwolnienie pracownikow. Obowiazek wyplaty odpraw i swiadczen.
- **Przeslanki:**
  - `input.partnership.dissolution_triggered == true` (z powodu upadlosci)
  - `input.partnership.employee_count > 0`
- **Oczekiwany rezultat:**
  - `employee_termination: "FORCE_MAJEURE"` — rozwiazanie umow z powodu likwidacji
  - `severance_pay_required: true` — 1-3 miesieczne wynagrodzenie
  - `fundusz_swiadczen_pracowniczych: true` — roszczenia pracownikow z FGSP
  - `_warning: "Rozwiazanie spolki — obowiazki wzgledem pracownikow"`
- **Podstawa prawna:** Art. 36¹¹ KP (zwolnienia grupowe), Ustawa o ochronie roszczen pracowniczych
- **Przypadki brzegowe:** Pracownicy moga dochodzic roszczen od wszystkich wspolnikow solidarnie.
- **Priorytet:** 1254

### P1255: `sc_bankruptcy_arrangement_sc` ★
- **Cel biznesowy:** Postepowanie ukladowe (restrukturyzacja) zamiast upadlosci likwidacyjnej — spolka moze kontynuowac dzialalnosc.
- **Przeslanki:**
  - `input.partnership.restructuring_type == "ARRANGEMENT"`
  - Sad zatwierdzil uklad z wierzycielami
- **Oczekiwany rezultat:**
  - `partnership_continues: true` — spolka dziala dalej
  - `debt_reduction: uklad przewiduje redukcje dlugu`
  - `pit_effect: "DEBT_FORGIVENESS_IS_REVENUE"` — umorzona czesc dlugu = przychod podatkowy!
  - `_warning: "Umorzenie dlugu w ukladzie to przychod — podatek do zaplaty"`
- **Podstawa prawna:** Art. 14 ust. 2 pkt 6 PIT (umorzone zobowiazanie = przychod), Prawo restrukturyzacyjne
- **Przypadki brzegowe:** Uklad czesciowy (redukcja 30% dlugu) → 30% × wartosc dlugu to przychod. Uklad z wierzycielami zagranicznymi → dodatkowe komplikacje.
- **Priorytet:** 1255

---

## Diagram integracji — gdzie nowe reguly wpinaja sie w lancuch

```
SC_DEFINITIVE_REGO_PLAN.md + SC_EXPANSION_14_AREAS.md
|
+- BLOK 0: RISK
|   +-- P1220 (AML 15k EUR) [NOWY]
|   +-- P1222 (AML suspicious) [NOWY]
|   +-- P1223 (AML whitelist) [NOWY]
|   +-- P1225 (GDPR processor) [NOWY]
|   +-- P1245 (leasing leaseback) [NOWY]
|
+- BLOK 3: CROSSBORDER — ROZBUDOWANY
|   +-- P1230-P1235 (non-resident partner) [NOWY]
|   +-- P1234 (non-EU partner VAT) [NOWY]
|
+- BLOK 7: PIT FUNDAMENT
|   +-- P1236-P1240 (EU grants) [NOWY]
|
+- BLOK 12: ULGI
|   +-- P1238 (grant depreciation exclusion) [NOWY]
|
+- BLOK 14: KSIEGOWOSC
|   +-- P1241-P1244 (leasing) [NOWY]
|   +-- P1248 (crypto holding) [NOWY]
|
+- BLOK 15: ODPOWIEDZIALNOSC — ROZBUDOWANY
|   +-- P1174-P1178 (enforcement) [NOWY]
|   +-- P1179-P1183 (spouse liability) [NOWY]
|   +-- P1190-P1193 (bailiff share seizure) [NOWY]
|
+- BLOK 16A: AUDIT — NOWY BLOK
|   +-- P1184-P1189 (tax audit) [NOWY]
|
+- BLOK 16B: LOCAL TAXES — NOWY BLOK
|   +-- P1194-P1197 (property tax) [NOWY]
|
+- BLOK 16C: EXCISE — NOWY BLOK
|   +-- P1198-P1201 (excise duty) [NOWY]
|
+- BLOK 16D: AML — NOWY BLOK
|   +-- P1221, P1224 (AML beneficial owner, risk) [NOWY]
|
+- BLOK 16E: GDPR — NOWY BLOK
|   +-- P1226-P1229 (GDPR employee, retention, transfer, fines) [NOWY]
|
+- BLOK 16F: CRYPTO — NOWY BLOK
|   +-- P1246-P1250 (crypto payments/exchange/reporting) [NOWY]
|
+- BLOK 16G: BANKRUPTCY — NOWY BLOK
|   +-- P1251-P1255 (partner consumer bankruptcy) [NOWY]
```

---

## Cross-Reference: Nowe reguly → Podstawa prawna

| Regula | Obszar | Podstawa prawna |
|--------|--------|-----------------|
| P1174-P1178 | Egzekucja/regres | Art. 864 KC, Art. 376 KC, Art. 778 KPC, Art. 26-27 ustawy o komornikach |
| P1179-P1183 | Malzonek wspolnika | Art. 31-41 KRO, Art. 6 PIT, Art. 86a VAT, Art. 872 KC |
| P1184-P1189 | Kontrola skarbowa | Art. 80-83, 70c, 81 Ordynacji podatkowej, Art. 53-56 KKS |
| P1190-P1193 | Zajecie udzialu | Art. 870 KC, Art. 831, 895-909, 948 KPC |
| P1194-P1197 | Podatek od nieruchomosci | Ustawa o podatkach i oplatach lokalnych, Art. 2-6, Art. 7 |
| P1198-P1201 | Akcyza | Ustawa o podatku akcyzowym, Art. 8, 10, 13, 21, 29a, 40-50, 88-89 |
| P1220-P1224 | AML | Art. 35, 55-66, 72, 74-77 ustawy o AML, Art. 96b VAT |
| P1225-P1229 | RODO | Art. 5, 6, 9, 30, 33-34, 44-49, 83 RODO, Art. 22 KP |
| P1230-P1235 | Cudzoziemiec | Art. 3 ust. 2a, Art. 4a, 29, 30f PIT, Art. 28b VAT |
| P1236-P1240 | Fundusze UE | Art. 14 ust. 2 pkt 2, Art. 21 ust. 1 pkt 46-47c, Art. 23 ust. 1 pkt 45 PIT |
| P1241-P1245 | Leasing | Art. 23a-23b PIT (op.), Art. 23f-23j PIT (fin.), Art. 23 ust. 1 pkt 47a PIT |
| P1246-P1250 | Kryptowaluty | Art. 14, 22, 24c, 30b PIT, Art. 28 UoR, Art. 29a VAT |
| P1251-P1255 | Upadlosc | Art. 874 KC, Art. 173-186, 369-370, 491 Prawa upadlosciowego |
| P562-P567 | Transakcje wspolnik-spolka | Art. 5, 15 VAT, Art. 22-23, 23m, 10, 14 PIT, Art. 119a OP |

---

> **Koniec dokumentu.** Ten plik uzupelnia SC_DEFINITIVE_REGO_PLAN.md i SC_EXPANSION_14_AREAS.md o 15 zaawansowanych, czesto pomijanych obszarow.
> **Lacznie nowych regul:** ~80 szczegolowo opisanych ze wszystkimi elementami (cel, przeslanki, rezultat, podstawa prawna, zaleznosci, przypadki brzegowe, priorytet).
> **Nowe pakiety:** `sc.enforcement`, `sc.audit`, `sc.local_taxes`, `sc.excise`, `sc.aml`, `sc.gdpr`, `sc.crypto`, `sc.bankruptcy`.
> **Laczny stan SC po polaczeniu:** ~550 (oryginalne) + ~85 (ekspansja 14) + ~80 (advanced gaps) = **~715 regul ENTERPRISE**.
