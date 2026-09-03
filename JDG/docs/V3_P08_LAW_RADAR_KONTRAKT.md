# KONTRAKT V3-P08 — LAW RADAR (monitoring prawa i adaptacja)

> Seria V3 (GLM 5.2) · Część P08 · Status: WDROŻONY_100 · Data: 2026-09-03
> Dokument wiążący dla P09, P10, P37, P38, P39, P43, P44, P06, P07, P05, P04.
> Pełny raport: `raporty_glm52_v3/RAPORT_V3_P08_LAW_RADAR.txt`.

## 1. Kanoniczne źródła (radar)
K1. Radar = `bundles/law_radar.json` (projekty) + `bundles/legal_change_calendar.json`
    (zmiany z datą wejścia). Każdy projekt: `source ∈ {RCL, SEJM, SENAT, ISAP_ACT}`,
    `status ∈ {PRACUJE_RCL, PIERWSZE_CZYTANIE, KOMISJE, DRUGIE_CZYTANIE, SENAT,
    PODPIS, ENACTED, WITHDRAWN, REPEALED}`, `confidence_draft` wg modelu etapów
    (0.25→1.0). Wiąże P09/P10/P38.
K2. Każda zmiana w kalendarzu ma `rules_prepared` (reguły SHADOW) i `lead_ok`
    (lead ≥ 30 dni). Zmiana bez przygotowanych reguł = NIE_GOTOWE. Wiąże P07/P38.

## 2. Diff prawny (AI-Reader)
K3. Schemat diffu (kanon, zgodny z LKG P01): `act, legal_unit, legal_node_id,
    change_type, old_text, new_text, effective_from, certainty` — artefakt
    `bundles/v3_p08_legal_diff_schema.json`. Wiąże P01 (LKG), P09, P10.
K4. AI-Reader wymaga walidacji 4-eyes: drugi model + prawnik; diff bez walidacji
    ma `certainty = 0.0` i nie może zasilać ACTIVE. Wiąże P10 (golden), P44.

## 3. Adaptacja i lifecycle
K5. Ścieżka zmiany: feed/drift → impact matrix (priorytet + szacunek) →
    pre-life SHADOW (dry run na bieżących danych) → CANDIDATE → ACTIVE w dniu
    wejścia. Bramki 30/14/7 dni (I04). Wiąże P07, P05, P06, P38.
K6. Uchylenie (REPEALED) → automatyczny wniosek deprecate do lifecycle (P07)
    z karencją; reguła ACTIVE z uchyloną podstawą = P1. Wiąże P07, P05.
K7. Scenariusze: projekt może mieć wiele wariantów (I07); uchwalenie wariantu A
    unieważnia B/C przez `superseded_by`. Wiąże P05 (okna per wariant), P07.

## 4. Raport gotowości i API
K8. Raport gotowości (I10, cykliczny): per zmiana status GOTOWE /
    W_PRZYGOTOWANIU / NIE_GOTOWE + data wejścia + reguły. Wiąże P37, P44, P41 (UI).
K9. API statusu (I12): `GET /api/v1/law-radar` → per ustawa
    `{status, effective_date, rule_ids, updated_at}`; brak danych = NEEDS_ADVICE.
    Wiąże P41 (UI księgowe), P37.
K10. SLO detekcji (I09): zmiana wykryta < 1 h od publikacji (webhook primary,
     polling fallback); metryka `time-to-detect` w P37. Wiąże P37, P43.

## Luki przekazane dalej (właściciele)
| Luka | Priorytet | Właściciel domknięcia |
|------|-----------|-----------------------|
| L01 feed projektów RCL/Sejm/Senat + predicted_diff | P1 | P09/P10 + kanał zewnętrzny |
| L02 AI-Reader diff + 4-eyes (llm_bridge rola) | P1 | P10 (golden), P44 |
| L03 0 reguł/parametrów z valid_from w przyszłości (pre-life) | P1 | P07, P05, P38 |
| L04 SLA lead 30/14/7 niewymierne | P1 | P37 (metryki), P38 |
| L05 impact matrix nieautomatyczny, brak szacunku | P1 | P06/P10–P36, P07 |
| L08 brak kanału REPEALED→deprecate | P1 | P07, P05 |
| L06/L07/L09/L10/L12 kalendarz, scenariusze, feed, gotowość, API | P2 | P37/P41/P09 |
| L11 E2E do SHADOW→ACTIVE/bundle | P3 | P07/P38/P10 |
