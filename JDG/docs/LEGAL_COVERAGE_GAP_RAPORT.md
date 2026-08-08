# 📊 LEGAL COVERAGE GAP REPORT — P02 (sekcja 3)

> Wygenerowano: 2026-08-08T12:11:23.468594+00:00 · generator: `legal_coverage_gap_report.py`

## Podsumowanie

- Artykuły w LEGAL_COVERAGE.md: 27
- Punkty prawne deklarowane: 18
- COMPLETE: 15 · PARTIAL: 0 · GAP: 12
- Rzeczywiste rule_id w rules/: 11860

## Priorytety domknięcia luk

| Priorytet | Luk |
|---|---|
| P1_KKS | 5 |
| P1_VAT_odliczenia | 0 |
| P1_amortyzacja | 0 |
| P2_UoR | 0 |
| P2_PCC_lokalne_akcyza | 0 |

### Szczegóły priorytetów

**P1_KKS**
- IV. KKS — KODEKS KARNY SKARBOWY Art. 16 — Czynny żal
- IV. KKS — KODEKS KARNY SKARBOWY Art. 54 — Uchylanie się od opodatkowania
- IV. KKS — KODEKS KARNY SKARBOWY Art. 56 — Nierzetelne księgi/PKPiR
- IV. KKS — KODEKS KARNY SKARBOWY Art. 62 — Puste faktury
- IV. KKS — KODEKS KARNY SKARBOWY Art. 57 — Nierzetelna ewidencja VAT

**P1_VAT_odliczenia**
- (brak)

**P1_amortyzacja**
- (brak)

**P2_UoR**
- (brak)

**P2_PCC_lokalne_akcyza**
- (brak)

## Tabela pokrycia (akt × artykuł × status)

| Akt | Art. | Status deklarowany | Status faktyczny | Brakujące reguły |
|---|---|---|---|---|
| I. USTAWA O VAT | 5 — Definicja dostawy towarów i świadczenia usług | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 17 — Reverse charge (odwrotne obciążenie) | COMPLETE | **GAP** | jdg.vat.a17.r5 |
| I. USTAWA O VAT | 41 — Stawki VAT (23%, 8%, 5%, 0%, ZW) | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 86 — Odliczenie VAT naliczonego | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 89a — Ulga na złe długi — wierzyciel | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 89b — Złe długi — obowiązek korekty dłużnika | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 90 — Proporcja VAT | COMPLETE | **GAP** | jdg.vat.a90.r1 |
| I. USTAWA O VAT | 106e — Elementy faktury (paragon ≤450 zł z NIP) | COMPLETE | **COMPLETE** | — |
| I. USTAWA O VAT | 113 — Zwolnienie podmiotowe do 200 000 PLN | COMPLETE | **GAP** | jdg.vat.a113.r1 |
| I. USTAWA O VAT | 106na-106nq — KSeF (obowiązkowe e-faktury od 01.02.2026) | COMPLETE | **GAP** | jdg.ksef_jpk.* |
| II. USTAWA O PIT | 9 — Strata podatkowa | COMPLETE | **GAP** | jdg.pit.advances_returns.loss_carry_forward |
| II. USTAWA O PIT | 14 — Przychody z działalności gospodarczej | COMPLETE | **COMPLETE** | — |
| II. USTAWA O PIT | 22 — Koszty uzyskania przychodu | COMPLETE | **COMPLETE** | — |
| II. USTAWA O PIT | 23 — Wydatki NKUP | PARTIAL | **COMPLETE** | — |
| II. USTAWA O PIT | 27 — Skala podatkowa 12%/32% | COMPLETE | **COMPLETE** | — |
| II. USTAWA O PIT | 30c — Podatek liniowy 19% | COMPLETE | **GAP** | jdg.pit.a30c.r1 |
| II. USTAWA O PIT | 30ca — IP Box (5%) | COMPLETE | **COMPLETE** | — |
| II. USTAWA O PIT | 30f — CFC (Zagraniczna Spółka Kontrolowana) | COMPLETE | **COMPLETE** | — |
| III. ORDYNACJA PODATKOWA | 70 — Przedawnienie zobowiązań (5 lat) | COMPLETE | **COMPLETE** | — |
| III. ORDYNACJA PODATKOWA | 81 — Korekty deklaracji | COMPLETE | **COMPLETE** | — |
| III. ORDYNACJA PODATKOWA | 117ba — Biała Lista | COMPLETE | **GAP** | jdg.ord.a117ba.r1 |
| IV. KKS — KODEKS KARNY SKARBOWY | 16 — Czynny żal | COMPLETE | **GAP** | jdg.kks.voluntary_disclosure_* |
| IV. KKS — KODEKS KARNY SKARBOWY | 44 — Przedawnienie karalności przestępstw (5 lat) | COMPLETE | **COMPLETE** | — |
| IV. KKS — KODEKS KARNY SKARBOWY | 54 — Uchylanie się od opodatkowania | PARTIAL | **GAP** | jdg.kks.tax_evasion_* |
| IV. KKS — KODEKS KARNY SKARBOWY | 56 — Nierzetelne księgi/PKPiR | COMPLETE | **GAP** | jdg.kks.unreliable_books_* |
| IV. KKS — KODEKS KARNY SKARBOWY | 62 — Puste faktury | COMPLETE | **GAP** | jdg.kks.empty_invoice_* |
| IV. KKS — KODEKS KARNY SKARBOWY | 57 — Nierzetelna ewidencja VAT | COMPLETE | **GAP** | jdg.kks.unreliable_vat_* |

*Status faktyczny = weryfikacja istnienia deklarowanych rule_id w rules/.*
