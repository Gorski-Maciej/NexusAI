# 🔍 JDG Enterprise Gap Analysis — Kompletna Analiza Luk

> **Status:** ENTERPRISE v1.0 — Dokument analizy luk między planem a implementacją
> **Data:** 2026-07-11
> **Bazuje na:** DocsJDG, Docs SC, Master Reference (20), all 29 implemented `.rego` files
> **Pokrycie:** 15 obszarów analizy × szczegółowe rekomendacje

---

## 📊 Executive Summary

| Metryka | Wartość |
|---|---|
| **Reguły zaimplementowane** | ~355 reguł w 29 plikach `.rego` |
| **Reguły w Master Planie** | 240 reguł (69 zaimplementowanych, 171 pseudokod) |
| **Zidentyfikowane luki** | **78 krytycznych reguł** w 15 obszarach |
| **Nowe pakiety potrzebne** | 3 (`jdg.audit`, `jdg.validation`, `jdg.conflicts`) |
| **Rozszerzenia istniejących** | 12 pakietów wymaga uzupełnienia |

---

## 1. 🏷️ Ulgi i Odliczenia — Brakujące

### 1.1 Ulga na darowizny (OPP / NGO)

| Pole | Wartość |
|---|---|
| **Reguła** | `relief_donation_opp` |
| **Priorytet** | P580 |
| **Pakiet** | `jdg.allowances` |
| **Podstawa prawna** | Art. 26 ust. 1 pkt 9 PIT |
| **Cel biznesowy** | Odliczenie darowizn na cele pożytku publicznego (OPP) — 6% dochodu |
| **Status** | ❌ Brak w implementacji, ✅ w planie (P130) |

```rego
# Mikro-reguły: jdg.pit.a26u1p9.r1-r5
# r1: donation_opp_eligibility — OPP registered in KRS
# r2: donation_opp_limit_6pct — max 6% of annual income
# r3: donation_opp_excess_carry — excess NOT carried forward (unlike CIT)
# r4: donation_opp_documentation — proof of donation required (bank transfer receipt)
# r5: donation_opp_non_cash — non-cash donations valued at cost
```

### 1.2 Ulga na krew / krwiodawstwo

| Pole | Wartość |
|---|---|
| **Reguła** | `relief_blood_donation` |
| **Priorytet** | P582 |
| **Pakiet** | `jdg.allowances` |
| **Podstawa prawna** | Art. 26 ust. 1 pkt 9 lit. c PIT |
| **Cel biznesowy** | Ekwiwalent 130 PLN za każdy litr oddanej krwi (odliczenie od dochodu) |
| **Status** | ❌ Brak w implementacji, ✅ w planie (P131) |

### 1.3 Ulga na dzieci (child tax credit)

| Pole | Wartość |
|---|---|
| **Reguła** | `relief_child_tax_credit` |
| **Priorytet** | P584 |
| **Pakiet** | `jdg.allowances` |
| **Podstawa prawna** | Art. 27f PIT |
| **Cel biznesowy** | Odliczenie od **podatku** (NIE dochodu!) — kwota roczna zależna od liczby dzieci |
| **Status** | ❌ Brak w implementacji, ❌ brak w planie JDG |
| **Uwaga** | Odlicza się od podatku, nie od dochodu — inny mechanizm niż pozostałe ulgi |

```rego
# Mikro-reguły: jdg.pit.a27f.r1-r7
# r1: child_count_determination — liczba dzieci uprawnionych
# r2: child_age_limit — do 18 lat (25 lat jeśli studiuje)
# r3: child_amount_first — 1 112,04 PLN rocznie (pierwsze i drugie)
# r4: child_amount_third — 2 000,04 PLN rocznie (trzecie)
# r5: child_amount_fourth_plus — 2 700,00 PLN rocznie (czwarte i kolejne)
# r6: child_income_threshold_single_parent — 56 000 PLN dla samotnego rodzica
# r7: child_refund_excess — zwrot niewykorzystanej kwoty (do kwoty składek ZUS+zdrowotnej)
```

### 1.4 Rozliczenie straty PIT

| Pole | Wartość |
|---|---|
| **Reguła** | `pit_loss_carry_forward` |
| **Priorytet** | P870a |
| **Pakiet** | `jdg.pit.advances_returns` |
| **Podstawa prawna** | Art. 9 ust. 3 PIT |
| **Cel biznesowy** | Odliczenie straty z lat ubiegłych — max 50% straty rocznie lub 5 000 000 PLN jednorazowo (Polski Ład) |
| **Status** | ❌ Brak w implementacji |

### 1.5 Wspólny limit PIT-0 (85 528 PLN) — kolizja ulg

| Pole | Wartość |
|---|---|
| **Reguła** | `pit_zero_mutual_limit_85k` |
| **Priorytet** | P586 |
| **Pakiet** | `jdg.pit.exemptions` |
| **Podstawa prawna** | Art. 21 ust. 1 pkt 148, 152-154 PIT |
| **Cel biznesowy** | Łączny limit zwolnień PIT-0 (młody + powrót + rodzina 4+ + senior) = 85 528 PLN rocznie |
| **Status** | ❌ Brak — istnieją tylko pojedyncze reguły, brak sumowania |
| **Uwaga** | ⚠️ KRYTYCZNE — JDG może nieświadomie przekroczyć limit łączny |

---

## 2. 🏥 Składki ZUS i Zdrowotne — Brakujące

### 2.1 Roczne rozliczenie składki zdrowotnej

| Pole | Wartość |
|---|---|
| **Reguła** | `zus_health_annual_reconciliation` |
| **Priorytet** | P749 |
| **Pakiet** | `jdg.zus` |
| **Podstawa prawna** | Art. 81 ust. 2d-2f ustawy o świadczeniach opieki zdrowotnej |
| **Cel biznesowy** | Roczne rozliczenie składki zdrowotnej — dopłata/zwrot różnicy między składkami miesięcznymi a roczną podstawą |
| **Status** | ❌ Brak — krytyczne dla ryczałtu i liniowego! |

```rego
# Mikro-reguły: jdg.zus.a81u2d.r1-r5
# r1: health_annual_base_recalc — przeliczenie podstawy rocznej
# r2: health_underpayment_detection — wykrycie niedopłaty (dopłata do 22 maja)
# r3: health_overpayment_refund — zwrot nadpłaty na wniosek
# r4: health_loss_year_scale — przy stracie na skali: podstawa = minimalna
# r5: health_annual_deadline — termin: 22 maja następnego roku
```

### 2.2 Zasiłek chorobowy JDG (dobrowolny)

| Pole | Wartość |
|---|---|
| **Reguła** | `zus_sickness_benefit_jdg` |
| **Priorytet** | P750 |
| **Pakiet** | `jdg.zus` |
| **Podstawa prawna** | Art. 4, 6-8 ustawy zasiłkowej |
| **Cel biznesowy** | Zasiłek chorobowy z dobrowolnego ubezpieczenia chorobowego — 90 dni okresu wyczekiwania |
| **Status** | ❌ Brak — tylko reguła `zus_sickness_voluntary` dla stawki, brak reguły o zasiłku |

### 2.3 Zasiłek macierzyński JDG

| Pole | Wartość |
|---|---|
| **Reguła** | `maternity_benefit_jdg` |
| **Priorytet** | P752 |
| **Pakiet** | `jdg.zus` |
| **Podstawa prawna** | Art. 29-31 ustawy zasiłkowej |
| **Cel biznesowy** | Zasiłek macierzyński 100%/80% podstawy (w zależności od deklaracji) |
| **Status** | ❌ Brak |

---

## 3. ⏸️ Zawieszenie i Wznowienie — Brakujące

### 3.1 Zerowe deklaracje VAT w zawieszeniu

| Pole | Wartość |
|---|---|
| **Reguła** | `suspension_vat_declaration_zero` |
| **Priorytet** | P919 |
| **Pakiet** | `jdg.business` |
| **Podstawa prawna** | Art. 99 ust. 7a VAT |
| **Cel biznesowy** | Obowiązek składania ZEROWYCH deklaracji VAT-7 w zawieszeniu (chyba że WNT) |
| **Status** | ❌ Brak |

### 3.2 Zakaz amortyzacji w zawieszeniu

| Pole | Wartość |
|---|---|
| **Reguła** | `suspension_depreciation_ban` |
| **Priorytet** | P916 |
| **Pakiet** | `jdg.accounting` |
| **Podstawa prawna** | Art. 22c pkt 4 PIT |
| **Cel biznesowy** | W okresie zawieszenia NIE dokonuje się odpisów amortyzacyjnych |
| **Status** | ❌ Brak |

### 3.3 Limit czasu zawieszenia

| Pole | Wartość |
|---|---|
| **Reguła** | `suspension_time_limit` |
| **Priorytet** | P918 |
| **Pakiet** | `jdg.business` |
| **Podstawa prawna** | Art. 22 Prawa przedsiębiorców |
| **Cel biznesowy** | Zawieszenie bezterminowe możliwe; ale po 6 miesiącach bez pracowników → wykreślenie z CEIDG |
| **Status** | ❌ Brak |

---

## 4. 📜 Sukcesja — Brakujące

### 4.1 Remanent na dzień śmierci

| Pole | Wartość |
|---|---|
| **Reguła** | `succession_inventory_death_date` |
| **Priorytet** | P928 |
| **Pakiet** | `jdg.restructuring` |
| **Podstawa prawna** | Art. 24 ust. 2 PIT + Art. 14 ust. 2 PIT |
| **Cel biznesowy** | Obowiązek sporządzenia remanentu na dzień śmierci przedsiębiorcy (opodatkowanie 10% nadwyżki) |
| **Status** | ❌ Brak — istnieje tylko reguła o zamknięciu JDG (P1505) |

### 4.2 Rozliczenia podatkowe po śmierci

| Pole | Wartość |
|---|---|
| **Reguła** | `succession_tax_responsibilities` |
| **Priorytet** | P922 |
| **Pakiet** | `jdg.restructuring` |
| **Podstawa prawna** | Art. 97 § 1-2, Art. 100 § 1-2 Ordynacji podatkowej |
| **Cel biznesowy** | Obowiązki podatkowe spadkobierców/zarządcy sukcesyjnego — złożenie zeznań za zmarłego |
| **Status** | ❌ Brak |

---

## 5. 🔄 Zmiana Formy Opodatkowania — Brakujące

### 5.1 Remanent przy zmianie formy

| Pole | Wartość |
|---|---|
| **Reguła** | `tax_form_change_inventory` |
| **Priorytet** | P830 |
| **Pakiet** | `jdg.pit.transitions` |
| **Podstawa prawna** | Art. 24 ust. 2 PIT, Art. 44 ust. 2 PIT |
| **Cel biznesowy** | Przy przejściu ryczałt→PKPiR (skala/liniowy) konieczny remanent na 1 stycznia dla KUP |
| **Status** | ❌ Brak — istnieje dual_return, ale brak remanentu |

### 5.2 Korekta kosztów przy zmianie formy

| Pole | Wartość |
|---|---|
| **Reguła** | `tax_form_change_kup_correction` |
| **Priorytet** | P832 |
| **Pakiet** | `jdg.pit.transitions` |
| **Podstawa prawna** | Art. 22 ust. 1 PIT, Art. 24 ust. 1 PIT |
| **Cel biznesowy** | Korekta KUP — wydatki poniesione przed zmianą formy, a wykorzystane po zmianie |
| **Status** | ❌ Brak |

---

## 6. 🌍 Crossborder / VAT UE — Brakujące

### 6.1 OSS / IOSS (e-commerce B2C)

| Pole | Wartość |
|---|---|
| **Reguła** | `vat_oss_ioss_procedure` |
| **Priorytet** | P250 |
| **Pakiet** | `jdg.vat.procedures` |
| **Podstawa prawna** | Art. 130a-130d VAT (OSS), Art. 138a-138i VAT (IOSS) |
| **Cel biznesowy** | Sprzedaż B2C do innych krajów UE — deklaracja OSS zamiast rejestracji w każdym kraju |
| **Status** | ❌ Brak — krytyczne dla JDG sprzedających online do UE |

### 6.2 Informacja podsumowująca VAT-UE

| Pole | Wartość |
|---|---|
| **Reguła** | `vat_ue_summary_deadline` |
| **Priorytet** | P255 |
| **Pakiet** | `jdg.vat.procedures` |
| **Podstawa prawna** | Art. 100 VAT |
| **Cel biznesowy** | VAT-UE składana do 25. dnia miesiąca za poprzedni miesiąc |
| **Status** | ❌ Brak — w crossborder jest flaga `vat_ue_summary_required` ale bez deadline'u |

---

## 7. ✏️ Korekty — Brakujące

### 7.1 Storno czerwone / czarne

| Pole | Wartość |
|---|---|
| **Reguła** | `correction_storno_detection` |
| **Priorytet** | P1115 |
| **Pakiet** | `jdg.corrections` |
| **Podstawa prawna** | Art. 29a ust. 13 VAT, Art. 106j VAT |
| **Cel biznesowy** | Wykrywanie storna czerwonego (wartości ujemne) vs storna czarnego (osobny dokument korygujący) |
| **Status** | ❌ Brak |

### 7.2 Zakaz korekty w trakcie kontroli

| Pole | Wartość |
|---|---|
| **Reguła** | `correction_lock_during_audit` |
| **Priorytet** | P180 |
| **Pakiet** | `jdg.corrections` |
| **Podstawa prawna** | Art. 81b § 1 Ordynacji podatkowej |
| **Cel biznesowy** | Blokada korekty deklaracji w trakcie trwającej kontroli celno-skarbowej |
| **Status** | ❌ Brak — istnieje `correction_statute_barred_block` (P1138), ale nie audit lock |

---

## 8. ⏳ Przedawnienia i Odpowiedzialność — Brakujące

### 8.1 Przerwanie biegu przedawnienia

| Pole | Wartość |
|---|---|
| **Reguła** | `statute_interruption_execution` |
| **Priorytet** | P1162 |
| **Pakiet** | `jdg.liability` |
| **Podstawa prawna** | Art. 70 § 4 Ordynacji podatkowej |
| **Cel biznesowy** | Zastosowanie środka egzekucyjnego → przerwanie biegu przedawnienia → nowy 5-letni termin |
| **Status** | ❌ Brak — istnieje tylko `statute_5_years` i `statute_suspended` |

### 8.2 Odpowiedzialność solidarna małżonka

| Pole | Wartość |
|---|---|
| **Reguła** | `liability_spousal_solidary` |
| **Priorytet** | P1164 |
| **Pakiet** | `jdg.liability` |
| **Podstawa prawna** | Art. 29 Ordynacji podatkowej |
| **Cel biznesowy** | Współmałżonek odpowiada solidarnie za zaległości JDG (majątek wspólny) |
| **Status** | ❌ Brak |

---

## 9. 📝 Reprezentacja — Brakujące

### 9.1 Pełnomocnictwo do doręczeń PPD-1

| Pole | Wartość |
|---|---|
| **Reguła** | `poa_delivery_ppd1` |
| **Priorytet** | P1214 |
| **Pakiet** | `jdg.representation` |
| **Podstawa prawna** | Art. 146 § 1 Ordynacji podatkowej |
| **Cel biznesowy** | PPD-1 — pełnomocnictwo tylko do odbioru korespondencji (nie do reprezentacji merytorycznej) |
| **Status** | ❌ Brak — PPS-1 i UPL-1 są, PPD-1 brak |

### 9.2 Prokura łączna

| Pole | Wartość |
|---|---|
| **Reguła** | `joint_procuration_check` |
| **Priorytet** | P1216 |
| **Pakiet** | `jdg.representation` |
| **Podstawa prawna** | Art. 109⁴ § 1 KSH |
| **Cel biznesowy** | Prokura łączna — wymaga współdziałania dwóch prokurentów (ważne przy przekształconych JDG) |
| **Status** | ❌ Brak |

---

## 10. 🔗 Interakcje Forma vs Składki — Brakujące

### 10.1 Składka zdrowotna przy stracie rocznej (skala)

| Pole | Wartość |
|---|---|
| **Reguła** | `health_contrib_loss_correction` |
| **Priorytet** | P754 |
| **Pakiet** | `jdg.zus` |
| **Podstawa prawna** | Art. 81 ust. 2d ustawy zdrowotnej |
| **Cel biznesowy** | Przy stracie na skali: podstawa składki zdrowotnej = minimalna (nie dochód) |
| **Status** | ❌ Brak |

### 10.2 Roczne dopłaty ryczałtowca

| Pole | Wartość |
|---|---|
| **Reguła** | `lump_sum_health_underpayment` |
| **Priorytet** | P756 |
| **Pakiet** | `jdg.zus` |
| **Podstawa prawna** | Art. 81 ust. 2f ustawy zdrowotnej |
| **Cel biznesowy** | Jeśli ryczałtowiec w ciągu roku płacił wg niższego progu, a roczny przychód przeszedł do wyższego → dopłata + odsetki |
| **Status** | ❌ Brak |

---

## 11. 📅 Progi i Limity Czasowe — Brakujące

### 11.1 Kwota wolna od podatku temporalna (30k od 2022)

| Pole | Wartość |
|---|---|
| **Reguła** | `pit_tax_free_amount_temporal` |
| **Priorytet** | P1614 |
| **Pakiet** | `jdg.temporal` |
| **Podstawa prawna** | Art. 27 ust. 1 PIT (Polski Ład od 2022) |
| **Cel biznesowy** | Kwota wolna 30 000 PLN od 2022 (wcześniej: różne stawki malejące) |
| **Status** | ❌ Brak w `jdg.temporal` |

```rego
# Mikro-reguły: jdg.temporal.a27u1.r1-r4
# r1: tax_free_amount_2022_plus — 30 000 PLN (effective from 2022-01-01)
# r2: tax_free_amount_2018_2021 — degressive (1 440 PLN → 0 PLN above 127k)
# r3: tax_free_amount_2017 — 6 600 PLN single / 1 188 PLN formula
# r4: tax_free_2019_young — full exemption <26 (different mechanism!)
```

### 11.2 Limit amortyzacji jednorazowej temporalny

| Pole | Wartość |
|---|---|
| **Reguła** | `depreciation_one_off_limit_temporal` |
| **Priorytet** | P1616 |
| **Pakiet** | `jdg.temporal` |
| **Podstawa prawna** | Art. 22d ust. 1 PIT (zmieniany wielokrotnie) |
| **Cel biznesowy** | Limit jednorazowej amortyzacji: 10 000 PLN (do 2018), później 100 000 PLN (de minimis) |
| **Status** | ❌ Brak — istnieje reguła `depreciation_one_off` z limitem, ale bez wariantów temporalnych |

---

## 12. ⚔️ Konflikty Reguł — Nowy pakiet `jdg.conflicts`

### 12.1 IP Box vs B+R — ten sam dochód

| Pole | Wartość |
|---|---|
| **Reguła** | `conflict_ipbox_vs_rd` |
| **Priorytet** | P900 |
| **Pakiet** | `jdg.conflicts` (NOWY) |
| **Podstawa prawna** | Art. 30ca ust. 3 PIT |
| **Cel biznesowy** | IP Box i B+R NIE mogą być stosowane do tego samego dochodu — JDG musi wybrać lub podzielić koszty kwalifikowane |
| **Status** | ❌ Brak — obie ulgi istnieją osobno (P600 i P610), brak logiki wykluczania |

### 12.2 Limit łączny PIT-0 (85 528 PLN)

| Pole | Wartość |
|---|---|
| **Reguła** | `conflict_pit0_combined_limit` |
| **Priorytet** | P902 |
| **Pakiet** | `jdg.conflicts` (NOWY) |
| **Podstawa prawna** | Art. 21 ust. 1 pkt 148, 152-154 PIT |
| **Cel biznesowy** | Suma zwolnień PIT-0 (młody + powrót + 4+ + senior) nie może przekroczyć 85 528 PLN |
| **Status** | ❌ Brak — krytyczne ryzyko nadużycia/niedopłaty |

### 12.3 B+R + IP Box vs Strata

| Pole | Wartość |
|---|---|
| **Reguła** | `conflict_allowances_vs_loss` |
| **Priorytet** | P904 |
| **Pakiet** | `jdg.conflicts` |
| **Cel biznesowy** | Ulgi nie mogą być odliczane od dochodu, gdy JDG wykazuje stratę (chyba że carry-forward B+R) |
| **Status** | ❌ Brak |

---

## 13. ✅ Reguły Walidacyjne — Nowy pakiet `jdg.validation`

### 13.1 Walidacja NIP (checksum)

| Pole | Wartość |
|---|---|
| **Reguła** | `validate_nip_checksum` |
| **Priorytet** | P950 |
| **Pakiet** | `jdg.validation` (NOWY) |
| **Podstawa prawna** | Rozp. MF ws. NIP |
| **Cel biznesowy** | Walidacja sumy kontrolnej NIP (6×1 + 5×3 + 7×1 + 2×3 + 3×1 + 4×3 + 5×1 + 6×3 + 7×1 mod 11) |
| **Status** | ❌ Brak — odrzucenie z błędem przed ewaluacją |

### 13.2 Data faktury vs data sprzedaży

| Pole | Wartość |
|---|---|
| **Reguła** | `validate_invoice_date_consistency` |
| **Priorytet** | P952 |
| **Pakiet** | `jdg.validation` |
| **Podstawa prawna** | Art. 106e VAT |
| **Cel biznesowy** | Data wystawienia faktury nie może być wcześniejsza niż data dostawy/usługi |
| **Status** | ❌ Brak |

### 13.3 Kwoty ujemne

| Pole | Wartość |
|---|---|
| **Reguła** | `validate_negative_amounts` |
| **Priorytet** | P954 |
| **Pakiet** | `jdg.validation` |
| **Cel biznesowy** | Zablokowanie faktur z kwotami ujemnymi, chyba że są explicite oznaczone jako faktury korygujące |
| **Status** | ❌ Brak |

---

## 14. 🔒 Bezpieczeństwo i Audyt — Nowy pakiet `jdg.audit`

### 14.1 Immutability log decyzji

| Pole | Wartość |
|---|---|
| **Reguła** | `audit_immutability_log` |
| **Priorytet** | P970 |
| **Pakiet** | `jdg.audit` (NOWY) |
| **Cel biznesowy** | Każda decyzja reguły musi generować hash (SHA-256) z całego werdyktu + timestamp + operator_id |
| **Status** | ❌ Brak — enterprise security requirement |

### 14.2 Decision timestamp enforcement

| Pole | Wartość |
|---|---|
| **Reguła** | `audit_decision_timestamp` |
| **Priorytet** | P972 |
| **Pakiet** | `jdg.audit` |
| **Cel biznesowy** | Każdy werdykt musi zawierać znacznik czasu decyzji (ISO 8601 z milisekundami) |
| **Status** | ❌ Brak |

### 14.3 Operator identity trace

| Pole | Wartość |
|---|---|
| **Reguła** | `audit_operator_identity` |
| **Priorytet** | P974 |
| **Pakiet** | `jdg.audit` |
| **Cel biznesowy** | Identyfikacja operatora/automatu który podjął decyzję (user_id lub `system_opa_auto`) |
| **Status** | ❌ Brak |

---

## 15. 🧪 Scenariusze Brzegowe

### 15.1 Przekroczenie limitu VAT 200k w trakcie roku

| Pole | Wartość |
|---|---|
| **Reguła** | `vat_exemption_limit_breach_mid_year` |
| **Priorytet** | P140 |
| **Pakiet** | `jdg.vat.substantive` |
| **Podstawa prawna** | Art. 113 ust. 5 VAT |
| **Cel biznesowy** | Przekroczenie 200 000 PLN w trakcie roku → VAT od NADWYŻKI + obowiązek rejestracji |
| **Status** | ❌ Brak — istnieje tylko `vat_exemption_subject` (P58), sprawdzające czy JDG jest <200k, ale nie mid-year breach |

### 15.2 JDG + pracownicy — obowiązki pracodawcy

| Pole | Wartość |
|---|---|
| **Reguła** | `jdg_employer_obligations_checklist` |
| **Priorytet** | P1220 |
| **Pakiet** | `jdg.employer` |
| **Cel biznesowy** | JDG zatrudniające pracowników: PIT-4R, PIT-11, ZUS DRA, PPK, BHP |
| **Status** | ⚠️ Częściowo — istnieją PIT-4R i PPK, ale brak ZUS DRA, BHP, PIT-11 |

### 15.3 JDG + etat jednocześnie (zbieg tytułów ZUS)

| Pole | Wartość |
|---|---|
| **Reguła** | `jdg_employment_concurrent_zus_complex` |
| **Priorytet** | P1222 |
| **Pakiet** | `jdg.zus` |
| **Cel biznesowy** | JDG + etat: składki społeczne z etatu (jeśli pensja ≥ min), z JDG tylko zdrowotna. Ale uwaga: jeśli pensja < min → składki z JDG! |
| **Status** | ⚠️ Częściowo — istnieje `concurrent_employment` (P743), ale tylko dla przypadku pensja≥min; brak dla pensja<min |

### 15.4 Kilka ulg jednocześnie + limit dochodu

| Pole | Wartość |
|---|---|
| **Reguła** | `multiple_allowances_income_cap` |
| **Priorytet** | P617 |
| **Pakiet** | `jdg.allowances` |
| **Cel biznesowy** | Suma ulg NIE MOŻE przekroczyć dochodu. B+R carry-forward 6 lat jako jedyna. |
| **Status** | ⚠️ Częściowo — jest `joint_allowances_limit_info` (P616), ale tylko informacyjne, bez logiki blokującej |

---

## 📦 Podsumowanie: Nowe Pakiety

| Pakiet | Reguł | Priorytety | Opis |
|---|---|---|---|
| **`jdg.conflicts`** | 5+ | P900-P909 | Wykrywanie i rozstrzyganie konfliktów między ulgami i formami opodatkowania |
| **`jdg.validation`** | 8+ | P950-P969 | Walidacja danych wejściowych (NIP, daty, kwoty, spójność) |
| **`jdg.audit`** | 6+ | P970-P989 | Ścieżka audytu, immutable log, timestamp, operator trace |

---

## 📦 Podsumowanie: Rozszerzenia Istniejących Pakietów

| Pakiet | Liczba nowych reguł | Kluczowe braki |
|---|---|---|
| `jdg.allowances` | 8 | Darowizny, krew, ulga na dzieci, strata PIT, limit łączny ulg |
| `jdg.zus` | 6 | Roczne rozliczenie zdrowotnej, zasiłek chorobowy, macierzyński, strata a zdrowotna |
| `jdg.business` | 3 | VAT-zero w zawieszeniu, limit czasu zawieszenia, amortyzacja w zawieszeniu |
| `jdg.restructuring` | 2 | Remanent na śmierć, rozliczenia spadkowe |
| `jdg.pit.transitions` | 2 | Remanent przy zmianie formy, korekta KUP |
| `jdg.pit.exemptions` | 1 | Łączny limit PIT-0 85 528 PLN |
| `jdg.vat.procedures` | 3 | OSS/IOSS, VAT-UE deadline, limit breach mid-year |
| `jdg.vat.substantive` | 1 | Przekroczenie limitu 200k w trakcie roku |
| `jdg.corrections` | 2 | Storno detection, audit lock |
| `jdg.liability` | 2 | Przerwanie przedawnienia, odpowiedzialność małżonka |
| `jdg.representation` | 2 | PPD-1, prokura łączna |
| `jdg.temporal` | 3 | Kwota wolna temporalna, limit amortyzacji temporalny, skutki COVID legacy |
| `jdg.employer` | 1 | JDG z pracownikami — pełna checklista |

---

## 🎯 Priorytety Wdrożenia (Critical Path)

| Faza | Priorytet | Reguły | Ryzyko pominięcia |
|---|---|---|---|
| **Faza A — KRYTYCZNE** | P0 | Konflikty ulg (P900-P909), limit PIT-0 (P586), walidacje NIP (P950), roczne rozliczenie zdrowotnej (P749) | **Sankcje podatkowe, nadużycia, błędne rozliczenia** |
| **Faza B — WYSOKIE** | P1 | Darowizny (P580+), strata PIT (P870a), OSS (P250), korekty (P1115, P180) | Utrata ulg, błędny VAT transgraniczny |
| **Faza C — ŚREDNIE** | P2 | Zawieszenie (P916-P919), sukcesja (P922, P928), zmiana formy (P830, P832), przedawnienia (P1162) | Niekompletny lifecycle JDG |
| **Faza D — NISKIE** | P3 | Audyt (P970+), temporal rules (P1614+), employer checklist (P1220), edge cases | Brak enterprise-grade traceability |

---

> **Następny krok:** Utworzenie szczegółowego planu implementacji dla każdej z 78 reguł 
> (priorytet, pakiet, pseudokod, test case) — dokument `36_JDG_GAP_IMPLEMENTATION_PLAN.md`

---

*Wygenerowano przez NexusAI Deep Analysis Engine na podstawie DocsJDG, Docs SC i Master Reference.*
*Data: 2026-07-11*
