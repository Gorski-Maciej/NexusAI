<!--
artifacts: [docs/DEVELOPER_GUIDE.md, docs/OPA_REGO_DEVELOPER_GUIDE.md]
status: ACTIVE
owner: docs
verified: 2026-09-19
verify_cmd: python3 tools/v3_p60_engines.py I03
-->

# NexusAI JDG — Developer Guide v8.0 (R11, P28 Grand Finale)

> Zgodny z ADR-008 — pełny przewodnik projektowy modułu JDG.

## 1. ARCHITEKTURA MODUŁU JDG

Moduł JDG to silnik reguł podatkowych OPA/Rego dla polskich JDG.
Architektura 8-warstwowa "Forteca Niechybnej Śmierci":

```
Warstwa 1 — WALIDACJA WEJŚCIA: schema + semantic_guard + firewall
Warstwa 2 — EKSTRAKCJA AI: 5 agentów, 4-Eyes, trust score ≥0.92
Warstwa 3 — REGUŁY KANONICZNE: 543 plików Rego w drzewie rules/, 12 111 unikalnych rule_id (MANIFEST regen. 2026-09-19; kampania V3 69/69)
Warstwa 4 — TEMPORALNOŚĆ: temporal.rego, valid_from/valid_to
Warstwa 5 — MULTI-PASS SHARDED ROUTER: ADR-007
Warstwa 6 — DECYZJA: decision_composer, AUTO_POST/SUGGEST/ASK_USER
Warstwa 7 — AUDYT: immutable audit trail, ADR-006
Warstwa 8 — MONITORING: isap_crawler, telemetria, chaos engineering
```

## 2. STRUKTURA KATALOGÓW

```
JDG/
├── rules/                  # 543 plików Rego (drzewo rules/)
│   ├── uor/                # NOWE Q3 2026: 8 plików jdg.uor.*
│   ├── pcc/                # NOWE Q3 2026: 4 pliki jdg.pcc.*
│   ├── local_taxes/        # NOWE Q3 2026: 2 pliki akcyza_*
│   ├── accounting/         # depreciation_enterprise_complete
│   ├── mdr/                # mdr_hallmarks.rego (120 reguł)
│   ├── crossborder/        # exit_tax_cfc_complete.rego (80 reguł)
│   ├── vat/ pit/ zus/ kks/ # Core domeny (A-grade)
│   └── micro/              # 106 plików warstwy atomowej
├── tests/
│   └── rego/               # NOWE: natywne testy Rego (opa test)
├── tools/                  # 22+ narzędzi deweloperskich
├── reports/                # Raporty analityczne P01-P28
└── .github/workflows/      # CI/CD: isap-scheduler, quality-gates-blocking
```

## 3. KONWENCJE REGO
Wzorzec reguły, kontrakt werdyktu 25-polowy i zasady First-Match-Wins — standard pisania reguł.


### 3.1. Wzorzec reguły
```rego
decide := {
    "matched": true,
    "rule_id": "jdg.[domena].[pakiet].[artykuł].[numer]",
    "package": "jdg.[domena].[pakiet]",
    "priority": [unikalny numeryczny],
    "_routing": "BLOCK_AND_ALERT|WARNING|TRIAGE_QUEUE|",
    "_routing_reason": "Powód routingu",
    "_legal_basis": "Art. XX Ustawy (Dz.U. YYYY)",
    "_warnings": ["Ostrzeżenie dla użytkownika"]
} {
    warunek_rego
}
```

### 3.2. Priorytetyzacja
- UoR: 100001-100743
- PCC: 200001-200343
- Akcyza: 250001-250143
- Amortyzacja: 300001-300054
- MDR: 350001-350062
- Exit Tax/CFC/WHT: 360001-360044

### 3.3. Pakiety (nowe Q3 2026)
- jdg.uor.obligation, jdg.uor.books, jdg.uor.revenue, jdg.uor.costs
- jdg.uor.assets, jdg.uor.inventory, jdg.uor.closing, jdg.uor.financial_stmt
- jdg.pcc.sales_agreements, jdg.pcc.loans, jdg.pcc.exchanges_companies, jdg.pcc.rate_changes
- jdg.akcyza.fuel_energy, jdg.akcyza.alcohol_tobacco
- jdg.pit.depreciation
- jdg.mdr.hallmarks
- jdg.exit_tax_cfc

## 4. CYKL ŻYCIA REGUŁY

```
1. SPECYFIKACJA → Prompt P## do generate_micro_rules.py
2. GENERACJA → Szablon OPA z pełnymi metadanymi
3. LINT → lint_rego_rules.py --check --strict (6-check)
4. WALIDACJA → validate_rules.py --strict
5. TESTY → opa test JDG/tests/rego/test_pakiet.rego
6. TAUTOLOGY GUARD → tautology_guard.py (BLOCKING)
7. ZERO-DEFECT → zero_defect_certification.py (score ≥85%)
8. REVIEW → Człowiek zatwierdza (4-Eyes)
9. MERGE → CI quality gates BLOCKING
10. MONITORING → isap_scheduler + drift_detector
```

## 5. NARZĘDZIA KRYTYCZNE

| Narzędzie | Cel | Wywołanie |
|-----------|-----|-----------|
| lint_rego_rules.py | 6-check lint | `python tools/lint_rego_rules.py --check --strict` |
| validate_rules.py | Walidacja reguł | `python tools/validate_rules.py --strict` |
| tautology_guard.py | Detekcja {true} | `python tools/tautology_guard.py --strict` |
| convert_true_to_conditions.py | Aktywacja martwych reguł | `python tools/convert_true_to_conditions.py` |
| self_healing_engine.py | Auto-naprawa | `python tools/self_healing_engine.py` |
| zero_defect_certification.py | Score certyfikacji | `python tools/zero_defect_certification.py` |
| rule_provenance_dna.py | DNA reguł | `python tools/rule_provenance_dna.py` |
| legal_change_impact_analyzer.py | Wpływ zmian prawa | `python tools/legal_change_impact_analyzer.py` |

## 6. CI/CD (BLOCKING)

Workflow `jdg-quality-gates-blocking.yml` blokuje merge jeśli:
- Lint 6-check FAIL
- validate_rules FAIL
- manifest_consistency FAIL
- tautology_guard FAIL
- zero_defect score < 85%

Workflow `isap-scheduler.yml` (cron daily):
- Sprawdza nowe akty prawne w ISAP
- Wykrywa drift temporalny
- Tworzy Issue z alertem

## 7. INNOWACJE WDROŻONE (P28)

| # | Innowacja | Status |
|---|-----------|--------|
| 1 | Self-Healing Rule Engine | ✅ Wdrożone |
| 4 | Real-Time Legal Change Impact Analyzer | ✅ Wdrożone |
| 5 | Zero-Defect Certification Engine | ✅ Wdrożone |
| 13 | Rule Provenance DNA | ✅ Wdrożone |

## 8. MAPA DROGOWA

- Q3 2026: UoR (8 plików) + PCC (4) + Akcyza (2) + PKPiR (1031 reguł) ✅
- Q4 2026: Amortyzacja KŚT + thresholds + testy natywne ✅
- Q1 2027: MDR/DAC6 + Exit Tax/CFC + WHT/PE ✅
- Q2 2027: Neural Mesh v2.0 + 100% coverage + Chaos Engineering
