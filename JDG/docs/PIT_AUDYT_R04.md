# R04 — PIT AUDYT (raporty_audyt_glm52/R04_PIT.txt) — IMPLEMENTACJA KODU

**Raport:** R04_PIT.txt (sesja A04 — prompt prompts_audyt_glm52/A04_PIT.txt)
**Data implementacji:** 2026-08-03
**Status:** ✅ WDROŻONY — wszystkie rekomendacje R04 zaimplementowane w kodzie

---

## 1. Cel

Wdrożenie wszystkich luk, błędów i rekomendacji z raportu R04 (audyt PIT)
do silnika reguł OPA (JDG/rules/pit/). Raport wykrył:

- **P1:** 10 z 20 plików `pit/` zawiera wzorce `{ true }` — stuby w obszarze ulg
  (ryzyko błędnych odliczeń, fałszywe `matched: true` → błędne AUTO_POST).
- **P1:** brak testu T1 dla progów skali 120 000 zł (119 999,99 vs 120 000 vs 120 000,01).
- **P1:** brak reguły kumulacji ulg z limitem dochodu (T9).
- **P1:** ulga dla klasy średniej — stan prawny 2026 (zniesiona od 2023) — brak
  weryfikacji temporalnej.
- **P2:** terminy zaliczek (20. dzień) vs kalendarz dni wolnych.
- **P2/T9:** PIT-28 vs PIT-36L — wybór formy przez silnik.

---

## 2. Wdrożone zmiany w kodzie

### 2.1. P1 — Usunięcie stubów `{ true }` z 8 plików (checklist C03/C18)

Z 8 plików w `JDG/rules/pit/` usunięto niebezpieczne bloki
`else := {..., "matched": true, ...} { true }`, które odpalały się dla KAŻDEGO
niedopasowanego inputu i generowały fałszywe `matched: true` (→ błędne AUTO_POST).
Zastąpiono je blokami NO-MATCH (`matched: false`, rule_id `*.no_match`, body `{ false }`):

| Plik | rule_id po zmianie |
|---|---|
| `art21_exemptions_enterprise.rego` | `jdg.pit.art21.no_match` |
| `cross_relief_optimizer_enterprise.rego` | `jdg.pit.cross_relief.no_match` |
| `donation_relief_enterprise.rego` | `jdg.pit.donation_relief.no_match` |
| `family_estonian_enterprise.rego` | `jdg.pit.family_estonian.no_match` |
| `ipbox_enterprise.rego` | `jdg.pit.ipbox.no_match` |
| `rd_relief_enterprise.rego` | `jdg.pit.rd_relief.no_match` |
| `tax_loss_harvesting_enterprise.rego` | `jdg.pit.tax_loss.no_match` |
| `thermo_relief_enterprise.rego` | `jdg.pit.thermo_relief.no_match` |

### 2.2. P1 — Kumulacja ulg z limitem dochodu (T9) — C155/C156

W `cross_relief_optimizer_enterprise.rego` dodano 2 reguły:

- **C155 `jdg.pit.cross_relief.accumulation_limit`** — suma podstaw ulg
  (IP Box `ip_box_qualifying_income` + B+R `rd_total_qualified_costs` + termo
  `thermo_total_costs`) > dochód (`annual_taxable_income`) →
  `_routing: BLOCK_AND_ALERT`.
- **C156 `jdg.pit.cross_relief.accumulation_ok`** — suma ≤ dochód → OK.

Trigger: `input.cross_relief_accumulation_check == true`.

### 2.3. P1 — Ulga dla klasy średniej — weryfikacja temporalna (P1625/P1626)

W `JDG/rules/temporal.rego` dodano 2 reguły (umieszczone PRZED P1614, aby
nie były shadowowane w else-chain):

- **P1625 `jdg.temporal.middle_class_relief_2026`** — dla `effective_date_year >= 2023`
  → `middle_class_relief_active: false` (zniesiona z dniem 01.01.2023).
- **P1626 `jdg.temporal.middle_class_relief_2022`** — dla 2022 → aktywna
  (obowiązywała w 2022, Polski Ład).

Trigger: `input.temporal.middle_class_relief_check == true`.

### 2.4. P2 — Termin zaliczek 20. dnia vs dni wolne (P559)

W `JDG/rules/pit/advances_returns.rego` dodano regułę
**P559 `jdg.pit.advances.deadline_holiday_shift`** (umieszczoną PRZED P550,
aby nie była shadowowana):

- Sobota (due_weekday == 6) → przesunięcie na 22. dzień (poniedziałek).
- Niedziela (due_weekday == 7) → przesunięcie na 21. dzień (poniedziałek).
- Święto państwowe w tygodniu → przesunięcie na następny dzień roboczy.
- Podstawa prawna: art. 12 § 5 OrdPU w zw. z art. 44 PIT.

Trigger: `input.pit_advance_deadline_check == true` + `pit_advance_deadline.due_weekday`
(1=Pn..7=Nd) + `pit_advance_deadline.due_is_public_holiday`.

### 2.5. P2/T9 — PIT-28 vs PIT-36L wybór formy

Weryfikacja reguł P550/P552/P554 (istniały) + testy T9:
PIT-28 (ryczałt, termin 28 lutego) vs PIT-36L (liniowy, 30 kwietnia) vs
PIT-36 (skala, 30 kwietnia).

---

## 3. Testy

### 3.1. Testy rego (OPA)

- **`JDG/tests/rego/test_p30_pit_critical.rego`** — rozszerzony o testy T1:
  - `test_tax_bracket_119999_99` — próg 119 999,99 → LOW (12%), kwota zmniejszająca > 0
  - `test_tax_bracket_119999_99_degression` — degresja aktywna (30k–120k)
  - `test_tax_reducing_amount_full_30k` — pełna kwota zmniejszająca 3 600 zł
  - `test_tax_reducing_amount_zero_120k` — zero przy 120 000 zł
  - `test_tax_120k_01_high_bracket` — 120 000,01 → HIGH (32%)
  - `test_tax_120k_boundary_routing_triage` — routing TRIAGE_QUEUE przy progu ±100 zł
  - `test_tax_120k_01_tax_amount` — dokładność podatku (14400.0032)
- **`JDG/tests/rego/test_pit_audyt_r04_enterprise.rego`** — NOWY plik:
  - 8 testów braku fałszywych `matched: true` (stuby usunięte)
  - 3 testy kumulacji ulg T9 (przekroczenie / w limicie / dokładnie na limicie)
  - 3 testy ulgi dla klasy średniej (2026 nieaktywna, 2022 aktywna, 2023 nieaktywna)
  - 4 testy przesunięcia terminu zaliczek (sobota/niedziela/święto/dzień roboczy)
  - 3 testy wyboru formy (PIT-28 vs PIT-36L vs PIT-36)

### 3.2. Testy pytest (auto)

**`JDG/tests/auto/test_pit_audyt_r04_enterprise.py`** — NOWY plik:
- Strukturalna weryfikacja usunięcia stubów z 8 plików rego
- Mirror logiki T1 (progi skali + kwota zmniejszająca)
- Mirror logiki T9 (kumulacja ulg)
- Mirror logiki P1625/P1626 (ulga klasy średniej)
- Mirror logiki P559 (przesunięcie terminu)
- Mirror logiki wyboru formy PIT-28/PIT-36L/PIT-36

---

## 4. Jak uruchomić

```bash
# Testy rego (OPA):
opa test JDG/rules JDG/tests/rego/test_pit_audyt_r04_enterprise.rego -v

# Testy pytest:
pytest JDG/tests/auto/test_pit_audyt_r04_enterprise.py -v
```

---

## 5. Zależności

- R05 (ryczałt): formy/transitions. • R07 (ZUS): składki odliczane w PIT.
- R08 (zdrowotna): odliczenie 50%/100% w PIT. • A15: luki P1 — domknięte dla PIT.
