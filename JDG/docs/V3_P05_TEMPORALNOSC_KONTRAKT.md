# V3-P05 KONTRAKT TEMPORALNOŚCI (WIĄŻĄCY DLA P06–P68)

Kontrakt wyjściowy części P05 (TEMPORALNOŚĆ). Wiąże: P06 (parametry jako dane),
P08 (Law Radar), P10 (Golden Oracle), P11 (certyfikaty), P37 (obserwowalność),
P38 (bundle), P39 (testy/CI) oraz wszystkie części domenowe P10–P36 (wzorce
przepisów przejściowych). Źródło: prompty_v3/V3_PROMPT_P05_TEMPORALNOSC.txt §11.2
+ wnioski raportu RAPORT_V3_P05_TEMPORALNOSC.txt (12 innowacji, bramki 5 PASS /
7 FAIL z lukami L01–L14).

---

## K1. Model Snapshot ID i skład snapshotu (I02)
- `snapshot_id = sha256(rules_rego + thresholds_data + legal_graph + golden_verdicts + migrations)` — kanoniczny JSON v1 (compact separators `(",",":")`, `sort_keys`, UTF-8), **spójny z `sha256-canonical-json-v1`** używanym w P00/P01/P03 (golden hash).
- Werdykt: `verdict = f(snapshot_id, input)`; zmiana któregokolwiek składnika = NOWY snapshot_id; stary wpis zostaje w vault jako niezmienny (WORM).
- Vault: `bundles/v3_p05_snapshot_vault.json` (lista wpisów + `current`). Rekonstrukcja historyczna = `snapshot_id + input → werdykt 1:1`.
- Pole `snapshot_id` trafia do kontraktu werdyktu (rozszerzenie P03, pole `snapshot_id` / `bundle_version`).
- Wiąże: P06 (parametry — wersjonowanie), P10 (golden oracle), P11 (certyfikaty), P38 (bundle).
- **L08 (P1):** 4 z 30 zapisanych `verdict_hash` w `golden_verdicts.json` NIE jest deterministyczną funkcją zapisanego werdyktu (wpisy z `*-bundle-v9.0.0`, syntetyczne `input_hash`). Regeneracja wg jednego kanonu — właściciel: P10 GOLDEN_ORACLE.

## K2. Bramka Time Gate CI (I05)
- Każda zmiana okna ważności (reguła lub parametr: `valid_from`/`valid_to`) = obowiązkowy dowód ciągłości **day-1 / day0 / day+1** w tym samym PR.
- Brak dowodu = **blokada merge [BM]** (P39). Dowód = asercje testowe: day-1 nieaktywna / day0 aktywna / day+1 aktywna (lub odwrotnie dla zamknięcia okna).
- Kotwice konstytucyjne (core anchors) mają pierwszeństwo domknięcia: L07 (P1) — 2 kotwice bez pary day-1/day0 (2018-04-01 ZUS ulgi, 2019-04-01 mały ZUS+).
- Wiąże: P39 (CI), P38 (bundle), P06 (parametry).

## K3. Procedura retroaktywności i rewizji (I04)
- Retroaktywność bez jawnego przepisu przejściowego = **BLOCKER** (zasada lex retro non agit; konstytucja art. 2).
- Wykrywanie: `valid_from < changed_at` (dane, `changed_by_audit`) + flagi retro w kodzie → podejrzane zdarzenia do weryfikacji **4-eyes**.
- Lista deklaracji do rewizji = rzutowanie zdarzeń retro na golden set (replay) → powiadomienie (P08) + korekta z nowym snapshot_id.
- Seed danych archiwalnych: jawny wpis `retroactive:false` + `source_act` (Dz.U.) — L06 (P3): `vat.standard_rate` (valid_from 2026-01-01 < changed_at 2026-08-08) bez jawnego pola.
- Wiąże: P08 (Law Radar), P11 (certyfikaty), P10 (golden replay), P39 (CI).

## K4. Wzorce przepisów przejściowych (I09)
- Biblioteka 11 wzorców (EFFECTIVE_GATE, EPOCH_LOOKUP, LEGACY_CLOSED,
  TRANSITION_WINDOW, WINDOW_SUPERSEDE) z kotwicą prawną per wzorzec
  (0 wpisów bez legal_anchor).
- Nowa nowelizacja = instancja wzorca z biblioteki + test day-1/0/+1 (K2).
- Wiąże: wszystkie części domenowe P10–P36 (stare fakty → nowe reguły).

## K5. Five-Date Matrix — rekord decyzji (I03)
- Pięć dat każdej decyzji: **T** (transaction_date), **E** (evaluation_date),
  **F** (effective_date), **P** (publication_date), **K** (knowledge_date).
- Reguły spójności: `E ≥ T`; `F ≥ P` (vacatio); `K ≥ P`; `F ≤ E` dla przepisu stosowanego w werdykcie.
- Werdykt MUSI zawierać: `transaction_date`, `evaluation_date`, `effective_date` użytych przepisów (rozszerzenie P03) — pole `dates` w kontrakcie.
- Cichy default `evaluation_datetime="2026-01-01"` (6 miejsc w main_jdg.rego) = luka L05 (P1) — jawna decyzja fail-closed przy braku daty.
- Wiąże: P06, P08, P11, P37.

## K6. Clock Service Contract (I08)
- **Pojedyncze źródło czasu**: `input.temporal.clock` (RFC3339 lub ns), wstrzykiwany przez ewaluatora. `time.now_ns()` w regułach **DECISION = ZAKAZANY** (L11 P1: 15 reguł decyzyjnych, w tym 6 przedawnień/terminów, czyta zegar ścienny — L04 P0).
- Strefa: Europe/Warsaw (CET/CEST); daty graniczne ISO 8601 date-only; DST dotyczy wyłącznie znaczników czasu.
- Pole w werdykcie: `clock_used` + `evaluation_date` (rozszerzenie P03). Walidacje przyszłości (date_not_future, invoice_date_future) wymagają zamrożenia zegara dla replay — L11b (P3).
- Wiąże: P06 / P37 / P38 (deployment — wstrzykiwanie zegara).

## K7. Immunitet przeszłości — Past Immunity (I06)
- Identyczny snapshot_id = identyczny werdykt (hash deterministyczny + łańcuch replay + stabilność vault).
- Uruchamiany po KAŻDEJ zmianie bundle (CI): 30 golden verdicts, 0 rozjazdów łańcucha (aktualnie chain 0 przerw; hash drift L08 do P10).
- Zmiana werdyktu historycznego = wyłącznie z uzasadnieniem prawnym (K3).
- Kanon hashowania: `sha256-canonical-json-v1` (compact separators) — patrz K1.

## K8. Metryki temporalne → P37 (I07)
Rejestr metryk (nazwy + progi alarmów; pierwsza emisja = L10 P3):

| Metryka | Próg | Alert |
|---|---|---|
| `temporal_rules_registry` | ≥ 32 | none |
| `open_windows_valid_to_null` | 100% | none |
| `runtime_window_enforcement_calls` | > 0 | **CRITICAL** (dziś 0 — L01) |
| `wall_clock_decisional_rules` | 0 | **CRITICAL** (dziś 15 — L11/L04) |
| `boundary_test_coverage_anchors` | 100% | WARN (dziś 36% — L07/L14) |
| `temporal_epochs_missing_years` | 0 | WARN (dziś [2024,2026,2027]) |
| `versioned_parameters` | ≥ 1 | none |

## K9. Algebra interwałów i PASS-0 temporalny (I01)
- Niezmiennik **INV-037** (zero luk + zero nakładek okien) — dowód w CI na 3 warstwach: RULES (32 wpisy registry), PARAMS (wersjonowane), LKG (258 węzłów / 26 aktów).
- Obecny stan: warstwy RULES/PARAMS/LKG bez luk i nakładek, ale **egzekucja = 0 wywołań `is_active*`** poza definicjami (L01 P0) — okna NIE filtrują decyzji.
- **Domknięcie (bramka PASS-0):** odfiltruj werdykty reguł nieaktywnych na `input.evaluation_datetime` wg registry (`is_active_for_date`) — koniec po safe_merge, przed public contract (P02).
- Epoki: `temporal_epochs` nieciągłe (brak 2024/2026 — L02 P2; brak 2026/2027 — L13 P2); nowelizacja publikowana → epoka dodawana w momencie publikacji (P06/P08).

## K10. Pokrycie testowe kotwic temporalnych (I12)
- Heatmapa pokrycia per domena (32 kotwice w 10 domenach; pytest 16, boundary 12, golden 0).
- Cel: **100% kotwic z parą day-1/day0** (bramka K2/I05); każda nowelizacja bez testów granicznych = P2.
- L14 (P2): 16 kotwic bez żadnego pokrycia (relief_rd, exit_tax, dac6_reporting, covid_legacy, slim_vat 1-3, estoński CIT...).

---

## Rejestr luk wiążących (P0/P1)

| ID | Priorytet | Właściciel domknięcia |
|---|---|---|
| V3-P05-L01 | P0 | PASS-0 temporalny (K9) — P05/I01 kontrakt; egzekucja w rego (P07/P38) |
| V3-P05-L04 | P0 | Zegar wstrzykiwany zamiast `time.now_ns` w 15 regułach DECISION (K6) |
| V3-P05-L05 | P1 | Jawny default evaluation_datetime (fail-closed) — 6 miejsc main_jdg |
| V3-P05-L07 | P1 | Time Gate CI — 2 kotwice core bez pary day-1/day0 (K2) |
| V3-P05-L08 | P1 | 4 drifty hash golden_verdicts — regeneracja w P10 (K1) |
| V3-P05-L11 | P1 | 15 reguł DECISION na zegarze ściennym (K6, razem z L04) |
| V3-P05-L02/L13 | P2 | Epoki 2024/2026/2027 — dodawane przy publikacji (P06/P08) |
| V3-P05-L14 | P2 | 16 kotwic bez testów — heatmapa K10, cele kwartalne |
| V3-P05-L06/L10/L11b | P3 | Jawne retroactive:false w seedach; dashboard P37; zamrożenie zegara replay |

Konflikty kontraktowe z wcześniejszymi częściami: brak KONFLIKTÓW — P05 rozszerza
P03 (pola `snapshot_id`, `clock_used`, `dates` — additive 1.1), honoruje INV-037
(P04) i allowlistę niemutowalną (P02).
