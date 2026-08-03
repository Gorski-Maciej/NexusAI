# P11 — Ordynacja Podatkowa (Enterprise)

Raport źródłowy: `prompts_glm52/P11_Ordynacja_Podatkowa.txt`
Status: **WDROŻONY** (raport `raporty_jdg_enterprise/R11_Ordynacja_Podatkowa.txt`)

## Pakiet rego: `jdg.p11_ordynacja_podatkowa_innovations`

Plik: `JDG/rules/p11_ordynacja_podatkowa_innovations_v9.rego`

Wdraża wszystkie 8 sekcji promptu jako działające reguły (priorytet: **przedawnienia i auto-korespondencja z urzędem**):

| Sekcja | Reguły | Kluczowe treści |
|---|---|---|
| **1. Mapa pokrycia artykułów OrdPU** | `ordpu_coverage_report` | 20 artykułów priorytetowych (a16 czynny żal, a53-56b odsetki, a67a-e ulgi, a70 przedawnienie, a72-81b nadpłaty/korekty, a117ba Biała Lista, a119a GAAR, a138a pełnomocnictwa, a193a JPK, a14a/14d interpretacje), status z `data.jdg.ordpu_audit` (424 rule_id micro) + gap_pct |
| **2. AUDYT PRZEDAWNIEŃ ★ PRIORYTET** | `limitation_engine`, `limitation_calendar` (INN-01), `interest_calculator` (INN-02) | art. 70: **5 lat od końca roku** (2026 → 31.12.2031), **przerwanie §4** (decyzja, egzekucja), **zawieszenie §6** (postępowanie karne), korekty po przedawnieniu; **kalendarz przedawnień per zobowiązanie z alertami URGENT**; **kalkulator odsetek 200% lombardu** (art. 56) |
| **3. Korekty i nadpłaty** | `corrections_overpayment_audit`, `auto_correction_engine` (INN-03) | art. 81/81b (korekta do 5 lat), art. 72-80 (nadpłata, zwrot do 3 mies., oprocentowanie art. 78); **silnik auto-korekty** — kierunek (dopłata/nadpłata), limit 5 lat, odsetki od zaległości |
| **4. Auto-korespondencja z urzędem** | `correspondence_audit`, `proceeding_tracker` (INN-04), `correspondence_generator` (INN-05) | System **obsługi postępowań od A do Z** (pismo → postępowanie art. 120-129 → decyzja/interpretacja art. 14d 30 dni → odwołanie 14 dni art. 223 → II instancja); integracja 6 pakietów enterprise (tax_authority_interaction, tax_correspondence_engine, tax_ruling_autodrafter, overpayment_auto_claimer, proceeding_tracker, poa_manager); **generator pism** (interpretacja, odwołanie, zwrot nadpłaty, czynny żal) |
| **5. GAAR i Biała Lista** | `gaar_audit`, `white_list_monitor` (INN-06) | art. 119a GAAR (korzyść + sprzeczność z celem + **sztuczność ≥60/100** → domiar); art. 117ba **Biała Lista** (płatność na konto spoza listy bez zawiadomienia w **30 dni** → **sankcja 20%**) |
| **6. OPA jako system** | `ordpu_pipeline_snapshot`, `ordpu_template_hook` (INN-14) | Pipeline ingest→generate→verify→emit (ADR-002), hot-reload pakietów jdg.limitations / jdg.interest_calculator, auto-aktualizacja terminów proceduralnych |
| **7. Genius ideas (15)** | INN-01..INN-15 | Kalendarz przedawnień, kalkulator odsetek, silnik auto-korekty, tracker postępowania, generator pism, monitor Białej Listy, **silnik ryzyka kontroli skarbowej**, **generator ulg w spłacie (art. 67a-e)**, **tracker interpretacji (art. 14a-m)**, **menedżer pełnomocnictw (art. 138a-o)**, **tracker JPK (art. 193a)**, **asystent czynnego żalu**, **kalkulator korzyści GAAR**, hook terminów, **panel zgodności proceduralnej** |
| **8. Mapa drogowa** | — | W raporcie R11 — luki P0/P1/P2 (Biała Lista micro, interpretacje micro, integracja z KKS) |

### Dane temporalne (ADR-002)
Wszystkie terminy czytane z `data.jdg.thresholds.ordpu` z domyślnymi (5 lat przedawnienia, 5 lat korekty, 200% odsetki, 30 dni Biała Lista, 20% sankcja, 3 mies. zwrot, 30 dni interpretacja, 14 dni odwołanie, 60/100 GAAR) — **zero hardcode w regułach**.

## Podpięcie (main_jdg.rego)
- Import: `import data.jdg.p11_ordynacja_podatkowa_innovations` (PAS 18l)
- `_package_decisions["jdg.p11_ordynacja_podatkowa_innovations"] = p11_ordynacja_podatkowa_innovations.decide`
- `final_verdict_p11 = safe_merge(final_verdict_p10, safe_merge(p11_ordynacja_podatkowa_innovations.decide, fallback.decide))`
- Pakiety REPORT-owe — nie nadpisują decyzji (safe_merge: final_verdict_p10 ma priorytet)

## Narzędzie: `JDG/tools/ordpu_auditor.py`
- `--audit` — audyt realnych plików `micro/ord/ord.rego` (12 016 linii, 424 rule_id, prefiks `jdg.micro.ord.a{N}.r{M}`) + `plan33_ord.rego`; pokrycie artykułów a16-a193a, duplikaty, stuby; **realne braki**: a117ba (Biała Lista), a14a/a14d (interpretacje)
- `--limitations` — kalendarz przedawnień z alertami (art. 70)
- `--interest` — kalkulator odsetek (art. 56, 200% lombardu)
- `--corrections` — silnik auto-korekty (art. 81/81b)
- `--overpayment` — audyt nadpłat (art. 72-80)
- `--gaar` — audyt GAAR (art. 119a)
- `--white-list` — monitor Białej Listy (art. 117ba)
- `--correspondence` — audyt auto-korespondencji
- `--table` / `--out FILE`

## Testy
- `JDG/tests/rego/test_p11_ordynacja_podatkowa_enterprise.rego` — 16 scenariuszy rego
- `JDG/tests/auto/test_p11_ordynacja_podatkowa_enterprise.py` — 19 testów pytest

## Walidacja
- Pełny zestaw P01-P11: pytest + py_compile + smoke CLI + code review (code-reviewer-glm)
