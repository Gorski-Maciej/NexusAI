#============================================================================
# README — SERIA 25 PROMPTÓW GLM 5.2 (NEXUSAI JDG ENTERPRISE)
#============================================================================

## JAK UŻYWAĆ SERII
1. Wklejaj prompty PO KOLEI (00 → 24), jeden na jedną sesję GLM 5.2.
2. Każdy prompt kończy się instrukcją WYCZYSZCZENIA OKNA KONTEKSTOWEGO — po zapisaniu raportu
   do JDG/raporty_glm52/ zacznij nową sesję i wklej następny prompt.
3. Raporty trafiają do JDG/raporty_glm52/ (RAPORT_XX_*.txt). Po wdrożeniu wzmocnień z raportów
   silnik reguł podatkowych OPA ma osiągnąć najwyższy zaawansowany poziom ENTERPRISE.

## KALIBRACJA OKNA KONTEKSTOWEGO
- GLM 5.2: okno 1 000 000 tokenów; dane wejściowe ≤ 50% okna (~500 tys. tokenów).
- Katalog JDG ≈ 8,2 mln tokenów (rego ~3,7 mln, docs ~447 tys., tools ~520 tys., tests ~618 tys.,
  bundles JSON ~3,1 mln — z czego duże JSON-y czytane selektywnie).
- Dlatego seria liczy 25 części — każda skalibrowana poniżej limitu 50%.

## SPIS CZĘŚCI (plik -> tytuł)
- 00_FUNDAMENT_ARCHITEKTURA_WIZJA_V1_V2_AKTY_PRAW.txt  |  FUNDAMENT — ARCHITEKTURA, WIZJA V1+V2, AKTY PRAWNE, STAN SYSTEMU (RAPORT MASTER)
- 01_ORKIESTRATOR_I_RDZEŃ_SILNIKA_main_jdg_routin.txt  |  ORKIESTRATOR I RDZEŃ SILNIKA (main_jdg, routing, risk, temporal, thresholds, validation)
- 02_VAT_CORE.txt  |  VAT — CORE (MACRO) + ENTERPRISE (stawki, odliczenia, MPP, fraud, korekty)
- 03_VAT_WARSTWA_MICRO.txt  |  VAT — WARSTWA MICRO (atomowe reguły per artykuł, plan33/plan34)
- 04_PIT_CORE.txt  |  PIT — CORE (MACRO) + ULGI (skala, liniowy, KUP, NKUP, amortyzacja, ulgi Art. 21–26h, IP Box)
- 05_PIT_ENTERPRISE.txt  |  PIT — ENTERPRISE (deklaracje PIT-36/36L/28, estoński CIT, exit tax, transformacje, optymalizacja)
- 06_ZUS_SUS_składki_ulgi.txt  |  ZUS/SUS — składki, ulgi (start/preferencyjny/Mały ZUS+), zdrowotna, zasiłki, PPK/PFRON, HR
- 07_KKS_Kodeks_Karny_Skarbowy.txt  |  KKS — Kodeks Karny Skarbowy (czynny żal, sankcje, kary, obrona, GAAR, sanctions)
- 08_ORDYNACJA_PODATKOWA_OBRONA_PODATNIKA_postępo.txt  |  ORDYNACJA PODATKOWA + OBRONA PODATNIKA (postępowania, przedawnienie, korekty, KAS, sądy)
- 09_UoR_PKPiR_KSIĘGOWOŚĆ_pełna_księgowość_księgi.txt  |  UoR / PKPiR / KSIĘGOWOŚĆ (pełna księgowość, księgi, kolumny PKPiR, amortyzacja, transformacja)
- 10_CROSS-BORDER_TP_MDR-DAC6_CFC_ViDA_CBAM_DAC8_.txt  |  CROSS-BORDER / TP / MDR-DAC6 / CFC / ViDA / CBAM / DAC8 (transakcje zagraniczne)
- 11_PCC_PODATKI_LOKALNE_AKCYZĄ_nieruchomości_śro.txt  |  PCC / PODATKI LOKALNE / AKCYZĄ (nieruchomości, środki transportu, umowy, paliwo, alkohol)
- 12_RYCZAŁT_CEIDG_PRAWO_PRZEDSIĘBIORCÓW_SUKCESJA.txt  |  RYCZAŁT / CEIDG / PRAWO PRZEDSIĘBIORCÓW / SUKCESJA / BUDOWNICTWO / CYKL ŻYCIA FIRMY
- 13_HYPER_PLAN45_REPREZENTACJA_DZIAŁALNOŚĆ_REGUL.txt  |  HYPER PLAN45 + REPREZENTACJA + DZIAŁALNOŚĆ REGULOWANA + KONTEKSTY SPECJALNE
- 14_RODO_AML-CBDD_BDO_ŚRODOWISKO_SEKURYTYZACJA_b.txt  |  RODO / AML-CBDD / BDO / ŚRODOWISKO / SEKURYTYZACJA (bezpieczeństwo i zgodność)
- 15_KSeF_JPK_e-DEKLARACJE_e-DORĘCZENIA_WIS_GTU_o.txt  |  KSeF / JPK / e-DEKLARACJE / e-DORĘCZENIA / WIS / GTU (obowiązki elektroniczne)
- 16_SYSTEM_OPA_INNOWACJE_P18_P35.txt  |  SYSTEM OPA — INNOWACJE P18–P35 (OPA jako rozbudowany SYSTEM, automatyzacja, walidacja, audyt)
- 17_ENTERPRISE_AI_INTELIGENCJA_SYSTEMU.txt  |  ENTERPRISE AI — INTELIGENCJA SYSTEMU (Neural Mesh, Adaptive Trust, Strategie, Bankowość PSD2)
- 18_NARZĘDZIA_SYSTEMOWE_walidacja_lint_pokrycie_.txt  |  NARZĘDZIA SYSTEMOWE (walidacja, lint, pokrycie prawne, legal twin, golden replay, CI)
- 19_NARZĘDZIA_DOMENOWE_generatory_reguł_audytory.txt  |  NARZĘDZIA DOMENOWE (generatory reguł, audytory per domena, ZUS atom, KKS toolkit, testy)
- 20_TESTY_PYTEST_testy_jednostkowe_i_integracyjn.txt  |  TESTY PYTEST (testy jednostkowe i integracyjne modułów ENTERPRISE)
- 21_TESTY_NATYWNE_REGO_opa_test_test_native_.reg.txt  |  TESTY NATYWNE REGO (opa test — test_native_*.rego, coverage testów reguł)
- 22_BUNDLE_API_MIGRACJE_bundle_OPA_OpenAPI_RuleS.txt  |  BUNDLE / API / MIGRACJE (bundle OPA, OpenAPI, RuleStore DuckDB, deployment, rejestry)
- 23_DOKUMENTACJA_TEMATYCZNA_docs_moduły_P02_P24_.txt  |  DOKUMENTACJA TEMATYCZNA (docs/ — moduły P02–P24, audyty, strategie)
- 24_POLICIES_LUSTRO_REGUŁ_OVERLAYS_v2026_v2027.txt  |  POLICIES — LUSTRO REGUŁ + OVERLAYS v2026/v2027 (spójność rules/ ↔ policies/)

## ZASADY
- Prompty GENERUJĄ INTELIGENTNY KOD — każdy raport .txt (30–50 stron) zawiera GOTOWE DO
  WDROŻENIA fragmenty kodu (Rego/Python/SQL/JSON) dla każdego ulepszenia. Po wdrożeniu kodu
  z raportów silnik reguł podatkowych OPA ma osiągnąć najwyższy zaawansowany poziom ENTERPRISE.
- W każdym prompcie frazy obowiązkowe ≥4x (głębokie myślenie, głęboka analiza, poziom ENTERPRISE,
  zaawansowany poziom Enterprise, innowacyjne ulepszenia wyprzedzające profesjonalistów).
- Każdy prompt odwołuje się do 4 PLIKÓW WZORCOWYCH (Louh, Bb, Jllug, Jnkkk — style procesu,
  standardów dokumentacji i struktury raportu) oraz do PLIKÓW ŚWIĘTYCH (V1/V2 + docs/Bbb).
- Spójność łańcucha: każda część czyta raport master 00 i raporty części powiązanych oraz
  publikuje sekcję KONTRAKTY Z INNYMI CZĘŚCIAMI.
- Regenerator: python3 JDG/tools/generate_glm52_prompty.py
