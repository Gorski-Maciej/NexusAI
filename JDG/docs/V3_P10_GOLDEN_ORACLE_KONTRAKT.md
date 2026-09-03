# KONTRAKT V3-P10 — GOLDEN VERDICTS ORACLE (V2/F3)

> Seria V3 (GLM 5.2) · Część P10 · Status: WDROŻONY_100 · Data: 2026-09-03
> Dokument wiążący dla P11, P37, P38, P39, P43, P44, P04, P07, P08.
> Pełny raport: `raporty_glm52_v3/RAPORT_V3_P10_GOLDEN_ORACLE.txt`.

## 1. Nietykalność przeszłości (WORM)
K1. Golden Vault WORM (I01): golden set (`bundles/golden_verdicts.json`, schema v2,
    30 werdyktów / 29 pakietów) jest NIEMODYFIKOWALNY — zmiana = nowa wersja z
    nowym hashem i uzasadnieniem; artefakt append-only (vault/archive) wymagany.
    Wiąże P38 (deploy), P43 (WORM/DR), P44.
K2. Oracle Export & Seal (I11): eksport audytowy z merkle-root i pieczęcią
    `sha256-merkle-v1` (`v3_p10_oracle_export.json`); każda zmiana setu zmienia
    seal. Wiąże P44 (audyt KAS), P43, P41 (API).

## 2. Delta analysis i wyroki
K3. Delta Autopsy Pipeline (I02): każda delta = klasyfikacja (oczekiwana wg
    nowelizacji / REGRESJA / dryf danych) → uzasadnienie prawne → wyrok
    UZASADNIONA/NIEUZASADNIONA → wpis audytowy. Wiąże P08 (diff prawny —
    `v3_p08_legal_diff_schema.json`), P39.
K4. Merge Oracle Gate (I03): merge zablokowany dopóki UVR > 0 lub delta bez
    wyroku; bramka CI twarda (bez `|| true`). Wiąże P39, P38, P07.
K5. Delta Regression Radar (I12): szereg czasowy UVR per re-generacja; rosnący
    trend = alarm + blokada awansu automatycznego reguł (delta > próg).
    Wiąże P37, P07.
K6. Retro-Delta Explorer (I10): każda delta historyczna ma wpis (stary hash,
    nowy hash, uzasadnienie, wyrok, wersje bundle) — przeglądalne i uczące.
    Wiąże P67 (self-learning), P37.

## 3. Weryfikacja formalna
K7. Formal Proof Matrix (I04): każdy INV z katalogu P04 (42 INV) ma metodę dowodu
    (SMT/property/fuzz) i status PROVEN/UNVERIFIED; PROVEN tylko z realnym
    dowodem (Z3), nigdy z deklaracji. Wiąże P04, P39, P44.
K8. Z3 Translation Harness (I05): translacja Rego→SMT tylko dla fragmentów
    formalizowalnych (arytmetyka, progi, else-chain); fragmenty z agregacjami/
    stringami = jawnie UNVERIFIED z metodą alternatywną. Wiąże P04, P39.

## 4. Konsensus i pokrycie
K9. Dual-Node Consensus (I06): ten sam input → ten sam hash na ≥2 węzłach;
    rozbieżność = NEEDS_ADVICE (nigdy AUTO_POST) + alarm. Sesje różnicowe
    rejestrowane (`differential_sessions.json`). Wiąże P38, P43, P03, P37.
K10. Oracle Health Dashboard (I07): metryki pokrycia, % uzasadnionych delt, wiek
     setu, częstotliwość re-generacji; raportowane przy każdej re-generacji.
     Wiąże P37, P44.
K11. Independent Oracle Validator (I08): golden set walidowany NIEZALEŻNIE
     (mirror reguł / review ekspercki / legal_basis_refs) — anty self-fulfilling
     oracle. Wiąże P01 (LKG), P48 (mirror sync), P44.
K12. Golden Coverage Planner (I09): plan domykania pokrycia golden per domena;
     domeny wysokiego ryzyka (vat/pit/zus/kks/ord/…) bez pokrycia = znany limit
     w dashboardzie z planem domknięcia. Wiąże P12–P28 (domeny), P44.

## Luki przekazane dalej (właściciele)
| Luka | Priorytet | Właściciel domknięcia |
|------|-----------|-----------------------|
| L03 miękka bramka CI (golden_replay z `\|\| true`) | P0 | P39 (CI), P38 |
| L01 brak artefaktu WORM/append-only golden vault | P1 | P38, P43 (DR) |
| L02 autojustify nie czyta diffu P08 automatycznie | P1 | P08, P09 (declarative) |
| L04 brak z3-solver → dowody UNVERIFIED | P1 | P39 (CI zależności) |
| L06 brak sesji dual-node w CI/deploy | P1 | P38, P39, P43 |
| L09 pokrycie golden 29/255 pakietów (87 domen HR bez setu) | P1 | P12–P28 (seed domen) |
| L12 UVR=619 powyżej progu alarmowego (radar RED) | P1 | P10-I12 + P39 + P07 |
| L07 set < 50 werdyktów (próg reprezentatywności) | P2 | P10-I09, P12–P28 |
| L10 brak artefaktu historii delt (annotacje/sesje) | P2 | P67 (self-learning) |
