# 🔄 JDG Deduplication Audit — Doc 22 vs Doc 23 vs Doc 28a

> **Status:** Enterprise Dedup Audit v1.0 — Kanoniczna referencja reguł JDG
> **Data:** 2026-07-11
> **Audytowane dokumenty:** `22_JDG_ENTERPRISE_PLAN.md` (145 reguł), `23_JDG_EXPANSION_SUPPLEMENT.md` (69 reguł), `28a_JDG_EDGE_CASES_FULL.md` (127 reguł)
> **Znalezione duplikaty/redundancje:** **18 par** (analizowanych)
> **Unikalne reguły oznaczone jako [DEPRECATED]:** **47**
> **Reguły zachowane jako KANONICZNE:** **18** (głównych decyzji kanonicznych)

---

## 📊 EXECUTIVE SUMMARY

| Metryka | Wartość |
|---|---|
| **Reguły łącznie w 3 dokumentach** | 341 (145 + 69 + 127) |
| **Unikalne reguły po deduplikacji** | **294** (341 − 47) |
| **Duplikaty bezpośrednie** (ta sama domena, różne P-ID/R-ID) | **10 par** |
| **Redundancje funkcjonalne** (różne P-ID, ta sama funkcja) | **5 par** |
| **Sprzeczności wymagające rozstrzygnięcia** | **3 pary** |
| **Reguły kanoniczne (zachowane)** | **18** (głównych decyzji) |
| **Unikalne reguły [DEPRECATED]** | **47** (indywidualnych P-ID/R-ID) |

### Kluczowe wnioski:

1. **Doc 22 i Doc 23 pokrywają się w ~10 obszarach** — Doc 23 dubluje reguły z Doc 22 zamiast je rozszerzać
2. **Doc 28a jest najbardziej szczegółowy** — reguły edge cases mają pełny 10-polowy format
3. **Konieczna jest deduplikacja przed implementacją Rego** — 47 reguł jest nadmiarowych

---

## 🔬 METODOLOGIA

Każda para reguł jest analizowana pod kątem:

| Kryterium | Pytanie |
|-----------|---------|
| **Tożsamość domeny** | Czy reguły dotyczą tego samego artykułu/mechanizmu prawnego? |
| **Tożsamość funkcji** | Czy obie reguły sprawdzają ten sam warunek? |
| **Kompletność** | Która wersja jest bardziej rozwinięta (10-polowy format, przykłady, edge cases)? |
| **Aktualność prawna** | Która wersja jest zgodna z najnowszym stanem prawnym (Polski Ład 2022+)? |

**Werdykt:**
- **KANONICZNA** — wybrana wersja do zachowania
- **[DEPRECATED]** — wersja do usunięcia/oznaczenia jako historyczna

---

## 📋 TABELA DEDUPLIKACJI — 18 PAR

### 🔴 Grupa A: Duplikaty bezpośrednie (ta sama domena, różne ID) — 10 par

---

### A1. P60 (Doc 22) vs P189 (Doc 23): Ulga na złe długi — wierzyciel

| Aspekt | P60 `vat_bad_debt_relief` (Doc 22) | P189 `bad_debt_relief_creditor` (Doc 23) |
|--------|-------------------------------------|------------------------------------------|
| **Dokument** | 22 §3.5.1 | 23 §8 |
| **Priorytet** | P60 | P189 |
| **Przesłanki** | `is_paid == false` + `days_overdue >= 150` | `direction == SALE` + `is_paid == false` + `days_overdue > 90` |
| **Szczegółowość** | 2 przesłanki, 1 rezultat | 5 przesłanek, 3 rezultaty |
| **Edge cases** | ❌ Brak | ❌ Brak |
| **Przykłady ±** | ❌ Brak | ❌ Brak |
| **Uwagi** | P60 mówi o 150 dniach (wierzyciel), P189 mówi o 90 dniach — **różnica w terminach!** | P189 dodaje warunek `direction == SALE` (tylko sprzedaż) |

**Werdykt:** P60 i P189 opisują ten sam mechanizm (wierzyciel — ulga na złe długi), ale z różnymi terminami. **150 dni to poprawny termin dla wierzyciela VAT (Art. 89a).** 90 dni to termin dla dłużnika (Art. 89b) i PIT.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P189** `bad_debt_relief_creditor` (Doc 23) — bardziej szczegółowa, 5 przesłanek, jawny kierunek faktury | **P60** `vat_bad_debt_relief` (Doc 22) — płytsza, brak kierunku faktury |

> ⚠️ Należy zaktualizować P189: termin 150 dni (nie 90). 90 dni dotyczy dłużnika (P184 / R0178).

---

### A2. P58 (Doc 22) vs P59 (Doc 23): Zwolnienie podmiotowe VAT

| Aspekt | P58 `vat_exemption_subject_jdg` (Doc 22) | P59 `subject_exemption_startup_proportion` (Doc 23) |
|--------|-------------------------------------------|-----------------------------------------------------|
| **Dokument** | 22 §3.5.1 | 23 §10 |
| **Priorytet** | P58 | P59 |
| **Domena** | Zwolnienie podmiotowe VAT — ogólne | Zwolnienie podmiotowe VAT — proporcjonalne dla nowych JDG |
| **Szczegółowość** | 3 przesłanki + proporcja dla nowych | 3 przesłanki dedykowane proporcji |
| **Edge cases** | ✅ Wspomina proporcję | ❌ Brak |

**Werdykt:** To NIE są ścisłe duplikaty — P58 jest regułą ogólną, P59 jest pod-regułą dla nowych JDG. **Zalecamy MERGE: P59 jako `else` blok w P58.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P58** `vat_exemption_subject_jdg` (Doc 22) — reguła nadrzędna | **P59** `subject_exemption_startup_proportion` (Doc 23) — wchłonięta jako edge case P58 |

> 📝 P58 rozszerzone o proporcję: jeśli `ceidg_entry_date > "01-01"` → użyj P59 jako `else` bloku.

---

### A3. P724 (Doc 22) vs P734 (Doc 23): Składka zdrowotna ryczałtowca — progi

| Aspekt | P724 `zus_health_lump_sum_jdg` (Doc 22) | P734 `lump_sum_health_tier_lockstep` (Doc 23) |
|--------|-----------------------------------------|-----------------------------------------------|
| **Dokument** | 22 §3.8.5 | 23 §7 |
| **Priorytet** | P724 | P734 |
| **Domena** | Składka zdrowotna ryczałtowca — definicja progów | Składka zdrowotna ryczałtowca — przekroczenie progu |
| **Szczegółowość** | 3 progi kwotowe, stawki | Alert przy przekroczeniu + dopłata |
| **Edge cases** | ❌ Brak | ✅ Dopłata za cały rok wstecz |

**Werdykt:** P724 definiuje progi, P734 obsługuje moment przekroczenia. **MERGE: P734 jako edge case P724.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P724** `zus_health_lump_sum_jdg` (Doc 22) — definicja progów + wchłonięty P734 jako edge case | **P734** `lump_sum_health_tier_lockstep` (Doc 23) — wchłonięta |

---

### A4. P562 (Doc 22) vs P850 (Doc 22): Wydatki mieszane / Home office

| Aspekt | P562 `kup_private_mixed_jdg` (Doc 22 §3.6.7) | P850 `private_mixed_home_office` (Doc 22 §3.9.5) |
|--------|-----------------------------------------------|---------------------------------------------------|
| **Priorytet** | P562 (PIT/KUP) | P850 (accounting) |
| **Domena** | Wydatki mieszane ogólnie | Wydatki mieszane — home office |
| **Szczegółowość** | Ogólna: `private_use_percent > 0` | Specyficzna: home office, proporcja powierzchni |
| **KUP/VAT** | Tylko KUP | KUP + VAT |

**Werdykt:** P562 jest ogólna, P850 jest szczegółowa dla home office. **Zachowaj obie, ale P562 → nadrzędna (ogólna), P850 → podrzędna (home office).**

| 🏆 **KANONICZNA (2)** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P562** `kup_private_mixed_jdg` — ogólna (wszystkie wydatki mieszane) + **P850** `private_mixed_home_office` — szczegółowa (home office) | Brak — obie reguły są potrzebne na różnych poziomach szczegółowości |

> 📝 P562 powinna delegować do P850 gdy `is_home_office == true`.

---

### A5. P720 (Doc 22) vs P738 (Doc 23): Składka zdrowotna skala — brak odliczenia

| Aspekt | P720 `zus_health_scale_jdg` (Doc 22) | P738 `scale_health_deduction_prohibition` (Doc 23) |
|--------|--------------------------------------|---------------------------------------------------|
| **Priorytet** | P720 | P738 |
| **Opis** | "NIE podlega odliczeniu od podatku" | "Bezwzględna blokada odliczenia" |
| **Funkcja** | Definiuje stawkę + skutek | Tylko blokuje odliczenie |

**Werdykt:** P738 jest całkowicie redundantna — P720 już mówi o braku odliczenia. **Usunąć P738.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P720** `zus_health_scale_jdg` (Doc 22) — bardziej kompletna | **P738** `scale_health_deduction_prohibition` (Doc 23) — REDUNDANTNA |

---

### A6. P40-P48 (Doc 22) vs P43-P49 + P190-P191 (Doc 23): Crossborder

| Aspekt | P40-P48 (Doc 22 §3.4) | P43-P49 + P190-P191 (Doc 23 §3) |
|--------|------------------------|--------------------------------|
| **Liczba reguł** | 5 (P40, P41, P42, P45, P48) | 8 (P43, P44, P46, P47, P49, P190, P191) + 1 (P232) |
| **Szczegółowość** | Skrajnie płytkie (1-2 linie na regułę) | Średnia (8-12 linii na regułę) |

**Werdykt:** Doc 23 ROZSZERZA Doc 22 o szczegóły. Doc 22 powinien zostać zaktualizowany o reguły z Doc 23, a nie zachowywać płytkie wersje.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **Doc 23** (P43-P49, P190-P191, P232) — wszystkie 8 reguł | **Doc 22** (P40, P41, P42, P45, P48) — płytkie wersje, zastąpione przez Doc 23 |

---

### A7. P1100-P1114 (Doc 23) vs R0420-R0435 (Doc 28a): Korekty

| Aspekt | P1100-P1114 (Doc 23 §4) | R0420-R0435 (Doc 28a Grupa... pośrednia) |
|--------|--------------------------|------------------------------------------|
| **Liczba reguł** | 8 | 16 |
| **Format** | 10-polowy (średnia głębia) | 10-polowy (pełny ENTERPRISE) |
| **Przykłady** | ❌ Brak | ✅ W Doc 28 (R0420-R0435 są w głównym indeksie) |

**Werdykt:** Doc 28a ma 16 reguł korekt vs 8 w Doc 23. **Doc 28a jest bardziej kompletny.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0420-R0435** (Doc 28a) — 16 reguł, pełny format | **P1100-P1114** (Doc 23) — 8 reguł, zastąpione przez Doc 28a |

---

### A8. P1150-P1166 (Doc 23) vs R0436-R0449 (Doc 28a): Przedawnienia i odpowiedzialność

| Aspekt | P1150-P1166 (Doc 23 §5) | R0436-R0449 (Doc 28a) |
|--------|--------------------------|------------------------|
| **Liczba reguł** | 9 | 14 |
| **Domeny** | Przedawnienia, odsetki, odpowiedzialność | To samo + dodatkowe |

**Werdykt:** Doc 28a pokrywa tę samą domenę z większą liczbą reguł. **Doc 28a jest kanoniczny.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0436-R0449** (Doc 28a) — 14 reguł | **P1150-P1166** (Doc 23) — 9 reguł, zastąpione |

---

### A9. R0546-R0559 (Doc 28a) vs P58/P59/P230-P235 (Doc 22/23): VAT Edge Cases ⚠️ PRZEKLASYFIKOWANE

| Aspekt | R0546-R0559 (Doc 28a Grupa A) | Doc 22/23 VAT |
|--------|-------------------------------|---------------|
| **Liczba reguł** | 14 | ~8 rozproszonych |
| **Format** | Pełny 10-polowy ENTERPRISE | Standardowy (3-6 pól) |
| **Edge cases** | ✅ 4 na regułę | ❌ Brak dla większości |
| **Przykłady ±** | ✅ Wszystkie 14 | ❌ Brak |
| **Rola** | **EDGE CASES** — co się dzieje gdy limit przekroczony, gdy nowa JDG, gdy zmiana formy | **REGUŁY GŁÓWNE** — podstawowe sprawdzenie limitów |

**Werdykt:** R0546-R0559 NIE zastępują P58 (głównej reguły zwolnienia VAT). Są to **edge cases w łańcuchu `else` PO P58**. P58 pozostaje kanoniczny jako reguła główna — R0546-R0559 obsługują przypadki szczególne:
- R0546: przekroczenie limitu w trakcie roku (P58 nie sprawdza *kiedy* nastąpiło przekroczenie)
- R0547: proporcjonalny limit dla nowych JDG (P58 używa pełnego limitu 200k)
- R0548-R0559: pozostałe edge cases VAT

**P59** (proporcja startup) jest już zdeprecjonowana w A2 (wchłonięta do P58 jako sub-reguła). **P230, P231, P235** (szczegółowe reguły podatkowe) są zastąpione przez odpowiednie R0546-R0559.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P58** `vat_exemption_subject_jdg` (Doc 22) — reguła GŁÓWNA + **R0546-R0559** (Doc 28a) — edge cases w `else`-chain po P58 | **P59** (już w A2), **P230, P231, P235** (Doc 22/23) — zastąpione przez R0546-R0559 |

> 📝 **Rekomendacja implementacyjna:** W `policies/jdg/vat/substantive.rego`: `decide := P58`, a R0546-R0559 jako `else :=` bloki w łańcuchu first-match-wins PO P58.

---

### A10. R0560-R0573 (Doc 28a) vs P500-P589 (Doc 22): PIT Edge Cases

| Aspekt | R0560-R0573 (Doc 28a Grupa B) | Doc 22 PIT |
|--------|-------------------------------|------------|
| **Liczba reguł** | 14 | ~30 |
| **Funkcja** | Edge cases: pierwszy rok, ostatni rok, podwójne opodatkowanie, darowizny | Reguły główne: formy, KUP, zaliczki |

**Werdykt:** NIE są to duplikaty — Doc 28a Grupa B to EDGE CASES dla PIT, Doc 22 to reguły GŁÓWNE. **Oba dokumenty są potrzebne.**

| 🏆 **KANONICZNA (2)** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **Doc 22 PIT** (reguły główne) + **Doc 28a Grupa B** (edge cases) | Brak — oba potrzebne |

---

### 🔴 Grupa B: Redundancje funkcjonalne — 5 par

---

### B1. P730 (Doc 23) vs P720/P722/P724/P736 (Doc 22): Macierz mapowania forma→składka

| Aspekt | P730 `health_contribution_rate_matrix` | P720/P722/P724/P736 |
|--------|---------------------------------------|---------------------|
| **Funkcja** | Centralna macierz mapowania | Reguły indywidualne per forma |

**Werdykt:** P730 jest metaregułą — agreguje to, co P720-P736 robią indywidualnie. **P730 jest pomocnicza, nie zastępuje reguł.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P720/P722/P724/P736** (Doc 22) — reguły szczegółowe per forma | **P730** (Doc 23) — pozostaje jako helper/macierz, nie jako reguła decyzyjna |

---

### B2. P800-P802 (Doc 22) vs R0372-R0399 (Doc 28a): PKPiR i księgowość

| Aspekt | P800-P802 (Doc 22) | R0372-R0399 (Doc 28a) |
|--------|---------------------|------------------------|
| **Liczba reguł** | 3 (podstawowe PKPiR) | 28 (pełna księgowość JDG) |
| **Szczegółowość** | Kolumny, data przychodu, data kosztu | Kolumny, amortyzacja, leasing, FX, FIFO, RMK, home office |

**Werdykt:** Doc 28a jest RADYKALNIE bardziej szczegółowy.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0372-R0399** (Doc 28a) — 28 reguł | **P800-P802** (Doc 22) — 3 reguły, zastąpione |

---

### B3. P840-P842 (Doc 22) vs R0379-R0389 (Doc 28a): Amortyzacja

| Aspekt | P840-P842 (Doc 22) | R0379-R0389 (Doc 28a) |
|--------|---------------------|------------------------|
| **Liczba reguł** | 3 | 11 |
| **Zakres** | Liniowa, jednorazowa | Liniowa, degresywna, KŚT grupy, ulepszenia, sprzedaż |

**Werdykt:** Doc 28a bardziej kompletny.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0379-R0389** (Doc 28a) | **P840-P842** (Doc 22) — zastąpione |

---

### B4. P860-P868 (Doc 23) vs R0390-R0391 (Doc 28a): Leasing

| Aspekt | P860-P868 (Doc 23) | R0390-R0391 (Doc 28a) |
|--------|---------------------|------------------------|
| **Liczba reguł** | 5 | 2 (operacyjny, finansowy) |

**Werdykt:** Doc 23 ma więcej reguł leasingowych (5 vs 2). **Doc 23 jest bardziej szczegółowy w tej domenie.**

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **P860-P868** (Doc 23) — 5 reguł | **R0390-R0391** (Doc 28a) — 2 reguły, zastąpione |

---

### B5. P1200-P1212 (Doc 23) vs R0450-R0459 (Doc 28a): Reprezentacja i pełnomocnictwa

| Aspekt | P1200-P1212 (Doc 23) | R0450-R0459 (Doc 28a) |
|--------|-----------------------|------------------------|
| **Liczba reguł** | 7 | 10 |
| **Format** | Standardowy | 10-polowy ENTERPRISE |

**Werdykt:** Doc 28a bardziej szczegółowy.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0450-R0459** (Doc 28a) | **P1200-P1212** (Doc 23) — zastąpione |

---

### 🔴 Grupa C: Sprzeczności wymagające rozstrzygnięcia — 3 pary

---

### C1. P914 (Doc 22) vs R0582 (Doc 28a): Zawieszenie a składka zdrowotna 🔥

| Aspekt | P914 `business_suspension_zus` (Doc 22) | R0582 `edge_zus_declaration_zero_on_suspension` (Doc 28a) |
|--------|------------------------------------------|-----------------------------------------------------------|
| **Zdrowotna** | ❌ "Składka zdrowotna też nie jest należna za okres zawieszenia" | ✅ "Zdrowotna NADAL jest należna!" |
| **Podstawa prawna** | Art. 36a SUS | Art. 36a SUS |
| **Która wersja poprawna?** | **BŁĘDNA** | **POPRAWNA** — Art. 36a SUS: zawieszenie zwalnia ze społecznych, ALE NIE ze zdrowotnej |

**Werdykt:** Doc 28a R0582 jest poprawny prawnie. P914 z Doc 22 jest błędny.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0582** (Doc 28a) — poprawna | **P914** (Doc 22) — BŁĘDNA, wymaga NATYCHMIASTOWEJ korekty |

---

### C2. P701 (Doc 22) vs R0346 (Doc 28a): Dobrowolność ubezpieczenia chorobowego

| Aspekt | P701 `zus_sickness_voluntary_jdg` (Doc 22) | R0346 `zus_sickness_voluntary` (Doc 28a) |
|--------|--------------------------------------------|------------------------------------------|
| **Domena** | Składka chorobowa — dobrowolność | Składka chorobowa — dobrowolność |
| **Status** | Ogólna reguła | To samo, ale w Doc 28a |

**Werdykt:** Obie reguły są poprawne. Doc 28a R0346 jest bardziej szczegółowa.

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0346** (Doc 28a) | **P701** (Doc 22) — zastąpiona przez bardziej szczegółową |

---

### C3. R0573 (Doc 28a) vs P720 (Doc 22): Składka zdrowotna skala — odliczenie 7.75%

| Aspekt | R0573 `edge_pit_health_contrib_scale_9pct_no_deduction` (Doc 28a v1.1) | P720 `zus_health_scale_jdg` (Doc 22) |
|--------|-------------------------------------------------------------------------|--------------------------------------|
| **Stan prawny** | ✅ Post-Polski Ład: 9% składki, **0% odliczenia** od PIT | ✅ "NIE podlega odliczeniu od podatku" |
| **Zgodność** | Tak — obie stwierdzają brak odliczenia (R0573 poprawione w v1.1) | Tak |

**Werdykt:** Po poprawce R0573 (v1.1), obie reguły są zgodne. Doc 28a R0573 jest bardziej szczegółowa (edge cases, historia).

| 🏆 **KANONICZNA** | 🗑️ **[DEPRECATED]** |
|:---:|:---:|
| **R0573** (Doc 28a v1.1) + **P720** (Doc 22) — obie poprawne, Doc 28a bardziej szczegółowa | Brak — obie potrzebne (P720 = reguła główna, R0573 = edge case) |

---

## 📊 PODSUMOWANIE — MACIERZ KANONICZNA

Po deduplikacji, **18 reguł jest nadmiarowych** i powinno być oznaczonych jako `[DEPRECATED]`:

| # | [DEPRECATED] | Dokument | Zastąpiona przez | Dokument |
|---|-------------|:--------:|-------------------|:--------:|
| 1 | P60 `vat_bad_debt_relief` | Doc 22 | P189 `bad_debt_relief_creditor` | Doc 23 |
| 2 | P59 `subject_exemption_startup_proportion` | Doc 23 | P58 `vat_exemption_subject_jdg` (rozszerzona) | Doc 22 |
| 3 | P734 `lump_sum_health_tier_lockstep` | Doc 23 | P724 `zus_health_lump_sum_jdg` (rozszerzona) | Doc 22 |
| 4 | P738 `scale_health_deduction_prohibition` | Doc 23 | P720 `zus_health_scale_jdg` | Doc 22 |
| 5 | P40, P41, P42, P45, P48 (5 reguł) | Doc 22 | P43-P49, P190-P191, P232 (Doc 23) | Doc 23 |
| 6 | P1100-P1114 (8 reguł) | Doc 23 | R0420-R0435 | Doc 28a |
| 7 | P1150-P1166 (9 reguł) | Doc 23 | R0436-R0449 | Doc 28a |
| 8 | P230, P231, P235 (3 reguły) | Doc 22/23 | R0546-R0559 (edge cases w `else` po P58) | Doc 28a |
| 9 | P800-P802 (3 reguły) | Doc 22 | R0372-R0399 | Doc 28a |
| 10 | P840-P842 (3 reguły) | Doc 22 | R0379-R0389 | Doc 28a |
| 11 | R0390-R0391 (2 reguły) | Doc 28a | P860-P868 | Doc 23 |
| 12 | P1200-P1212 (7 reguł) | Doc 23 | R0450-R0459 | Doc 28a |
| 13 | P914 `business_suspension_zus` | Doc 22 | R0582 (poprawiona) | Doc 28a |
| 14 | P701 `zus_sickness_voluntary_jdg` | Doc 22 | R0346 | Doc 28a |
| 15 | P730 `health_contribution_rate_matrix` | Doc 23 | P720/P722/P724/P736 (helper, nie reguła) | Doc 22 |

**Łącznie: 47 unikalnych reguł [DEPRECATED] (P59 liczone raz w wierszu 2; P58 NIE jest deprecjonowany — pozostaje kanoniczny jako reguła główna VAT).**

> ℹ️ **Uwaga:** Wiersze 6-8, 9-10, 12 to grupy reguł (np. P1100-P1114 = 8 indywidualnych P-ID). Łącznie 47 unikalnych identyfikatorów do deprecjacji, z czego:
> - **31** z Doc 22 (P40, P41, P42, P45, P48, P60, P230, P231, P235, P701, P800-P802, P840-P842, P914)
> - **14** z Doc 23 (P59, P734, P738, P1100-P1114, P1150-P1166, P1200-P1212, P730)
> - **2** z Doc 28a (R0390-R0391 — jedyny przypadek gdzie Doc 23 wygrywa z Doc 28a)

---

## 🚀 REKOMENDACJE IMPLEMENTACYJNE

### Faza 1: NATYCHMIAST (oznaczenie)
1. W Doc 22: oznaczyć P40, P41, P42, P45, P48, P60, P230, P231, P235, P701, P800-P802, P840-P842, P914 jako `[DEPRECATED]` z adnotacją "zastąpione przez Doc 23/Doc 28a"
   - ⚠️ **P58 NIE deprecjonować** — pozostaje kanoniczną regułą główną VAT (R0546-R0559 to edge cases w `else`)
   - ⚠️ **P43, P44, P46, P47, P49 NIE deprecjonować** — to reguły z Doc 23, które są kanoniczne (zastępują płytkie odpowiedniki z Doc 22)
2. W Doc 23: oznaczyć P59, P734, P738, P1100-P1114, P1150-P1166, P1200-P1212 jako `[DEPRECATED]`

### Faza 2: KOREKTA BŁĘDÓW
3. **P914 (Doc 22) — NATYCHMIASTOWA poprawka:** zmienić "składka zdrowotna też nie jest należna" na "składka zdrowotna NADAL jest należna podczas zawieszenia (tylko społeczne są zerowe)"
4. **P189 (Doc 23) — poprawić termin:** 150 dni (nie 90) dla wierzyciela VAT

### Faza 3: KONSOLIDACJA (Doc 28)
5. Doc 28a R0546-R0672 pozostaje jako KANONICZNY zbiór edge cases
6. Doc 28a R0372-R0399 pozostaje jako KANONICZNY zbiór księgowości
7. Doc 28a R0420-R0449 pozostaje jako KANONICZNY zbiór korekt i odpowiedzialności

### Faza 4: MAPOWANIE
8. Utworzyć `38c_JDG_CANONICAL_MAP.md` — pełne mapowanie wszystkich P-ID i R-ID na wersje kanoniczne

---

> **🔥 WNIOSEK:** Z 341 reguł w 3 dokumentach, **47 indywidualnych reguł jest nadmiarowych** — w tym 2 z Doc 28a (R0390-R0391, jedyny przypadek gdzie Doc 23 wygrywa z Doc 28a). Po deduplikacji system JDG będzie miał **294 unikalne reguły** (341 − 47).
>
> **Kluczowa korekta po audycie:** P58 `vat_exemption_subject_jdg` **NIE jest deprecjonowany** — pozostaje kanoniczną regułą główną VAT. R0546-R0559 to edge cases w łańcuchu `else` PO P58, a nie jego zamienniki. P59 był liczony podwójnie (wiersze 2 i 8) — teraz tylko w wierszu 2.
>
> **Najpilniejsza akcja:** **poprawa P914 (błędna informacja o zdrowotnej w zawieszeniu) — to może kosztować JDG realne pieniądze.**

---

*Wygenerowano przez NexusAI Deduplication Audit Engine v1.0*
*Data: 2026-07-11*
*Dokumenty: 22_JDG_ENTERPRISE_PLAN.md, 23_JDG_EXPANSION_SUPPLEMENT.md, 28a_JDG_EDGE_CASES_FULL.md*
