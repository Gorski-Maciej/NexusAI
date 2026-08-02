# 🚨 ISAP Legal Drift Alarm — NexusAI JDG v8.0

> **Wygenerowano:** 2026-08-02 08:46:31 | **Innowacja 14**
> **Znanych zmian prawnych:** 3
> **Reguł dotkniętych zmianami:** 148
> **Problemów temporalnych:** 511

## Znane zmiany prawne wpływające na reguły

| Data | Opis | Fix wdrożony? |
|------|------|:------------:|
| 2025-07-01 | SLIM VAT 3 — ulga złe długi: 150→90 dni | ✅ |
| 2026-02-01 | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | ✅ |
| 2026-01-01 | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | ❌ |

## Reguły dotknięte zmianami prawnymi

| Plik | Zmiana | Data zmiany | Fix? |
|------|--------|:-----------:|:----:|
| `_business_lifecycle_rates.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `_business_lifecycle_rates.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `_compliance_rates.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `_crossborder_rates.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `_edge_cases_conflicts_rates.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `_edge_cases_conflicts_rates.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `_metadata_jdg.rego` | SLIM VAT 3 — ulga złe długi: 150→90 dni | 2025-07-01 | ✅ |
| `_metadata_jdg.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `_metadata_jdg.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `_uor_rates.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `accounting/uor_enterprise_live.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `accounting.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `annual_declaration_enterprise.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `api_fallback.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `audit/plan44_audit.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `business/strategic_intelligence.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `business/strategic_intelligence.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `cross_domain_intelligence_enterprise.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `cross_domain_intelligence_enterprise.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `decision_composer_enterprise.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `defense_builder_enterprise.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `digital.rego` | SLIM VAT 3 — ulga złe długi: 150→90 dni | 2025-07-01 | ✅ |
| `edelivery/plan44_edelivery.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `edelivery_gateway_v2_enterprise.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `edge_cases.rego` | SLIM VAT 3 — ulga złe długi: 150→90 dni | 2025-07-01 | ✅ |
| `edge_cases.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `edge_cases.rego` | Nowe limity: zwolnienie podmiotowe VAT, ryczałt, składki ZUS | 2026-01-01 | ⚠️ |
| `esig/plan44_esig.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `esig/plan45_esig.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |
| `esig_auto_applicator_enterprise.rego` | KSeF obowiązkowy dla wszystkich podatników VAT czynnych | 2026-02-01 | ✅ |

## Problemy temporalne

| Lokalizacja | Problem | Severity |
|-------------|---------|:--------:|
| `_crossborder_rates.rego` | Potencjalnie nieaktualna data: 2021-01-01 (5 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2006-01-02 (20 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2006-01-02 (20 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2000-01-01 (26 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2000-01-01 (26 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2021-12-31 (4 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2023-01-01 (3 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2022-07-01 (4 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_helpers_jdg.rego` | Potencjalnie nieaktualna data: 2019-01-01 (7 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-04-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2019-04-01 (7 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2018-04-01 (8 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2023-07-01 (3 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-04-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-04-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2018-04-01 (8 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2019-04-01 (7 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2018-04-01 (8 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2023-07-01 (3 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2018-01-01 (8 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2022-01-01 (4 lat temu) | WARNING |
| `_metadata_jdg.rego` | Potencjalnie nieaktualna data: 2019-01-01 (7 lat temu) | WARNING |

---
*Wygenerowano — 2026-08-02 08:46:31*
*Innowacja 14 — `python JDG/tools/isap_drift_alarm.py`*