# P09 — Księgowość PKPiR + UoR + Amortyzacja (Enterprise)

Kampania: `prompty_glm52/09_PROMT_KSIEGOWOSC_PKPIR_UOR.txt`
Raport: `raporty_glm52/raport_enterprise_P09.txt`
Status: **✅ WDROŻONY_100** (2026-08-09)

## Pakiet rego: `jdg.p09_ksiegowosc_pkpir_uor_innovations`

Plik: `JDG/rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego` (692 linie, 20 INN)

Wdraża wszystkie sekcje promptu jako działające reguły (priorytet: **audyt UoR — próg 2M EUR**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Audyt struktury PKPiR** | `pkpir_structure_audit`, `pkpir_auto_dekretacja` (INN-02), `pkpir_validator_realtime` (INN-03), `pkpir_intelligent_classifier` (INN-20) | Kolumny 1-17 wg rozporządzenia (Dz.U. 2025 poz. 567), 14 wymaganych, termin 20 dni, auto-dekretacja (dokument → dekret → kolumny), walidator realtime (kol. 9 = 7+8, kol. 14 = 10+11+12+13), klasyfikator kolumn po opisie faktury |
| **2. AUDYT UoR ★ PRIORYTET** | `uor_obligation_engine` (INN-01), `uor_audit`, `amortization_dual_calculator` (INN-04), `uor_threshold_tracker` (INN-10), `uor_opening_balance_continuity` (INN-19) | **Silnik decyzji „PKPiR czy UoR?"** — próg 2M EUR (art. 2 ust. 1 pkt 5), wczesne ostrzeżenie 75%, zasady memoriałowe, dowody księgowe (art. 21), inwentaryzacja (art. 26), wycena, amortyzacja bilansowa vs podatkowa, sprawozdania (art. 45-49), ciągłość bilansu otwarcia (art. 10-12) |
| **3. Amortyzacja i leasing** | `amortization_leasing_audit`, `one_time_depreciation_audit` (INN-05), `car_limit_audit` (INN-06), `leasing_comparator` (INN-14) | KŚT grupy 0-8 (stawki 0-20%), **jednorazowa 100k EUR** (art. 22k ust. 7), **auta 150k/225k** (art. 23a pkt 47a), leasing operacyjny (art. 23b, cała rata KUP) vs finansowy (art. 23f, tylko odsetki), NKUP |
| **4. Remanent i korekty** | `remanent_audit`, `remanent_simulator` (INN-07) | Remanent końcowy → przychód roku następnego (art. 24 ust. 2), symulator wpływu na dochód, korekty ksiąg (zwroty, rabaty) |
| **5. Transformacja PKPiR → UoR** | `pkpir_uor_transformation_audit`, `uor_opening_balance_continuity` (INN-19) | 5 kroków: zamknięcie PKPiR → otwarcie ksiąg → migracja sald → różnice amortyzacyjne → memoriał; wspiera `pkpir_to_uor_transformer.rego`; ciągłość bilansu otwarcia = zamknięcie poprzedniego roku |
| **6. OPA jako system** | `accounting_pipeline_snapshot`, `accounting_template_hook` (INN-15) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload szablonów księgi, auto-aktualizacja przy zmianach rozporządzenia |
| **7. Genius ideas (20)** | INN-01..INN-20 | Silnik PKPiR-czy-UoR, auto-dekretacja, walidator realtime, amortyzacja dualna, jednorazowa, limity aut, symulator remanentu, plan kont dla JDG (INN-08), generator PKPiR z dokumentów (INN-09), tracker progu (INN-10), walidator dowodów (INN-11), harmonogram inwentaryzacji (INN-12), generator sprawozdań (INN-13), symulator leasingu (INN-14), hook szablonów (INN-15), **walidator międzyksięgowy PKPiR↔VAT↔PIT↔ZUS (INN-16)**, **zamknięcie roku z checklistą prawną (INN-17)**, **JPK_PKPIR readiness (INN-18)**, **ciągłość bilansu otwarcia (INN-19)**, **klasyfikator kolumn po opisie (INN-20)** |
| **8. Mapa drogowa** | — | W raporcie R09 — luki P0/P1/P2 (PKPiR 100%, UoR od zera do pełni, integracja JPK, automatyzacja zamknięcia roku) — wszystkie domknięte |

### Dane temporalne (ADR-002)
Wszystkie progi czytane z `data.jdg.thresholds.accounting` z domyślnymi (2M EUR, kurs 4.50, 75% ostrzeżenie, 100k EUR, 150k/225k, stawki KŚT) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p09_ksiegowosc_pkpir_uor_innovations` (PAS 18j)
- `_package_decisions["jdg.p09_ksiegowosc_pkpir_uor_innovations"] = p09_ksiegowosc_pkpir_uor_innovations.decide`
- `final_verdict_p09 = safe_merge(final_verdict_p08, safe_merge(p09_ksiegowosc_pkpir_uor_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p08 ma priorytet)

## Warstwa reguł wspierająca
- `rules/accounting.rego` — 74 rule_id (kolumny PKPiR, remanent, amortyzacja, **P870 różnice kursowe NBP A/B/C**)
- `rules/micro/pkpir/*.rego` — 81 rule_id (kolumny p10.r1-17, przychody, koszty, NKUP, remanent, korekty)
- `rules/uor/*.rego` — 253 rule_id (art. 2-74 UoR: books, assets, costs, revenue, inventory, closing, financial stmt, obligation)
- `rules/micro/uor/uor.rego` — 149 rule_id (atomowe per artykuł a2-a74)
- `rules/accounting/uor_enterprise_live.rego` — 12 rule_id (double entry, inwentaryzacja, wycena, RMK, sprawozdanie, retencja, zasady)
- `rules/accounting/pkpir_enterprise_live.rego` + `pkpir_enterprise_validation.rego` + `pkpir_enterprise_validator.rego`
- `rules/nkup_enterprise_complete.rego` — 60 rule_id (art. 23 NKUP)
- `rules/pkpir_to_uor_transformer.rego` — 413 linii (migracja PKPiR→UoR)
- `rules/jdg/hyper/...` + `rules/ksef_jpk.rego` + `rules/micro/plan33_jpk.rego` — JPK_PKPIR (16 kolumn, na żądanie US, 30 dni)

## Narzędzie: `JDG/tools/ksiegowosc_pkpir_uor_auditor.py`
- `--audit` — audyt realnych plików `micro/pkpir/*.rego` (81 rule_id) i `uor/*.rego` (253 rule_id); pokrycie artykułów UoR a2-a74, pokrycie kolumn PKPiR 1-17
- `--uor` — silnik decyzji PKPiR czy UoR (próg 2M EUR, 75% ostrzeżenie)
- `--pkpir` — struktura PKPiR (kolumny 1-17, dekretacja, walidator)
- `--amortization` — KŚT + jednorazowa 100k EUR + limity aut
- `--leasing` — operacyjny vs finansowy
- `--remanent` — symulator remanentu
- `--table` / `--out FILE`

## Testy
- `JDG/tests/rego/test_p09_ksiegowosc_pkpir_uor_enterprise.rego` — 26 scenariuszy natywnych (16 + 10 dla INN-16..20)
- `JDG/tests/auto/test_p09_ksiegowosc_pkpir_uor_enterprise.py` — 22 testy pytest (w tym parser `future.keywords.if`, INN-16..20, raport)
- `JDG/tests/test_pkpir_uor_enterprise.py` — testy PKPiR/UoR live (kolumny, remanent, podwójny zapis, inwentaryzacja, wycena, sprawozdanie, retencja)

## Walidacja (2026-08-09)
- pytest P01+P02+P03+PKPiR/UoR: **113/113** zielonych
- tests/auto P09: **22/22**
- Parser Rego: balanced braces, `import future.keywords.if` obecny
- Bundle OPA: **446 plików** (bundle.sh v9.0, SBOM)
- Spójność międzyczęściowa: P07 (KUP/NKUP) · P08 (ZUS w kosztach) · P12 (kursy walut) · P17 (JPK_PKPIR) · P03 (orkiestrator PAS 18j)
