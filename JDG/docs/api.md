# 📡 NexusAI JDG Decision API — Dokumentacja

> **Auto-generowane:** 2026-08-02 08:39:57 (aktualizacja stanu: 2026-08-22) | **Wersja:** 1.0.0
> **Generator:** Innowacja 6 — API Documentation Auto-Generator

Silnik decyzyjny JDG oparty na OPA/Rego. Ewaluuje transakcje gospodarcze
Jednoosobowej Działalności Gospodarczej przeciwko ~11 855 regułom podatkowym,
ubezpieczeniowym i compliance (472 pliki Rego). Zwraca werdykt z pełnym drzewem proweniencji
(A1) i łańcuchem przyczynowości temporalnej (A2).

Architektura Multi-Pass:
  PASS 0: RISK (fraud/GKS/GAAR) → risk_verdict
  PASS 1: ROUTING (field confidence) → routing_verdict
  PASS 2: COMPLIANCE (Biała Lista/MPP/EPS) → compliance_verdict
  PASS 3: CROSSBORDER (WNT/WDT/import) → crossborder_verdict
  PASS 4: VAT (stawki + GTU + deductions) → vat_verdict
  PASS 5: PIT (forma + KUP + zaliczki) → pit_verdict
  PASS 6: ALLOWANCES (ulgi podatkowe) → allowances_verdict
  PASS 7: ACCOUNTING (PKPiR + amortyzacja) → accounting_verdict
  PASS 8: ZUS + BUSINESS + KSeF + JPK + RESZTA → misc_verdict
  POST-MERGE: Cross-Domain Conflict Detection (R0586-R0612)

Sharded Router (B1): O(1) hash kontekstu → dedykowany shard (5-25 reguł).
  Kontekst: tax_form × transaction_type × entity_flags × evaluation_date.
  Latency p95: < 5 ms per shard.

## 🌐 Serwery

- **Produkcja:** `https://api.nexusai.pl/v1`
- **Staging:** `https://api-staging.nexusai.pl/v1`
- **Lokalny development:** `http://localhost:8000/v1`

## 📋 Endpointy (10)

### GET `/jdg/audit/{verdict_id}`

**Time-travel audit — verify historical verdict** | Tagi: Audit | `operationId: auditHistoricalVerdict`

A2 Temporal Causality Chain. Odtwarza werdykt dla historycznej daty

**Parametry:**

- `verdict_id` (string) ✅ — ID werdyktu (UUID lub rule_id + timestamp)
- `verify_merkle` (boolean)  — Czy zweryfikować podpis Merkle Tree
**Response codes:** 200, 404

### GET `/jdg/coverage`

**Get legal coverage report — Doc 50 mapping to Rego rules** | Tagi: Health | `operationId: getCoverageReport`

R14: Zwraca raport pokrycia prawnego. Mapuje punkty prawne

**Parametry:**

- `prefix` (string (enum: V, P, OP, K, Z, R, PP, U, Pcc, Akc, CB, Suk, Zdr, AML, RODO, all))  — Filter by act prefix
**Response codes:** 200

### POST `/jdg/decide`

**Evaluate JDG transaction against 7000 rules** | Tagi: Decision | `operationId: evaluateJdgTransaction`

Główny endpoint decyzyjny NexusAI JDG. Przyjmuje dane faktury i kontekst
**Request Body:** `DecisionRequest`
**Response codes:** 200, 400, 409, 422, 429, 500, 503

### POST `/jdg/explain`

**Translate OPA verdict to natural language via LLM** | Tagi: Decision | `operationId: explainVerdict`

C2 LLM Bridge. Tłumaczy techniczny werdykt OPA na język naturalny
**Request Body:** ``
**Response codes:** 200

### GET `/jdg/health`

**System health and dependency status** | Tagi: Health | `operationId: healthCheck`

Zwraca status systemu JDG: wersję OPA, stan DuckDB, stan zewnętrznych
**Response codes:** 200

### GET `/jdg/legal-coverage`

**Get legal coverage status per act (Class A/B/C)** | Tagi: Health | `operationId: getLegalCoverage`

R14: Zwraca status pokrycia prawnego dla wszystkich 13 aktów

**Parametry:**

- `act` (string (enum: vat, pit, zus, kks, ord, uor, pp, pcc, local, ryczalt, sukcesja, rodo, aml, all))  — Filter by legal act
**Response codes:** 200

### GET `/jdg/manifest`

**Get rule manifest — list of all rules with metadata** | Tagi: Health | `operationId: getManifest`

R14: Zwraca MANIFEST.md w formacie JSON. Zawiera listę wszystkich

**Parametry:**

- `format` (string (enum: json, summary))  — Output format — full JSON or summary only
**Response codes:** 200

### GET `/jdg/rules/{rule_id}`

**Get rule detail by rule_id** | Tagi: Health | `operationId: getRuleDetail`

R14: Zwraca szczegóły pojedynczej reguły: plik źródłowy,

**Parametry:**

- `rule_id` (string) ✅ — Rule ID (np. jdg.vat.substantive.fuel_pl)
**Response codes:** 200, 404

### POST `/jdg/simulate`

**Shadow evaluation — predict KAS risk before committing** | Tagi: Simulation | `operationId: simulateJdgTransaction`

C1 Judgment Predictor z NexusAI_JDG_STRATEGIC_IMPROVEMENTS_7000.txt.
**Request Body:** `DecisionRequest`
**Response codes:** 200

### GET `/jdg/thresholds`

**List all active tax thresholds** | Tagi: Decision | `operationId: listThresholds`

B2 Decoupled Thresholds. Zwraca listę wszystkich aktywnych progów

**Parametry:**

- `scope` (string (enum: vat, pit, zus, ordpu, ksef, cfc, all))  — Scope filter
**Response codes:** 200


## 📦 Schematy

Liczba schematów: 13

### `DecisionRequest` (object)
- Wymagane: `transaction_date`, `context`, `payload`
- Pola: `transaction_date`, `evaluation_datetime`, `context`, `payload`

### `JdgContext` (object)
- Wymagane: `tenant_id`, `tenant_type`, `pit_form`
- Pola: `tenant_id`, `tenant_type`, `pit_form`, `transaction_type`, `pkpid_main`, `entity_status`

### `VerdictResponse` (object)
- Wymagane: `matched`, `rule_id`, `_provenance`, `_cost_ms`
- Pola: `matched`, `rule_id`, `action`, `vat_rate`, `vat_exemption`, `pit_form`, `pit_rate`, `kus_qualification`, `zus_social_base_type`, `zus_health_rate` +9 więcej

### `ProvenanceTree` (object)
- Wymagane: `matched_at`, `conditions_evaluated`, `decision_hash`
- Pola: `matched_at`, `path`, `conditions_evaluated`, `legal_basis_summary`, `temporal_snapshot_used`, `rule_version_applied`, `decision_hash`, `root_hash`, `evaluation_ms`, `evaluated_at` +2 więcej

### `DecisionStep` (object)
- Wymagane: brak
- Pola: `step`, `package`, `rule_id`, `priority`, `legal_basis`, `routing`, `routing_reason`, `matched`, `threshold_refs`, `temporal_valid_from` +2 więcej

### `EvaluatedCondition` (object)
- Wymagane: brak
- Pola: `condition_id`, `match_score`, `legal_basis`, `temporal_version`, `evaluation_time_us`

### `CrossDomainConflict` (object)
- Wymagane: brak
- Pola: `rule_id`, `conflict_domains`, `conflict_severity`, `conflict_resolution`, `conflict_message`

### `SimulationResponse` (object)
- Wymagane: brak
- Pola: `severity_score`, `potential_fine_pln`, `fine_probability`, `kks_articles_triggered`, `recommendations`, `verdict`

### `AuditResponse` (object)
- Wymagane: brak
- Pola: `verdict_id`, `original_verdict`, `temporal_snapshot`, `merkle_root`, `merkle_verified`, `ecdsa_signature`

### `HealthResponse` (object)
- Wymagane: brak
- Pola: `status`, `opa_version`, `bundle_version`, `external_apis`, `shard_count`, `rules_count`, `uptime_seconds`

### `ErrorResponse` (object)
- Wymagane: brak
- Pola: `error`, `message`, `details`, `request_id`

### `DegradationResponse` (object)
- Wymagane: brak
- Pola: `error`, `message`, `degraded_apis`, `fallback_active`, `retry_after_seconds`

### `ConflictResponse` (object)
- Wymagane: brak
- Pola: `error`, `message`, `conflicts`, `resolution_hint`

---
*Auto-generowane — 2026-08-02 08:39:57*
*Innowacja 6 — `python JDG/tools/api_doc_generator.py`*