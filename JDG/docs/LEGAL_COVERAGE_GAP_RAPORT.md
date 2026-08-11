# 📊 LEGAL COVERAGE GAP REPORT — P02 (sekcja 3)

> Wygenerowano: 2026-08-11T19:35:15.217378+00:00 · generator: `legal_coverage_gap_report.py`

## Podsumowanie

- Artykuły w LEGAL_COVERAGE.md: 27
- Punkty prawne deklarowane: 18
- COMPLETE: 5 · PARTIAL: 16 · GAP: 6
- Rzeczywiste rule_id w rules/: 11992

## Priorytety domknięcia luk

| Priorytet | Luk |
|---|---|
| P1_KKS | 2 |
| P1_VAT_odliczenia | 1 |
| P1_amortyzacja | 0 |
| P2_UoR | 0 |
| P2_PCC_lokalne_akcyza | 0 |

### Szczegóły priorytetów

**P1_KKS**
- IV. KKS — KODEKS KARNY SKARBOWY Art. 16 — Czynny żal
- IV. KKS — KODEKS KARNY SKARBOWY Art. 44 — Przedawnienie karalności przestępstw (5 lat)

**P1_VAT_odliczenia**
- I. USTAWA O VAT Art. 86 — Odliczenie VAT naliczonego

**P1_amortyzacja**
- (brak)

**P2_UoR**
- (brak)

**P2_PCC_lokalne_akcyza**
- (brak)

## Tabela pokrycia (akt × artykuł × status)

| Akt | Art. | Status deklarowany | Status faktyczny | Brakujące reguły |
|---|---|---|---|---|
| I. USTAWA O VAT | 5 — Definicja dostawy towarów i świadczenia usług | COMPLETE | **PARTIAL** | jdg.vat.a5.r1 |
| I. USTAWA O VAT | 17 — Reverse charge (odwrotne obciążenie) | COMPLETE | **GAP** | jdg.vat.a17.r5 |
| I. USTAWA O VAT | 41 — Stawki VAT (23%, 8%, 5%, 0%, ZW) | COMPLETE | **PARTIAL** | jdg.vat.a41.r1 |
| I. USTAWA O VAT | 86 — Odliczenie VAT naliczonego | COMPLETE | **PARTIAL** | jdg.vat.a86.r1 |
| I. USTAWA O VAT | 89a — Ulga na złe długi — wierzyciel | COMPLETE | **PARTIAL** | jdg.vat.a89a.r1 |
| I. USTAWA O VAT | 89b — Złe długi — obowiązek korekty dłużnika | COMPLETE | **PARTIAL** | jdg.vat.a89b.r1 |
| I. USTAWA O VAT | 90 — Proporcja VAT | COMPLETE | **GAP** | jdg.vat.a90.r1 |
| I. USTAWA O VAT | 106e — Elementy faktury (paragon ≤450 zł z NIP) | COMPLETE | **PARTIAL** | jdg.vat.a106e.r10 |
| I. USTAWA O VAT | 113 — Zwolnienie podmiotowe do 200 000 PLN | COMPLETE | **GAP** | jdg.vat.a113.r1 |
| I. USTAWA O VAT | 106na-106nq — KSeF (obowiązkowe e-faktury od 01.02.2026) | COMPLETE | **PARTIAL** | jdg.ksef_jpk.jpk_gtu_completeness, jdg.ksef_jpk.jpk_pkpir, jdg.ksef_jpk.jpk_v7m |
| II. USTAWA O PIT | 9 — Strata podatkowa | COMPLETE | **GAP** | jdg.pit.advances_returns.loss_carry_forward |
| II. USTAWA O PIT | 14 — Przychody z działalności gospodarczej | COMPLETE | **PARTIAL** | jdg.pit.a14.r1 |
| II. USTAWA O PIT | 22 — Koszty uzyskania przychodu | COMPLETE | **PARTIAL** | jdg.pit.a22.r1 |
| II. USTAWA O PIT | 23 — Wydatki NKUP | PARTIAL | **PARTIAL** | jdg.pit.a23.r1 |
| II. USTAWA O PIT | 27 — Skala podatkowa 12%/32% | COMPLETE | **PARTIAL** | jdg.pit.a27.r1 |
| II. USTAWA O PIT | 30c — Podatek liniowy 19% | COMPLETE | **GAP** | jdg.pit.a30c.r1 |
| II. USTAWA O PIT | 30ca — IP Box (5%) | COMPLETE | **PARTIAL** | jdg.pit.a30ca.r1 |
| II. USTAWA O PIT | 30f — CFC (Zagraniczna Spółka Kontrolowana) | COMPLETE | **COMPLETE** | — |
| III. ORDYNACJA PODATKOWA | 70 — Przedawnienie zobowiązań (5 lat) | COMPLETE | **PARTIAL** | jdg.ord.a70.r1 |
| III. ORDYNACJA PODATKOWA | 81 — Korekty deklaracji | COMPLETE | **PARTIAL** | jdg.ord.a81.r1 |
| III. ORDYNACJA PODATKOWA | 117ba — Biała Lista | COMPLETE | **GAP** | jdg.ord.a117ba.r1 |
| IV. KKS — KODEKS KARNY SKARBOWY | 16 — Czynny żal | COMPLETE | **PARTIAL** | jdg.kks.voluntary_disclosure_art16, jdg.kks.voluntary_disclosure_correction_before_audit, jdg.kks.voluntary_disclosure_deadline |
| IV. KKS — KODEKS KARNY SKARBOWY | 44 — Przedawnienie karalności przestępstw (5 lat) | COMPLETE | **PARTIAL** | jdg.kks.statute_of_limitations_crime_5y |
| IV. KKS — KODEKS KARNY SKARBOWY | 54 — Uchylanie się od opodatkowania | PARTIAL | **COMPLETE** | — |
| IV. KKS — KODEKS KARNY SKARBOWY | 56 — Nierzetelne księgi/PKPiR | COMPLETE | **COMPLETE** | — |
| IV. KKS — KODEKS KARNY SKARBOWY | 62 — Puste faktury | COMPLETE | **COMPLETE** | — |
| IV. KKS — KODEKS KARNY SKARBOWY | 57 — Nierzetelna ewidencja VAT | COMPLETE | **COMPLETE** | — |

*Status faktyczny = weryfikacja istnienia deklarowanych rule_id oraz niepustej podstawy prawnej i statycznego evidence syntaktycznego (assert/call) dla każdego dopasowanego rule_id; evidence nie zastępuje dowodu wykonania runtime.*
