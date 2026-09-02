==============================================================================
NEXUSAI JDG — KAMPANIA V3 „FORTRESS” — PAKIET PROMPTÓW DLA GLM 5.2
==============================================================================

Cel kampanii
-----------
Sekwencyjna, część po części, analiza i wzmacnianie modułu JDG (silnik reguł podatkowych OPA)
do poziomu ENTERPRISE opisanego w dwóch dokumentach świętych:

  * JDG/docs/ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md  (V1 — Control Plane, Data Plane, cykl życia reguł)
  * JDG/docs/WIZJA_OPA_ENTERPRISE_V2.md             (V2 — Legal Twin, konstytucja, Golden Oracle,
                                                     Decision Certificate, Law Radar, Declarative Change)

Cel nadrzędny biznesowy: pełna automatyzacja księgowości JDG (wirtualny księgowy) przy nienaruszalnej
precyzji prawnej i fail-closed. OPA ma być SYSTEMEM (zmiana prawa = prosta, szybka, bezpieczna zmiana
reguł/parametrów), a nie zborem plików Rego.

Zasady kampanii
---------------
1. Jeden prompt = jeden plik TXT w JDG/prompty_v3/. Każdy wklejasz do GLM 5.2 w ŚWIEŻEJ (czystej) sesji.
2. Kolejność: P00 → P01 → … → P68. Bez pomijania — każda część honoruje kontrakty wyjściowe wcześniejszych.
3. Budżet kontekstu: dane wejściowe odczytane wg linków z promptu mają zająć maksymalnie 50% okna
   kontekstowego GLM 5.2 (wg założenia właściciela okno GLM 5.2 ≈ 1 000 000 tokenów; jeśli realne okno
   modelu jest mniejsze, czytaj wskazane pliki partiami wg sekcji — mechanizm opisano w Sekcji 3 każdego
   promptu). Reszta okna pozostaje na myślenie i generowanie raportu.
4. Raporty zapisywane do JDG/raporty_glm52_v3/RAPORT_V3_<kod>_<slug>.txt. Identyfikatory: V3-<kod>-Lxx
   (luki), V3-<kod>-Ixx (innowacje), V3-<kod>-Cx (konflikty), V3-<kod>-Qxx (pytania), V3-<kod>-Xxx (krzyżowe).
5. Po KAŻDYM raporcie: potwierdzenie zakresu → wdrożenie zatwierdzonego zakresu przez człowieka →
   walidacja i testy → dopiero wtedy następny prompt. Raport NIE jest wdrożeniem.
6. Każdy prompt kończy się komendą czyszczenia okna kontekstowego po zapisaniu raportu (Sekcja 16).
7. Dokumenty święte są nadrzędne; JDG/docs/Bbb to katalog twierdzeń prawnych do weryfikacji w ISAP/RCL/MF.
8. Zakaz duplikacji i zakaz fikcyjnych faktów; fail-closed: AUTO_POST tylko przy pełnym dowodzie.

Skala pakietu: 69 promptów (P00–P68) + ten README. Każdy raport: duży, dowodowy, wdrożeniowy.

Mapa kampanii (część → zakres katalogu JDG → raport)
---------------------------------------------------

| Część | Tytuł | Plik promptu | Raport docelowy |
|-------|-------|--------------|-----------------|
| P00 | MAPA KANONICZNA, INWENTARYZACJA I KONTRAKT INTEGRACYJNY SERII V3 | JDG/prompty_v3/V3_PROMPT_P00_MAPA_KANONICZNA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P00_MAPA_KANONICZNA.txt |
| P01 | LEGAL TWIN, LEGAL KNOWLEDGE GRAPH I ŚCIEŻKA DOWODOWA ZGODNOŚCI Z PRAWEM | JDG/prompty_v3/V3_PROMPT_P01_LEGAL_TWIN_LKG.txt | JDG/raporty_glm52_v3/RAPORT_V3_P01_LEGAL_TWIN_LKG.txt |
| P02 | ORKIESTRATOR MULTI-PASS, SHARDED ROUTING I SAFE MERGE | JDG/prompty_v3/V3_PROMPT_P02_ORKIESTRATOR.txt | JDG/raporty_glm52_v3/RAPORT_V3_P02_ORKIESTRATOR.txt |
| P03 | KONTRAKT WERDYKTU 25-POLOWY, KOMPOZYCJA DECYZJI I KLASA PEWNOŚCI | JDG/prompty_v3/V3_PROMPT_P03_KONTRAKT_WERDYKTU.txt | JDG/raporty_glm52_v3/RAPORT_V3_P03_KONTRAKT_WERDYKTU.txt |
| P04 | WARSTWA KONSTYTUCYJNA — RUNTIME INVARIANTS I EGZEKUCJA FAIL-CLOSED | JDG/prompty_v3/V3_PROMPT_P04_INVARIANTY_RUNTIME.txt | JDG/raporty_glm52_v3/RAPORT_V3_P04_INVARIANTY_RUNTIME.txt |
| P05 | TEMPORALNOŚĆ, TIME-TRAVEL I DOWÓD NIEZMIENNOŚCI PRZESZŁOŚCI | JDG/prompty_v3/V3_PROMPT_P05_TEMPORALNOSC.txt | JDG/raporty_glm52_v3/RAPORT_V3_P05_TEMPORALNOSC.txt |
| P06 | PARAMETRY JAKO DANE: PROGI, STAWKI, LIMITY I HOT-RELOAD | JDG/prompty_v3/V3_PROMPT_P06_PARAMETRY_DANE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P06_PARAMETRY_DANE.txt |
| P07 | CYKL ŻYCIA REGUŁ: SHADOW→CANDIDATE→ACTIVE→ROLLBACK I OPERACJE AWARYJNE | JDG/prompty_v3/V3_PROMPT_P07_RULE_LIFECYCLE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P07_RULE_LIFECYCLE.txt |
| P08 | LAW RADAR — PROAKTYWNA ADAPTACJA DO ZMIAN PRAWA (V2/F5) | JDG/prompty_v3/V3_PROMPT_P08_LAW_RADAR.txt | JDG/raporty_glm52_v3/RAPORT_V3_P08_LAW_RADAR.txt |
| P09 | DECLARATIVE CHANGE — ZMIANA W JĘZYKU PROSTYM (V2/F6) | JDG/prompty_v3/V3_PROMPT_P09_DECLARATIVE_CHANGE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P09_DECLARATIVE_CHANGE.txt |
| P10 | GOLDEN VERDICTS ORACLE I NIEZNISZCZALNOŚĆ PRZESZŁOŚCI (V2/F3) | JDG/prompty_v3/V3_PROMPT_P10_GOLDEN_ORACLE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P10_GOLDEN_ORACLE.txt |
| P11 | DECISION CERTIFICATE — DOWÓD DECYZJI DLA PRZEDSIĘBIORCY (V2/F4) | JDG/prompty_v3/V3_PROMPT_P11_DECISION_CERTIFICATE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P11_DECISION_CERTIFICATE.txt |
| P12 | VAT — STAWKI, ZWOLNIENIA I KLASYFIKACJA (MACRO + MICRO) | JDG/prompty_v3/V3_PROMPT_P12_VAT_STAWKI_ZWOLNIENIA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P12_VAT_STAWKI_ZWOLNIENIA.txt |
| P13 | VAT — ODLICZENIA, PROPORCJE, KOREKTY, MPP/SPLIT PAYMENT I FRAUD | JDG/prompty_v3/V3_PROMPT_P13_VAT_ODLICZENIA_MPP.txt | JDG/raporty_glm52_v3/RAPORT_V3_P13_VAT_ODLICZENIA_MPP.txt |
| P14 | PIT — FORMY OPODATKOWANIA, ULGI I OPTYMALIZACJA | JDG/prompty_v3/V3_PROMPT_P14_PIT_ULGI_OPTYMALIZACJA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P14_PIT_ULGI_OPTYMALIZACJA.txt |
| P15 | CROSS-BORDER, WDT/WNT, TP/MDR/CFC I WALUTY | JDG/prompty_v3/V3_PROMPT_P15_CROSSBORDER_TP.txt | JDG/raporty_glm52_v3/RAPORT_V3_P15_CROSSBORDER_TP.txt |
| P16 | KSeF 2.0, JPK_V7, DEKLARACJE I E-DOREĄCZENIA | JDG/prompty_v3/V3_PROMPT_P16_KSEF_JPK.txt | JDG/raporty_glm52_v3/RAPORT_V3_P16_KSEF_JPK.txt |
| P17 | ORDYNACJA PODATKOWA — OBRONA, ODSETKI, PRZEDAWNIENIE I PROWADZENIE SPRAW | JDG/prompty_v3/V3_PROMPT_P17_ORDYNACJA_OBRONA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P17_ORDYNACJA_OBRONA.txt |
| P18 | RYCZAŁT OD PRZYCHODÓW EWIDENCJONOWANYCH I KARTA PODATKOWA | JDG/prompty_v3/V3_PROMPT_P18_RYCZALT.txt | JDG/raporty_glm52_v3/RAPORT_V3_P18_RYCZALT.txt |
| P19 | PCC, PODATKI LOKALNE, AKCYZA I ŚRODOWISKO (BDO, CBAM, CO2) | JDG/prompty_v3/V3_PROMPT_P19_PCC_AKCYZA_BDO.txt | JDG/raporty_glm52_v3/RAPORT_V3_P19_PCC_AKCYZA_BDO.txt |
| P20 | PKPiR, UoR, AMORTYZACJA I LEASING — RDZEŃ KSIĘGOWOŚCI | JDG/prompty_v3/V3_PROMPT_P20_KSIEGOWOSC_PKPIR_UOR.txt | JDG/raporty_glm52_v3/RAPORT_V3_P20_KSIEGOWOSC_PKPIR_UOR.txt |
| P21 | KKS — KARY, PRZEDAWNIENIE KARNE, VCC I OBRONA | JDG/prompty_v3/V3_PROMPT_P21_KKS_SANKCJE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P21_KKS_SANKCJE.txt |
| P22 | RODO, AML, BEZPIECZEŃSTWO I OCHRONA DANYCH W SILNIKU | JDG/prompty_v3/V3_PROMPT_P22_RODO_AML_SECURITY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P22_RODO_AML_SECURITY.txt |
| P23 | PRAWO PRZEDSIEBIORCÓW — CEIDG, ZAWIESZENIE, SUKCESJA, CYKL ŻYCIA | JDG/prompty_v3/V3_PROMPT_P23_PRAWO_PRZEDSIEBIORCOW.txt | JDG/raporty_glm52_v3/RAPORT_V3_P23_PRAWO_PRZEDSIEBIORCOW.txt |
| P24 | PRAWO PRACY W JDG — PRACOWNICY, PPK/PFRON, ŚWIADCZENIA | JDG/prompty_v3/V3_PROMPT_P24_PRACA_SWIADCZENIA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P24_PRACA_SWIADCZENIA.txt |
| P25 | KALENDARZ ZBIORCZY TERMINÓW I OBOWIĄZKÓW — JEDNO ŹRÓDŁO PRAWDY | JDG/prompty_v3/V3_PROMPT_P25_KALENDARZ_ZBIORCZY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P25_KALENDARZ_ZBIORCZY.txt |
| P26 | ZUS — SKŁADKI SPOŁECZNE, ZDROWOTNA, ULGI I KALENDARZ | JDG/prompty_v3/V3_PROMPT_P26_ZUS_SKLADKI.txt | JDG/raporty_glm52_v3/RAPORT_V3_P26_ZUS_SKLADKI.txt |
| P27 | CFC, EXIT TAX, MDR SZCZEGÓŁY I PRZEPŁYWY MIĘDZYJURYSDYKCYJNE | JDG/prompty_v3/V3_PROMPT_P27_CFC_EXIT_MDG.txt | JDG/raporty_glm52_v3/RAPORT_V3_P27_CFC_EXIT_MDG.txt |
| P28 | HYPERKONTEKSTY PLAN44/45 I KRYTYCZNE ŚCIEŻKI DZIAŁANIA | JDG/prompty_v3/V3_PROMPT_P28_HYPER_PLAN45.txt | JDG/raporty_glm52_v3/RAPORT_V3_P28_HYPER_PLAN45.txt |
| P29 | KAMPANIE JAKOŚCI V3 — 8 BRAMEK (MICRO/HYPER/ENTERPRISE/TOOLS/TESTS_CI/BUNDLES/API_UI/DOCS) | JDG/prompty_v3/V3_PROMPT_P29_KAMPANIE_JAKOSCI_V3.txt | JDG/raporty_glm52_v3/RAPORT_V3_P29_KAMPANIE_JAKOSCI_V3.txt |
| P30 | FALE INNOWACJI — 24 GATE'Y RAPORTÓW R01–R24 I SPÓJNOŚĆ WDROŻEŃ | JDG/prompty_v3/V3_PROMPT_P30_FALE_INNOWACJI_GATES.txt | JDG/raporty_glm52_v3/RAPORT_V3_P30_FALE_INNOWACJI_GATES.txt |
| P31 | ETAPY AUDYTÓW 12–28 — DOMKNIĘCIE CYKLU KAMPANII ETAPOWEJ | JDG/prompty_v3/V3_PROMPT_P31_ETAPY_AUDYTOW_12_28.txt | JDG/raporty_glm52_v3/RAPORT_V3_P31_ETAPY_AUDYTOW_12_28.txt |
| P32 | AUTOMATYZACJA KSIEGOWOŚCI JDG — OD FAKTURY DO ARCHIWUM (CEL NADRZĘDNY) | JDG/prompty_v3/V3_PROMPT_P32_AUTOMATYZACJA_KSIEGOWOSCI.txt | JDG/raporty_glm52_v3/RAPORT_V3_P32_AUTOMATYZACJA_KSIEGOWOSCI.txt |
| P33 | WARSTWA AI ENTERPRISE — NEURAL MESH, LLM BRIDGE I HUMAN-IN-THE-LOOP | JDG/prompty_v3/V3_PROMPT_P33_NEURAL_MESH_AI.txt | JDG/raporty_glm52_v3/RAPORT_V3_P33_NEURAL_MESH_AI.txt |
| P34 | NARZĘDZIA WALIDACJI I HIGIENA KODU — ZERO STUBÓW, ZERO DEAD CODE | JDG/prompty_v3/V3_PROMPT_P34_WALIDACJA_NARZEDZIA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P34_WALIDACJA_NARZEDZIA.txt |
| P35 | AUDYTORY DOMENOWE I DASHBOARDY — VAT/PIT/ZUS/KKS/KSEF/ORDYNACJA | JDG/prompty_v3/V3_PROMPT_P35_AUDYTORY_DOMENOWE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P35_AUDYTORY_DOMENOWE.txt |
| P36 | GENERATORY I MIGRATORY — PLAN33/PLAN50, NAPRAWY, DEDUPLIKACJA, PROWIENIE | JDG/prompty_v3/V3_PROMPT_P36_GENERATORY_MIGRATORY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P36_GENERATORY_MIGRATORY.txt |
| P37 | OBSERWOWALNOŚĆ — METRYKI, SLO, DASHBOARDY I WCZESNE OSTRZEGANIE | JDG/prompty_v3/V3_PROMPT_P37_OBSERWOWALNOSC.txt | JDG/raporty_glm52_v3/RAPORT_V3_P37_OBSERWOWALNOSC.txt |
| P38 | BUNDLE, DEPLOY I CYKL ŻYCIA WERSJI — CANARY, ROLLBACK, IMMUTABLE ARTEFAKTY | JDG/prompty_v3/V3_PROMPT_P38_BUNDLE_DEPLOY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P38_BUNDLE_DEPLOY.txt |
| P39 | TESTY I CI — NATYWNE REGO, PYTEST, GOLDEN, FUZZ I BRAMKI BLOKUJĄCE | JDG/prompty_v3/V3_PROMPT_P39_TESTY_CI.txt | JDG/raporty_glm52_v3/RAPORT_V3_P39_TESTY_CI.txt |
| P40 | API, DANE I UI — ORKIESTRATOR DLA PRZEDSIĘBIORCY I KSIĘGOWEGO | JDG/prompty_v3/V3_PROMPT_P40_API_DANE_UI.txt | JDG/raporty_glm52_v3/RAPORT_V3_P40_API_DANE_UI.txt |
| P41 | DOKUMENTACJA ENTERPRISE — JEDNO ŹRÓDŁO PRAWDY, SPÓJNOŚĆ Z KODEM | JDG/prompty_v3/V3_PROMPT_P41_DOKUMENTACJA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P41_DOKUMENTACJA.txt |
| P42 | ENTERPRISE — RESZTA LUK SYSTEMOWYCH: HEALTH TIERS, SMT, WORM, ZALEŻNOŚCI | JDG/prompty_v3/V3_PROMPT_P42_ENTERPRISE_RESZTA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P42_ENTERPRISE_RESZTA.txt |
| P43 | BEZPIECZEŃSTWO, ODPORNOŚĆ I DR — FORTYFIKACJA OSTATECZNA | JDG/prompty_v3/V3_PROMPT_P43_SECURITY_DR.txt | JDG/raporty_glm52_v3/RAPORT_V3_P43_SECURITY_DR.txt |
| P44 | CERTYFIKACJA FINALNA FORTECY — ZAMKNIĘCIE KAMPANII V3 I DEKLARACJA STANU | JDG/prompty_v3/V3_PROMPT_P44_CERTYFIKACJA_FINALNA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P44_CERTYFIKACJA_FINALNA.txt |
| P45 | ELIMINACJA STUBÓW I FASAD — ZERO REGUŁ UDĄJĄCYCH POKRYCIE | JDG/prompty_v3/V3_PROMPT_P45_STUB_KILLER.txt | JDG/raporty_glm52_v3/RAPORT_V3_P45_STUB_KILLER.txt |
| P46 | ELIMINACJA HARDCODE — WSZYSTKIE PROGI, STAWKI I LIMITY DO DATA.THRESHOLDS.* | JDG/prompty_v3/V3_PROMPT_P46_HARDCODE_ELIMINACJA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P46_HARDCODE_ELIMINACJA.txt |
| P47 | WERYFIKACJA PODSTAW PRAWNYCH — ZERO FIKCJI, KAŻDY CYTAT W ISAP | JDG/prompty_v3/V3_PROMPT_P47_LEGAL_BASIS_WERYFIKACJA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P47_LEGAL_BASIS_WERYFIKACJA.txt |
| P48 | SYNCHRONIZACJA MIRROR POLICIES — ZERO DRYFU CANONICAL↔MIRROR | JDG/prompty_v3/V3_PROMPT_P48_MIRROR_SYNC.txt | JDG/raporty_glm52_v3/RAPORT_V3_P48_MIRROR_SYNC.txt |
| P49 | DOMKNIĘCIE FAIL-CLOSED — ZERO CICHYCH AUTO_POST, KAŻDA NIEPEWNOŚĆ MA ŚCIEŻKĘ | JDG/prompty_v3/V3_PROMPT_P49_FAIL_CLOSED_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P49_FAIL_CLOSED_DOMKNIECIE.txt |
| P50 | DEAD CODE I DUPLIKATY — UNIKALNOŚĆ RULE_ID, JEDNO ŹRÓDŁO PRAWDY PER ZASADA | JDG/prompty_v3/V3_PROMPT_P50_DEAD_CODE_DUPLIKATY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P50_DEAD_CODE_DUPLIKATY.txt |
| P51 | PUSTYNIE PRAWNE — DOMKNIĘCIE LUK POKRYCIA AKT→REGUŁY | JDG/prompty_v3/V3_PROMPT_P51_PUSTYNIE_PRAWNE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P51_PUSTYNIE_PRAWNE.txt |
| P52 | GRANICE GROSZOWE, WALUTY I ZAOKRĄGLENI — PRECYZJA WYPOWIEDZI FINANSOWEJ | JDG/prompty_v3/V3_PROMPT_P52_GRANICE_GROSZOWE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P52_GRANICE_GROSZOWE.txt |
| P53 | TEMPORALNOŚĆ NA GRANICACH — DAY-0 NOWELIZACJI I TIME-TRAVEL BEZ WĄTPLIWOŚCI | JDG/prompty_v3/V3_PROMPT_P53_TEMPORALNOSC_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P53_TEMPORALNOSC_DOMKNIECIE.txt |
| P54 | KSEF 2.0 I JPK — TERMINY, SCHEMATY I KOLEJKI NA POZIOMIE ENTERPRISE | JDG/prompty_v3/V3_PROMPT_P54_KSEF_JPK_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P54_KSEF_JPK_DOMKNIECIE.txt |
| P55 | ZUS DO ZERA — 30-KROTNOŚĆ, ULGI, CHOROBOWE I TERMINY BEZ LUK | JDG/prompty_v3/V3_PROMPT_P55_ZUS_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P55_ZUS_DOMKNIECIE.txt |
| P56 | VAT I PIT — SZCZEGÓŁY MATERIALNE, KTÓRE DECYDUJĄ O POPRAWNOŚCI | JDG/prompty_v3/V3_PROMPT_P56_VAT_PIT_SZCZEGOLY.txt | JDG/raporty_glm52_v3/RAPORT_V3_P56_VAT_PIT_SZCZEGOLY.txt |
| P57 | INGEST DANYCH — DOKUMENTY, FAKTY I KOLEJKI BEZ UTRATY I BEZ DUPLIKATÓW | JDG/prompty_v3/V3_PROMPT_P57_INGEST_DANYCH.txt | JDG/raporty_glm52_v3/RAPORT_V3_P57_INGEST_DANYCH.txt |
| P58 | OBSERWOWALNOŚĆ FORTHECY — METRYKI DECYZYJNE I ALARMY NA TYM, CO PRAWNIE WRAŻLIWE | JDG/prompty_v3/V3_PROMPT_P58_OBSERWOWALNOSC_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P58_OBSERWOWALNOSC_DOMKNIECIE.txt |
| P59 | BEZPIECZEŃSTWO DOMKNIĘCIE — GRANICE ZAUFANIA, SEKRETY I ANTY-MANIPULACJA | JDG/prompty_v3/V3_PROMPT_P59_SECURITY_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P59_SECURITY_DOMKNIECIE.txt |
| P60 | DOKUMENTACJA DOMKNIECIE — DOKUMENT MÓWI PRAWDĘ O KODZIE | JDG/prompty_v3/V3_PROMPT_P60_DOKUMENTACJA_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P60_DOKUMENTACJA_DOMKNIECIE.txt |
| P61 | INTEGRACJE ZEWNĘTRZNE — KSEF/MF, BANKI, NBP, ISAP NA POZIOMIE PRODUKCYJNYM | JDG/prompty_v3/V3_PROMPT_P61_INTEGRACJE_DOMKNIECIE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P61_INTEGRACJE_DOMKNIECIE.txt |
| P62 | PRZEPYWY PIENIĘŻNE — PŁATNOŚCI, PRIORYTETY I CASHFLOW W HORYZONCIE | JDG/prompty_v3/V3_PROMPT_P62_PRZEPYWY_PIENIEZNE.txt | JDG/raporty_glm52_v3/RAPORT_V3_P62_PRZEPYWY_PIENIEZNE.txt |
| P63 | RBAC, MULTI-TENANT I DANE — IZOLACJA I UPRawnienia NA POZIOMIE ENTERPRISE | JDG/prompty_v3/V3_PROMPT_P63_RBAC_MULTITENANT.txt | JDG/raporty_glm52_v3/RAPORT_V3_P63_RBAC_MULTITENANT.txt |
| P64 | SWEEP LUK REZYDUALNYCH — PRZEGLĄD CAŁOŚCIOWY PO FALACH NAPRAW | JDG/prompty_v3/V3_PROMPT_P64_LUKA_SWEEP.txt | JDG/raporty_glm52_v3/RAPORT_V3_P64_LUKA_SWEEP.txt |
| P65 | NOWE NARZĘDZIA FORTECY — CO PRZEGAPIŁA FALA (Projekty 8–12 narzędzi) | JDG/prompty_v3/V3_PROMPT_P65_NOWE_NARZEDZIA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P65_NOWE_NARZEDZIA.txt |
| P66 | CHAOS I ODPORNOŚĆ — FORTECA TESTOWANA NISZCZYCIELEM | JDG/prompty_v3/V3_PROMPT_P66_CHAOS_ODPORNOSC.txt | JDG/raporty_glm52_v3/RAPORT_V3_P66_CHAOS_ODPORNOSC.txt |
| P67 | SELF-LEARNING FORTECY — PĘTLA WIEDZY Z DECYZJI I WYJĄTKÓW | JDG/prompty_v3/V3_PROMPT_P67_SELF_LEARNING.txt | JDG/raporty_glm52_v3/RAPORT_V3_P67_SELF_LEARNING.txt |
| P68 | RE-CERTYFIKACJA FORTECY — DOWÓD STANU PO FALACH NAPRAWCZYCH | JDG/prompty_v3/V3_PROMPT_P68_RECERTYFIKACJA_FINALNA.txt | JDG/raporty_glm52_v3/RAPORT_V3_P68_RECERTYFIKACJA_FINALNA.txt |

Struktura logiczna kampanii
---------------------------
Części P00–P09 budują SYSTEM (kanon, Legal Twin, orkiestrator, kontrakt werdyktu, invarianty,
temporalność, parametry, lifecycle, Law Radar, Declarative Change). Części P10–P11 domykają pewność
(Golden Oracle, Decision Certificate). Części P12–P28 są DOMENOWE (VAT ×2, PIT, cross-border, KSeF/JPK,
Ordynacja, ryczałt, PCC/lokalne/akcyza/BDO, PKPiR/UoR, KKS, RODO/AML, Prawo przedsiębiorców, praca,
kalendarz zbiorczy, ZUS, CFC/exit/MDR, hiperkonteksty plan45). Części P29–P36 to fala jakości i narzędzi
(kampanie quality v3, fale innowacji pXX/rXX/etapy, automatyzacja księgowości, neural mesh AI, walidacja,
audytory domenowe, generatory/migratory). Części P37–P44 domykają warstwę systemową (obserwowalność,
bundle/deployment, testy/CI, API/dane/UI, dokumentacja, enterprise-reszta, security/DR, certyfikacja w P44).
FALA NAPRAWCZA P45–P67 celuje w LUKI wykryte w analizie V3: stuby i fasady, hardcode parametrów,
niezweryfikowane podstawy prawne, dryf mirror policies, dziury fail-closed, dead code, duplikaty rule_id,
pustynie pokrycia prawnego, testy graniczne, temporalność, KSeF 2.0, ZUS, VAT/PIT szczegóły, ingest danych,
obserwowalność, security, DR, dokumentacja, wydajność, RuleStore, CI. Część P68 = RE-CERTYFIKACJA
fortecy po domknięciu fali naprawczej — nowy dowód stanu, nie powtórzenie certyfikatu P44.

Definicja sukcesu kampanii (potwierdzana w P68)
----------------------------------------------
Silnik reguł podatkowych OPA jako ufortyfikowana forteca klasy ENTERPRISE: mierzalne pokrycie prawa
(Legal Twin), egzekwowane invarianty w runtime, golden oracle przeszłości, certyfikaty decyzji,
proaktywny Law Radar, deklaratywna zmiana reguł — zero duplikatów, zero stubów, zero hardcode,
zero fikcyjnych podstaw prawnych, pełny fail-closed. Precyzja, profesjonalizm, zero nieporozumień.

Artefakty pakietu
-----------------
  JDG/prompty_v3/V3_PROMPT_Pxx_<slug>.txt   — prompty (jeden plik na część, wklejany pojedynczo).
  JDG/raporty_glm52_v3/                      — miejsce docelowe raportów generowanych przez GLM 5.2.
  JDG/tools/glm52_v3_campaign/               — generator pakietu (Python; waliduje ścieżki i minimum).

