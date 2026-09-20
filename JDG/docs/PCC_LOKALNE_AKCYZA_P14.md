# P14 — PCC + Podatki Lokalne + Akcyza (Enterprise)

> **📌 Aktualizacja 2026-08-22:** dokument historyczny opisujący wdrożenie promptu GLM 5.2.
> Raporty źródłowe (`prompty_glm52/`, `raporty_glm52/`, `raporty_jdg_enterprise/`) zostały zarchiwizowane poza repo.
> Aktualny stan wdrożenia: [`KAMPANIA_GLM52_ETAPY_10_28.md`](KAMPANIA_GLM52_ETAPY_10_28.md) + `JDG/bundles/*audit_state.json` (certyfikacja końcowa ETAP 28 — 2026-08-22: 13/14 bramek `NIEPELNY`; domknięcie V4 2026-08-29: `WDROŻONY_100` 6/6).

> Wdrożenie raportu analitycznego **P14_PCC_Lokalne_Akcyza.txt** (v9.5)
> jako działający pakiet rego + narzędzie audytowe + testy + dokumentacja.
> Obszar wskazany w LEGAL_COVERAGE.md jako **największa luka pokrycia (~1%)** — DOMKNIĘTY.
> **Priorytet: podatki lokalne (rejestr stawek gminnych) + PCC.**

## Pakiet rego

**Plik:** `JDG/rules/p14_pcc_lokalne_akcyza_innovations_v9.rego`
**Pakiet:** `jdg.p14_pcc_lokalne_akcyza_innovations`
**Okablowanie:** `main_jdg.rego` — import PAS 18p + `_package_decisions` + `final_verdict_p14`
(bez kolizji ze starym pakietem `jdg.p14_innovations` v8, który pozostaje nietknięty)

### Sekcje wdrożone jako reguły

| Sekcja | Reguły | Kluczowe elementy |
|---|---|---|
| **1. Mapa pokrycia** | `pcc_local_excise_coverage_report` | 12 artykułów priorytetowych (a1-a7 PCC, a8/a12/a16 transport, a26/a30/a99 akcyza), status z `data.jdg.p14_audit`, gap_pct |
| **1. AUDYT PCC ★** | `pcc_audit`, `pcc3_generator` (INN-01), `pcc_detector` (INN-02) | czynności art. 1, obowiązek art. 4, **stawki art. 6-7**: sprzedaż 2%, pożyczka 0,5%, spółki 0,5%, hipoteka 0,1%, wymiana 2/1%; zwolnienia (≤1000 zł art. 9, pożyczka rodzinna 36 120 zł); **PCC-3 w 14 dni (art. 10)**; wyłączenia VAT (art. 2 pkt 4) |
| **2. PODATKI LOKALNE ★ PRIORYTET** | `local_taxes_audit`, `gmina_rates_registry` (INN-03), `real_estate_tax_calculator` (INN-04), `transport_tax_calculator` (INN-05), `dn1_tracker` (INN-06) | **nieruchomości 2026**: grunty biznes 1,43 zł/m², budynki biznes 33,10 zł/m², DN-1 w 14 dni, raty 15.03/15.05/15.09/15.11; **transport >3,5t**; opłata targowa/uzdrowiskowa; **rejestr stawek gminnych + auto-aktualizacja** |
| **3. AKCYZYZA** | `excise_audit`, `excise_fuel_calculator` (INN-07), `excise_alcohol_calculator` (INN-08), `excise_cost_detector` (INN-09), `excise_warehouse_tracker` (INN-11) | paliwa 2026 (benzyna 1566, ON 1206, LPG 695 zł/1000l), alkohol (etanol 6900 zł/hl, piwo 8,57/°P, wino 185 zł/hl), tytoń, energia; **skład podatkowy** (przestępstwo art. 65 KKS), banderole |
| **4. Luki i duplikaty** | `gaps_duplicates_audit` | LEGAL_COVERAGE: 225 punktów, porównanie rule_id, stuby, brakujące obszary |
| **5. OPA jako system** | `local_taxes_pipeline_snapshot` | pipeline ingest→generate→verify→emit (ADR-002, hot-reload stawek gminnych) |
| **6. Genius ideas (17)** | INN-01..INN-17 | generator PCC-3, detektor czynności, rejestr stawek gminnych, symulator nieruchomości, kalkulator transportu, tracker DN-1, kalkulator paliw, kalkulator alkoholu, wykrywacz akcyzy w kosztach, hook stawek gminnych, tracker składu, panel compliance + **v9.1: detektor obowiązku PCC (INN-13), zero-click PCC-3 (INN-14), mapa stawek gminnych (INN-15), VAT vs PCC (INN-16), akcyza w imporcie (INN-17)** |

### Progi ustawowe (ADR-002 — zero hardcode)

Wszystkie progi czytane z `data.jdg.thresholds.pcc_local_excise`:
stawki PCC (sprzedaż 2%, pożyczka 0,5%, spółki 0,5%, hipoteka 0,1%) · próg 1000 zł · pożyczka rodzinna 36 120 zł · PCC-3 14 dni · nieruchomości (grunty 1,43, budynki 33,10 zł/m²) · DN-1 14 dni · transport >3,5t · akcyza (benzyna 1566, ON 1206, LPG 695) · alkohol (6900/8,57/185)

## Narzędzie

**Plik:** `JDG/tools/pcc_local_excise_auditor.py`

- `--audit` — audyt realnych plików: `micro/pcc/pcc.rego` (90 rule_id, artykuły a1-a16l), `micro/plan33_pcc.rego` (60), `micro/akcyza/akcyza.rego` (133), `micro/transport/transport.rego` (45); pokrycie 12 artykułów priorytetowych, duplikaty, stuby
- `--pcc` / `--pcc3` — kalkulator PCC + auto-generator PCC-3 (14 dni)
- `--real-estate` — symulator podatku od nieruchomości (DN-1, stawki gminne)
- `--transport` — kalkulator podatku od środków transportowych (>3,5t)
- `--gmina-registry` — rejestr stawek gminnych
- `--fuel` / `--alcohol` / `--warehouse` — akcyza paliwa/alkohol/skład podatkowy
- `--pcc-obligation` ★ — auto-detektor obowiązku PCC — kupno od osoby prywatnej (INN-13)
- `--pcc3-click` ★ — zero-click PCC-3 — countdown 14 dni (INN-14)
- `--gmina-map` ★ — mapa stawek gminnych — wersjonowanie YoY (INN-15)
- `--vat-pcc` ★ — rekomendacja struktury VAT vs PCC (INN-16)
- `--excise-import` ★ — wykrywacz akcyzy w imporcie (INN-17)
- `--table` / `--out FILE`

## Testy

- `JDG/tests/rego/test_p14_pcc_lokalne_akcyza_enterprise.rego` — **28 scenariuszy rego** (20 + 8 nowych dla INN-13..17)
- `JDG/tests/auto/test_p14_pcc_lokalne_akcyza_enterprise.py` — **30 testów pytest** (23 + 7 nowych: funkcje narzędzia v9.1, parser `future.keywords.in/.if`, struktura INN-13..17)

## Nowe innowacje v9.1 (INN-13..17)

| INN | Reguła | Funkcja narzędzia | Wartość biznesowa |
|---|---|---|---|
| **INN-13** | `pcc_obligation_detector` | `pcc_obligation_detector(type, from_private_party, vat_applicable, amount)` | Auto-detektor obowiązku PCC — kupno pojazdu od osoby prywatnej → PCC 2% + TRIAGE_QUEUE (art. 2 pkt 4 wyłącza VAT) |
| **INN-14** | `pcc3_zero_click` | `pcc3_zero_click(type, amount, days_elapsed)` | Zero-click PCC-3 — auto-generowanie + countdown 14 dni + alert ≤3 dni (art. 10) |
| **INN-15** | `gmina_rates_map` | `gmina_rates_map(gmina)` | Mapa stawek gminnych — wersjonowanie (uchwała + data), delta YoY (Law Radar F5) |
| **INN-16** | `vat_vs_pcc_optimizer` | `vat_vs_pcc_optimizer(type, amount, buyer_vat_deductible, from_private_party)` | Rekomendacja struktury transakcji — VAT 23% vs PCC 2% (legalna optymalizacja) |
| **INN-17** | `excise_import_detector` | `excise_import_detector(imported_goods)` | Wykrywacz obowiązku akcyzowego w imporcie — paliwa/alkohol/tytoń/energia (spójność P12) |

Parser: dodane `import future.keywords.in` + `import future.keywords.if` (plik używał if/else bez żadnego importu) — zbalansowany (613 linii, 25 rule_id).

## Mapa drogowa (luki P0/P1/P2)

Wykryte przez realny audyt narzędzia:

| Luka | Priorytet | Opis |
|---|---|---|
| Opłata targowa/uzdrowiskowa micro | **P1** | Stawki per gmina — brak reguł micro (tylko enterprise) |
| Tytoń — pełne stawki | **P1** | Stawki akcyzy na wyroby tytoniowe (art. 99) — częściowe pokrycie |
| Energia — stawki akcyzy | **P2** | Akcyza na energię elektryczną/węglową (art. 89) |
| Rejestr stawek gminnych | **P2** | Pełna baza gmin (obecnie rejestr domyślny) |
| Formularze (DN-1, PCC-3) | **P2** | Generatory formularzy w warstwie enterprise |

## Raport

`raporty_glm52/raport_enterprise_P14.txt` — pełny raport analityczny ENTERPRISE P14 (9 sekcji: TOP 10, mapa pokrycia wobec 225 pkt, audyt PCC/nieruchomości/transportu/akcyzy, Local Tax Engine, 17 genialnych pomysłów, roadmapa).

## Status kampanii

**P14 → WDROZONY_100** (v9.5.0-p14) — wpis w `unified_plan_progress.yaml`.
