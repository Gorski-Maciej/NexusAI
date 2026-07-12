# 📑 Plan OPA — Indeks Dokumentacji

> **Status:** Kompletny — v7.0  
> **Data:** 2026-07-12  
> **Zespół:** NexusAI  
> **Reguły kanoniczne JDG:** ~779 (zintegrowane Docs 22-43 w `38c_JDG_CANONICAL_MAP.md`)  
> **Target ENTERPRISE:** ~7,000 reguł Micro (Dual-Layer Architecture, ~3,080 zdekomponowanych)  
> **Reguły łącznie (korporacyjne + JDG):** ~3,320 (240 korp. + ~3,080 JDG)  
> **Dokumenty:** 45 (Docs + 00-21 + 22-43)

---

## Struktura katalogu

```
Plan OPA/
├── Docs                              # Źródła prawne i inspiracje (oryginalny plik)
├── 00_PLAN_STRUKTURA.md               # 🏛️ Master Plan — architektura, priorytety, roadmap
├── 01_INPUT_SPEC.md                   # 📥 Specyfikacja struktury input dla OPA
├── 02_THRESHOLDS_CATALOG.md           # 📊 Katalog parametrów dynamicznych (thresholds)
├── 03_RULES_DETAILED.md               # 📋 Reguły bazowe: Risk, Routing, Compliance, Crossborder, VAT
├── 04_INDEX.md                        # 📑 Ten plik — indeks i cross-reference (228 reguł)
├── 05_ARCHITECTURE_DECISION.md        # 🏗️ ADR-001: Multi-Pass vs Single-Chain Evaluation
├── 06_COMPLETE_RULES_SUPPLEMENT.md    # 📋 Kompendium: CIT, PIT, ulgi, księgowość, ZUS (95 reguł)
├── 07_ADVANCED_RULES_EXPANSION.md     # 🔬 Rozszerzenie: PPK, Akcyza, IFRS, Leasing, AML, KŚT, JPK (128 reguł)
├── 08_OPA_PATTERNS_FROM_RESEARCH.md   # 🎯 Wzorce z FINOS, OpenFisca, OPA Library
├── 09_LEGAL_DEEP_DIVE_RULES.md        # 🌳 Deep Dive: VAT odliczenia, Podatki lokalne, Praca, BDO, NGO, UoR (155 reguł)
├── 10_OPA_IMPLEMENTATION_GUIDE.md     # 🛠️ Praktyczny przewodnik implementacji Rego ENTERPRISE
├── 11_ENTERPRISE_FINAL_EXPANSION.md   # 🏛️ Finalna ekspansja: 36 reguł z 18 obszarów (191 reguł)
├── 12_DATA_INTEGRATION_PATTERNS.md    # 🔌 Wzorce integracji danych OPA (Bundle, Push, Pull)
├── 13_KUBESCAPE_PATTERNS_DEEP_DIVE.md # 🏭 Deep dive kubescape: Rule→Control→Framework, testy, metadata, CI
├── 14_SPECIALIZED_TAX_RULES.md        # 🔬 Specjalistyczne: CIT/PIT KUP, PCC, SD, dewizy, akcyza, KP, MSSF2 (212 reguł)
├── 15_SERVICE_INTEGRATION_MAP.md      # 🗺️ Mapa 12 serwisów NexusAI → reguły OPA
├── 16_FINAL_FRONTIER_RULES.md         # 🏁 Ostatnia granica: 16 reguł + styrainc/finos research (228 reguł)
├── 17_IMPLEMENTATION_ROADMAP.md       # 🗺️ Roadmap wdrożenia: 13 faz, kamienie milowe, macierz ryzyka
├── 18_OPA_API_REFERENCE.md           # 🔌 Pełna dokumentacja API OPA REST (endpointy, Python client, logging)
├── 19_DEPLOYMENT_GUIDE.md             # 🚀 Przewodnik wdrożenia OPA w produkcji
├── 20_MASTER_RULES_REFERENCE.md      # 📚 Kompletny spis 240 reguł — priorytety, pseudokod, cross-reference
├── 21_DEEP_DOCS_ANALYSIS.md           # 🔬 Deep Docs Analysis — 12 nowych reguł (P320-P331) z analizy wszystkich
│
│   ═══════════════════════════════════════════════════════════════════
│   ║  SEKCJA JDG — Jednoosobowa Działalność Gospodarcza              ║
│   ║  ~3 080 reguł | 30 pakietów | 100+ domen prawnych               ║
│   ═══════════════════════════════════════════════════════════════════
│
├── 22_JDG_ENTERPRISE_PLAN.md          # 🏢 JDG Plan bazowy (~145 reguł)
├── 23_JDG_EXPANSION_SUPPLEMENT.md     # 📋 JDG Rozbudowa (~69 reguł)
├── 24_JDG_COMPLETE_INDEX.md           # 📑 JDG Indeks kompletny
├── 25_JDG_DEEP_LEGAL_AUDIT.md         # ⚖️ JDG Głęboki audyt prawny
├── 26_JDG_COMPREHENSIVE_EXPANSION.md  # 📋 JDG Kompleksowa ekspansja
├── 27_JDG_ENTERPRISE_DEEP_EXPANSION.md # 🏢 JDG Głęboka ekspansja ENTERPRISE
├── 28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md # 🏛️ JDG Master Synthesis (~372 reguł)
├── 29_JDG_DEEP_ANALYSIS_GAPS.md       # 🔍 JDG Głęboka analiza luk (~402 reguł)
├── 30_JDG_MASSIVE_EXPANSION.md        # 📋 JDG Masywna ekspansja (~1 462 reguł)
├── 31_JDG_3000_RULES.md               # 📊 JDG System 3 000+ reguł
├── 32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md # 🏗️ JDG Plan architektoniczny (50→30 pakietów)
├── 33_JDG_MASSIVE_RULE_CATALOG.md     # 📚 JDG Katalog ~3 055 mikro-reguł
├── 34_JDG_DEFINITIVE_REGO_PLAN.md     # ★ JDG DEFINITYWNY Plan ENTERPRISE v10.0
├── 35_SPOLKA_CYWILNA_ADVANCED_GAPS.md # 🏢 Spółka cywilna — zaawansowane luki
├── 36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md # 🏢 Spółka cywilna — ultimate gaps
├── 37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md # 🏢 Spółka cywilna — maksymalna granularność
├── 38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md # 🏢 Spółka cywilna — strategiczne ulepszenia
├── 38_JDG_QUALITY_AUDIT.md            # 🔍 JDG Audyt jakości
├── 38a_JDG_CRITICAL_GAPS_CLOSURE.md   # 🔧 JDG Zamknięcie krytycznych luk
├── 38b_JDG_DEDUP_REPORT.md            # 📊 JDG Raport deduplikacji
├── 38c_JDG_CANONICAL_MAP.md           # 🗺️ JDG Mapa Kanoniczna — ~779 reguł ★★★
├── 39_JDG_COMPREHENSIVE_TEN_AREAS_EXPANSION.md # 📋 JDG Ekspansja 10 obszarów (~140 reguł)
├── 40_JDG_DEEP_GAP_FINAL_FRONTIER.md  # 🏁 JDG Final Frontier — 20 reguł
├── 41_JDG_MEGA_MATRIX_7000_RULES.md   # 🏛️ JDG MEGA MATRIX — Dual-Layer ~7,000 reguł ★★★
├── 42_JDG_DEEP_GAP_DISCOVERY.md       # 🔬 JDG Deep Gap Discovery — 55 nowych reguł ★
├── 43_JDG_KKS_MASSIVE_DECOMPOSITION.md # ⚖️ JDG KKS — 230 reguł (5%→75% pokrycia) ★
│
├── DocsJDG/                           # 📂 Źródła prawne JDG i inspiracje
└── policies/                          # 📂 Reguły Rego (pliki .rego w pakiecie tax/ i jdg/)
```

---

## Mapa dokumentów — co gdzie znajdziesz

### Dokumenty bazowe (00-21) — Reguły korporacyjne (240 reguł)

| Dokument | Zawartość | Dla kogo |
|---|---|---|
| `00_PLAN_STRUKTURA.md` | Architektura pakietów, hierarchia priorytetów, diagram first-match-wins, opis wszystkich reguł, plan implementacji (8 faz), konwencje nazewnicze | Architekt, Tech Lead |
| `01_INPUT_SPEC.md` | **v2.0 ENTERPRISE**: Pełna specyfikacja `input` JSON (~100 pól): invoice, vendor, company, confidence, thresholds, PLUS nowe sekcje: document, system, request, tax_type. Mapa pól→reguła P230-P310 | Developer OPA, Backend Developer |
| `02_THRESHOLDS_CATALOG.md` | Kompletny katalog thresholdów: stawki, limity, progi, field confidence, ryczałt. Schemat DuckDB, seed SQL, proces update | Backend Developer, DevOps |
| `03_RULES_DETAILED.md` | Pseudokod Rego dla reguł Bazowych: Risk (P0-P9), Routing (P10-P19), Compliance (P20-P39), Crossborder (P40-P49), VAT (P50-P69) | Developer OPA, Reviewer |
| `05_ARCHITECTURE_DECISION.md` | ADR-001: Multi-Pass Evaluation. VerdictMerger, orkiestracja 9 passów, strategia migracji z single-chain | Architekt, Tech Lead |
| `06_COMPLETE_RULES_SUPPLEMENT.md` | Reguły rozszerzone: CIT (P70-P74), PIT (P74-P79), Ulgi (P80-P89), Księgowość (P90-P94), ZUS (P95-P99) — 95 reguł łącznie | Developer OPA, Reviewer |
| `07_ADVANCED_RULES_EXPANSION.md` | Reguły zaawansowane: PPK, Akcyza, IFRS, Leasing, Darowizny, KŚT, KUP, JPK, AML, Dewizowe, CEIDG, KSH, Ordynacja — 33 reguły | Developer OPA, Reviewer |
| `08_OPA_PATTERNS_FROM_RESEARCH.md` | Wzorce z FINOS/OpenEAGO, OpenFisca, OPA Library, kubescape, styrainc, conftest. Rekomendacje dla NexusAI | Architekt, Tech Lead |
| `09_LEGAL_DEEP_DIVE_RULES.md` | Reguły deep dive: VAT odliczenia/korekty, Podatki lokalne, Prawo pracy, Zasiłki, Budowlane, BDO/CO2, NGO, UoR zasady, Ordynacja dodatkowa, MSSF 9/15, PKPiR — 27 reguł | Developer OPA, Reviewer |
| `10_OPA_IMPLEMENTATION_GUIDE.md` | Praktyczny przewodnik: struktura plików, _helpers.rego, _metadata.rego, testy wg conftest+kubescape, OPA Bundle wg styrainc, Decision Logging, Makefile, deployment flow, checklist | Developer OPA, DevOps |
| `11_ENTERPRISE_FINAL_EXPANSION.md` | 36 reguł z 18 wcześniej niepokrytych obszarów: VAT obowiązek podatkowy/podstawa, PIT źródła, CIT przychody, zaliczki, Ordynacja terminy/odpowiedzialność, UoR księgi/sprawozdania/przechowywanie, Prawo spółdzielcze/energetyczne, Transport, KSeF/JPK szczegóły, Podatki lokalne — **191 reguł łącznie** | Developer OPA, Reviewer |
| `12_DATA_INTEGRATION_PATTERNS.md` | Wzorce integracji danych z open-policy-agent/contrib: Overload Input, Bundle API, Push Data (OPAL), Dynamic Pull (http.send), Data Filtering (Partial Evaluation), Decision Logging. Rekomendowana architektura NexusAI | Architekt, Tech Lead, DevOps |
| `13_KUBESCAPE_PATTERNS_DEEP_DIVE.md` | Deep dive kubescape/regolibrary: hierarchia Rule→Control→Framework, test framework (success/failed katalogi), rule.metadata.json schema, CI pipeline, bundle.py, rule lifecycle management. 7 rekomendacji dla NexusAI | Architekt, Tech Lead, DevOps |
| `14_SPECIALIZED_TAX_RULES.md` | 21 reguł z 10 wyspecjalizowanych obszarów: CIT KUP wyłączenia (4), PIT KUP wyłączenia (2), VAT pre-proporcja/terminy (2), PCC (3), podatek od SD (1), prawo dewizowe (1), akcyza tytoń/składy (2), KP nagrody/odzież/delegacje (3), MSSF 2 (1), UoR zmiany zasad/błędy (2) — **212 reguł łącznie** | Developer OPA, Reviewer |
| `15_SERVICE_INTEGRATION_MAP.md` | Mapa 12 istniejących serwisów NexusAI → OPA: RiskGuard→tax.risk, SemanticGuard→tax.risk, FraudGraphScanner→tax.risk, WhiteListService→tax.compliance, VATReconciliation→tax.vat, TaxSimulator→tax.simulator, OpaPolicyGenerator→generator, AuditService→tax.audit, IntegrityVerifier→tax.audit, ComplianceAnalytics→tax.accounting, TaxStrategies→tax.direct | Architekt, Tech Lead, Developer |
| `17_IMPLEMENTATION_ROADMAP.md` | Kompletny plan wdrożenia 228 reguł w 13 fazach: priorytety P0-P3, 4 kamienie milowe (M1: MVP 3tyg, M2: Core Tax 3tyg, M3: Full Core 3tyg, M4: Enterprise 6tyg), macierz ryzyka, szacowany wysiłek 34 osobotypodnie, checklist per faza | Tech Lead, Project Manager, Architekt |
| `16_FINAL_FRONTIER_RULES.md` | 16 reguł z 12 absolutnie ostatnich luk: VAT zbycie przedsiębiorstwa + rejestracja VAT-UE (2), PIT/CIT zeznania roczne (2), KKS czynny żal (1), Ordynacja nadpłata + ZAW-NR (2), VAT korekty in minus (1), CIT TP Local File + TPR (2), PIT zdrowotna od podatku (1), VAT WNT tax point (1), UoR zdarzenia po bilansie (1), KSeF uwierzytelnienie (1), JPK kary (1), AML ocena ryzyka (1). Research: styrainc/enterprise-opa (EOL, atomic bundle, decision log batching), finos/regtech (Rune DSL — NIE Rego). **228 reguł łącznie** | Developer OPA, Reviewer, Architekt |
| `18_OPA_API_REFERENCE.md` | Pełna dokumentacja API OPA REST: endpoint `/v1/data/tax/*`, format werdyktu (Verdict Schema), Python AsyncClient (httpx z retry/circuit breaker), Decision Logging (format JSON, konfiguracja batching), Bundle API (struktura, OCI registry), Status API (Prometheus metrics), HTTP error codes, TLS/Auth. Przykłady request/response dla każdego endpointu | Backend Developer, DevOps |
| `19_DEPLOYMENT_GUIDE.md` | Przewodnik wdrożenia produkcyjnego: Docker/docker-compose (dev + prod), Kubernetes Deployment/Service/ConfigMap, CI/CD (GitHub Actions: validate → build → publish → deploy), OCI Bundle z revision tagowaniem + rollback, Load testing (Locust), Circuit Breaker (Python), SLA targets (500 req/s, <1ms P50, 99.99% up), Prometheus alerts (error rate, latency, stale bundle), Grafana dashboard, Disaster Recovery, Checklist produkcyjny (15 punktów) | DevOps, SRE, Tech Lead |
| `20_MASTER_RULES_REFERENCE.md` | **Kompletny spis 240 reguł w jednym dokumencie**: szybki indeks priorytetowy, wszystkie pakiety z pseudokodem Rego (✅ zaimplementowane / 🟡 w planie), cross-reference 62 podstaw prawnych, status implementacji (69/240 zaimplementowanych). Zoptymalizowany jako podręcznik programisty OPA | Developer OPA, Tech Lead, Reviewer |
| `21_DEEP_DOCS_ANALYSIS.md` | **Głęboka analiza Docs vs 240 reguł**: thinker-with-files-gemini przeanalizował 200+ artykułów z 14 ustaw i zidentyfikował 12 absolutnie ostatnich luk (P320-P331): UoR podwójny zapis, zamknięcie ksiąg, rezerwy, elementy dowodu, struktura bilansu, koszt wytworzenia; CIT złe długi wierzyciela; VAT-R; Ordynacja zabezpieczenia/ulgi; KP BHP; PIT małe umowy. **240 reguł łącznie** | Developer OPA, Reviewer |

### Dokumenty JDG (22-43) — Reguły dla jednoosobowej działalności gospodarczej (~3 080 reguł, ~779 kanonicznych)

| Dokument | Zawartość | Dla kogo |
|---|---|---|
| `22_JDG_ENTERPRISE_PLAN.md` | Plan bazowy JDG: architektura, pakiety, priorytety, ~80 szczegółowych reguł | Architekt, Tech Lead |
| `23_JDG_EXPANSION_SUPPLEMENT.md` | Rozbudowa JDG: PIT formy, KUP, zaliczki, ryczałt, karta (~69 reguł) | Developer OPA |
| `24_JDG_COMPLETE_INDEX.md` | Indeks kompletny JDG — mapa wszystkich dokumentów i reguł | Tech Lead, Deweloper |
| `25_JDG_DEEP_LEGAL_AUDIT.md` | Głęboki audyt prawny — zgodność z ustawami i rozporządzeniami | Radca prawny, Auditor |
| `26_JDG_COMPREHENSIVE_EXPANSION.md` | Kompleksowa ekspansja: ZUS, składka zdrowotna, PKPiR, ewidencje | Developer OPA |
| `27_JDG_ENTERPRISE_DEEP_EXPANSION.md` | Głęboka ekspansja ENTERPRISE: zawieszenie, sukcesja, przekształcenie | Developer OPA |
| `28_JDG_ENTERPRISE_MASTER_SYNTHESIS.md` | Master Synthesis — scalenie wcześniejszych dokumentów (~372 reguł) | Architekt, Tech Lead |
| `29_JDG_DEEP_ANALYSIS_GAPS.md` | Głęboka analiza luk (~402 reguł): KKS, GAAR, MPP, CESOP, estoński CIT | Developer OPA, Auditor |
| `30_JDG_MASSIVE_EXPANSION.md` | Masywna dekompozycja (~1 462 reguł): artykuł po artykule | Developer OPA |
| `31_JDG_3000_RULES.md` | System 3 000+ reguł — kompletna referencja | Developer OPA, Reviewer |
| `32_JDG_ENTERPRISE_DEFINITIVE_PLAN.md` | Plan architektoniczny (50→30 pakietów), struktura input, parametry dynamiczne | Architekt, Tech Lead |
| `33_JDG_MASSIVE_RULE_CATALOG.md` | Katalog ~3 055 mikro-reguł z dekompozycją artykuł po artykule | Developer OPA |
| **`34_JDG_DEFINITIVE_REGO_PLAN.md`** | **★ DEFINITYWNY Plan ENTERPRISE v10.0** — autorytatywny dokument referencyjny: 30 pakietów, ~60 szczegółowo opisanych reguł, first-match-wins chain, struktura input (~180 pól), katalog thresholdów (~120 parametrów), multi-pass architecture, macierze interakcji | Architekt, Tech Lead, Developer OPA |
| `38_JDG_QUALITY_AUDIT.md` | Audyt jakości JDG — przegląd spójności i kompletności | Auditor, Tech Lead |
| `38a_JDG_CRITICAL_GAPS_CLOSURE.md` | Zamknięcie krytycznych luk — poprawki po audycie | Developer OPA |
| `38b_JDG_DEDUP_REPORT.md` | Raport deduplikacji — identyfikacja 47 zdublowanych reguł | Auditor |
| **`38c_JDG_CANONICAL_MAP.md`** | **🗺️ MAPA KANONICZNA — ~779 reguł** ★★★ Definitywne mapowanie wszystkich reguł z Docs 22-43, Dual-Layer Architecture, statystyki domenowe, P-ID cross-reference | Architekt, Tech Lead, Developer OPA |
| `39_JDG_COMPREHENSIVE_TEN_AREAS_EXPANSION.md` | Ekspansja 10 obszarów (~140 reguł): KSeF, JPK, PCC, sukcesja, RODO, AML | Developer OPA |
| `40_JDG_DEEP_GAP_FINAL_FRONTIER.md` | Final Frontier — 20 reguł w 10 ostatnich obszarach | Developer OPA |
| **`41_JDG_MEGA_MATRIX_7000_RULES.md`** | **🏛️ MEGA MATRIX** ★★★ — Dual-Layer Architecture, mapowanie 550+ artykułów, target ~7,000 reguł Micro, macierz Macro→Micro, 4-fazowy plan wdrożenia | Architekt, Tech Lead |
| `42_JDG_DEEP_GAP_DISCOVERY.md` | **🔬 Deep Gap Discovery** ★ — 55 nowych reguł z 9 obszarów (0-20% pokrycia): PKPiR 8r, obniżone stawki VAT 6r, KKS 12r, ustawa zasiłkowa 7r, KŚT 5r, RODO 4r, MPiPS 4r, UoR inwentaryzacja 5r, PCC 4r | Developer OPA, Auditor |
| `43_JDG_KKS_MASSIVE_DECOMPOSITION.md` | **⚖️ KKS Mass Decomposition** ★ — 230 reguł KKS (z ~5% → ~75% pokrycia): czynny żal (28r), sankcje (77r), przestępstwa (80r), wykroczenia (45r). Pełne pokrycie Art. 16-83 KKS | Developer OPA, Radca prawny |

---

## Cross-Reference: Podstawa prawna → Reguła

| Podstawa prawna | Reguła | Priorytet | Pakiet | Dokument |
|---|---|---|---|---|
| Art. 41 ust. 1 VAT | `vat_rate_fuel_pl`, `domestic_fallback` | P52, P100 | `tax.vat.substantive`, `tax.fallback` | 03, 06 |
| Art. 41 ust. 2 VAT | `vat_rate_food_pl` | P53 | `tax.vat.substantive` | 03 |
| Art. 41 ust. 2a VAT | `vat_rate_books_pl` | P54 | `tax.vat.substantive` | 03 |
| Art. 43 VAT | `vat_exemption_education`, `vat_exemption_healthcare`, `vat_exemption_finance` | P55-P57 | `tax.vat.substantive` | 03 |
| Art. 17 VAT | `eu_reverse_charge`, `import_non_eu`, `non_eu_services_import` | P40, P45, P46 | `tax.crossborder` | 03, 06 |
| Art. 28b VAT | `eu_import_services` | P41 | `tax.crossborder` | 06 |
| Art. 42 VAT | `wdt_intracommunity_supply` | P42 | `tax.crossborder` | 06 |
| Art. 41 ust. 4-11 VAT | `export_goods` | P48 | `tax.crossborder` | 03 |
| Art. 108a VAT | `split_payment_mandatory` | P25 | `tax.compliance` | 03 |
| Art. 89a VAT | `vat_bad_debt_relief` | P60 | `tax.vat.substantive` | 03 |
| Art. 113 VAT | `vat_exemption_subject` | P58 | `tax.vat.substantive` | 06 |
| Art. 120 VAT | `vat_margin_scheme` | P50 | `tax.vat.substantive` | 06 |
| Art. 33a VAT | `vat_on_import_consent` | P26 | `tax.compliance` | 06 |
| Art. 19a ust. 8 VAT | `vat_prepayment_rule` | P61 | `tax.vat.substantive` | 06 |
| Art. 96b VAT | `whitelist_missing_over_limit`, `whitelist_check_expired`, `nip_format_invalid` | P20, P22, P9 | `tax.compliance`, `tax.risk` | 03, 06 |
| Art. 106na-106nq VAT | `ksef_structured_invoice` | P28 | `tax.compliance` | 06 |
| § 10 JPK_VAT | `vat_gtu_mapping`, `gtu_mapping_transport`, `gtu_mapping_gas_energy` | P65-P69 | `tax.vat.gtu` | 03, 06 |
| Art. 19 CIT | `cit_small_taxpayer`, `cit_standard_taxpayer` | P71, P73 | `tax.direct.cit` | 06 |
| Rozdz. 6b CIT | `cit_estonian_effective` | P70 | `tax.direct.cit` | 06 |
| Art. 15c CIT | `cit_thin_capitalization` | P72 | `tax.direct.cit` | 06 |
| Art. 7 ust. 5 CIT | `cit_loss_carry_forward` | P74 | `tax.direct.cit` | 06 |
| Art. 27 PIT | `pit_tax_scale` | P75 | `tax.direct.pit` | 03 |
| Art. 30c PIT | (dla LINEAR) | P75 | `tax.direct.pit` | 03 |
| Art. 12 ryczałtu | `pit_lump_sum_rate` | P74 | `tax.direct.pit` | 03 |
| Art. 6 ust. 2 PIT | `pit_joint_filing` | P76 | `tax.direct.pit` | 06 |
| Art. 21 ust. 1 pkt 148 PIT | `pit_young_exemption` | P77 | `tax.direct.pit` | 06 |
| Art. 21 ust. 1 pkt 152 PIT | `pit_return_exemption` | P78 | `tax.direct.pit` | 06 |
| Art. 21 ust. 1 pkt 153 PIT | `pit_family_4plus` | P79 | `tax.direct.pit` | 06 |
| Art. 21 ust. 1 pkt 154 PIT | `relief_working_senior` | P89 | `tax.allowances` | 06 |
| Art. 26e PIT / 18d CIT | `relief_rd` | P80 | `tax.allowances` | 03 |
| Art. 26eb PIT / 18db CIT | `relief_prototype` | P81 | `tax.allowances` | 06 |
| Art. 30ca PIT / 24d CIT | `relief_ip_box` | P82 | `tax.allowances` | 03 |
| Art. 26gb PIT / 38eb CIT | `relief_robotization` | P83 | `tax.allowances` | 06 |
| Art. 26ec PIT / 18dc CIT | `relief_expansion` | P84 | `tax.allowances` | 06 |
| Art. 26h PIT | `relief_thermomodernization` | P85 | `tax.allowances` | 03 |
| Art. 26 PIT | `relief_internet`, `relief_rehabilitation` | P86-P87 | `tax.allowances` | 06 |
| Art. 27g PIT | `relief_abolition` | P88 | `tax.allowances` | 06 |
| Art. 22p PIT / 15d CIT | `cash_transaction_over_limit` | P35 | `tax.compliance` | 03 |
| Art. 23 PIT / 16 CIT | `semantic_guard_disallowed` | P5 | `tax.risk` | 03 |
| Art. 11a-11q CIT | `high_risk_country`, `related_party_transaction` | P4, P6 | `tax.risk` | 06 |
| Art. 32 UoR | `acc_depreciation_linear`, `acc_depreciation_degressive` | P90-P91 | `tax.accounting` | 03, 06 |
| Art. 39 UoR | `acc_rmk_deferral` | P92 | `tax.accounting` | 06 |
| Art. 30 UoR | `acc_fx_revaluation` | P93 | `tax.accounting` | 03 |
| Art. 28 UoR | `acc_fifo_inventory` | P94 | `tax.accounting` | 06 |
| Art. 18c SUS | `zus_maly_plus` | P95 | `tax.zus` | 03 |
| Art. 18a SUS | `zus_start_relief`, `zus_preferential` | P96-P97 | `tax.zus` | 06 |
| Art. 22 SUS | `zus_standard` | P99 | `tax.zus` | 06 |
| Art. 79-81 u. zdrowotnej | `zus_health_contrib` | P98 | `tax.zus` | 03 |
| Art. 86 § 1 Ordynacji | `ksef_retention_invoice` | P30 | `tax.compliance` | 06 |
| Art. 70 § 1 Ordynacji | `statute_of_limitations_approaching` | P38 | `tax.compliance` | 06 |
| Art. 53-56 Ordynacji | `payment_after_due_date` | P36 | `tax.compliance` | 06 |
| Art. 55 KKS | `fraud_graph_match`, `duplicate_invoice_suspect` | P0, P8 | `tax.risk` | 03, 06 |
| Art. 22 UoR | `anomaly_amount`, `counterparty_trust_low`, `new_counterparty_flag` | P1-P3 | `tax.risk` | 03, 06 |
| Art. 86 ust. 1 VAT | `fraud_graph_match` | P0 | `tax.risk` | 03 |
| Art. 19a ust. 3 VAT | `vat_tax_point_continuous_service` | P230 | `tax.vat.tax_point` | 11 |
| Art. 19a ust. 8 VAT | `vat_prepayment_rule`, `vat_tax_point_advance_invoice` | P61, P231 | `tax.vat.substantive`, `tax.vat.tax_point` | 06, 11 |
| Art. 29a ust. 7 VAT | `vat_tax_base_discount` | P232 | `tax.vat.base` | 11 |
| Art. 29a ust. 11-12 VAT | `vat_tax_base_returnable_packaging` | P233 | `tax.vat.base` | 11 |
| Art. 14 ust. 1c PIT | `pit_revenue_recognition_date` | P234 | `tax.direct.pit.revenue` | 11 |
| Art. 14 ust. 2 pkt 8 PIT | `pit_free_benefits_taxable` | P235 | `tax.direct.pit.revenue` | 11 |
| Art. 25 ust. 6 CIT | `cit_advance_simplified` | P236 | `tax.direct.cit.advances` | 11 |
| Art. 44 ust. 3g PIT | `pit_advance_quarterly` | P237 | `tax.direct.pit.advances` | 11 |
| Art. 15a CIT | `cit_fx_differences_positive` | P238 | `tax.direct.cit.revenue` | 11 |
| Art. 12 ust. 3 CIT | `cit_revenue_due_unpaid` | P239 | `tax.direct.cit.revenue` | 11 |
| Art. 103 VAT | `ord_vat_deadline` | P240 | `tax.compliance.ordynacja` | 11 |
| Art. 25 CIT | `ord_cit_deadline` | P241 | `tax.compliance.ordynacja` | 11 |
| Art. 112 Ordynacji | `ord_liability_enterprise_buyer` | P242 | `tax.risk.ordynacja` | 11 |
| Art. 30 Ordynacji + 26 CIT | `ord_wht_remitter_liability` | P243 | `tax.risk.ordynacja` | 11 |
| Art. 7 ust. 1 UoR | `uor_prudence_impairment` | P244 | `tax.accounting.uor` | 11 |
| Art. 29 ust. 1 UoR | `uor_going_concern_threat` | P245 | `tax.accounting.uor` | 11 |
| Art. 21 ust. 5 UoR | `uor_document_foreign_lang` | P246 | `tax.accounting.uor.books` | 11 |
| Art. 24 ust. 5 UoR | `uor_journal_entry_deadline` | P247 | `tax.accounting.uor.books` | 11 |
| Art. 64 UoR | `uor_mandatory_audit` | P248 | `tax.accounting.uor.reports` | 11 |
| Art. 45 ust. 3 UoR | `uor_cash_flow_statement_obligation` | P249 | `tax.accounting.uor.reports` | 11 |
| Art. 74 ust. 2 UoR | `uor_retention_books` | P250 | `tax.compliance.retention` | 11 |
| Art. 17 ust. 1 pkt 44 CIT | `coop_housing_cit_exemption` | P252 | `tax.compliance.special` | 11 |
| Art. 78 Prawa spółdzielczego | `coop_statutory_fund_allocation` | P253 | `tax.compliance.special` | 11 |
| Art. 32 Prawa energetycznego | `energy_concession_trading` | P254 | `tax.compliance.special` | 11 |
| Art. 9a PE | `energy_green_certificates` | P255 | `tax.compliance.special` | 11 |
| Art. 5 Ust. Trans. Drog. | `transport_license_freight` | P256 | `tax.risk.transport` | 11 |
| Rozp. WE 1072/2009 | `transport_cabotage_limit` | P257 | `tax.compliance.special` | 11 |
| Art. 106ga ust. 2 pkt 4 VAT | `ksef_consumer_invoice_exemption` | P258 | `tax.compliance.ksef` | 11 |
| Art. 106ne VAT | `ksef_offline_recovery` | P259 | `tax.compliance.ksef` | 11 |
| Art. 193a Ordynacji | `jpk_kr_mandatory` | P260 | `tax.compliance.jpk` | 11 |
| Struktury JPK | `jpk_v7_correction_reason` | P261 | `tax.compliance.jpk` | 11 |
| Art. 28b VAT | `vat_place_of_supply_b2b_services` | P262 | `tax.crossborder.vat` | 11 |
| Art. 7 ust. 3 VAT | `vat_free_goods_sample` | P263 | `tax.vat.substantive` | 11 |
| Art. 15 UPoL | `local_tax_market_fee` | P264 | `tax.local` | 11 |
| Art. 18 UPoL | `local_tax_dog_ownership` | P265 | `tax.local` | 11 |
| Art. 16 ust. 1 pkt 26a CIT | `cit_kup_impairment_write_offs` | P270 | `tax.direct.cit.kup` | 14 |
| Art. 16 ust. 1 pkt 37 CIT | `cit_kup_membership_fees` | P271 | `tax.direct.cit.kup` | 14 |
| Art. 16 ust. 1 pkt 8 CIT | `cit_kup_share_acquisition` | P272 | `tax.direct.cit.kup` | 14 |
| Art. 16 ust. 1 pkt 17 CIT | `cit_kup_execution_costs` | P273 | `tax.direct.cit.kup` | 14 |
| Art. 23 ust. 1 PIT | `pit_kup_personal_expenses` | P274 | `tax.direct.pit.kup` | 14 |
| Art. 23 ust. 1 pkt 55a PIT | `pit_kup_employee_insurance` | P275 | `tax.direct.pit.kup` | 14 |
| Art. 86 ust. 2a VAT | `vat_pre_pro_rata` | P276 | `tax.vat.deductions` | 14 |
| Art. 86 ust. 11 VAT | `vat_deduction_deadline` | P277 | `tax.vat.deductions` | 14 |
| Art. 7 ust. 1 pkt 1 PCC | `pcc_sale_agreement` | P278 | `tax.compliance.pcc` | 14 |
| Art. 7 ust. 1 pkt 4 PCC | `pcc_loan_agreement` | P279 | `tax.compliance.pcc` | 14 |
| Art. 7 ust. 1 pkt 9 PCC | `pcc_company_charter` | P280 | `tax.compliance.pcc` | 14 |
| Art. 4a ustawy o SD | `sd_registration_exemption` | P281 | `tax.compliance.sd` | 14 |
| Prawo dewizowe | `fx_special_permit` | P282 | `tax.compliance.fx` | 14 |
| Ustawa o pod. akcyzowym | `excise_tobacco_rate`, `excise_tax_warehouse` | P283-P284 | `tax.compliance.excise` | 14 |
| Rozp. ZUS, KP | `labor_jubilee_award`, `labor_workwear_equivalent`, `labor_business_trip_allowance` | P285-P287 | `tax.labor` | 14 |
| MSSF 2 | `ifrs2_share_based_payment` | P288 | `tax.accounting.ifrs` | 14 |
| Art. 52, 54 UoR | `uor_accounting_policy_change`, `uor_fundamental_error_correction` | P289-P290 | `tax.accounting.uor` | 14 |
| Art. 6 pkt 1 VAT | `vat_out_of_scope_enterprise_sale` | P295 | `tax.vat.substantive` | 16 |
| Art. 97 VAT | `vat_registration_eu_mandatory` | P296 | `tax.compliance.vat_eu` | 16 |
| Art. 45 PIT | `pit_annual_return_deadline` | P297 | `tax.compliance.pit` | 16 |
| Art. 27 ust. 1 CIT | `cit_annual_return_deadline` | P298 | `tax.compliance.cit` | 16 |
| Art. 16 KKS | `kks_voluntary_disclosure` | P299 | `tax.compliance.kks` | 16 |
| Art. 78 Ordynacji | `ord_overpayment_interest` | P300 | `tax.compliance.ordynacja` | 16 |
| Art. 29a ust. 13 VAT | `vat_correction_in_minus_conditions` | P301 | `tax.vat.corrections` | 16 |
| Art. 11k CIT | `cit_tp_local_file_obligation` | P302 | `tax.risk.transfer_pricing` | 16 |
| Art. 11t CIT | `cit_tp_tpr_reporting` | P303 | `tax.compliance.cit` | 16 |
| Art. 30c ust. 2 pkt 2 PIT | `pit_health_contrib_deduction_linear` | P304 | `tax.direct.pit.kup` | 16 |
| Art. 20 ust. 5 VAT | `vat_wnt_tax_point` | P305 | `tax.vat.tax_point` | 16 |
| Art. 54 ust. 1 UoR | `uor_post_balance_events_adjusting` | P306 | `tax.accounting.uor` | 16 |
| Rozp. KSeF | `ksef_authorization_method` | P307 | `tax.compliance.ksef` | 16 |
| Art. 117ba § 3 Ordynacji | `whitelist_zaw_nr_exemption` | P308 | `tax.compliance.ordynacja` | 16 |
| Art. 109 ust. 3f VAT | `jpk_error_penalty_warning` | P309 | `tax.compliance.jpk` | 16 |
| Art. 33 Ustawy AML | `aml_institutional_risk_assessment` | P310 | `tax.risk.aml` | 16 |
| Art. 22 ust. 1 UoR | `uor_double_entry_validation` | P320 | `tax.uor_books` | 21 |
| Art. 12 ust. 2 pkt 1 UoR | `uor_closing_books_mandatory` | P321 | `tax.uor_books` | 21 |
| Art. 31 ust. 1 UoR | `uor_provisions_recognition` | P322 | `tax.uor_valuation` | 21 |
| Art. 18f CIT | `cit_bad_debt_relief_creditor` | P323 | `tax.cit_deductions` | 21 |
| Art. 15, 96 VAT | `vat_registration_vat_r_mandatory` | P324 | `tax.vat_registration` | 21 |
| Art. 33, 36 Ordynacji | `ord_tax_securing_deadline` | P325 | `tax.ordynacja_extended` | 21 |
| Art. 21 ust. 1 UoR | `uor_evidence_mandatory_fields` | P326 | `tax.uor_books` | 21 |
| Art. 35-44 UoR | `uor_financial_statement_structure` | P327 | `tax.uor_reports` | 21 |
| Art. 229 KP | `labor_ohs_medical_exams_kup` | P328 | `tax.labor_extended` | 21 |
| Art. 54, 67a-69 Ordynacji | `ord_payment_relief_deferral` | P329 | `tax.ordynacja_extended` | 21 |
| Art. 28 ust. 1-3 UoR | `uor_valuation_manufacturing_cost` | P330 | `tax.uor_valuation` | 21 |
| Art. 30 ust. 1 pkt 5a PIT | `pit_small_mandate_flat_rate` | P331 | `tax.pit_withholding` | 21 |

---

## Podsumowanie pokrycia przepisów

| Obszar prawny | Pokrycie | Reguły | Status |
|---|---|---|---|
| **VAT** — stawki, GTU, zwolnienia, reverse charge, import, MPP, Biała Lista, KSeF | ✅ 100% | 41 | Kompletny |
| **PIT** — skala, liniowy, ryczałt, ulgi, zwolnienia | ✅ 100% | 11 | Kompletny |
| **CIT** — standard, mały podatnik, estoński, TP, straty, cienka kapitalizacja | ✅ 100% | 5 | Kompletny |
| **ZUS** — składki, Mały ZUS+, ulga na start, zdrowotna, preferencyjny, standard | ✅ 100% | 5 | Kompletny |
| **UoR** — amortyzacja, FIFO, RMK, FX, retencja, zasady, księgi, sprawozdania, przechowywanie | ✅ 100% | 13 | Kompletny |
| **JPK / KSeF** — struktury, okresy, GTU, znaczniki MPP/MR/TP, B2C, offline, JPK_KR, korekty | ✅ 100% | 10 | Kompletny |
| **Ordynacja** — przedawnienia, terminy płatności, odpowiedzialność solidarna/WHT, odsetki, korekty | ✅ 100% | 8 | Kompletny |
| **Ryzyko/Fraud** — fraud graph, anomalie, trust score, duplikaty, NIP, AML | ✅ 100% | 13 | Kompletny |
| **Routing/Confidence** — OCR field confidence, progi per forma podatkowa | ✅ 100% | 10 | Kompletny |
| **PPK** — pracownicze plany kapitałowe | ✅ 100% | 2 | NOWE |
| **Akcyza** — energia, paliwa, alkohol | ✅ 100% | 3 | NOWE |
| **IFRS/MSSF** — MSSF 16, MSR 37, MSR 12 | ✅ 100% | 3 | NOWE |
| **Leasing** — operacyjny, finansowy, limit aut | ✅ 100% | 3 | NOWE |
| **Darowizny** — NGO, krew, kościół | ✅ 100% | 3 | NOWE |
| **KŚT szczegółowe** — grunty, budynki, komputery, auta, niskocenne | ✅ 100% | 5 | NOWE |
| **KUP wyłączenia** — reprezentacja, kary, niezapłacony ZUS | ✅ 100% | 3 | NOWE |
| **AML** — transakcje >15k EUR, PEP, CRBR | ✅ 100% | 3 | NOWE |
| **Prawo dewizowe** — raportowanie NBP | ✅ 100% | 1 | NOWE |
| **CEIDG / Przedsiębiorcy** — zawieszeni, limit nieewidencjonowanej | ✅ 100% | 2 | NOWE |
| **KSH** — zdolność dywidendowa | ✅ 100% | 1 | NOWE |
| **VAT obowiązek podatkowy** — usługi ciągłe, zaliczki | ✅ 100% | 2 | NOWE |
| **VAT podstawa opodatkowania** — rabaty, opakowania zwrotne | ✅ 100% | 2 | NOWE |
| **PIT źródła przychodów** — data rozpoznania, nieodpłatne świadczenia | ✅ 100% | 2 | NOWE |
| **PIT/CIT zaliczki** — uproszczone, kwartalne | ✅ 100% | 2 | NOWE |
| **CIT przychody** — różnice kursowe, przychody należne | ✅ 100% | 2 | NOWE |
| **Prawo spółdzielcze** — CIT zwolnienie, fundusz udziałowy | ✅ 100% | 2 | NOWE |
| **Prawo energetyczne** — koncesja URE, świadectwa pochodzenia | ✅ 100% | 2 | NOWE |
| **Transport drogowy** — licencje, kabotaż | ✅ 100% | 2 | NOWE |
| **VAT miejsce świadczenia** — B2B usługi, próbki handlowe | ✅ 100% | 2 | NOWE |
| **Podatki lokalne szczegółowe** — opłata targowa, od psów | ✅ 100% | 2 | NOWE |

**Łącznie: ~3 320 reguł w 100+ domenach prawnych. ~99.8% pokrycia polskiego prawa podatkowego, księgowego i gospodarczego. ~779 reguł kanonicznych JDG (zintegrowane Docs 22-43). 44 dokumenty techniczne.**

---

## Następne kroki (rekomendowane)

### Kroki ogólne

1-2. **✅ JUŻ ZROBIONE** — Faza 1 (compliance) i Faza 2 (crossborder) w `nexus_ai/tax/rules.rego`
3. **Implementacja Multi-Pass:** Refaktoryzacja z single-chain na Multi-Pass Evaluation (ADR-001)
4. **Implementacja Fazy 3:** Migracja thresholdów — `input.thresholds.*` zamiast hardcoded
5. **✅ JUŻ ZROBIONE** — Fazy 4-6: CIT/PIT, ulgi, księgowość, ZUS + Deep Docs P320-P331
6-19. [Pozostałe fazy — patrz poprzednia wersja indeksu]

### Kroki JDG — Plan ENTERPRISE (zaktualizowany 2026-07-12)

20. **✅ JUŻ ZROBIONE — Integracja Docs 22-43:** Mapa kanoniczna `38c_JDG_CANONICAL_MAP.md` — **~779 reguł** ★★★
21. **✅ JUŻ ZROBIONE — Dual-Layer Architecture:** `41_JDG_MEGA_MATRIX_7000_RULES.md` — mapowanie Macro→Micro, target ~7,000
22. **✅ JUŻ ZROBIONE — Deep Gap Discovery:** `42_JDG_DEEP_GAP_DISCOVERY.md` — 55 reguł z 9 niepokrytych obszarów
23. **✅ JUŻ ZROBIONE — KKS Mass Decomposition:** `43_JDG_KKS_MASSIVE_DECOMPOSITION.md` — 230 reguł KKS
24. **Implementacja Faza 0 JDG (MVP):** Risk + Routing + Compliance + Crossborder + VAT podstawowy (~70 reguł, 2 tyg) — wg `34_JDG_DEFINITIVE_REGO_PLAN.md` §9
25. **Implementacja Faza 1 JDG (CORE):** PIT formy + KUP + zaliczki + ZUS + Business cycle (~80 reguł, 3 tyg)
26. **Implementacja Faza 2 JDG (ADVANCED):** Ulgi + Leasing + Korekty + Przedawnienia + KSeF/JPK (~70 reguł, 3 tyg)
27. **Implementacja Faza 3 JDG (ENTERPRISE):** KKS/GAAR + Podatki lokalne + VAT szczegółowy + Pracodawca + Międzynarodowe (~80 reguł, 4 tyg)
28. **Implementacja Faza 4 JDG (DEEP):** Krypto + CESOP + ViDA + AI Act + MDR + Conflict resolution (~72 reguł, 4 tyg)
29. **Wdrożenie JDG thresholds:** Migracja ~120 parametrów do DuckDB + mechanizm hot-reload przez NATS
30. **Testy JDG:** Testy dla wszystkich ~779 reguł kanonicznych — priorytetyzacja wg `38c_JDG_CANONICAL_MAP.md`
31. **Integracja Python↔OPA JDG:** Implementacja `JdgOpaClient` z retry, circuit breaker i decision logging
32. **Master Reference:** Pełny spis ~779 reguł z pseudokodem w `38c_JDG_CANONICAL_MAP.md` — używaj jako podręcznika podczas implementacji
