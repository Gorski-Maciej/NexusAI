# P20 — Neural Mesh + Innowacje v8 (p01-p24, p33-p35, Strategia, Orzecznictwo)

**Pakiet:** `jdg.p20_neural_mesh_innovations`
**Plik:** `JDG/rules/p20_neural_mesh_innovations_v9.rego`
**Raport:** `raporty_jdg_enterprise/R20_Neural_Mesh_Innowacje.txt`
**Status:** [✅ WDROŻONY] — POSTĘP 20/24

## Zakres (7 sekcji promptu wdrożone jako reguły)

1. **Audyt Neural Mesh** — neural_rule_mesh (20) + neural_mesh_v2 (16): wykrywanie konfliktów między domenami (VAT×PIT×ZUS×KKS×Ordynacja), trust scores per domena, override AUTO_POST; **Knowledge Graph reguł**, propagacja pewności, samoucząca się sieć decyzji.
2. **Audyt innowacji v8 (PRIORYTET ★)** — p01-p24, p33-p35: cel, stan (wdrożone/stub), wartość, ryzyko; **auto-detektor martwych innowacji**.
3. **Audyt spójności międzyaktowej (p33-p35)** — p35_cross_act_coherence (11), p35_system_gaps (12), p35_innovations_engine (17): konflikty między ustawami; **deklaracje zależności międzyaktowych**, weryfikacja krzyżowa.
4. **Audyt strategii i orzecznictwa** — strategic_advisor (9), cross_domain_intelligence (16), tax_optimization (11), judicial_interpretations (6), legislative_monitor (8); **radar zmian prawa** (legislacja.gov.pl), **panel SRO**.
5. **OPA jako rozbudowany system** — auto-dostrajanie wag/pewności, hot-swap reguł bez przerw, symulator zmiany prawa, pipeline auto-adaptacji sieci.
6. **15 genialnych pomysłów Enterprise (INN-01..INN-15)**.
7. **Mapa drogowa P0/P1/P2** (w raporcie R20).

## Genialne pomysły (INN)

| # | Reguła | Opis |
|---|--------|------|
| INN-01 | `knowledge_graph` | Knowledge Graph reguł — graf zależności między domenami z wagami |
| INN-02 | `confidence_propagation` | propagacja pewności (confidence × edge_weight, cutoff 0.5) |
| INN-03 | `self_learning_network` | samoucząca się sieć decyzji (POSITIVE +0.05 / NEGATIVE -0.05) |
| INN-04 | `dead_innovation_detector` | auto-detektor martwych innowacji (12 cykli bez użycia) |
| INN-05 | `cross_act_dependency_declaration` | deklaracje zależności międzyaktowych |
| INN-06 | `cross_act_verification` | weryfikacja krzyżowa międzyaktowa |
| INN-07 | `legislative_radar` | radar zmian prawa (legislacja.gov.pl, horyzont 30 dni) |
| INN-08 | `judicial_fast_response` | panel SRO — szybkie reagowanie na orzecznictwo (wpływ ≥ 0.6) |
| INN-09 | `weight_auto_tuning` | auto-dostrajanie wag/pewności reguł |
| INN-10 | `hot_swap_rules` | hot-swap reguł bez przerw (atomowa wymiana pakietów) |
| INN-11 | `legal_change_simulator` | symulator zmiany prawa (co się zmieni po nowelizacji) |
| INN-12 | `rule_ranking` | samouczący się ranking trafności reguł |
| INN-13 | `domain_trust_scoreboard` | tablica zaufania domen (trust scores vs baseline 0.8) |
| INN-14 | `mesh_adaptation_pipeline` | pipeline auto-adaptacji sieci (radar → symulator → hot-swap) |
| INN-15 | `cross_domain_ai_assistant` | AI asystent międzydomenowy (VAT×PIT×ZUS×KKS×ORD) |

## Reguły audytu (Sekcje 1-5)

- `neural_mesh_coverage_report` — mapa pokrycia 6 modułów (neural_mesh, innovations_v8, cross_act, strategy, judicial, legislative)
- `neural_mesh_audit` — konflikty między domenami, trust scores, override AUTO_POST
- `innovations_v8_audit` — stan p01-p24, p33-p35 (wdrożone/stub)
- `cross_act_coherence_audit` — spójność międzyaktowa
- `strategy_judicial_audit` — strategia, orzecznictwo, monitoring legislacyjny
- `mesh_adaptation_pipeline` — pipeline auto-adaptacji (ADR-002, hot-reload)

## Progi (ADR-002 — data.jdg.thresholds, zero hardcode)

Konflikt alert 0.7, bazowy trust 0.8, cutoff pewności 0.5, wpływ orzecznictwa 0.6, horyzont radaru 30 dni, martwa innowacja 12 cykli, override AUTO_POST.

## Artefakty

- Rego: `JDG/rules/p20_neural_mesh_innovations_v9.rego` (20 reguł + decide + default — 21 reguł łącznie, 15 INN, 15+ podstaw prawnych)
- Narzędzie: `JDG/tools/neural_mesh_innovations_auditor.py` (audyt 363 rule_id w 26 plikach + 16 kalkulatorów CLI)
- Testy rego: `JDG/tests/rego/test_p20_neural_mesh_innovations_enterprise.rego` (26 scenariuszy)
- Testy pytest: `JDG/tests/auto/test_p20_neural_mesh_innovations_enterprise.py` (36 testów)
- Okablowanie: `main_jdg.rego` — import + `_package_decisions` + `final_verdict_p20 = safe_merge(final_verdict_p19, ...)` — bez kolizji z `jdg.p21_innovations` (już wpięty wcześniej)
