# 🧪 JDG Tests

## Skopiowane testy

16 testów JDG skopiowanych z `tests/` do `JDG/tests/` ze zaktualizowanymi ścieżkami:

| Plik testowy | Status | Uwagi |
|-------------|:------:|------|
| `test_temporal_validity.py` | ✅ **40/40 PASS** | Testy walidacji temporalnej Rego |
| `test_temporal_manager.py` | ⚠️ Wymaga duckdb | Import nexus_ai |
| `test_ksef_generator.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai.services |
| `test_priority_engine.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai.services |
| `test_semantic_guard.py` | ⚠️ Wymaga duckdb | Import nexus_ai.services |
| `test_risk_guard.py` | ⚠️ Wymaga nexus_ai | Import + dane testowe |
| `test_risk_api.py` | ⚠️ Wymaga nexus_ai | Full API context |
| `test_risk_guard_integration.py` | ⚠️ Wymaga nexus_ai | Integracja |
| `test_facts_aggregator.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai.services |
| `test_fraud_graph_scanner.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai.services |
| `test_payment_priority_service.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai |
| `test_phase5_modules.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai |
| `test_strategic_v2_modules.py` | ⚠️ Wymaga nexus_ai | Import nexus_ai.tax |
| `test_tax_pipeline.py` | ⚠️ Wymaga nexus_ai | Full pipeline context |
| `test_tax_rules.py` | ⚠️ Wymaga nexus_ai | Full rules context |
| `test_tax_audit.py` | ⚠️ Wymaga nexus_ai | Tax audit imports |

## Jak uruchomić

```bash
# Testy niezależne (tylko stdlib)
python -m pytest JDG/tests/test_temporal_validity.py -v

# Wszystkie testy JDG (wymaga pip install -e .)
pip install -e .
python -m pytest JDG/tests/ -v

# Walidacja reguł OPA (bez Pythona)
python JDG/tools/validate_rules.py --strict
```

## Zmiany ścieżek

- `policies/jdg/` → `JDG/rules/` (w test_temporal_validity.py)
- `PROJECT_ROOT` = `.parent.parent.parent` (testy w `JDG/tests/`, root 3 poziomy wyżej)

---

*Struktura ENTERPRISE JDG — 16 testów, 40/40 temporal_validity PASS ✅*
