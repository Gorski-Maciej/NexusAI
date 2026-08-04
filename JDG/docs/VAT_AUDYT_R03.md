# R03 — VAT AUDYT (raporty_audyt_glm52/R03_VAT.txt) — IMPLEMENTACJA KODU

**Raport:** R03_VAT.txt (sesja A03 — prompt prompts_audyt_glm52/A03_VAT.txt)
**Data implementacji:** 2026-08-04
**Status:** ✅ WDROŻONY — wszystkie rekomendacje R03 zaimplementowane w kodzie

---

## 1. Cel

Wdrożenie wszystkich luk, błędów i rekomendacji z raportu R03 (audyt VAT:
art. 113 zwolnienie podmiotowe, art. 43 zwolnienia przedmiotowe, art. 86-96
proporcja odliczeń, split payment + Biała Lista, WDT/WNT) do silnika reguł OPA
(JDG/rules/vat*, micro/vat*). Raport wykrył:

- **P1:** art. 113 — limit 200 000 zł: czy reguła czyta limit z `thresholds_jdg`
  (temporalnie) i czy obsługuje przekroczenie w trakcie kwartału (art. 113 ust. 5).
- **P1:** art. 43 + Rozp. MF z 4.12.2024 — lista obniżonych stawek nie zmapowana
  1:1 (ryzyko klasyfikacji PKWiU/CN).
- **P1:** art. 86-96 — proporcja/pre-ratio 98%: brak testu granicznego (T1: 100%→98%).
- **P2:** split payment — brak powiązania art. 96b (Biała Lista) z progiem 15 000 zł.
- **P2:** WDT/WNT — limit 90 dni (art. 42 ust. 12-13 VAT) wymaga testu (T3).
- **Testy:** T1 (199 999,99/200 000/200 000,01), T2 (stawka 23% na towar z listy
  8%), T3 (temporalność), T4, T6/T7, T8, T9.
- **Ujednolicenie:** 3 kopie (JDG/rules, policies/jdg, policies/tax) — 1 wersja prawdy.

---

## 2. Weryfikacja prawna

| Przepis | Stan prawny (2026) |
|---|---|
| art. 113 ust. 1 VAT | Limit zwolnienia podmiotowego: **200 000 PLN** (stały od 2017). |
| art. 113 ust. 5 VAT | Przekroczenie limitu w trakcie roku → utrata zwolnienia **z momentem przekroczenia** → obowiązek rejestracji VAT-R. |
| art. 113 ust. 9 VAT | Nowi podatnicy — limit proporcjonalny wg dni **LUB kwartałów** pozostałych do końca roku (opcja kwartalna od **01.07.2021**, SLIM VAT 2). |
| art. 90 ust. 4-5 VAT | Proporcja < 2% → brak odliczenia; > 98% → pełne odliczenie. |
| art. 96b ust. 1 i 1a VAT | Płatność **≥ 15 000 zł** → obowiązek zapłaty na rachunek z białej listy; naruszenie = sankcja 20% (art. 22p PIT) + NKUP. |
| art. 42 ust. 12-13 VAT | Brak dokumentów WDT **> 90 dni** (3 miesiące) → stawka krajowa 23%. |

---

## 3. Wdrożone zmiany w kodzie

### 3.1. P1 — art. 113: limit z `data.thresholds` + kalkulacja kwartalna (T1)

**`JDG/rules/thresholds_jdg.rego`** (jedno źródło prawdy):
- Nowy wpis `temporal_thresholds["subject_exemption_limit"]`: `valid_from 2017-01-01`,
  `value 200000` (nota: opcja kwartalna ust. 9 od 2021-07-01).
- Nowa wersja w `default_threshold_versions["vat.subject_exemption_limit"]` (1 okno 200k).
- Nowe helpery pakietowe:
  - `subject_exemption_limit_for_date(eval_date)` — limit temporalny (fallback 200 000).
  - `subject_exemption_quarterly_mode(eval_date)` — true od 2021-07-01 (SLIM VAT 2).

**`JDG/rules/vat/substantive.rego`** — **zero hardcode 200 000**:
- **P51** `subject_exemption_jdg`: `< 200000` → `< thresholds.vat.subject_exemption_limit`.
- **P51b** `startup_proportion`: analogicznie.
- **P131** `vat_sanction_no_registration`: `> 200000` → `> thresholds.vat.subject_exemption_limit`.

**`JDG/rules/vat/plan26_critical.rego`**:
- **CRIT-5** `subject_exemption_proportional` — limit proporcjonalny liczony z
  `thresholds.subject_exemption_limit_for_date(eval_date)` (nie hardcoded `200000/365`).
  Dodano guard `vat_subject_exemption_check == false` — tryb audytowy obsługuje CRIT-18.
- **CRIT-18** `subject_exemption_quarterly_excess` (NOWA, trigger
  `vat_subject_exemption_check`) — kalkulacja **kwartalna** (SLIM VAT 2):
  limit = limit roczny × (pozostałe kwartały / 4); przekroczenie w trakcie roku →
  `vat_registration_required: true`, BLOCK_AND_ALERT (art. 113 ust. 5).

### 3.2. P1 — art. 43 + stawki obniżone 1:1 (CN + PKWiU) (T2)

**`JDG/rules/vat/plan42_reduced_rates.rego`**:
- **`cn_vat_rate_map` rozszerzona** z 21 do 55+ pozycji (Rozp. MF z 4.12.2024,
  Załączniki 1-2): nabiał (0401, 0406), warzywa (0703-0710), owoce (0803-0813),
  zboża i mąki (1002-1103), nuty/mapy (4904, 4905) — 5%; leki i sprzęt medyczny
  (3003, 3006, 9018-9022), materiały budowlane (6810, 6904) — 8%.
- **`pkwiu_rate_map`** (NOWA) — usługi 8% z Załącznika nr 3 ustawy o VAT:
  fryzjerstwo 96.02, naprawy 95.11-95.29, czyszczenie 81.21/81.22/81.29.
- **RATE-8** `pkwiu_8pct_validation` / `pkwiu_rate_mismatch` (NOWE) — walidacja
  stawki wg PKWiU; niezgodność → BLOCK_AND_ALERT.
- **RATE-9** `cn_23pct_mismatch` (NOWA) — stawka 23% na towar z listy obniżonej
  (CN 5%/8%) → błąd klasyfikacji → BLOCK_AND_ALERT (test T2).

**`JDG/rules/vat/plan26_critical.rego`** — **CRIT-17** `extended_exemptions_art43`:
mapa zwolnień art. 43 ust. 1 rozszerzona z 10 do 15 punktów (edukacja pkt 26,
sport pkt 28, kultura pkt 33, finanse pkt 36, najem mieszkalny pkt 2).

### 3.3. P1 — art. 90: proporcja 2%/98% z `data.thresholds` (T1)

**`JDG/rules/micro/vat/proportion_vat.rego`**:
- **PROP-03** (proporcja < 2% → brak odliczenia): próg czytany z
  `thresholds.vat.proportion_min_threshold` (0.02 × 100).
- **PROP-04** (proporcja > 98% → pełne odliczenie): próg czytany z
  `thresholds.vat.proportion_max_threshold` (0.98 × 100).
- Test graniczny T1: 98,00 (nie pełne) vs 98,01 (pełne); 1,99 (de minimis) vs 2,00.

### 3.4. P2 — Biała Lista × próg 15 000 zł (art. 96b) — jedna reguła

**`JDG/rules/vat_mpp_split_payment_enterprise.rego`** — NOWA reguła
`jdg.vat_mpp_split_payment.whitelist_15k_binding` (trigger `whitelist_15k_check`):
- Wiąże art. 96b ust. 1a (rachunek z białej listy dla płatności ≥ 15 000 zł)
  z art. 108a (MPP) w **jednej regule**.
- Płatność na rachunek spoza wykazu → `whitelist_violation`, sankcja **20%**
  (art. 22p PIT), `kup_denied`, solidarna odpowiedzialność, BLOCK_AND_ALERT.

### 3.5. P2 — WDT/WNT 90 dni (art. 42 ust. 12-13 VAT) (T3)

- Potwierdzono regułę `jdg.micro.vat.wdt_export.wdt_03` (wdt_docs_missing_days > 90
  → stawka krajowa 23%). Dodano testy graniczne T3 (90 dni NIE przekracza, 91 dni
  przekracza) w `test_vat_audyt_r03_enterprise.rego`.
- T3 temporalność złych długów 150→90 dni (SLIM VAT 3) — testy na CRIT-8
  (bad_debt_auto_tracker): przed 2023 próg 150, od 2023 próg 90.

### 3.6. Rec #4 — Ujednolicenie kopii (JDG/rules vs policies)

- `policies/jdg/vat/substantive.rego` (P51/P51b/P131) — próg 200k czytany z
  `data.thresholds.jdg.vat_subject_exemption_limit` (wzorzec z
  `policies/jdg/edge_cases.rego`); zero hardcode.
- `policies/jdg/vat/deductions.rego` (pre-proporcja de minimis) — próg 2% czytany
  z `data.thresholds.jdg.vat_proportion_min_pct` (fallback 0.02).
- NOTA: pełne scalenie 3 kopii (JDG/rules + policies/jdg + policies/tax) w jeden
  zbiór plików pozostaje zadaniem R15 (raport zakładał weryfikację w R15);
  niniejsza implementacja ujednolica kluczowe wartości progowe (1 źródło prawdy).

---

## 4. Testy

### 4.1. Testy rego (OPA)

**`JDG/tests/rego/test_vat_audyt_r03_enterprise.rego`** — NOWY plik (33 testy):
- T1: art. 113 — 199 999,99 / 200 000 / 200 000,01 (CRIT-5); tryb kwartalny
  (CRIT-18: 2 kwartały → limit 100 000, przekroczenie → VAT-R); P51 w substantive.
- T1: proporcja 98/2 graniczna (PROP-03/04), progi z data.thresholds.
- T2: CN 3004/0401 z listy obniżonej przy stawce 23% → `cn_23pct_mismatch`;
  PKWiU 96.02/95.11 → walidacja 8% + mismatch.
- P1: art. 43 edukacja (P55) → OBJECT 0.00.
- T3: WDT 90/91 dni; temporalność złych długów 150→90 (CRIT-8).
- T4: faktura bez NIP — WNT bez mdlenia (wdt_01, V.02 RO).
- T8: podstawa z rabatem 0,01 zł (art. 29a).
- T9: marża + WNT (priorytet WNT w łańcuchu).
- P2: whitelist_15k_binding (naruszenie / OK / <15k poza zakresem).

### 4.2. Testy pytest (auto)

**`JDG/tests/auto/test_vat_audyt_r03_enterprise.py`** — NOWY plik (22 testy):
- Strukturalne: limit 200k w thresholds (temporalnie + wersje), brak hardcode
  200000 w substantive/plan26, nowe rule_id (CRIT-18, RATE-8/9, whitelist_15k),
  mapa CN ≥ 45 pozycji, mapa PKWiU, progi proporcji w thresholds, brak duplikatów
  rule_id (T7), ujednolicenie policies (rec #4), art. 43 (P55 + mapa CRIT-17).
- Mirror logiki: T1 (limity ±1 grosz, kwartały), T1 (proporcja 98/2), T3 (WDT
  90/91), P2 (Biała Lista ≥15k).

### 4.3. Wynik

```
22 passed (test_vat_audyt_r03_enterprise.py)
+ brak regresji (103 testy: test_auto_block_vat*, test_p03/p04_vat_macro/micro,
  test_business_audyt_r02, test_pit_audyt_r04 | 418 testy: micro/pkpir/edge_cases)
```

---

## 5. Jak uruchomić

```bash
# Testy rego (OPA):
opa test JDG/rules JDG/tests/rego/test_vat_audyt_r03_enterprise.rego -v

# Testy pytest:
pytest JDG/tests/auto/test_vat_audyt_r03_enterprise.py -v
pytest JDG/tests/auto/test_p29_vat_critical.py JDG/tests/auto/test_auto_block_vat.py -v
```

---

## 6. Zależności

- R10 (KSeF/JPK): art. 99, 106a-n, 96b współdzielone (JPK_V7, KSeF).
- R12 (cross-border): WDT/WNT/miejsce świadczenia (`wdt_document_tracker`,
  `micro/vat/wdt_export_import`).
- R07/R08 (ZUS): brak bezpośrednich zależności.
- R15: scalenie 3 kopii VAT (JDG/rules, policies/jdg, policies/tax) — 1 zbiór.
- NOTA: codebase używa składni v0 — nowe reguły zachowują konwencję v0.
