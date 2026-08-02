# NexusAI JDG — Legal Coverage Documentation
# ═══════════════════════════════════════════════════════════════════════════════
# Source: NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt, Part 2
# Purpose: Documents the legal coverage of 13 acts (1935 legal points) for JDG.
# Each act mapped to Rego packages with coverage status and gaps.
# Auto-generated template — filled by ISAP Crawler (C3) and A3 Legal Cartography.
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# I. USTAWA O VAT — 350 punktów prawnych
# ═══════════════════════════════════════════════════════════════════════════════

## Art. 5 — Definicja dostawy towarów i świadczenia usług
- **Punkty prawne:** V.01-V.05
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a5.r1`
- **Pliki:** `JDG/rules/vat/substantive.rego`
- **Progi:** brak

## Art. 17 — Reverse charge (odwrotne obciążenie)
- **Punkty prawne:** V.17-V.23
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a17.r5`, `jdg.crossborder.eu_reverse_charge`
- **Pliki:** `JDG/rules/vat/substantive.rego`, `JDG/rules/crossborder.rego`
- **Progi:** `vat_reverse_charge_threshold`

## Art. 41 — Stawki VAT (23%, 8%, 5%, 0%, ZW)
- **Punkty prawne:** V.41-V.45
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a41.r1`, `jdg.vat.substantive.vat_rate_calculator`
- **Pliki:** `JDG/rules/vat/substantive.rego`
- **Progi:** `vat_standard_rate`, `vat_reduced_rate_8`, `vat_reduced_rate_5`, `vat_zero_rate`

## Art. 86 — Odliczenie VAT naliczonego
- **Punkty prawne:** V.86-V.95
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a86.r1`, `jdg.vat.deductions.*`
- **Pliki:** `JDG/rules/vat/deductions.rego`
- **Progi:** `vat_deduction_proportion`

## Art. 89a — Ulga na złe długi — wierzyciel
- **Punkty prawne:** V.89a.1-V.89a.9
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a89a.r1`, `jdg.conflicts.bad_debt_creditor_vat_corrected_but_not_pit`
- **Pliki:** `JDG/rules/vat/substantive.rego`, `JDG/rules/conflicts.rego`
- **Progi:** `vat_bad_debt_days` (90 dni od SLIM VAT 3/2025)
- **Temporal:** ⚠️ P189: 150 dni → 90 dni (2025-07-01)

## Art. 89b — Złe długi — obowiązek korekty dłużnika
- **Punkty prawne:** V.89b.1-V.89b.5
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a89b.r1`, `jdg.conflicts.bad_debt_debtor_vat_vs_pit_income`
- **Pliki:** `JDG/rules/vat/deductions.rego`, `JDG/rules/conflicts.rego`
- **Progi:** `vat_bad_debt_days`, `vat_bad_debt_sanction_30pct`

## Art. 90 — Proporcja VAT
- **Punkty prawne:** V.90.1-V.90.10
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a90.r1`, `jdg.vat.procedures.pre_proportion`
- **Pliki:** `JDG/rules/vat/procedures.rego`
- **Progi:** `vat_proportion_min_threshold` (2%), `vat_proportion_max_threshold` (98%)

## Art. 106e — Elementy faktury (paragon ≤450 zł z NIP)
- **Punkty prawne:** V.106e.1-V.106e.14
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a106e.r10`, `jdg.validation.*`
- **Pliki:** `JDG/rules/vat/substantive.rego`, `JDG/rules/validation.rego`
- **Progi:** `vat_receipt_nip_limit` (450 PLN)

## Art. 113 — Zwolnienie podmiotowe do 200 000 PLN
- **Punkty prawne:** V.113.1-V.113.13
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.vat.a113.r1`, `jdg.edge_cases.vat_breach_mid_year`, `jdg.edge_cases.vat_breach_proportion_new_jdg`
- **Pliki:** `JDG/rules/vat/substantive.rego`, `JDG/rules/edge_cases.rego`
- **Progi:** `vat_subject_exemption_limit` (200 000 PLN)

## Art. 106na-106nq — KSeF (obowiązkowe e-faktury od 01.02.2026)
- **Punkty prawne:** V.106na-V.106nq
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.ksef_jpk.*`, `jdg.validation.ksef_upo_required`, `jdg.edge_cases.vat_ksef_mandatory_from_2026`
- **Pliki:** `JDG/rules/ksef_jpk.rego`, `JDG/rules/validation.rego`, `JDG/rules/edge_cases.rego`
- **Progi:** `ksef_mandatory_from_date` (2026-02-01), `ksef_offline_grace_days` (7), `ksef_sanction_max_pln` (500 000)

## BRAKI (Klasa B — szkielety):
- V.060-V.099: Szczegółowe definicje dostawy (Art. 5-7)
- V.100-V.139: Reverse charge — pełna lista towarów i usług
- V.140-V.179: Podatnik VAT — definicje małego podatnika, rolnika ryczałtowego
- V.180-V.219: Odliczenia — szczegółowe warunki (Art. 86-88)
- V.220-V.259: Proporcja — korekta roczna (Art. 90-91)
- V.260-V.289: Import towarów (Art. 116-123)
- V.290-V.319: WNT szczegółowe (Art. 117-138)


# ═══════════════════════════════════════════════════════════════════════════════
# II. USTAWA O PIT — 320 punktów prawnych
# ═══════════════════════════════════════════════════════════════════════════════

## Art. 9 — Strata podatkowa
- **Punkty prawne:** P.09.1-P.09.5
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.advances_returns.loss_carry_forward`
- **Progi:** `pit_loss_carry_years` (5), `pit_loss_carry_max_pct` (50%)

## Art. 14 — Przychody z działalności gospodarczej
- **Punkty prawne:** P.14.1-P.14.8
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.a14.r1`
- **Pliki:** `JDG/rules/pit/forms.rego`

## Art. 22 — Koszty uzyskania przychodu
- **Punkty prawne:** P.22.1-P.22.15
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.a22.r1`, `jdg.pit.kup.*`
- **Pliki:** `JDG/rules/pit/kup.rego`

## Art. 23 — Wydatki NKUP
- **Punkty prawne:** P.23.1-P.23.57
- **Pokrycie JDG:** ⚠️ PARTIAL
- **Reguły Rego:** `jdg.pit.a23.r1`, `jdg.conflicts.representation_vs_marketing_classification`
- **Pliki:** `JDG/rules/pit/kup.rego`, `JDG/rules/conflicts.rego`
- **Luki:** art23_pkt23_representation_detail, art23_pkt46_car_75pct, art23_pkt47_lease_limit

## Art. 27 — Skala podatkowa 12%/32%
- **Punkty prawne:** P.27.1-P.27.9
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.a27.r1`, `jdg.pit.forms.scale`
- **Pliki:** `JDG/rules/pit/forms.rego`
- **Progi:** `pit_scale_low_rate` (12%), `pit_scale_high_rate` (32%), `pit_scale_threshold` (120 000), `pit_tax_free_amount` (30 000)

## Art. 30c — Podatek liniowy 19%
- **Punkty prawne:** P.30c.1-P.30c.3
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.a30c.r1`, `jdg.pit.forms.linear`
- **Pliki:** `JDG/rules/pit/forms.rego`
- **Progi:** `pit_linear_rate` (19%)

## Art. 30ca — IP Box (5%)
- **Punkty prawne:** P.30ca.1-P.30ca.11
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.pit.a30ca.r1`, `jdg.conflicts.ip_box_*`
- **Pliki:** `JDG/rules/allowances.rego`, `JDG/rules/conflicts.rego`
- **Progi:** `pit_ip_box_rate` (5%)

## Art. 30f — CFC (Zagraniczna Spółka Kontrolowana)
- **Punkty prawne:** P.30f.1-P.30f.20
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.crossborder.cfc_jdg_controlled`
- **Progi:** `cfc_control_threshold` (50%), `cfc_passive_income_threshold` (33%)

## BRAKI (Klasa B/C):
- P.060-P.149: Zwolnienia przedmiotowe (Art. 21) — Klasa B
- P.150-P.169: Ulgi i odliczenia (Art. 26) — Klasa B
- P.170-P.229: Amortyzacja szczegółowa (Art. 22a-22o) — Klasa B
- P.230-P.249: Exit Tax (Art. 30da) — Klasa C


# ═══════════════════════════════════════════════════════════════════════════════
# III. ORDYNACJA PODATKOWA — 180 punktów prawnych
# ═══════════════════════════════════════════════════════════════════════════════

## Art. 70 — Przedawnienie zobowiązań (5 lat)
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.ord.a70.r1`, `jdg.liability.statute_5_years`
- **Progi:** `ord_statute_of_limitations_years` (5)

## Art. 81 — Korekty deklaracji
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.ord.a81.r1`, `jdg.corrections.vat_declaration_period`

## Art. 117ba — Biała Lista
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.ord.a117ba.r1`
- **Progi:** `ord_whitelist_verification_days` (30)


# ═══════════════════════════════════════════════════════════════════════════════
# IV. KKS — KODEKS KARNY SKARBOWY — 160 punktów prawnych
# ═══════════════════════════════════════════════════════════════════════════════

## Art. 16 — Czynny żal
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.kks.voluntary_disclosure_*` (P200-P209)

## Art. 44 — Przedawnienie karalności przestępstw (5 lat)
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.kks.statute_of_limitations_crime_5y`

## Art. 54 — Uchylanie się od opodatkowania
- **Pokrycie JDG:** ⚠️ PARTIAL
- **Reguły Rego:** `jdg.kks.tax_evasion_*` (P240-P254, 15 reguł)
- **Luki:** kks_art54_penalty_graduation, kks_art54_materiality_threshold

## Art. 56 — Nierzetelne księgi/PKPiR
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.kks.unreliable_books_*` (P255-P269, 15 reguł)

## Art. 62 — Puste faktury
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.kks.empty_invoice_*` (P300-P319, 20 reguł)

## Art. 57 — Nierzetelna ewidencja VAT
- **Pokrycie JDG:** ✅ COMPLETE
- **Reguły Rego:** `jdg.kks.unreliable_vat_*` (P270-P279, 10 reguł)

## BRAKI (Klasa B):
- Art. 54-83: 78 brakujących szczegółowych reguł KKS


# ═══════════════════════════════════════════════════════════════════════════════
# V-XIII: POZOSTAŁE AKTY
# ═══════════════════════════════════════════════════════════════════════════════

## V. SUS/ZUS (120 punktów) — pokrycie ~15%
- Ulga na start (P740), Mały ZUS+ (P741), Preferencyjny (P742) — ✅ COMPLETE
- Zawieszenie R0582 — ✅ NAPRAWIONE
- Zdrowotna P720/P722/P724 — ✅ COMPLETE
- Zasiłki chorobowe — ⚠️ Klasa C

## VI. Ryczałt (90 punktów) — pokrycie ~20%
- Stawki PKWiU (P521), limit 2M EUR (P523) — ✅ COMPLETE

## VII. Prawo Przedsiębiorców (80 punktów) — pokrycie ~10%
- CEIDG (P900), nieewidencjonowana (P930) — ✅ COMPLETE

## VIII. UoR (100 punktów) — pokrycie ~0% ⚠️
- 56 reguł PKPiR = matched:false (martwa warstwa)
- Wymaga implementacji P811-P818 (walidacja kolumn PKPiR)

## IX. PCC + Lokalne + Akcyza (225 punktów) — pokrycie ~1% ❌
- local_taxes.rego: 4 reguły z ~80 potrzebnych
- Największa luka w pokryciu!

## X. Cross-border/TP/CFC/ViDA (80 punktów) — pokrycie <2%
- MDR/DAC6 (P1800-P1809) — Klasa C

## XI. CEIDG/Sukcesja/PPK (60 punktów) — pokrycie ~10%
- Sukcesja (P920-P928) — ✅ COMPLETE

## XII. Zdrowotna + Zasiłkowa (50 punktów) — pokrycie ~15%

## XIII. AML V/RODO/BDO/SUP/KOBiZE (120 punktów) — pokrycie ~5%
- RODO (P1610-P1621) — ✅ COMPLETE
- AML (P1731+) — ⚠️ Klasa C


# ═══════════════════════════════════════════════════════════════════════════════
# PODSUMOWANIE
# ═══════════════════════════════════════════════════════════════════════════════

Status na 2026-08-02 (zaktualizowany po audycie P25, v8.0):

| Klasa | Opis | % punktów |
|-------|------|-----------|
| A (GOTOWE) | matched:true z pełną logiką i testami | ~31% (600 pkt) |
| B (SZKIELETY) | Framework Rego istnieje, treść z ISAP do wciągnięcia | ~57% (1100 pkt) |
| C (PLANOWANE) | Tylko dokumentacja, brak implementacji | ~12% (235 pkt) |

**Łącznie:** 1935 punktów prawnych w 13 aktach.

**Następne priorytety:**
1. Klasa IX (PCC + lokalne + akcyza) — 225 punktów, największa luka
2. Klasa VIII (UoR) — 100 punktów, martwa warstwa PKPiR
3. Klasa B — 1100 punktów do wypełnienia z ISAP

---
*Dokument wygenerowany z NexusAI_JDG_7000_MASTER_IMPLEMENTATION_PLAN.txt, Part 2.*
*Auto-aktualizowany przez ISAP Crawler (C3) i A3 Legal Cartography.*
*Data ostatniej aktualizacji: 2026-08-02 (Audyt P25 — rekomendacja R9).*
*Uwaga: Klasyfikacja A/B/C wymaga pełnego przeliczenia po 20+ commitach od 2026-07-17.*
*Nowe narzędzia: doc_consistency_validator.py, dead_rule_detector.py, cross_ref_validator.py*
