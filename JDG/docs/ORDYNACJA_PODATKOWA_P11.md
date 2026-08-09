# P11 — Ordynacja Podatkowa (Enterprise)

Kampania: `prompty_glm52/11_PROMT_ORDYNACJA_PODATKOWA.txt`
Raport: `raporty_glm52/raport_enterprise_P11.txt`
Status: **✅ WDROŻONY_100** (2026-08-09)

## Pakiet rego: `jdg.p11_ordynacja_podatkowa_innovations`

Plik: `JDG/rules/p11_ordynacja_podatkowa_innovations_v9.rego` (646 linii, 19 INN)

Wdraża wszystkie sekcje promptu jako działające reguły (priorytet: **przedawnienia i auto-korespondencja z urzędem**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Mapa pokrycia artykułów OrdPU** | `ordpu_coverage_report` | 20 artykułów priorytetowych (a16 czynny żal, a53-56b odsetki, a67a-e ulgi, a70 przedawnienie, a72-81b nadpłaty/korekty, a117ba Biała Lista, a119a GAAR, a138a pełnomocnictwa, a193a JPK, a14a/14d interpretacje), status z `data.jdg.ordpu_audit` (424 rule_id micro) + gap_pct |
| **2. AUDYT PRZEDAWNIEŃ ★ PRIORYTET** | `limitation_engine`, `limitation_calendar` (INN-01), `interest_calculator` (INN-02), `prescription_windup_guard` (INN-19) | art. 70: **5 lat od końca roku** (2026 → 31.12.2031), **przerwanie §4**, **zawieszenie §6**; **kalendarz przedawnień z alertami URGENT**; **auto-wykrywanie przedawnienia → WSTRZYMAJ windykację**; **kalkulator odsetek 200% lombardu** (art. 56) |
| **3. Korekty i nadpłaty** | `corrections_overpayment_audit`, `auto_correction_engine` (INN-03), `correction_profitability_calculator` (INN-17) | art. 81/81b (korekta do 5 lat), art. 72-80 (nadpłata, zwrot do 3 mies., oprocentowanie art. 78); **silnik auto-korekty**; **opłacalność korekty vs ryzyko kontroli** |
| **4. Auto-korespondencja z urzędem** | `correspondence_audit`, `proceeding_tracker` (INN-04), `correspondence_generator` (INN-05), `silent_settlement_tracker` (INN-16) | System **obsługi postępowań od A do Z** (pismo → postępowanie art. 120-129 → decyzja/interpretacja art. 14d 30 dni → odwołanie 14 dni art. 223 → II instancja); **generator pism**; **tracker milczącego załatwienia** (art. 139 — po 2 mies. pozytywne z mocy prawa) |
| **5. GAAR i Biała Lista** | `gaar_audit`, `white_list_monitor` (INN-06) | art. 119a GAAR (korzyść + sprzeczność z celem + **sztuczność ≥60/100** → domiar); art. 117ba **Biała Lista** (30 dni → **sankcja 20%**) |
| **6. OPA jako system** | `ordpu_pipeline_snapshot`, `ordpu_template_hook` (INN-14) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload, auto-aktualizacja terminów proceduralnych |
| **7. Genius ideas (19)** | INN-01..INN-19 | Kalendarz przedawnień, kalkulator odsetek, silnik auto-korekty, tracker postępowania, generator pism, monitor Białej Listy, silnik ryzyka kontroli, generator ulg w spłacie, tracker interpretacji, menedżer pełnomocnictw, tracker JPK, asystent czynnego żalu, kalkulator korzyści GAAR, hook terminów, panel zgodności proceduralnej, **milczące załatwienie (INN-16)**, **opłacalność korekty (INN-17)**, **symulator ulg (INN-18)**, **przedawnienie windup (INN-19)** |
| **8. Mapa drogowa** | — | W raporcie R11 — odsetki → przedawnienia → korekty/nadpłaty → ulgi → pełnomocnictwa → GAAR — wszystkie domknięte |

### Dane temporalne (ADR-002)
Wszystkie terminy czytane z `data.jdg.thresholds.ordpu` z domyślnymi (5 lat przedawnienia, 5 lat korekty, 200% odsetki, 30 dni Biała Lista, 20% sankcja, 3 mies. zwrot, 30 dni interpretacja, 14 dni odwołanie, 60/100 GAAR) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p11_ordynacja_podatkowa_innovations` (PAS 18l)
- `_package_decisions["jdg.p11_ordynacja_podatkowa_innovations"] = p11_ordynacja_podatkowa_innovations.decide`
- `final_verdict_p11 = safe_merge(final_verdict_p10, safe_merge(p11_ordynacja_podatkowa_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p10 ma priorytet)

## Warstwa reguł wspierająca
- `rules/micro/ord/ord.rego` — 424 rule_id (atomowe per artykuł a16-a193a)
- `rules/micro/plan34_ord.rego` — 190 rule_id
- `rules/ord/ord_innovations_v8.rego` — 21 rule_id
- `rules/statute_of_limitations.rego` — 17 rule_id (przedawnienia)
- `rules/interest_calculator_enterprise.rego` — 4 rule_id (odsetki 200%)
- `rules/gaar_shield_enterprise.rego` — 3 rule_id (ochrona GAAR)
- `rules/poa_manager_enterprise.rego`, `proceeding_tracker_enterprise.rego`,
  `overpayment_auto_claimer_enterprise.rego`, `tax_authority_interaction_enterprise.rego`,
  `tax_ruling_autodrafter_enterprise.rego`, `liability.rego`

## Narzędzie: `JDG/tools/ordpu_auditor.py`
- `--audit` — audyt realnych plików `micro/ord/ord.rego` (12 016 linii, 424 rule_id) + `plan33_ord.rego`; pokrycie artykułów a16-a193a, duplikaty, stuby
- `--limitations` — kalendarz przedawnień z alertami (art. 70)
- `--interest` — kalkulator odsetek (art. 56, 200% lombardu)
- `--corrections` — silnik auto-korekty (art. 81/81b)
- `--overpayment` — audyt nadpłat (art. 72-80)
- `--gaar` — audyt GAAR (art. 119a)
- `--white-list` — monitor Białej Listy (art. 117ba)
- `--correspondence` — audyt auto-korespondencji
- `--table` / `--out FILE`

## Testy
- `JDG/tests/auto/test_p11_ordynacja_podatkowa_enterprise.py` — 23 testy pytest (w tym parser `future.keywords.if`, INN-16..19, raport)
- `JDG/tests/rego/test_p11_ordynacja_podatkowa_enterprise.rego` — 24 scenariusze natywne (16 + 8 dla INN-16..19)
- `JDG/tests/auto/test_auto_block_limitations.py` + `test_auto_block_statute.py` — bloki domenowe (przedawnienia, statut)

## Walidacja (2026-08-09)
- pytest P01+P02+P03+PKPiR/UoR: **113/113** zielonych; tests/auto P11: **23/23**
- Parser Rego: balanced braces, `import future.keywords.if` obecny
- Bundle OPA: **446 plików** (bundle.sh v9.0, SBOM)
- Spójność międzyczęściowa: P10 (KKS — czynny żal) · P16 (e-Doręczenia) · P17 (JPK na żądanie) · P09 (przechowywanie art. 86) · P04 (Biała Lista) · P03 (orkiestrator PAS 18l)
