NEXUSAI JDG — PAKIET PROMPTÓW GLM 5.2
======================================

Cel
---
Pakiet służy do sekwencyjnej analizy i ulepszania modułu `JDG/` przez GLM 5.2. Każdy prompt jest osobnym plikiem TXT i ogranicza materiały wejściowe do jednej spójnej części systemu. Raport z jednego promptu jest kontraktem wejściowym dla kolejnych raportów, ale nie zastępuje ponownego odczytania wskazanych plików.

Zasada prawdy
-------------
Dokumenty `JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md` oraz `JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md` są nadrzędną architekturą docelową. Jeżeli inny dokument, kod, README, manifest albo wcześniejszy raport jest z nimi sprzeczny, GLM musi wykazać konflikt, nie zgadywać i oznaczyć go jako BLOCKER do rozstrzygnięcia.

Zasada prawna
-------------
`JDG/docs/Bbb` jest katalogiem wskazanych podstaw prawnych, ale jego numery Dz.U. i opisy muszą zostać zweryfikowane wobec oficjalnych źródeł ISAP/RCL/MF. GLM nie może traktować wpisu z Bbb jako dowodu aktualnego prawa bez weryfikacji. Każda propozycja reguły musi zawierać akt, artykuł/paragraf/punkt, wersję przepisu, datę obowiązywania, źródło oraz poziom pewności.

Kolejność
---------
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15 → 16 → 17 → 18 → 19 → 20.

Po każdym raporcie:
- zapisuj raport jako `JDG/reports/glm52/<numer>_<slug>.txt`;
- nie wdrażaj zmian bez osobnego przeglądu i testów;
- zachowaj identyfikatory rekomendacji `GLM52-<numer>-<ID>`;
- aktualizuj rejestr zależności i `JDG/reports/glm52/DECISION_LOG.txt`;
- przed następnym promptem wdrażaj tylko zatwierdzony zakres, a następnie uruchom walidację i testy;
- raport nie może twierdzić, że kod działa, jeżeli nie został rzeczywiście uruchomiony i zweryfikowany.

Budżet kontekstu
----------------
Do GLM przekazuj wyłącznie linki wymienione w danym promptcie oraz niezbędne krótkie raporty poprzednich części. Materiały wejściowe nie mogą przekroczyć 50% okna kontekstowego. Nie wklejaj całego repozytorium. Jeżeli wskazane pliki są zbyt duże, GLM ma analizować je partiami według sekcji, a nie pomijać niejawnie treści.

Bezpieczeństwo
--------------
OPA może wspierać księgowanie, lecz decyzja `AUTO_POST` jest dopuszczalna wyłącznie po przejściu bramek, invariants, legal traceability, kompletności danych, zgodności temporalnej i polityki pewności. Przy konflikcie, luce prawnej, niezweryfikowanym źródle lub naruszeniu invariantów obowiązuje fail-closed: `NEEDS_ADVICE` / `MANUAL_REVIEW`, nigdy automatyczne księgowanie.

Lista promptów
--------------
01_fundament_architektury_i_inwentaryzacja.txt
02_orkiestrator_i_kontrakt_werdyktu.txt
03_temporalnosc_thresholds_i_rule_lifecycle.txt
04_legal_twin_i_traceability.txt
05_vat_core_i_micro.txt
06_pit_formy_ulgi_i_koszty.txt
07_zus_i_skladka_zdrowotna.txt
08_ksiegowosc_pkpir_uor_amortyzacja.txt
09_ryczalt_pcc_lokalne_akcyza.txt
10_crossborder_tp_mdr_cfc.txt
11_ksef_jpk_deklaracje_edoreczenia.txt
12_kks_compliance_fraud_i_sankcje.txt
13_bdo_rodo_aml_bezpieczenstwo.txt
14_integracje_api_rule_store_i_dane.txt
15_control_plane_bundles_deployment_i_rollback.txt
16_testy_rego_ci_mutation_fuzz_formal.txt
17_obserwowalnosc_audyt_certificates_i_provenance.txt
18_neural_mesh_ai_i_declarative_change.txt
19_resilience_performance_chaos_i_dr.txt
20_audyt_integracyjny_roadmap_i_certification.txt

Każdy prompt kończy się poleceniem wyczyszczenia okna kontekstowego po zapisaniu raportu i przed użyciem następnego promptu.
