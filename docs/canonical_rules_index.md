# 📋 NexusAI SC — Kanoniczny Indeks Reguł (Canonical Rules Index)

> **Status:** KANONICZNY — jedno źródło prawdy dla wszystkich reguł Spółki Cywilnej  
> **Data:** 2026-07-11  
> **Plik:** `docs/canonical_rules_index.md`  
> **Reguł łącznie:** ~1,255 (w planach + zaimplementowane Rego)

---

## 📑 Struktura

| Warstwa | Pliki | Reguły |
|---------|-------|:------:|
| **Plany dokumentacyjne** | `Plan OPA/SC_*.md` (6 plików) | ~1,187 |
| **Implementacja Rego** | `policies/tax/*.rego` (29 plików) | ~68 |
| **Tools Python** | `tools/sc_*.py` (4 pliki) | — |

---

## 🔗 Mapowanie P↔GR↔Rego

| ID Planu | ID GR | Rule ID Rego | Pakiet | Status |
|----------|-------|-------------|--------|:------:|
| P0 | GR-0 | `tax.risk.fraud_graph_match` | `tax.risk` | ✅ Zaimplementowane |
| P1 | GR-1 | `tax.risk.counterparty_trust_low` | `tax.risk` | ✅ Zaimplementowane |
| P2 | GR-2 | `tax.risk.anomaly_amount` | `tax.risk` | ✅ Zaimplementowane |
| P3 | GR-3 | `tax.risk.new_counterparty_flag` | `tax.risk` | ✅ Zaimplementowane |
| P5 | GR-5 | `tax.risk.semantic_guard_disallowed` | `tax.risk` | ✅ Zaimplementowane |
| P10 | GR-10 | `tax.routing.fc_vat_rate_low` | `tax.routing` | ✅ Zaimplementowane |
| P12 | GR-12 | `tax.routing.fc_vendor_nip_low` | `tax.routing` | ✅ Zaimplementowane |
| P20 | GR-20 | `tax.compliance.whitelist_missing` | `tax.compliance` | ✅ Zaimplementowane |
| P21 | GR-21 | `tax.compliance.split_payment_mandatory` | `tax.compliance` | ✅ Zaimplementowane |
| P22 | GR-22 | `tax.compliance.cash_over_limit` | `tax.compliance` | ✅ Zaimplementowane |
| P100 | GR-100 | `tax.fallback.domestic_default` | `tax.fallback` | ✅ Zaimplementowane |
| P200 | GR-200 | `tax.fallback.no_match` | `tax.fallback` | ✅ Zaimplementowane |
| — | — | `tax.temporal.period_active` | `tax.temporal` | ✅ ScTemporalSandbox |
| — | — | `tax.anomaly.amount_zscore` | `tax.anomaly` | ✅ ScAnomalyGuard |
| — | — | `tax.anomaly.vendor_first_large` | `tax.anomaly` | ✅ ScAnomalyGuard |
| — | — | `tax.anomaly.partner_cost_ratio` | `tax.anomaly` | ✅ ScAnomalyGuard |
| — | — | `tax.anomaly.seasonal_december_spike` | `tax.anomaly` | ✅ ScAnomalyGuard |
| — | — | `tax.anomaly.ml_model_high_risk` | `tax.anomaly` | ✅ ScAnomalyGuard (Faza 2) |
| — | — | `tax.what_if.simulation_active` | `tax.what_if` | ✅ ScWhatIf Engine |
| — | — | `tax.partner_mirror.split_active` | `tax.partner_mirror` | ✅ ScPartnerMirror |
| — | — | `tax.sc_partnership.formation_verbal` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.partner_addition_no_consent` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.share_change_no_annex` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.dissolution_all_agree` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.succession_death` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.suspension_over_24m` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_partnership.post_dissolution_liability` | `tax.sc_partnership` | ✅ |
| — | — | `tax.sc_liability.joint_all` | `tax.sc_liability` | ✅ |
| — | — | `tax.sc_liability.regress_right` | `tax.sc_liability` | ✅ |
| — | — | `tax.sc_liability.creditor_enforcement` | `tax.sc_liability` | ✅ |
| — | — | `tax.sc_liability.spouse_limited` | `tax.sc_liability` | ✅ |
| — | — | `tax.sc_liability.no_exposure` | `tax.sc_liability` | ✅ |
| — | — | `tax.sc_ksef_jpk.ksef_mandatory` | `tax.sc_ksef_jpk` | ✅ |
| — | — | `tax.sc_ksef_jpk.invoice_not_in_ksef` | `tax.sc_ksef_jpk` | ✅ |
| — | — | `tax.sc_ksef_jpk.jpk_v7_due` | `tax.sc_ksef_jpk` | ✅ |
| — | — | `tax.sc_ksef_jpk.whitelist_transfer` | `tax.sc_ksef_jpk` | ✅ |
| — | — | `tax.sc_ksef_jpk.cash_over_limit` | `tax.sc_ksef_jpk` | ✅ |
| — | — | `tax.sc_fallback.domestic_sc` | `tax.sc_fallback` | ✅ |
| — | — | `tax.sc_fallback.vat_exempt_sc` | `tax.sc_fallback` | ✅ |
| — | — | `tax.sc_fallback.dissolved_sc` | `tax.sc_fallback` | ✅ |
| — | — | `tax.sc_fallback.suspended_sc` | `tax.sc_fallback` | ✅ |
| — | — | `tax.sc_fallback.succession_sc` | `tax.sc_fallback` | ✅ |
| — | — | `tax.sc_fallback.no_match_sc` | `tax.sc_fallback` | ✅ |
| V-X | GR-X | `tax.vat.substantive.*` | `tax.vat.substantive` | 📋 W planie |
| V-X | GR-X | `tax.vat.deductions.*` | `tax.vat.deductions` | 📋 W planie |
| V-X | GR-X | `tax.vat.procedures.*` | `tax.vat.procedures` | 📋 W planie |
| GR-170–209 | GR-170–209 | — | `sc.pit.partners` | 📋 W planie (Art. 8 PIT — podział) |
| GR-210–239 | GR-210–239 | — | `sc.pit.kup` | 📋 W planie (KUP per wspólnik) |
| GR-240–279 | GR-240–279 | — | `sc.pit.allowances` | 📋 W planie (ulgi per wspólnik) |
| GR-280–329 | GR-280–329 | — | `sc.zus.social`, `sc.zus.health` | 📋 W planie (ZUS per wspólnik) |
| GR-330–349 | GR-330–349 | `tax.sc_partnership.*` | `tax.sc_partnership` | 📋 W planie (formation) |
| GR-350–384 | GR-350–384 | — | `sc.partnership.changes` | 📋 W planie (zmiany składu) |
| GR-385–414 | GR-385–414 | `tax.sc_partnership.*` | `tax.sc_partnership` | 📋 W planie (dissolution) |
| GR-415–433 | GR-415–433 | `tax.sc_liability.*` | `tax.sc_liability` | 📋 W planie (liability) |
| GR-434–454 | GR-434–454 | — | `sc.partnership.representation` | 📋 W planie |
| GR-500–599 | GR-500–599 | — | `sc.sanctions` | 📋 W planie |
| GR-600–699 | GR-600–699 | — | `sc.interactions` | 📋 W planie |

---

## 📦 Kompletna mapa pakietów (33 pakiety)

| Kategoria | Pakiet | Plik Rego | Status |
|-----------|--------|-----------|:------:|
| **Risk & Routing** | `tax.risk` | `risk.rego` | ✅ |
| | `tax.routing` | `routing.rego` | ✅ |
| | `tax.compliance` | `compliance.rego` | ✅ |
| | `tax.crossborder` | `crossborder.rego` | ✅ |
| | `tax.temporal` | `temporal.rego` | ✅ ScTemporalSandbox |
| **VAT (spółka)** | `tax.vat.substantive` | `vat/substantive.rego` | 📋 |
| | `tax.vat.deductions` | `vat/deductions.rego` | 📋 |
| | `tax.vat.procedures` | `vat/procedures.rego` | 📋 |
| | `tax.vat.gtu` | (w helpers) | 📋 |
| **PIT (wspólnicy)** | `sc.pit.partners` | (planowane) | 📋 Art. 8 PIT |
| | `sc.pit.forms` | (planowane) | 📋 |
| | `sc.pit.kup` | (planowane) | 📋 |
| | `sc.pit.advances` | (planowane) | 📋 |
| | `sc.pit.returns` | (planowane) | 📋 |
| | `sc.pit.exemptions` | (planowane) | 📋 |
| | `sc.pit.allowances` | `allowances.rego` | 📋 |
| **ZUS (wspólnicy)** | `sc.zus.social` | `zus.rego` | 📋 |
| | `sc.zus.health` | `zus.rego` | 📋 |
| **Accounting** | `sc.accounting.full` | `accounting.rego`, `uor_*.rego` | 📋 |
| | `sc.accounting.pkpir` | (planowane) | 📋 |
| | `sc.accounting.vat_register` | `vat_registration.rego` | 📋 |
| **Anomaly (nowe)** | `tax.anomaly` | `anomaly.rego` | ✅ ScAnomalyGuard |
| **Simulation (nowe)** | `tax.what_if` | `what_if.rego` | ✅ ScWhatIf |
| **Privacy (nowe)** | `tax.partner_mirror` | `partner_mirror.rego` | ✅ ScPartnerMirror |
| **Partnership Lifecycle** | `tax.sc_partnership` | `sc_partnership.rego` | ✅ |
| **Joint Liability** | `tax.sc_liability` | `sc_liability.rego` | ✅ |
| **KSeF/JPK** | `tax.sc_ksef_jpk` | `sc_ksef_jpk.rego` | ✅ |
| **Fallback SC** | `tax.sc_fallback` | `sc_fallback.rego` | ✅ |
| **Orchestrator SC** | `tax.main_sc` | `main_sc.rego` | ✅ |
| **Employer** | `sc.employer` | `labor_extended.rego` | 📋 |
| **Sanctions** | `sc.sanctions` | (planowane) | 📋 |
| **Interactions** | `sc.interactions` | (planowane) | 📋 |
| **Data** | `data.sc.thresholds` | `thresholds_sc.rego` | ✅ ScThresholdPrecompute |

**Legenda:** ✅ = Zaimplementowane | 📋 = W planie (do implementacji)

---

## 🛠 Narzędzia (Python)

| Plik | Funkcja | Strategia |
|------|---------|-----------|
| `tools/sc_legal_graph.py` | Analizator grafu zależności reguł | 🔬 ScLegalGraph |
| `tools/regulatory_radar.py` | Monitor zmian legislacyjnych | 💡 ScRegulatoryRadar |
| `tools/sc_verdict_streaming.py` | Batch processing faktur | ⚡ ScVerdictStreaming |
| `tools/sc_context_enricher.py` | Pre-processor walidacji input | NOWY |

---

## 📄 Plany dokumentacyjne

| Plik | Opis | Reguł |
|------|------|:------:|
| `SC_DEFINITIVE_REGO_PLAN.md` | Architektura główna | ~550 |
| `SC_EXPANSION_14_AREAS.md` | Rozszerzenia obszarowe | ~85 |
| `35_SPOLKA_CYWILNA_ADVANCED_GAPS.md` | 15 zaawansowanych luk | ~69 |
| `36_SPOLKA_CYWILNA_ULTIMATE_GAPS.md` | 17 ultimate pod-obszarów | ~48 |
| `37_SPOLKA_CYWILNA_ULTIMATE_GRANULARITY.md` | Mikro-dekompozycja GR | ~435 |
| `38_SPOLKA_CYWILNA_STRATEGIC_IMPROVEMENTS.md` | Analiza strategiczna | — |

---

> **Ostatnia aktualizacja:** 2026-07-11 | **Zespół:** NexusAI SC Engineering

---

## 📊 Finalne statystyki wdrożenia (v8.0)

| Metryka | Wartość |
|---------|:------:|
| **Pliki Rego** | 28 |
| **Reguły decyzyjne zaimplementowane** | 31 |
| **Plany dokumentacyjne (Plan OPA/)** | 6 plików, ~1,187 reguł |
| **Testy integracyjne** | 15 |
| **Narzędzia Python** | 4 |
| **Pakiety Rego** | 22+ |
| **Strategiczne ulepszenia** | 9/9 wdrożonych |
| **Mechanizmy integracyjne** | 8/8 wdrożonych |
| **Linii kodu Rego** | ~3,500 |
| **Linii kodu Python** | ~1,400 |
