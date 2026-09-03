# KONTRAKT V3-P09 — DECLARATIVE CHANGE (V2/F6)

> Seria V3 (GLM 5.2) · Część P09 · Status: WDROŻONY_100 · Data: 2026-09-03
> Dokument wiążący dla P10, P38, P41, P43, P44, P06, P07, P08, P04, P01, P05.
> Pełny raport: `raporty_glm52_v3/RAPORT_V3_P09_DECLARATIVE_CHANGE.txt`.

## 1. Deklaracja zmiany (kanon)
K1. Schema deklaracji v1 (I01) — JSON Schema w bundle `v3_p09_declaration_schema.json`:
    `change_type ∈ {RATE_CHANGE, THRESHOLD_CHANGE, NEW_LIMIT, DEADLINE_CHANGE,
    REPEAL, DEFINITION_CHANGE}`, pola: domain, target{kind,key}, old/new value,
    valid_from/valid_to, legal_basis{act,article,dz_u}, justification,
    declared_by, reviewers. Walidacja: daty (from ≤ to), zakresy wartości,
    istnienie podstawy w LKG (P01). Wiąże P41 (UI), P06 (parametry).
K2. Kompilacja (I02): cel deklaracji musi istnieć w `thresholds_data.json` (P06)
    lub `rule_registry.json` (P07); kompilacja do nieistniejącego klucza = FAIL
    (wykryty dryf: `vat.rate.declared` zapisywany zamiast `vat.standard_rate`).
    Wiąże P06, P07.

## 2. Recipes i wykonanie
K3. 6 recipes (I03) — RATE_CHANGE/THRESHOLD_CHANGE/NEW_LIMIT/DEADLINE_CHANGE/
    REPEAL/DEFINITION_CHANGE z mapą param→test→ryzyko→podstawa prawna (bundle
    `v3_p09_recipe_library.json`). Nowy typ zmiany = nowy recipe, nie nowy regex.
K4. Auto-test synthesizer (I04): każda deklaracja generuje 5 testów
    (D-1/D0/D+1/±grosz/negatywny); żadna deklaracja nie przechodzi 4-eyes bez
    wygenerowanych testów. Wiąże P10 (golden delta), P05, P39.
K5. Impact preview (I05): przed 4-eyes uruchomienie replayu portfela
    (law_amendment_simulator) → raport zmienionych werdyktów. Wiąże P10, P37.
K6. 4-eyes (I06): DRAFT→REVIEW_1→REVIEW_2→APPROVED→EXECUTED z rozłącznymi
    rolami i podpisami; autor ≠ obaj recenzenci; EXECUTE tylko po APPROVED.
    Wiąże P07, P43 (RBAC), migracja 007 (policy_change_reviews).

## 3. Granice i bezpieczeństwo
K7. Dangerous Change Guard (I07): bez podstawy prawnej w LKG = BLOCK; poza
    granicami deklaratywności (nowe domeny, zmiany invariantów P04, kontrakt
    werdyktu, schema diffu) = MANUAL_REVIEW; nigdy cichy zapis. Wiąże P04, P01.
K8. Law Radar Prefill (I08): diff prawny (P08) → pre-deklaracja
    AWAITS_LAWYER_CONFIRM; prefill bez potwierdzenia prawnika nie wykonuje.
    Wiąże P08, P01.
K9. Rollback-as-Declaration (I09): cofnięcie = nowa deklaracja z `reverts=DEC-X`
    przez 4-eyes; ręczne operacje na store/rejestrze = naruszenie audytu.
    Wiąże P07, P06, P43 (DR), P10.

## 4. Proces, telemetria i UI
K10. Emergency Manual Mode (I11): zmiana ręczna tylko z flagą EMERGENCY +
     retro-deklaracja ≤ 48 h (normalny 4-eyes); runbooki RB-01..04 (P07-I11)
     wymagane jako artefakt. Wiąże P43 (DR), P07.
K11. Change Telemetry (I10): każda deklaracja z declared_at/approved_at/
     executed_at + rejection_reason; SLO deklaracja→produkcja ≤ 14 dni, odrzucenia
     ≤ 20%. Wiąże P37, P41.
K12. Declarative UI Contract (I12): pola + walidacje + autocomplete LKG
     (akt→artykuł→parametr/reguła) + state machine; API POST /api/v1/
     declarations dla P41. Wiąże P41, P01 (LKG podpowiedzi).

## Luki przekazane dalej (właściciele)
| Luka | Priorytet | Właściciel domknięcia |
|------|-----------|-----------------------|
| L07 fail-open ścieżki execute (bez strażnika) | P0 | P04+P01 (guard), P39 |
| L01 brak JSON Schema + walidacji dat/LKG | P1 | P41 (UI), P01 |
| L02 dryf klucza docelowego (`vat.rate.declared`) | P1 | P06 (store), P07 |
| L03 tylko 3 wzorce regex (brak 6 recipes) | P1 | P09-I03 + P08 |
| L05 brak impact preview przed zatwierdzeniem | P1 | P10, P37 |
| L06 brak 4-eyes w execute (omija migrację 007) | P1 | P07, P43 |
| L09 brak rollback-as-declaration (brak historii) | P1 | P07, P06, P43 |
| L04/L08/L10/L11/L12 synthesizer, prefill, telemetria, tryb awaryjny, UI | P2 | P10/P08/P37/P43/P41 |
