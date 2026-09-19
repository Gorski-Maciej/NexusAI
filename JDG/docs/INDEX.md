<!--
artifacts: [docs/INDEX.md]
status: ACTIVE
owner: docs
verified: 2026-09-19
verify_cmd: python3 tools/v3_p60_engines.py I03
-->

# 🗺️ NexusAI JDG — INDEX dokumentacji (master spis)

> **Dokument:** INDEX.md | **Cel:** znajdź właściwy dokument w < 30 sekund — wg roli, wg zadania lub alfabetycznie.
> **Stan projektu:** Kampania V3 **69/69 WDROŻONY_100** (2026-09-19), certyfikat fortecy WYDANY · 543 plików Rego · 12 111 unikalnych rule_id · 288 pytest + 278 natywnych Rego · 1033 narzędzi.

---

## 🔎 Wyszukiwarka (Ctrl+F)

`indeks` · `index` · `spis treści` · `dokumentacja` · `mapa dokumentów` · `od czego zacząć` · `start` · `onboarding` · `rola` · `developer` · `integrator` · `księgowa` · `doradca` · `DevOps` · `QA` · `compliance` · `audyt` · `gdzie szukać`

---

## 1. Wartość biznesowa (PWE)

| | |
|---|---|
| **P — Problem** | Dokumentacja liczy 70+ plików; nowa osoba nie wie, od czego zacząć, a weteran nie pamięta, w którym pliku jest ERD albo tabela kodów błędów. |
| **W — Wartość** | Ten indeks mapuje **role → dokumenty** i **zadania → sekcje**; każdy wiersz mówi, co znajdziesz i dla kogo. |
| **E — Efekt** | Onboarding w godzinę zamiast dni; zero zagubionych odpowiedzi; Ctrl+F prowadzi wprost do sekcji. |

---

## 2. Start wg roli — „od czego zacząć?"

| Rola | Kolejność czytania | Cel |
|---|---|---|
| **Nowa osoba (każda)** | [../README.md](../README.md) → [ARCHITEKTURA.md](ARCHITEKTURA.md) §1–2 → [STRUKTURA_PROJEKTU.md](STRUKTURA_PROJEKTU.md) §2 | zrozumieć misję, architekturę i gdzie co leży |
| **Developer Rego** | [OPA_REGO_DEVELOPER_GUIDE.md](OPA_REGO_DEVELOPER_GUIDE.md) → [KATALOG_REGUL.md](KATALOG_REGUL.md) → [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) → [LOGIKA_BIZNESOWA.md](LOGIKA_BIZNESOWA.md) | pisać reguły wg konwencji ADR-001/002/008 |
| **Integrator (API)** | [API_REFERENCJA.md](API_REFERENCJA.md) → [../api/openapi.yaml](../api/openapi.yaml) → [FAQ.md](FAQ.md) §2 | podłączyć ERP w jeden dzień |
| **Użytkownik / księgowa** | [PODRECZNIK_UZYTKOWNIKA.md](PODRECZNIK_UZYTKOWNIKA.md) → [FAQ.md](FAQ.md) §4 | pierwsza faktura w 15 minut |
| **Compliance / audytor** | [ZGODNOSC_PRAWNA.md](ZGODNOSC_PRAWNA.md) → [LEGAL_TWIN_TRACEABILITY.md](LEGAL_TWIN_TRACEABILITY.md) → [LEGAL_SOURCE_REGISTRY.md](LEGAL_SOURCE_REGISTRY.md) | ścieżka audytu, podstawy prawne |
| **DevOps / QA** | [ARCHITECTURE.md](ARCHITECTURE.md) (ADR) → [TESTY_REGO_CI_P23.md](TESTY_REGO_CI_P23.md) → [KAMPANIA_V3_PROMPTY_P00_P68.md](KAMPANIA_V3_PROMPTY_P00_P68.md) §8 | bramki, testy, ledger |
| **Zarząd / biznes** | [../README.md](../README.md) §Misja i PWE → [WIZJA_OPA_ENTERPRISE_V2.md](WIZJA_OPA_ENTERPRISE_V2.md) → [PEWNOSC_DASHBOARD.md](PEWNOSC_DASHBOARD.md) | wartość, ryzyko, status |

---

## 3. Indeks tematyczny — „gdzie jest…?"

| Szukam… | Dokument → sekcja |
|---|---|
| Diagramów C4 (Context/Container/Component) | [ARCHITEKTURA.md](ARCHITEKTURA.md) §2 (+ §11 warstwa V3 z diagramami P67/P68) |
| Warstw Domain/Application/Infrastructure/Presentation | [ARCHITEKTURA.md](ARCHITEKTURA.md) §Warstwy |
| Wzorców projektowych i ADR | [ARCHITECTURE.md](ARCHITECTURE.md) (ADR 001–022) + [ARCHITEKTURA.md](ARCHITEKTURA.md) §Wzorce |
| Diagramów sekwencji (faktura, decyzja) | [ARCHITEKTURA.md](ARCHITEKTURA.md) §Sekwencje · [LOGIKA_BIZNESOWA.md](LOGIKA_BIZNESOWA.md) §4 |
| Drzewa katalogów i konwencji nazewniczych | [STRUKTURA_PROJEKTU.md](STRUKTURA_PROJEKTU.md) §2–3 |
| ERD, tabel, indeksów, przykładowych zapytań SQL | [STRUKTURA_PROJEKTU.md](STRUKTURA_PROJEKTU.md) §4–5 (+ §5.1 domeny: księgowania/raporty/decyzje/środki trwałe) |
| Migracji i seedowania DuckDB | [STRUKTURA_PROJEKTU.md](STRUKTURA_PROJEKTU.md) §6 |
| Endpointów API, rate limiting, kodów błędów | [API_REFERENCJA.md](API_REFERENCJA.md) §3–6 |
| Modułów, algorytmów, debugowania | [LOGIKA_BIZNESOWA.md](LOGIKA_BIZNESOWA.md) §2, §5–6 (+ §2.2 moduły V3) |
| UoR / IFRS / GAAP / KSeF / JPK / deklaracje / retencja | [ZGODNOSC_PRAWNA.md](ZGODNOSC_PRAWNA.md) §3–8 |
| Ścieżki audytu (odtworzenie decyzji) | [ZGODNOSC_PRAWNA.md](ZGODNOSC_PRAWNA.md) §7 |
| RBAC, workflow, centrum decyzji, integracji | [PODRECZNIK_UZYTKOWNIKA.md](PODRECZNIK_UZYTKOWNIKA.md) §3–9 |
| Statusów kampanii (GLM 5.2, V3) i certyfikacji | [KAMPANIA_GLM52_ETAPY_10_28.md](KAMPANIA_GLM52_ETAPY_10_28.md) · [KAMPANIA_V3_PROMPTY_P00_P68.md](KAMPANIA_V3_PROMPTY_P00_P68.md) |
| Kontraktów V3 (werdykt, invariants, temporalność…) | [V3_P03_KONTRAKT_WERDYKTU_KONTRAKT.md](V3_P03_KONTRAKT_WERDYKTU_KONTRAKT.md) i sąsiednie `V3_P*.md` |
| Metryk / MANIFEST / pokrycia | [../MANIFEST.md](../MANIFEST.md) · [../COVERAGE_REPORT.md](../COVERAGE_REPORT.md) |
| Planu strategicznego (fazy, S1–S24) | [UNIFIED_PLAN.md](UNIFIED_PLAN.md) + [../unified_plan_progress.yaml](../unified_plan_progress.yaml) |

---

## 4. Katalog dokumentów (alfabetycznie)

| Dokument | Zakres | Audytorium |
|---|---|---|
| [ANALIZA_STANU_OPA_JAKO_SYSTEM.md](ANALIZA_STANU_OPA_JAKO_SYSTEM.md) | analiza dojrzałości OPA jako system | architekci |
| [ARCHITEKTURA.md](ARCHITEKTURA.md) | C4, warstwy, wzorce, sekwencje, warstwa V3 (P67/P68) | architekci, developerzy |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Architecture Decision Records (ADR) | architekci |
| [AUDYT_KOMPLETNY_P24.md](AUDYT_KOMPLETNY_P24.md) | audyt kompletności (ETAP kampanii GLM 5.2) | QA |
| [COVERAGE_CANON.md](COVERAGE_CANON.md) | kanon pomiaru pokrycia | QA, compliance |
| [CONTROL_PLANE_RULE_LIFECYCLE.md](CONTROL_PLANE_RULE_LIFECYCLE.md) | cykl życia reguły (Control Plane) | developerzy |
| [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) | przewodnik developera modułu JDG | developerzy |
| [FAQ.md](FAQ.md) | najczęstsze pytania (8 kategorii) | wszyscy |
| [KALENDARZ_ZMIAN_PRAWNYCH.md](KALENDARZ_ZMIAN_PRAWNYCH.md) | nadchodzące nowelizacje | compliance |
| [KAMPANIA_GLM52_ETAPY_10_28.md](KAMPANIA_GLM52_ETAPY_10_28.md) | kampania GLM 5.2 (ETAP 06–28) | wszyscy |
| [KAMPANIA_V3_PROMPTY_P00_P68.md](KAMPANIA_V3_PROMPTY_P00_P68.md) | kampania V3: 69/69, dowody, mapa V4 | wszyscy |
| [KATALOG_NARZEDZI.md](KATALOG_NARZEDZI.md) | katalog narzędzi Python | developerzy, DevOps |
| [KATALOG_REGUL.md](KATALOG_REGUL.md) | katalog plików Rego i rule_id | developerzy, QA |
| [LEGAL_COVERAGE.md](LEGAL_COVERAGE.md) | pokrycie prawne A/B/C | compliance |
| [LEGAL_SOURCE_REGISTRY.md](LEGAL_SOURCE_REGISTRY.md) | rejestr źródeł prawnych (SHA-256) | compliance |
| [LEGAL_TWIN_TRACEABILITY.md](LEGAL_TWIN_TRACEABILITY.md) | łańcuch reguła ↔ artykuł ↔ werdykt | compliance, QA |
| [LOGIKA_BIZNESOWA.md](LOGIKA_BIZNESOWA.md) | moduły, algorytmy, błędy, debugowanie | developerzy |
| [MANIFEST_2_0.md](MANIFEST_2_0.md) | koncepcja manifestu 2.0 | QA |
| [OPA_JAKO_SYSTEM_P21.md](OPA_JAKO_SYSTEM_P21.md) | OPA jako system (inicjatywa) | architekci |
| [OPA_REGO_DEVELOPER_GUIDE.md](OPA_REGO_DEVELOPER_GUIDE.md) | standard pisania reguł Rego | developerzy |
| [PODRECZNIK_UZYTKOWNIKA.md](PODRECZNIK_UZYTKOWNIKA.md) | instrukcja „krok po kroku" | użytkownicy |
| [ROLE_MAPS.md](ROLE_MAPS.md) | mapy ról i uprawnień | wszyscy |
| [STRUKTURA_PROJEKTU.md](STRUKTURA_PROJEKTU.md) | drzewo, konwencje, ERD, tabele, migracje | developerzy, DevOps |
| [TESTY_REGO_CI_P23.md](TESTY_REGO_CI_P23.md) | testy Rego + CI/CD | QA, DevOps |
| [TOOLS_P65_GENERATED.md](TOOLS_P65_GENERATED.md) | narzędzia wygenerowane falą P65 | DevOps |
| [UNIFIED_PLAN.md](UNIFIED_PLAN.md) | zunifikowany plan wdrożenia v8 | zarząd, DevOps |
| [V3_BLOCKER_TRIAGE_MATRIX.md](V3_BLOCKER_TRIAGE_MATRIX.md) | triage blokerów V3 | zarządzanie |
| [V3_ID_CANON.md](V3_ID_CANON.md) | kanon identyfikatorów V3 | developerzy |
| [V3_P01..P11 _KONTRAKT.md](V3_P01_LEGAL_TWIN_KONTRAKT.md) | kontrakty rdzenia V3 | developerzy, architekci |
| [WIZJA_OPA_ENTERPRISE_V2.md](WIZJA_OPA_ENTERPRISE_V2.md) | wizja enterprise | zarząd |
| [ZGODNOSC_PRAWNA.md](ZGODNOSC_PRAWNA.md) | zgodność: UoR/IFRS/GAAP, KSeF, JPK, audyt, retencja | compliance |

> Dokumenty tematyczne domen — pełne mapowanie poniżej (§4.1–4.3).

### 4.1. Kontrakty i standardy V3 (12 kontraktów + standardy)

| Dokument | Zakres (kontrakt) |
|---|---|
| [V3_P01_LEGAL_TWIN_KONTRAKT.md](V3_P01_LEGAL_TWIN_KONTRAKT.md) | Legal Twin / LKG — podstawa prawna jako węzeł grafu |
| [V3_P02_ORKIESTRATOR_KONTRAKT.md](V3_P02_ORKIESTRATOR_KONTRAKT.md) | orkiestrator — kontrakt danych wejściowych/wyjściowych |
| [V3_P03_KONTRAKT_WERDYKTU_KONTRAKT.md](V3_P03_KONTRAKT_WERDYKTU_KONTRAKT.md) | kontrakt werdyktu (pola, klasa pewności) |
| [V3_P03_ERROR_TAXONOMY.md](V3_P03_ERROR_TAXONOMY.md) | taksonomia błędów (E-kody) |
| [V3_P04_INVARIANTY_KONTRAKT.md](V3_P04_INVARIANTY_KONTRAKT.md) | niezmienniki runtime (INV) |
| [V3_P05_TEMPORALNOSC_KONTRAKT.md](V3_P05_TEMPORALNOSC_KONTRAKT.md) | temporalność (valid_from/valid_to, epoki) |
| [V3_P06_PARAMETRY_DANE_KONTRAKT.md](V3_P06_PARAMETRY_DANE_KONTRAKT.md) | parametry jako dane (ADR-002) |
| [V3_P07_RULE_LIFECYCLE_KONTRAKT.md](V3_P07_RULE_LIFECYCLE_KONTRAKT.md) | cykl życia reguły (DRAFT→ACTIVE…) |
| [V3_P08_LAW_RADAR_KONTRAKT.md](V3_P08_LAW_RADAR_KONTRAKT.md) | Law Radar — monitoring legislacji |
| [V3_P09_DECLARATIVE_CHANGE_KONTRAKT.md](V3_P09_DECLARATIVE_CHANGE_KONTRAKT.md) | zmiana deklaratywna (bez edycji kodu) |
| [V3_P10_GOLDEN_ORACLE_KONTRAKT.md](V3_P10_GOLDEN_ORACLE_KONTRAKT.md) | Golden Oracle — ewaluacja różnicowa (UVR=0) |
| [V3_P11_DECISION_CERTIFICATE_KONTRAKT.md](V3_P11_DECISION_CERTIFICATE_KONTRAKT.md) | Decision Certificate — pieczęć F4 |
| [V3_P46_PARAMETER_ANCHORS.md](V3_P46_PARAMETER_ANCHORS.md) | kotwice parametrów |
| [V3_P47_CITATION_STYLE_GUIDE.md](V3_P47_CITATION_STYLE_GUIDE.md) | styl cytowania podstaw prawnych |
| [DOC_STANDARD_P60.md](DOC_STANDARD_P60.md) | standard: „dokument mówi prawdę o kodzie” (front-matter, verify_cmd) |

### 4.2. Fundamenty rdzenia (ETAP 04–06)

| Dokument | Zakres |
|---|---|
| [CONTROL_PLANE_RULE_LIFECYCLE.md](CONTROL_PLANE_RULE_LIFECYCLE.md) | Control Plane cyklu życia (ETAP 04) |
| [ORCHESTRATOR_DATA_CONTRACT.md](ORCHESTRATOR_DATA_CONTRACT.md) | kontrakt danych orkiestratora (ETAP 05) |
| [DECISION_CORE_P02.md](DECISION_CORE_P02.md) | rdzeń decyzyjny |
| [CORE_GUARDS_TEMPORAL_THRESHOLDS.md](CORE_GUARDS_TEMPORAL_THRESHOLDS.md) | 42 niezmienniki + progi temporalne (ETAP 06, INV-001..042) |
| [RULE_LIFECYCLE.md](RULE_LIFECYCLE.md) | model stanów reguły |

### 4.3. Dokumenty domenowe (P03–P24) i audyty (R02–R04)

| Domena | Dokumenty |
|---|---|
| VAT | [VAT_MACRO_P03.md](VAT_MACRO_P03.md) · [VAT_MICRO_P04.md](VAT_MICRO_P04.md) · audyt: [VAT_AUDYT_R03.md](VAT_AUDYT_R03.md) |
| PIT | [PIT_MACRO_P05.md](PIT_MACRO_P05.md) · [PIT_MICRO_P06.md](PIT_MICRO_P06.md) · audyt: [PIT_AUDYT_R04.md](PIT_AUDYT_R04.md) |
| ZUS | [ZUS_MACRO_P07.md](ZUS_MACRO_P07.md) · [ZUS_MICRO_P08.md](ZUS_MICRO_P08.md) |
| Księgowość | [KSIEGOWOSC_PKPIR_UOR_P09.md](KSIEGOWOSC_PKPIR_UOR_P09.md) · [KKS_P10.md](KKS_P10.md) · [ORDYNACJA_PODATKOWA_P11.md](ORDYNACJA_PODATKOWA_P11.md) |
| Cross-border, PCC, ryczałt | [CROSSBORDER_P12.md](CROSSBORDER_P12.md) · [RYCZALT_CYKL_ZYCIE_P13.md](RYCZALT_CYKL_ZYCIE_P13.md) · [PCC_LOKALNE_AKCYZA_P14.md](PCC_LOKALNE_AKCYZA_P14.md) |
| BDO, RODO/AML, HR | [SRODOWISKO_BDO_P15.md](SRODOWISKO_BDO_P15.md) · [RODO_AML_BEZPIECZENSTWO_P16.md](RODO_AML_BEZPIECZENSTWO_P16.md) · [HR_SWIADCZENIA_P19.md](HR_SWIADCZENIA_P19.md) |
| KSeF/JPK, automatyzacja, Neural Mesh | [KSEF_JPK_EDEKLARACJE_P17.md](KSEF_JPK_EDEKLARACJE_P17.md) · [AUTOMATYZACJA_KSIEGOWOSCI_P18.md](AUTOMATYZACJA_KSIEGOWOSCI_P18.md) · [NEURAL_MESH_INNOWACJE_P20.md](NEURAL_MESH_INNOWACJE_P20.md) |
| Narzędzia/testy | [NARZEDZIA_WALIDACJI_P22.md](NARZEDZIA_WALIDACJI_P22.md) · [TESTY_REGO_CI_P23.md](TESTY_REGO_CI_P23.md) |
| Audyty prawne | [AUDYT_PODSTAW_PRAWNYCH.md](AUDYT_PODSTAW_PRAWNYCH.md) · [P00_REMEDIACJA_PODSTAW_PRAWNYCH.md](P00_REMEDIACJA_PODSTAW_PRAWNYCH.md) · [PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md](PRAWA_PRZEDSIEBIORCOW_AUDYT_R02.md) |
| Raporty pokrycia | [LEGAL_COVERAGE_GAP_RAPORT.md](LEGAL_COVERAGE_GAP_RAPORT.md) · [LEGAL_TWIN_RAPORT.md](LEGAL_TWIN_RAPORT.md) |

### 4.4. Pozostałe (referencje, generatory, wizje)

| Dokument | Zakres |
|---|---|
| [Bbb.md](Bbb.md) | **kompletna lista aktów prawnych** (ujednolicone źródło, uzupełnia LEGAL_REFERENCE_ACTS) |
| [LEGAL_REFERENCE_ACTS.md](LEGAL_REFERENCE_ACTS.md) | referencje aktów z per-regułowym mapowaniem |
| [SLOWNIK_REFERENCJI_PRAWNYCH.md](SLOWNIK_REFERENCJI_PRAWNYCH.md) | słownik referencji prawnych |
| [ZGODNOSC_DOKUMENTY_KSIEGOWE.md](ZGODNOSC_DOKUMENTY_KSIEGOWE.md) | zgodność dokumentów księgowych |
| [ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md](ARCHITEKTURA_OPA_ENTERPRISE_TARGET.md) | architektura docelowa (target state) |
| [WIZJA_OPA_ENTERPRISE_V2.md](WIZJA_OPA_ENTERPRISE_V2.md) | wizja enterprise v2 |
| [MANIFEST_2_0.md](MANIFEST_2_0.md) | manifest 2.0 |
| [PEWNOSC_DASHBOARD.md](PEWNOSC_DASHBOARD.md) | dashboard pewności decyzji |
| [ROLE_MAPS.md](ROLE_MAPS.md) | mapy ról i uprawnień |
| [INWENTARYZACJA_PLIKOW.md](INWENTARYZACJA_PLIKOW.md) | inwentaryzacja plików JDG + policies |
| [KALENDARZ_ZMIAN_PRAWNYCH.md](KALENDARZ_ZMIAN_PRAWNYCH.md) | kalendarz nowelizacji |
| [COVERAGE_CANON.md](COVERAGE_CANON.md) | kanon pomiaru pokrycia |
| [TOOLS_P65_GENERATED.md](TOOLS_P65_GENERATED.md) | katalog narzędzi fali P65 |
| [api.md](api.md) | API — dokumentacja **auto-generowana** (Innowacja 6; źródłem jest [API_REFERENCJA.md](API_REFERENCJA.md)) |
| [KALENDARZ_ZBIORCZY](KAMPANIA_V3_PROMPTY_P00_P68.md) | zob. kampania V3 §4 (P25) |

---

## 5. Źródła prawdy (kto wygrywa przy rozbieżności)

| Temat | Źródło prawdy |
|---|---|
| Liczba reguł / plików | `MANIFEST.md` (auto) — metoda: bloki `matched:true`; stan dysku: `find rules -name "*.rego"` |
| Status kampanii V3 | `bundles/v3_campaign_ledger.json` (`python tools/v3_campaign_ledger.py`) |
| Status kampanii GLM 5.2 | `bundles/*audit_state.json` (22 pliki) |
| Certyfikacja | `bundles/final_certification_v4_evidence.json` (P68) + polityka odnowienia §7.1 kampanii V3 |
| Progi/stawki | `rules/thresholds_jdg.rego` + seed `migrations/001` (ADR-002 — zero hardcode) |
| Kontrakt API | `api/openapi.yaml` |

---

*INDEX v1.0 (2026-09-19). Zasada: dokument bez wpisu w tym indeksie = kandydat do przeglądu; wpis bez dokumentu = bug — zgłoś issue.*
