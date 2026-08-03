# P15 — Środowisko + BDO + Branża (Enterprise)

Pakiet: `jdg.p15_srodowisko_bdo_innovations`
Plik: `JDG/rules/p15_srodowisko_bdo_innovations_v9.rego`
Raport: `raporty_jdg_enterprise/R15_Srodowisko_BDO_Branza.txt`
Narzędzie: `JDG/tools/bdo_environment_auditor.py`

## Zakres (8 sekcji promptu wdrożone jako reguły)

| Sekcja | Reguły | Status |
|---|---|---|
| 1. Mapa pokrycia | `srodowisko_bdo_coverage_report` — 8 modułów (rejestracja, ewidencja, EWC, transport, zezwolenia, WEEE/baterie, środowisko, budownictwo) z `data.jdg.p15_audit` + gap_pct | ✅ |
| 1. AUDYT BDO (PRIORYTET) | `bdo_audit` — opłaty rejestracyjne 100/300/500 zł (art. 49-53 UoO), kara 5000 zł (art. 194 UoO), ewidencja kwartalna, KPO elektroniczne, WEEE/baterie, opakowania | ✅ |
| 1. Asystent BDO (INN-01) | `bdo_assistant` — rejestracja, opłaty per rozmiar firmy, alerty, terminy | ✅ |
| 1. KPO (INN-02) | `kpo_generator` — kody EWC, karta przekazania odpadów elektronicznie (art. 66-70 UoO) | ✅ |
| 1. Terminy (INN-03) | `bdo_deadline_tracker` — ewidencja kwartalna do 15., sprawozdania roczne do 15.03 | ✅ |
| 1. Opłaty produktowe (INN-04) | `product_fee_tracker` — opakowania 2 zł/kg, WEEE/baterie | ✅ |
| 2. AUDYT BUDOWNICTWA (PRIORYTET) | `budownictwo_audit` — pozwolenie/zgłoszenie, nadzór, podatek od nieruchomości, VAT 8%/23%, KUP | ✅ |
| 2. Pozwolenie (INN-05) | `budowlane_pozwolenie_calculator` — typ inwestycji (prawo budowlane art. 28-30) | ✅ |
| 3. TRANSPORT I ROLNICTWO | `transport_rolnictwo_audit` — licencja wspólnotowa (art. 5 u.t.d.), tachograf >3,5t, rolnik ryczałtowy (PIT art. 20 pkt 1 — 150 000 zł), podatek rolny | ✅ |
| 4. ZAWODY REGULOWANE / TAX-FREE / SEZONOWOŚĆ | `regulated_taxfree_seasonal_audit` — izby/komisje, VAT-REF (art. 127-130 VAT), sezonowość rozliczeń | ✅ |
| 5. CBAM | `cbam_audit` + `cbam_calculator` (INN-06) — rozporządzenie UE 2023/956, raporty kwartalne, certyfikaty od 2026, estoński CIT | ✅ |
| 6. OPA jako system | `bdo_pipeline_snapshot` — pipeline ingest→generate→verify→emit (ADR-002, hot-reload) | ✅ |
| 7. Genius ideas (12) | INN-01..12: bdo_assistant, kpo_generator, bdo_deadline_tracker, product_fee_tracker, budowlane_pozwolenie_calculator, cbam_calculator, branza_compliance_panel, branza_template_hook, regulated_profession_assistant, taxfree_calculator, seasonal_assistant, agricultural_tax_calculator | ✅ |
| 8. Mapa drogowa | w raporcie R15 — luki P0/P1/P2 | ✅ |

## Progi (ADR-002 — `data.jdg.thresholds.bdo_environment`)

- Opłaty rejestracyjne BDO: mikro 100 / mały 300 / średni 500 zł
- Kara za brak rejestracji: 5 000 zł (art. 194 UoO)
- Ewidencja: kwartalna; KPO elektroniczne
- Opłata produktowa za opakowania: 2 zł/kg (orientacyjnie)
- CBAM: 80 EUR/t CO2 (orientacyjna cena EU ETS)
- Podatek rolny: 2,5 q żyta/ha × 89,63 zł/q (2026)
- Tax-free: VAT 23%

## Narzędzie CLI

```bash
python JDG/tools/bdo_environment_auditor.py --audit            # audyt micro (bdo 52 + srodowisko 49 + budownictwo 65 = 166 rule_id)
python JDG/tools/bdo_environment_auditor.py --bdo-assistant    # asystent BDO
python JDG/tools/bdo_environment_auditor.py --kpo --ewc-code "17 01 01"
python JDG/tools/bdo_environment_auditor.py --product-fee --packaging-kg 100
python JDG/tools/bdo_environment_auditor.py --permit --project-type nowy_budynek
python JDG/tools/bdo_environment_auditor.py --cbam --co2-t 10 --import-value 50000
python JDG/tools/bdo_environment_auditor.py --taxfree --sale-amount 1230
python JDG/tools/bdo_environment_auditor.py --agricultural --ha-conversion 4
```

## Testy

- Rego: `JDG/tests/rego/test_p15_srodowisko_bdo_enterprise.rego` (24 scenariusze)
- Pytest: `JDG/tests/auto/test_p15_srodowisko_bdo_enterprise.py` (23 testy)
- Pełny przebieg P01-P15: 256 testów

## Okablowanie

- `main_jdg.rego`: `import data.jdg.p15_srodowisko_bdo_innovations` (PAS 18q), wpis w `_package_decisions`, `final_verdict_p15 = safe_merge(final_verdict_p14, ...)` — bez kolizji ze starym pakietem `jdg.p15_innovations` (v8).
