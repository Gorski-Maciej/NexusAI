# R02 — PRAWA PRZEDSIĘBIORCÓW AUDYT (raporty_audyt_glm52/R02_Prawa_Przedsiebiorcow.txt) — IMPLEMENTACJA KODU

**Raport:** R02_Prawa_Przedsiebiorcow.txt (sesja A02 — prompt prompts_audyt_glm52/A02_Prawa_Przedsiebiorcow.txt)
**Data implementacji:** 2026-08-04
**Status:** ✅ WDROŻONY — wszystkie rekomendacje R02 zaimplementowane w kodzie

---

## 1. Cel

Wdrożenie wszystkich luk, błędów i rekomendacji z raportu R02 (audyt PP / CEIDG /
sukcesja / działalność nieewidencjonowana) do silnika reguł OPA (JDG/rules/business*).
Raport wykrył:

- **P1:** limit działalności nieewidencjonowanej („50% płacy minimalnej”) — czy wartość
  pochodzi z `data.thresholds` (weryfikowalnie zewnętrznie) czy jest hardcoded.
- **P1:** sukcesja bez zarządcy — niezbadany stan „brak następcy → wygaszenie działalności”.
- **P2:** prokura (art. 18 PP) — potwierdzenie integracji z `poa_manager_enterprise`.
- **Testy:** T3 (granice zawieszenia), T1 (limit nieewidencjonowanej ±1 zł), T4, T6, T7, T9, T10.
- **Ujednolicenie:** `business.rego` vs `policies/jdg/business.rego` — 1 wersja prawdy.

---

## 2. Weryfikacja prawna (korekta stanu z raportu)

Raport opisywał limit jako „50% płacy minimalnej”. Weryfikacja aktualnego stanu prawnego
(art. 5 ust. 1 pkt 1 Prawa przedsiębiorców) wykazała stan temporalny:

| Okres | Limit | Wyliczenie |
|---|---|---|
| do 30.06.2023 | **50%** płacy min. miesięcznie | 2022: 50% × 3 010 = 1 505 zł |
| 01.07.2023 → 31.12.2025 | **75%** płacy min. miesięcznie | 2025: 75% × 4 666 = 3 499,50 zł |
| od 01.01.2026 | **225%** płacy min. **kwartalnie** | 2026: 225% × 4 800 = 10 800 zł/kwartał (ekwiwalent mies. 75% = 3 600 zł) |

Raport R02 oraz warstwa macro (`business.rego` P930) używały nieaktualnych 50% — warstwa
micro (`micro/pp` L-PP-2) już używała 75%. Implementacja ujednolica wg stanu prawnego.

---

## 3. Wdrożone zmiany w kodzie

### 3.1. P1 — Limit nieewidencjonowanej z `data.thresholds` + temporalność

**`JDG/rules/thresholds_jdg.rego`** (jedno źródło prawdy):
- `ord.unregistered_revenue_pct`: 0.50 → **0.75** (stan aktualny od 01.07.2023).
- Nowy wpis `temporal_thresholds["unregistered_revenue_pct"]`: `valid_from 2023-07-01`,
  `value 0.75`, `previous_value 0.50` (do 30.06.2023).
- Nowa wersja w `default_threshold_versions["business.unregistered_revenue_pct"]`:
  3 okna (2018–2023-06: 0.50; 2023-07–2025: 0.75; 2026+: **2.25 kwartalnie**).
- Nowe helpery pakietowe:
  - `unregistered_limit_pct(eval_date)` — miesięczny ekwiwalent procentu (50% → 75%).
  - `unregistered_quarterly_multiplier(eval_date)` — 2.25 od 2026, inaczej 0.

**`JDG/rules/business.rego`**:
- **P930** `unregistered_activity_limit_exceeded` — warunek przebudowany: limit czytany
  z `data.thresholds` (płaca minimalna + `data.jdg.thresholds.unregistered_limit_pct(eval_date)`),
  **zero hardcode kwoty/procentu**; `eval_date` z `input.evaluation_date` →
  `jdg_entrepreneur.effective_date` → domyślnie 2026.
- **P931** `jdg.business.unregistered_limit_check` (NOWA, trigger `business_unregistered_limit_check`)
  — audyt limitu: `unregistered_limit_monthly`, `unregistered_limit_quarterly`,
  `unregistered_limit_pct`, `unregistered_quarterly_mode` (2026+), `unregistered_revenue_checked`,
  `unregistered_limit_applied`, `unregistered_within_limit`, `unregistered_activity_limit_exceeded`,
  routing BLOCK_AND_ALERT / OK. Tryb kwartalny używany, gdy podany `quarterly_revenue` (2026+).

### 3.2. P1 — Sukcesja bez zarządcy (wygaśnięcie działalności)

**`JDG/rules/business.rego`** (2 NOWE reguły przed P929c w łańcuchu else):
- **P921a** `jdg.business.succession_no_manager_grace` — `in_succession == true`, brak NIP
  zarządcy, `succession_days_elapsed < 60` → `TRIAGE_QUEUE` (okno 2 mies. na powołanie,
  art. 3 u.z.s.), `succession_grace_days_left`.
- **P921b** `jdg.business.succession_no_manager_expiry` — `>= 60 dni` → `BLOCK_AND_ALERT`,
  `business_status: "EXPIRED"`, `ceidg_deregistration_required: true`, `nip_status:
  "DECEASED_NO_SUCCESSOR"` (art. 30 ust. 2 ustawy o CEIDG — wykreślenie z urzędu).
- Stan „brak następcy → wygaszenie” domknięty; test negatywny T4 (input bez pola zarządcy
  → werdykt grace, brak mdlenia).

### 3.3. P2 — Prokura (art. 18 PP) ↔ `poa_manager_enterprise`

**`JDG/rules/representation/plan26_prokura.rego`** — NOWA reguła (pierwsza w łańcuchu,
trigger audytowy `business_audit_prokura_check`):
- `jdg.representation.prokura_poa_manager_bridge` — potwierdza integrację reprezentacji
  z pakietem `jdg.poa_manager` (rejestr PPS-1/UPL-1/PPD-1, CRPO, e-Doręczenia, alerty
  wygaśnięcia). Nie koliduje z normalnym łańcuchem prokury (SELF/JOINT/BRANCH/unregistered).

### 3.4. T3 — Granica okresu zawieszenia

**`JDG/rules/business.rego`** — NOWA reguła `jdg.business.suspension_period_boundary`
(trigger `business_suspension_check`): okres zawieszenia `[start, end]` włącznie;
`eval_date > end` → wznowienie (`ACTIVE`), `eval_date < start` → `PRE_SUSPENSION`.
Test T3: 31.12 23:59 (w okresie) vs 1.01 00:01 (wznowienie).

### 3.5. T7 — Duplikaty rule_id w pakiecie `jdg.business` / `jdg.representation`

- `business/plan26_suspension_succession.rego` — usunięto zduplikowany
  `default decide` (`jdg.business.no_match`, priority 99999) — pojedynczy default żyje
  w `business.rego` (priority 950). Lista rule_id pakietu bez duplikatów.
- `representation/plan26_prokura.rego` — analogicznie usunięto zduplikowany
  `default decide` (`jdg.representation.no_match`) — default żyje w `representation.rego`.

### 3.6. Ujednolicenie `policies/jdg/business.rego` (1 wersja prawdy)

- `policies/jdg/business.rego` = pełne lustro `JDG/rules/business.rego` (copy — wcześniej
  brakowało reguł P916/P917/P929c/P929d/P922/P928/P830/P918/P832 i używano nieaktualnego
  domyślnego `minimum_wage_gross` 4666 zamiast 4800).

### 3.7. Spójność danych

- `JDG/rules/_business_lifecycle_rates.rego` — `unregistered_activity_limit_pct`: 50 → 75,
  `unregistered_activity_limit_pln`: 75% × 4 800 = 3 600.
- `tests/test_boundary_fuzz_auto.py` (P930) + `nexus_ai/tax/boundary_fuzz_generator.py` —
  limit 50.0 → 75.0.

---

## 4. Testy

### 4.1. Testy rego (OPA)

**`JDG/tests/rego/test_business_audyt_r02_enterprise.rego`** — NOWY plik (23 testy):
- T1: limit 2026 (mies. 3 600 / kwart. 10 800, ±1 grosz), 2022 (50% × 3 010 = 1 505),
  2023H2 (75% × 3 600 = 2 700) — z injekcją `data.thresholds` (weryfikacja zewnętrzności).
- T1: P930 w łańcuchu — równy limit NIE przekracza, +1 grosz → BLOCK.
- T3: granice zawieszenia (ostatni dzień / wznowienie / przed okresem).
- T4: sukcesja bez zarządcy (30/59 dni grace; 60/61 dni expiry; brak pola → grace bez mdlenia;
  pusty input → no_match).
- T5: aktualizacja CEIDG w trakcie roku (`ceidg_update_overdue`).
- T9: zawieszenie + zmiana formy w tym samym roku (werdykt SUSPENDED).
- T10: `limits.trust_auto_post == 0.92` (próg AUTO_POST).
- P2: bridge prokura↔poa_manager + normalny łańcuch + prokura niezarejestrowana.

### 4.2. Testy pytest (auto)

**`JDG/tests/auto/test_business_audyt_r02_enterprise.py`** — NOWY plik (21 testów):
- Strukturalne: `unregistered_revenue_pct == 0.75`, wpis temporalny + wersje per okres,
  brak hardcode `0.50` w P930, nowe rule_id obecne, policies == JDG/rules (ujednolicenie),
  prokura bridge, T7 (zero duplikatów rule_id w pakiecie), T10 (risk.rego czyta threshold).
- Mirror logiki: T1 (progi/epoki ±1 grosz), T3 (granice), T4 (grace/expiry).

### 4.3. Wynik

```
21 passed (test_business_audyt_r02_enterprise.py)
61 passed (test_boundary_p930 + R04 + test_auto_block_business) — brak regresji
```

---

## 5. Jak uruchomić

```bash
# Testy rego (OPA):
opa test JDG/rules JDG/tests/rego/test_business_audyt_r02_enterprise.rego -v

# Testy pytest:
pytest JDG/tests/auto/test_business_audyt_r02_enterprise.py -v
pytest tests/test_boundary_fuzz_auto.py::test_boundary_p930 -v
```

---

## 6. Zależności

- A07 (ZUS): próg nieewidencjonowanej wspólny z `micro/pp` (L-PP-2: 75% — zgodny).
- A04 (PIT): zmiana formy (plan23_tax_form_change) współdzieli `form_transition`.
- R14/R15: stuby `{ true }`, duplikaty `rule_id` w innych pakietach — do dalszych raportów.
- NOTA: codebase używa składni v0 — nowe reguły zachowują konwencję v0.
