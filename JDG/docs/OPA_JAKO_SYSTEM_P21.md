# P21 — OPA JAKO SYSTEM (Bundles, Policies, API, Migracje, Adaptacja do zmian prawa)

**Raport:** RAPORT ANALITYCZNY ENTERPRISE — JDG OPA JAKO SYSTEM (P21) v8.0
**Pakiet Rego:** `jdg.p21_opa_system_innovations` (`JDG/rules/p21_opa_system_innovations_v9.rego`)
**Status:** ✅ WDROŻONY — POSTĘP 21/24

---

## 1. Cel

Przekształcenie OPA z pojedynczego silnika reguł w **rozbudowany system klasy
ENTERPRISE**, który szybko i niezawodnie adaptuje się do zmian prawa:
hot-reload reguł, wersjonowanie, kanary, rollback, shadow deployment,
zero-downtime, monitoring jakości decyzji.

**Główny priorytet:** SZYBKA I NIEZAWODNA ADAPTACJA DO ZMIAN PRAWA
(auto-adaptacja w 24 h — INN-07).

---

## 2. Wdrożone sekcje promptu P21 (8 sekcji → reguły)

### Sekcja 1 — Audyt Bundles i Deploymentu
| Reguła | Opis |
|---|---|
| `bundle_audit` | bundle.sh (fix R1 — struktura katalogów, zero kolizji nazw), manifest.json (10878 reguł, 383 pliki), podpis SHA256 |
| `canary_deploy` (INN-01) | Kanary 5% ruchu, obserwacja 30 min, zero-downtime, auto-rollback (jakość < 95% lub błąd > 1%) |
| `shadow_deployment` (INN-02) | Równoległa ewaluacja prod vs shadow, delta werdyktów ≤ 2% |
| `bundle_signature` (INN-03) | Weryfikacja podpisu bundle (SHA256, manifest_hash, tamper detection) |

### Sekcja 2 — Audyt Policies Produkcyjnych (PRIORYTET ★)
| Reguła | Opis |
|---|---|
| `policies_drift_audit` | Dryf policies/jdg (29 plików) + policies/tax (28) vs JDG/rules (383) — alert przy ≥ 10% |
| `auto_sync_policies` (INN-04) | Single-source-of-truth (JDG/rules) + auto-sync co 24 h |

### Sekcja 3 — Audyt API i Migracji
| Reguła | Opis |
|---|---|
| `api_migration_audit` | openapi.yaml (12 endpointów) vs docs/api.md vs implementacja; migracje 001/002 (rule_versions, jdg_verdict_audit) |
| `temporal_migration` (INN-05) | Pełny schemat migracji temporalnych reguł (valid_from/valid_to, max 5 wersji) |

### Sekcja 4 — Audyt Narzędzi Systemowych (Control Tower)
| Reguła | Opis |
|---|---|
| `tools_audit` | Audyt 98 narzędzi (validate_rules, lint_rego, cross_ref, dead_rule, tautology, hardcoded, zero_defect, self_healing, adaptive_trust, isap_drift) |
| `control_tower` (INN-06) | 7 bramek jakości (syntax, legal_basis, dead_rule, tautology, hardcoded, cross_ref, regression) — block_on_fail |

### Sekcja 5 — System Cyklu Życia Reguły (PRIORYTET ★)
| Reguła | Opis |
|---|---|
| `rule_lifecycle_pipeline` | 11 kroków: ISAP → DETEKCJA → ANALIZA WPLYWU → GENEROWANIE → WALIDACJA → TESTY → SYMULACJA → BUNDLE → DEPLOY KANARY → MONITORING → ROLLBACK |

### Sekcja 6 — Odporność i Niezawodność
| Reguła | Opis |
|---|---|
| `resilience_audit` | Fallbacki, retry (3× backoff), circuit-breaker (5 błędów), timeout 500 ms |

### Sekcja 7 — Genialne Pomysły Enterprise (INN-01..INN-15)
| INN | Reguła | Opis |
|---|---|---|
| INN-07 | `legal_adaptation_24h` | Auto-adaptacja do nowelizacji w 24 h (ISAP → reguły → testy → bundle) |
| INN-08 | `legal_change_simulator` | Symulator wpływu zmiany prawa na portfel decyzji |
| INN-09 | `rule_registry_api` | Registry reguł z API (/v1/rules, 10878 reguł, searchable, versioned) |
| INN-10 | `rule_feature_flags` | Feature-flagi dla reguł (shadow mode, kill-switch) |
| INN-11 | `rule_change_proof` | Blockchainowy proof zmian reguł (hash-chain, jdg_verdict_audit) |
| INN-12 | `decision_quality_monitor` | Monitoring jakości decyzji (30 dni, jakość < 95% → alert) |
| INN-13 | `isap_drift_alarm` | Alarm rozjazdu reguł z legislacją (ISAP, legislacja.gov.pl) |
| INN-14 | `self_healing` | Self-healing engine (auto-naprawa dead rules, tautologii, hardcode) |
| INN-15 | `system_observability` | Pełna telemetria (latency p95 < 5 ms/shard, fallback rate, rollback events) |

### Sekcja 8 — Mapa drogowa P0/P1/P2
Szczegóły w raporcie `raporty_jdg_enterprise/R21_OPA_jako_System.txt`.

---

## 3. Okablowanie (main_jdg.rego)

```rego
import data.jdg.p21_opa_system_innovations          # linia 347

_package_decisions["jdg.p21_opa_system_innovations"] = p21_opa_system_innovations.decide   # linia 1333

final_verdict_p21 = safe_merge(final_verdict_p20,
    safe_merge(p21_opa_system_innovations.decide,
        fallback.decide
    ))                                              # linia 1625
```

Brak kolizji ze starym pakietem `jdg.p21_innovations` (v7, 49 reguł — FX/TP/Residency).

---

## 4. Pliki

| Plik | Opis |
|---|---|
| `JDG/rules/p21_opa_system_innovations_v9.rego` | Pakiet rego — 20 reguł + decide + default (21 reguł łącznie), 21 podstaw prawnych, 15 INN |
| `JDG/tools/opa_system_auditor.py` | Narzędzie audytora — audyt realnych plików infrastruktury OPA + 23 funkcje CLI |
| `JDG/tests/rego/test_p21_opa_system_enterprise.rego` | Testy rego (28) |
| `JDG/tests/auto/test_p21_opa_system_enterprise.py` | Testy pytest (37) |
| `JDG/docs/OPA_JAKO_SYSTEM_P21.md` | Dokumentacja |
| `raporty_jdg_enterprise/R21_OPA_jako_System.txt` | Raport analityczny Enterprise |

---

## 5. Zgodność i konwencje

- **ADR-002:** progi z `data.jdg.thresholds` (`opa_system` — zero hardcode)
- **ADR-001:** Multi-Pass OPA, **B1:** Sharded Router, **B2:** Threshold Injection
- **A1:** provenance (jdg_verdict_audit), **A2:** temporal causality (rule_versions)
- **C3:** Legal Radar (legislacja.gov.pl, ISAP)
- Konwencje P18-P20: funkcje pomocnicze else-chain, brak `if/else` w literałach
  obiektów, notacja nawiasowa dla kluczy z myślnikami w testach

## 6. Walidacja

- ✅ pytest P21: **37/37**
- ✅ regresja P01–P21: **469/469 passed** (432 + 37)
- ✅ py_compile OK, braces zbalansowane, smoke CLI
- ✅ pokrycie realne infrastruktury OPA (bundle 383 pliki, policies 57+, migracje 2, narzędzia 98)
- ✅ Code review (2 rundy, bez blokerów)
