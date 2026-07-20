# 🔥 PROMPT 05: JDG — Narzędzia, Testy, API, Dokumentacja

> **⚠️ WYJŚCIE OBOWIĄZKOWE — PLIK .TXT:** Cały wygenerowany raport analityczny ZAPISZ jako czysty plik `.txt` (plain text, bez formatowania Markdown). To jedyne akceptowane WYJŚCIE twojej pracy.

```text
🚨 INSTRUKCJA DLA MODELU GLM 5.2:

Analizujesz infrastrukturę narzędziową i testową modułu JDG — silnika reguł podatkowych OPA/Rego.
Jesteś Ekspertem w dziedzinie DevOps, CI/CD, quality assurance i inżynierii oprogramowania klasy Enterprise.

## ⚠️ NIE GENERUJ KODU — tylko RAPORT ANALITYCZNY

## 📂 PLIKI DO ANALIZY (~35 plików):

### Narzędzia JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_manifest.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/validate_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/lint_rego_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_micro_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_massive_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/crossref_plan50.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/generate_from_plan50.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/isap_crawler.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/judgment_predictor.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/llm_bridge.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_plan34_duplicates.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/convert_true_to_conditions.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/debug_converter.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/parse_plan33_and_generate.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_hyper_legal_basis.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tools/fix_micro_plan33_legal_basis.py

### Testy JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_temporal_validity.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_temporal_manager.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_phase5_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_strategic_v2_modules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_ksef_generator.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_pipeline.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_tax_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_risk_guard.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_fraud_graph_scanner.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pkpir_uor_enterprise.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/tests/test_pcc_excise_enterprise.py

### Bundle, API, Migracje:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/bundles/bundle.sh
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/bundles/manifest.json
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/api/openapi.yaml
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/migrations/001_jdg_rule_store.sql
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/generate_coverage_report.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/generate_missing_rules.py
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/COVERAGE_REPORT.md

### Dokumentacja JDG:
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/UNIFIED_PLAN.md
- https://github.com/Gorski-Maciej/NexusAI/blob/main/JDG/docs/OPA_REGO_DEVELOPER_GUIDE.md

## 🎯 CEL ANALIZY:

Przeprowadź GŁĘBOKIE MYŚLENIE i GŁĘBOKĄ ANALIZĘ infrastruktury narzędziowej i testowej JDG na ZAAWANSOWANYM POZIOMIE ENTERPRISE.
Wygeneruj ROZBUDOWANY RAPORT ANALITYCZNY (min. 14-18 stron) zawierający:

### 1. ANALIZA NARZĘDZI DEVOPS (POZIOM ENTERPRISE)
- Oceń kompletność narzędzi do walidacji, lintowania i generowania reguł
- Zaproponuj INNOWACYJNE NARZĘDZIA WYPRZEDZAJĄCE PROFESJONALISTÓW:
  - Automatyczny generator testów regresyjnych dla reguł Rego
  - System continuous rule validation z każdym commitem

### 2. ANALIZA POKRYCIA TESTOWEGO — które moduły NIE mają testów?

### 3. ANALIZA API I MIGRACJI — specyfikacja OpenAPI, schemat bazy

### 4-8. 🆕 AUDYT 2026 + FRAUD + TIGERBEETLE + STRESS + TEMPORAL

### 9. GENIALNE POMYSŁY ENTERPRISE (min. 10 INNOWACYJNYCH USPRAWNIEŃ)

## ⚠️ NIE GENERUJ KODU. Tylko RAPORT.
```

📄 **WYJŚCIE = PLIK .TXT:** Zapisz cały wygenerowany raport analityczny jako czysty plik `.txt` (plain text, bez formatowania).

🧹 PO ZAKOŃCZENIU ANALIZY: WYCZYŚĆ OKNO KONTEKSTOWE przed przejściem do następnej sesji.
