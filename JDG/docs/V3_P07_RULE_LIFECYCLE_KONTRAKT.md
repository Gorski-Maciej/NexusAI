# V3-P07 KONTRAKT CYKLU ŻYCIA REGUŁ (WIĄŻĄCY DLA P08–P68)

Kontrakt wyjściowy części P07 (RULE_LIFECYCLE). Wiąże: P08 (Law Radar),
P09 (declarative change), P10 (golden oracle), P37 (obserwowalność), P38
(deployment), P39 (testy/CI), P40 (jakość), P43 (security/DR), P44
(certyfikacja) oraz P07–P36 (rejestracja reguł domenowych). Źródło:
prompty_v3/V3_PROMPT_P07_RULE_LIFECYCLE.txt §11.2 + wnioski
RAPORT_V3_P07_RULE_LIFECYCLE.txt (12 innowacji; bramki 9 FAIL / 3 PASS;
luki L01–L18).

---

## K1. Kryteria awansu + protokół 4-eyes (I01/I05) — wiąże P38/P40/P44
- Awans SHADOW→CANDIDATE→ACTIVE tylko z wyrokiem PASS zamkniętej listy:
  `tests_ok`, `delta_shadow ≤ 2%`, `quality ≥ 95%`, `no_temporal_conflict`,
  `four_eyes` (autor ≠ recenzent ≠ operator), `error_rate ≤ próg`.
- Wyrok HOLD = blokada [BM] z listą niespełnionych kryteriów; MANUAL = 4-eyes.
- Role zapisywane w rekordach operacji (owner/reviewed_by/operator) — dziś
  0/13 wersji (L04 P1); model SQL istnieje (migracja 007: policy_change_reviews,
  control_plane_audit) — narzędzia JSON muszą go honorować.

## K2. Immutable Rule Vault (I02) — wiąże P38/P39/P44/P05
- Każda wersja reguły = artefakt z hashem kanonicznym
  (`sha256-canonical-json-v1`) i podpisem ról; edycja istniejącej wersji =
  BLOCKER [BM]; nowa wersja = NOWY wpis.
- Dziś 0/13 wersji z hashem; rule_lifecycle_manager mutuje JSON w miejscu
  (L05 P1) — wymagany append-only log operacji (WORM, wzorzec P04).

## K3. Shadow Delta Automator (I03) — wiąże P38/P39/P37
- Faza SHADOW_COMPARE obowiązkowa przed awansem: delta werdyktów ≤ 2%
  (mechanizm istnieje w deployment_orchestrator; automatyzacja brak — L06 P1).
- Dowód zapisywany w deployments.json (shadow_delta_pct) — dziś 25/44 wpisów
  ma deltę, 0 przeszło fazę przejściową; raport różnic do PR.

## K4. Kill-Switch i SLO (I04) — wiąże P43/P37/P04
- Suspend pojedynczej reguły < 1 s (istnieje: cmd_suspend); BRAK: suspend
  pakietu/domeny, NEEDS_ADVICE dla dotkniętych strumieni, pomiar SLO (L09 P1).
- SLO wiążące: MTTR ≤ 15 min, auto-rollback ≤ 5 min; decyzje dotknięte =
  NEEDS_ADVICE (fail-closed); alert + audyt (kto/kiedy/dlaczego).

## K5. Proces deprecate→retire→purge (I06) — wiąże P39/P44/P10
- Karencja 2 okresów rozliczeniowych między DEPRECATED a RETIRED (dziś
  natychmiastowe przejścia — L10 P1); purge tylko po dowodzie ZEROWYCH odwołań
  (werdykty/reguły/testy) + zielony golden replay (P10); tygodniowy raport
  „reguły do usunięcia” z telemetrią procesu.

## K6. Rejestr zmian (I09/I01) — źródło dla P09 i P08
- Registry Reconciler w CI: każdy nowy rule_id w kodzie rejestrowany
  (CANDIDATE); dryf > 1% = alert [BM]. Dziś: 13/12 439 reguł w rejestrze
  (pokrycie 0,10% — L01 P0).
- Każda zmiana = wpis w rejestrze zmian (kto/kiedy/dlaczego/supersedes) —
  wejście do P09 (declarative change) i P08 (Law Radar pipeline).

## K7. Kolejkowanie zmian per domena (I07) — wiąże P09/P38
- Lock per domena na czas zmiany (register→awans); druga zmiana = HOLD;
  kolejka FIFO; konflikt wymaga 4-eyes (L11 P2 — mechanizm częściowy).

## K8. Granica roku podatkowego (I08) — wiąże P05/P06/P39
- Wersje ROCZNE wchodzą z valid_from=01.01 + test day-1/day0 (P05-I05);
  testy granicy roku w tests/ istnieją (20 trafień) — dla reguł rejestru
  wymagane domknięcie (L12/L13 P2).

## K9. Telemetria lifecycle (I10) — wiąże P37/P43
- Metryki: `lifecycle_pr_to_prod_hours`, `lifecycle_mttr_minutes`,
  `lifecycle_auto_rollback_minutes`, `lifecycle_rollback_count`,
  `lifecycle_shadow_delta_pct`, `lifecycle_shadow_age_days`.
- Dziś PR→prod/MTTR/auto-rollback NIE są mierzone (L15 P2); wskaźnik
  rollbacków w historii deploymentów 57% (L07 P2 — wymaga analizy przyczyn).

## K10. Runbooki awaryjne + AUTO_POST lifecycle (I11/I12) — wiąże P43/P03
- Runbooki deklaratywne (RB-01..RB-04: kill-switch, auto-rollback, freeze P04,
  przywrócenie healthy) — dziś BRAK artefaktów (L17 P2); testy tabletop w CI.
- Granica zaufania: pole `auto_post` (AUTO_POST/NO_AUTO_POST/SUGGEST_ONLY)
  w schema wersji; ACTIVE + NO_AUTO_POST = decyzje SUGGEST do pełnego dowodu
  (P03-I11); dziś 0/13 wersji z deklaracją (L18 P2).

---

## Rejestr luk wiążących

| ID | Priorytet | Właściciel domknięcia |
|---|---|---|
| V3-P07-L01 | P0 | Pokrycie rejestru 0,10% (13/12 439) — Registry Reconciler w CI; rejestracja przez P07–P36 |
| V3-P07-L02 | P1 | cmd_promote bez kryteriów zdrowia — Promotion Contract Engine [BM] |
| V3-P07-L03 | P1 | Delta shadow ≤ 2% nieegzekwowana (0 faz przejściowych) — Shadow Delta Automator |
| V3-P07-L04 | P1 | 4-eyes nieobecne w rejestrze/deployments — Enforcement Layer (I05) |
| V3-P07-L05 | P1 | Brak hash/wersji; mutacja w miejscu — Immutable Vault (I02) |
| V3-P07-L06 | P1 | Automatyzacja shadow compare brak (mechanizm ręczny) — I03 |
| V3-P07-L07 | P2 | Wskaźnik rollbacków 57% w historii — analiza przyczyn (I10) |
| V3-P07-L09 | P1 | Kill-switch bez domeny/NEEDS_ADVICE/pomiaru SLO — I04 |
| V3-P07-L10 | P1 | Karencja 2 okresów + purge zero-ref brak — Retirement Scheduler (I06) |
| V3-P07-L11 | P2 | Lock/kolejka per domena brak — Change Queue (I07) |
| V3-P07-L12/L13 | P2 | Granica roku nieegzekwowana dla rejestru; testy przejścia roku — I08 |
| V3-P07-L15 | P2 | SLO lifecycle niewymierne (brak timestampów) — Telemetry (I10) |
| V3-P07-L16/L17 | P3/P2 | Telemetria pierwsza emisja; runbooki awaryjne brak — I10/I11 |
| V3-P07-L18 | P2 | Granica AUTO_POST poza lifecycle — I12 |

Konflikty kontraktowe z wcześniejszymi częściami: brak KONFLIKTÓW — P07 honoruje
okna temporalne i snapshot_id (P05), protokół naruszeń/auto-revert (P04),
kontrakt werdyktu i AUTO_POST gate (P03) oraz parametry-as-data (P06).
