# P09 — Księgowość PKPiR + UoR + Amortyzacja (Enterprise)

Raport źródłowy: `prompts_glm52/P09_Ksiegowosc_PKPIR_UoR.txt`
Status: **WDROŻONY** (raport `raporty_jdg_enterprise/R09_Ksiegowosc_PKPIR_UoR.txt`)

## Pakiet rego: `jdg.p09_ksiegowosc_pkpir_uor_innovations`

Plik: `JDG/rules/p09_ksiegowosc_pkpir_uor_innovations_v9.rego`

Wdraża wszystkie 8 sekcji promptu jako działające reguły (priorytet: **audyt UoR — próg 2M EUR**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Audyt struktury PKPiR** | `pkpir_structure_audit`, `pkpir_auto_dekretacja` (INN-02), `pkpir_validator_realtime` (INN-03) | Kolumny 1-17 wg rozporządzenia (Dz.U. 2025 poz. 567), 14 wymaganych, termin 20 dni, auto-dekretacja operacji (dokument → dekret → kolumny), walidator realtime (kol. 9 = 7+8, kol. 14 = 10+11+12+13) |
| **2. AUDYT UoR ★ PRIORYTET** | `uor_obligation_engine` (INN-01), `uor_audit`, `amortization_dual_calculator` (INN-04), `uor_threshold_tracker` (INN-10) | **Silnik decyzji „PKPiR czy UoR?"** — próg 2M EUR (art. 2 ust. 1 pkt 5), kurs referencyjny 4.50, **wczesne ostrzeżenie 75%**, zasady memoriałowe, dowody księgowe (art. 21), inwentaryzacja (art. 26), wycena, amortyzacja bilansowa vs podatkowa, sprawozdania (art. 45-49) |
| **3. Amortyzacja i leasing** | `amortization_leasing_audit`, `one_time_depreciation_audit` (INN-05), `car_limit_audit` (INN-06), `leasing_comparator` (INN-14) | KŚT grupy 0-8 (stawki 0-20%), **jednorazowa 100k EUR** (art. 22k ust. 7), **auta 150k/225k** (art. 23a pkt 47a), leasing operacyjny (art. 23b, cała rata KUP) vs finansowy (art. 23f, tylko odsetki), NKUP |
| **4. Remanent i korekty** | `remanent_audit`, `remanent_simulator` (INN-07) | Remanent końcowy → przychód roku następnego (art. 24 ust. 2), symulator wpływu na dochód, korekty ksiąg (zwroty, rabaty) |
| **5. Transformacja PKPiR → UoR** | `pkpir_uor_transformation_audit` | 5 kroków: zamknięcie PKPiR → otwarcie ksiąg → migracja sald → różnice amortyzacyjne → memoriał; wspiera `pkpir_to_uor_transformer` |
| **6. OPA jako system** | `accounting_pipeline_snapshot`, `accounting_template_hook` (INN-15) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload szablonów księgi, auto-aktualizacja przy zmianach rozporządzenia |
| **7. Genius ideas (15)** | INN-01..INN-15 | Silnik PKPiR-czy-UoR, auto-dekretacja, walidator realtime, amortyzacja dualna, jednorazowa, limity aut, symulator remanentu, **plan kont dla JDG** (INN-08), **generator PKPiR z dokumentów** (INN-09), tracker progu (INN-10), walidator dowodów (INN-11), harmonogram inwentaryzacji (INN-12), generator sprawozdań (INN-13), symulator leasingu (INN-14), hook szablonów (INN-15) |
| **8. Mapa drogowa** | — | W raporcie R09 — luki P0/P1/P2 osobno (PKPiR, UoR, amortyzacja, remanent) |

### Dane temporalne (ADR-002)
Wszystkie progi czytane z `data.jdg.thresholds.accounting` z domyślnymi (2M EUR, kurs 4.50, 75% ostrzeżenie, 100k EUR, 150k/225k, stawki KŚT) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p09_ksiegowosc_pkpir_uor_innovations` (PAS 18j)
- `_package_decisions["jdg.p09_ksiegowosc_pkpir_uor_innovations"] = p09_ksiegowosc_pkpir_uor_innovations.decide`
- `final_verdict_p09 = safe_merge(final_verdict_p08, safe_merge(p09_ksiegowosc_pkpir_uor_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p08 ma priorytet)

## Narzędzie: `JDG/tools/ksiegowosc_pkpir_uor_auditor.py`
- `--audit` — audyt realnych plików `micro/pkpir/*.rego` (81 rule_id, prefiks `jdg.micro.pkpir(.pkpir_columns)` — kolumny p10.r1-17) i `uor/*.rego` (253 rule_id, prefiks `jdg.uor.<moduł>.a{N}.r{M}`); pokrycie artykułów UoR a2-a74, pokrycie kolumn PKPiR 1-17
- `--uor` — silnik decyzji PKPiR czy UoR (próg 2M EUR, 75% ostrzeżenie)
- `--pkpir` — struktura PKPiR (kolumny 1-17, dekretacja)
- `--amortization` — KŚT + jednorazowa 100k EUR + limity aut
- `--leasing` — operacyjny vs finansowy
- `--remanent` — symulator remanentu
- `--table` / `--out FILE`

## Testy
- `JDG/tests/rego/test_p09_ksiegowosc_pkpir_uor_enterprise.rego` — 16 scenariuszy rego
- `JDG/tests/auto/test_p09_ksiegowosc_pkpir_uor_enterprise.py` — 18 testów pytest

## Walidacja
- Pełny zestaw P01-P09: pytest + py_compile + smoke CLI + code review (code-reviewer-glm)
