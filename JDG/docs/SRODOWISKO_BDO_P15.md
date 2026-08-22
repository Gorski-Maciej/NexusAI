# P15 — Środowisko + BDO + Branża (Enterprise)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28/29 — 2026-08-22, 14/14 bramek).

Pakiet: `jdg.p15_srodowisko_bdo_innovations`
Plik: `JDG/rules/p15_srodowisko_bdo_innovations_v9.rego`
Raport: `raporty_glm52/raport_enterprise_P15.txt`
Narzędzie: `JDG/tools/bdo_environment_auditor.py`
Wersja: v9.6 (2026-08-09) — parser fix + INN-13..17

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
| 7. Genius ideas (17) | INN-01..17: bdo_assistant, kpo_generator, bdo_deadline_tracker, product_fee_tracker, budowlane_pozwolenie_calculator, cbam_calculator, branza_compliance_panel, branza_template_hook, regulated_profession_assistant, taxfree_calculator, seasonal_assistant, agricultural_tax_calculator, **zero_click_bdo (13), bdo_registration_detector (14), weee_product_fee_calculator (15), recycling_level_tracker (16), transport_licence_assistant (17)** | ✅ |
| 8. Mapa drogowa R15 (P0/P1/P2) | **UZUPEŁNIONE 2026-08-05** — 7 reguł: `product_fee_material_map` (P0-1), `bdo_api_integration` (P0-2), `ewc_full_catalog` (P1-1), `agricultural_tax_rate_registry` (P1-2), `transport_permit_tables` (P1-3), `cbam_certificates_2026` (P2-1), `bdo_online_registration` (P2-2) + lookup w `jdg.micro.bdo_ewc` | ✅ |

## Progi (ADR-002 — `data.jdg.thresholds.bdo_environment`)

- Opłaty rejestracyjne BDO: mikro 100 / mały 300 / średni 500 zł
- Kara za brak rejestracji: 5 000 zł (art. 194 UoO)
- Ewidencja: kwartalna; KPO elektroniczne
- Opłata produktowa za opakowania: 2 zł/kg (orientacyjnie)
- CBAM: 80 EUR/t CO2 (orientacyjna cena EU ETS)
- Podatek rolny: 2,5 q żyta/ha × 89,63 zł/q (2026)
- Tax-free: VAT 23%

### Mapa drogowa R15 (uzupełniona 2026-08-05)

| Luka | Reguła / dane | Status |
|---|---|---|
| P0-1 opłaty produktowe per materiał | `packaging_fee_rates_per_material` (papier 0,50 / tworzywa 2,00 / szkło 0,20 / metale 0,30 / drewno 0,20 / wielomateriałowe 1,00 zł/kg) + `product_fee_material_map` | ✅ |
| P0-2 API BDO (KPO + sprawozdania) | `bdo_api` (endpointy, auth) + `bdo_api_integration` (status KPO/sprawozdań, ready) | ✅ |
| P1-1 pełny katalog EWC 6-cyfrowy | `ewc_catalog` — **301 kodów w 20 rozdziałach** + `ewc_full_catalog` + `jdg.micro.bdo_ewc.ewc_catalog_lookup` | ✅ |
| P1-2 stawki podatku rolnego per gmina | `agricultural_tax_multiplier_by_gmina` (rejestr + fallback 2,5 q) + `agricultural_tax_rate_registry` | ✅ |
| P1-3 tabele zezwoleń transportowych | `transport_permits` (krajowy/unijny_ue/poza_ue/tachograf) + `transport_permit_tables` | ✅ |
| P2-1 certyfikaty CBAM 2026 | `cbam_certificates` (2026-01-01, 80 EUR/t, umorzenie 31.05, kara 50 EUR/t) + `cbam_certificates_2026` | ✅ |
| P2-2 rejestracja online BDO | `bdo_online_registration` (endpoint, kroki, opłata, terminy 30 dni) + reguła | ✅ |

### Sekcja 8 — innowacje INN-13..17 (2026-08-09)

| Innowacja | Reguła | Efekt |
|---|---|---|
| INN-13 zero-click BDO | `zero_click_bdo` | ewidencja odpadów generowana automatycznie z dokumentów WZ → wpis ewidencji + KPO auto (art. 66-70 UoO) |
| INN-14 auto-detecktor rejestracji BDO | `bdo_registration_detector` | analiza opisu działalności (produkcja/transport/zbieranie) → obowiązek rejestracji przed startem, integracja P13 |
| INN-15 kalkulator opłaty WEEE | `weee_product_fee_calculator` | stawki wg kategorii (IT 3,0 / małe AGD 2,5 / duże AGD 1,5 zł/kg) + rejestracja GIOŚ |
| INN-16 tracker poziomów recyklingu | `recycling_level_tracker` | wymagane % (tworzywa 50, papier 75, szkło 70, metale 70, drewno 60) vs osiągnięte + alert RECYCLING_ALERT |
| INN-17 asystent licencji transportowej | `transport_licence_assistant` | ścieżka 6 kroków (CEIDG → niekaralność → kwalifikacja → OC → wniosek → opłata), kara 5 tys. zł |

Dane (stawki WEEE, poziomy recyklingu) w `thresholds_jdg.rego` (sekcja `bdo_environment`) — zero hardcode.

Wszystkie wartości w `JDG/rules/thresholds_jdg.rego` (sekcja `bdo_environment`) — zero hardcode w regułach (ADR-002). Katalog EWC rozszerzalny przez dodanie wpisów `{"code", "name", "hazardous"}`.

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

# ── R15 MAPA DROGOWA P0/P1/P2 ──
python JDG/tools/bdo_environment_auditor.py --product-fee-material --material papier --packaging-kg 100   # P0-1 opłaty per materiał
python JDG/tools/bdo_environment_auditor.py --bdo-api --api-configured --api-credentials                  # P0-2 API BDO (KPO/sprawozdania)
python JDG/tools/bdo_environment_auditor.py --ewc-lookup --ewc-code "17 06 01*"                           # P1-1 katalog EWC 6-cyfrowy
python JDG/tools/bdo_environment_auditor.py --agricultural --gmina Warszawa --ha-conversion 4             # P1-2 podatek rolny per gmina
python JDG/tools/bdo_environment_auditor.py --transport --route-type poza_ue                              # P1-3 zezwolenia transportowe
python JDG/tools/bdo_environment_auditor.py --cbam-certificates --co2-t 10 --authorized-declarant         # P2-1 certyfikaty CBAM 2026
python JDG/tools/bdo_environment_auditor.py --bdo-register-online --registration-status nie_zarejestrowany  # P2-2 rejestracja online BDO

# ── SEKCJA 8: innowacje INN-13..17 ──
python JDG/tools/bdo_environment_auditor.py --zero-click-bdo --wz-documents 5                        # INN-13 zero-click BDO (ewidencja z WZ)
python JDG/tools/bdo_environment_auditor.py --bdo-reg-detector --activity-desc "produkcja mebli"      # INN-14 auto-detecktor rejestracji BDO
python JDG/tools/bdo_environment_auditor.py --weee-fee --weee-category sprzęt_it --weee-mass-kg 100   # INN-15 opłata WEEE wg kategorii
python JDG/tools/bdo_environment_auditor.py --recycling --recycling-material papier --achieved-pct 80   # INN-16 tracker poziomów recyklingu
python JDG/tools/bdo_environment_auditor.py --transport-licence --transport-type "przewóz rzeczy"      # INN-17 licencja transportowa krok po kroku
```

## Testy

- Rego: `JDG/tests/rego/test_p15_srodowisko_bdo_enterprise.rego` (**50** scenariuszy: 39 + 11 INN-13..17)
- Pytest: `JDG/tests/auto/test_p15_srodowisko_bdo_enterprise.py` (**50** testów: 43 + 7 INN-13..17)
- Pełny przebieg P01-P15: 300+ testów

## Okablowanie

- `main_jdg.rego`: `import data.jdg.p15_srodowisko_bdo_innovations` (PAS 18q), wpis w `_package_decisions`, `final_verdict_p15 = safe_merge(final_verdict_p14, ...)` — bez kolizji ze starym pakietem `jdg.p15_innovations` (v8).
