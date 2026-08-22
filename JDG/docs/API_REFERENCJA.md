# 📡 NexusAI JDG — API Reference (Decision API v1.0.0)

> **Dokument:** API_REFERENCJA.md | **Specyfikacja:** [../api/openapi.yaml](../api/openapi.yaml) (OpenAPI 3.0.3)
> **Cel:** Samowystarczalny przewodnik integracji — każdy endpoint ma metodę, ścieżkę, nagłówki, parametry, body, odpowiedzi (kody + schemat JSON) i przykłady curl.

---

## 🔎 Wyszukiwarka (Ctrl+F)

`API` · `endpoint` · `REST` · `curl` · `decide` · `simulate` · `audit` · `health` · `explain` · `thresholds` · `manifest` · `coverage` · `rules` · `legal-coverage` · `rate limit` · `throttling` · `429` · `błąd` · `error code` · `kod błędu` · `JWT` · `Bearer` · `nagłówki` · `headers`

---

## 1. Wartość biznesowa (PWE)

| | |
|---|---|
| **P — Problem** | Integrator nie wie, jak wywołać ewaluację faktury, jakie pola wysłać i jak obsłużyć błędy (429, 503, 409). |
| **W — Wartość** | Jeden dokument opisuje wszystkie 17 endpointów z gotowymi do wklejenia przykładami curl i pełną tabelą kodów błędów. |
| **E — Efekt** | Integracja systemu ERP z silnikiem JDG w jeden dzień, bez zgadywania. |

---

## 2. Informacje ogólne

### 2.1. Serwery (bazowe URL)

| Środowisko | URL |
|---|---|
| Produkcja | `https://api.nexusai.pl/v1` |
| Staging | `https://api-staging.nexusai.pl/v1` |
| Lokalny development | `http://localhost:8000/v1` |

### 2.2. Autoryzacja

Wszystkie endpointy wymagają nagłówka:

```
Authorization: Bearer <JWT>
```

Token JWT wystawiany przez **NexusAI Auth Service**. Zawartość: `tenant_id`, `tenant_type` (`jdg`/`cit`/`other`), uprawnienia (`decide`/`simulate`/`audit`).

### 2.3. Nagłówki wspólne

| Nagłówek | Wymagany | Opis |
|---|---|---|
| `Authorization: Bearer <JWT>` | ✅ | Token dostępu |
| `Content-Type: application/json` | ✅ (POST) | Format body |
| `Accept: application/json` | ✅ | Format odpowiedzi |
| `X-Request-Id` | opcjonalny | Identyfikator korelacji (zwracany w `request_id` błędów) |

### 2.4. Format dat

| Pole | Format | Przykład |
|---|---|---|
| data transakcji `transaction_date` | `date` ISO-8601 | `2026-07-17` |
| timestamp ewaluacji `evaluation_datetime` | `date-time` ISO-8601 | `2026-07-17T10:00:00+02:00` |

---

## 3. Lista endpointów (17)

| # | Metoda | Ścieżka | Tag | Opis |
|---|---|---|---|---|
| 1 | POST | `/jdg/decide` | Decision | Ewaluacja transakcji JDG |
| 2 | POST | `/jdg/simulate` | Simulation | Symulacja „shadow mode" (predykcja ryzyka) |
| 3 | GET | `/jdg/audit/{verdict_id}` | Audit | Audyt historyczny (time-travel, Merkle) |
| 4 | GET | `/jdg/health` | Health | Status systemu i zależności |
| 5 | POST | `/jdg/explain` | Decision | Tłumaczenie werdyktu na język naturalny (LLM) |
| 6 | GET | `/jdg/thresholds` | Decision | Lista aktywnych progów podatkowych |
| 7 | GET | `/jdg/manifest` | Health | Manifest reguł (JSON) |
| 8 | GET | `/jdg/coverage` | Health | Raport pokrycia prawnego |
| 9 | GET | `/jdg/rules/{rule_id}` | Health | Szczegóły pojedynczej reguły |
| 10 | GET | `/jdg/legal-coverage` | Health | Pokrycie prawne per akt (klasy A/B/C) |
| 11 | GET | `/jdg/rules` | Registry | Policy Registry API — wyszukiwanie reguł |
| 12 | POST | `/jdg/change` | Registry | Declarative Change (ADR-021) |
| 13 | POST | `/jdg/cert` | Audit | Issue Decision Certificate (F4) |
| 14 | GET | `/bundles` | Bundles | Katalog wersji bundle |
| 15 | POST | `/bundles/{version}/verify` | Bundles | Weryfikacja podpisu + SBOM |
| 16 | GET | `/bundles/{version}/health` | Bundles | Zdrowie rollout'u bundle |
| 17 | POST | `/dr/restore` | DR | Disaster recovery — przywrócenie stanu |

---

## 4. Endpointy — szczegóły

### 4.1. POST `/jdg/decide` — ewaluacja transakcji JDG

**Opis:** Główny endpoint decyzyjny. Uruchamia pełny pipeline Multi-Pass (PASS 0–8 + POST-MERGE) z Sharded Routerem i zwraca werdykt z drzewem proweniencji (A1) i śladem temporalnym (A2).

**Nagłówki:** `Authorization: Bearer <JWT>`, `Content-Type: application/json`

**Body — `DecisionRequest`** (wymagane: `transaction_date`, `context`, `payload`):

| Pole | Typ | Wymagany | Opis |
|---|---|---|---|
| `transaction_date` | date | ✅ | Data transakcji — wybiera wersję reguły (temporalność A2) |
| `evaluation_datetime` | date-time | — | Czas ewaluacji; do time-travel podaj datę historyczną |
| `context` | object | ✅ | `JdgContext` (poniżej) |
| `payload` | object | ✅ | `invoice`, `vendor`, `jdg_entrepreneur`, `system`, `confidence`… |

**`JdgContext`** (wymagane: `tenant_id`, `tenant_type`, `pit_form`):

| Pole | Typ | Wartości |
|---|---|---|
| `tenant_id` | string | np. `tnt_abc123` |
| `tenant_type` | string | `jdg` / `cit` / `other` |
| `pit_form` | string | `SCALE` / `LINEAR` / `LUMP_SUM` / `TAX_CARD` |
| `transaction_type` | string | `DOMESTIC_SALE` / `DOMESTIC_PURCHASE` / `EXPORT` / `IMPORT` / `CROSS_BORDER_SALE` |
| `pkpid_main` | string | kod PKD (np. `62.01.Z`) |
| `entity_status` | string | `ACTIVE` / `SUSPENDED` / `IN_SUCCESSIO` / `UNREGISTERED` |

**Przykład body (faktura krajowa, skala):**

```json
{
  "transaction_date": "2026-07-17",
  "evaluation_datetime": "2026-07-17T10:00:00+02:00",
  "context": {
    "tenant_id": "tnt_abc123",
    "tenant_type": "jdg",
    "pit_form": "SCALE",
    "transaction_type": "DOMESTIC_SALE",
    "pkpid_main": "62.01.Z"
  },
  "payload": {
    "invoice": {
      "invoice_number": "FV/2026/07/001",
      "issue_date": "2026-07-17",
      "sale_date": "2026-07-15",
      "direction": "SALE",
      "document_type": "INVOICE",
      "currency": "PLN",
      "amount_net": 10000.00,
      "amount_gross": 12300.00,
      "vat_rate": "0.23",
      "vat_amount": 2300.00,
      "expense_type": "IT_SERVICES",
      "ksef_sent": true,
      "ksef_upo_received": true,
      "is_paid": true,
      "days_overdue": 0
    },
    "vendor": {
      "name": "TechSolutions Sp. z o.o.",
      "nip": "1234567890",
      "country": "PL",
      "iban": "PL61109010140000071219812874",
      "whitelist_status": "VERIFIED",
      "ceidg_status": "ACTIVE"
    },
    "jdg_entrepreneur": {
      "tax_form": "SCALE",
      "vat_status": "ACTIVE",
      "business_status": "ACTIVE",
      "has_employees": false,
      "annual_revenue_pln": 250000,
      "annual_taxable_income": 120000,
      "sales_ytd_vat_exempt": 0,
      "zus_start_relief_active": false,
      "zus_maly_plus_active": true,
      "zus_preferential_active": false,
      "has_rd_status": false
    },
    "system": { "ksef_status": "ONLINE", "nbp_rate_available": true }
  },
  "confidence": { "vendor_nip": 1.0, "vat_rate": 0.98, "expense_type": 0.95 }
}
```

**Odpowiedzi:**

| Kod | Opis | Schemat |
|---|---|---|
| **200** | Werdykt z drzewem proweniencji | `VerdictResponse` |
| **400** | Brak wymaganych pól / zły format | `ErrorResponse` |
| **409** | Konflikt reguł między domenami | `ConflictResponse` |
| **422** | Brak reguły dla inputu → `BLOCK_AND_ALERT` | `ErrorResponse` |
| **429** | Przekroczony rate limit (nagłówek `Retry-After`) | — |
| **500** | Wewnętrzny błąd ewaluacji OPA/WASM | `ErrorResponse` |
| **503** | Degradacja API zewnętrznych (Biała Lista/CEIDG/KSeF offline) | `DegradationResponse` |

**Przykład curl:**

```bash
curl -X POST https://api.nexusai.pl/v1/jdg/decide \
  -H "Authorization: Bearer $JWT" \
  -H "Content-Type: application/json" \
  -d @faktura.json
```

**Przykładowa odpowiedź 200 (`VerdictResponse`):**

```json
{
  "matched": true,
  "rule_id": "jdg.vat.substantive.it_services_pl",
  "action": "ALLOW",
  "vat_rate": "0.23",
  "vat_exemption": null,
  "pit_form": "SCALE",
  "pit_rate": "0.12",
  "kus_qualification": "deductible_full",
  "zus_social_base_type": "MALY_ZUS_PLUS",
  "zus_health_rate": "0.09",
  "business_status": "ACTIVE",
  "_routing": "",
  "_routing_reason": "",
  "_legal_basis": "Art. 41 ust. 1 ustawy o VAT",
  "_warnings": [],
  "_cross_domain_conflicts": [],
  "_shard_routed": "sale_scale_active",
  "_cost_ms": 4.2,
  "_provenance": {
    "matched_at": "2026-07-17T10:00:01.234Z",
    "path": [
      { "step": 0, "package": "jdg.risk", "rule_id": "jdg.risk.no_match", "matched": false }
    ],
    "legal_basis_summary": ["Art. 41 ust. 1 ustawy o VAT"],
    "temporal_snapshot_used": "2026-Q3",
    "rule_version_applied": 2,
    "decision_hash": "sha256:9f86d081884c7d659a2feaa0c55ad015…",
    "root_hash": "merkle:ab12…",
    "evaluation_ms": 4.2,
    "evaluated_at": "2026-07-17T10:00:01.234Z",
    "active_packages": 35,
    "total_packages": 60
  }
}
```

### 4.2. POST `/jdg/simulate` — symulacja „shadow mode" (C1)

**Opis:** Uruchamia wszystkie reguły **bez zmiany stanu**; zwraca szacowaną karę KKS i prawdopodobieństwo sankcji. **Użycie:** przed wystawieniem/opłaceniem faktury.

**Body:** `DecisionRequest` (jak w 4.1).

**Odpowiedź 200 (`SimulationResponse`):**

| Pole | Typ | Opis |
|---|---|---|
| `severity_score` | number | Ryzyko 0.0–1.0 |
| `potential_fine_pln` | number | Szacowana kara w PLN |
| `fine_probability` | number | Prawdopodobieństwo kary 0.0–1.0 |
| `kks_articles_triggered` | string[] | Naruszone artykuły KKS |
| `recommendations` | string[] | Co zrobić przed wystawieniem |
| `verdict` | object | Pełny werdykt (jak w 4.1) |

```bash
curl -X POST https://api.nexusai.pl/v1/jdg/simulate \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d @roboczy_input.json
```

### 4.3. GET `/jdg/audit/{verdict_id}` — audyt historyczny (A2)

**Opis:** Odtwarza werdykt dla historycznej daty wg stanu prawnego z dnia transakcji (DuckDB time-travel). Zwraca oryginalny werdykt + Merkle root + snapshot temporalny.

**Parametry:**

| Parametr | Typ | Wymagany | Opis |
|---|---|---|---|
| `verdict_id` (path) | string | ✅ | UUID werdyktu lub `rule_id` + timestamp |
| `verify_merkle` (query) | boolean | — | Weryfikacja podpisu Merkle (domyślnie `true`) |

**Odpowiedź 200 (`AuditResponse`):** `verdict_id`, `original_verdict`, `temporal_snapshot` (`evaluation_date`, `thresholds_snapshot_hash`, `rules_version_hash`), `merkle_root`, `merkle_verified`, `ecdsa_signature`. **404** — brak werdyktu.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/audit/550e8400-e29b-41d4-a716-446655440000?verify_merkle=true" \
  -H "Authorization: Bearer $JWT"
```

### 4.4. GET `/jdg/health` — status systemu

**Opis:** wersja OPA, stan DuckDB, stan API zewnętrznych (Biała Lista, CEIDG, KSeF, NBP), liczba shardów, liczba reguł, uptime, wersja bundle.

**Odpowiedź 200 (`HealthResponse`):**

```json
{
  "status": "healthy",
  "opa_version": "v0.60.0",
  "bundle_version": "8.0.0",
  "external_apis": {
    "whitelist_mf": "online",
    "ceidg": "online",
    "ksef": "online",
    "nbp": "online"
  },
  "shard_count": 4,
  "rules_count": 11808,
  "uptime_seconds": 86400
}
```

```bash
curl -X GET https://api.nexusai.pl/v1/jdg/health -H "Authorization: Bearer $JWT"
```

### 4.5. POST `/jdg/explain` — tłumaczenie werdyktu na język naturalny (C2)

**Body:**

| Pole | Typ | Opis |
|---|---|---|
| `verdict` | object | Werdykt (`VerdictResponse`) |
| `style` | string | `advisor` / `compliance` / `educational` / `executive` / `eli5` (domyślnie `advisor`) |
| `model` | string | `gemini-flash` / `claude-haiku` / `gpt-4o-mini` (domyślnie `gemini-flash`) |
| `provenance_tree` | object | opcjonalne drzewo proweniencji |

**Odpowiedź 200:** `status`, `explanation` (`title`, `summary`, `body`, `recommendation`, `risk_level`, `style`, `model_used`, `legal_disclaimer`).

```bash
curl -X POST https://api.nexusai.pl/v1/jdg/explain \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"verdict": {"rule_id": "jdg.vat.substantive.fuel_pl"}, "style": "advisor"}'
```

### 4.6. GET `/jdg/thresholds` — progi podatkowe (B2)

**Parametr:** `scope` (query): `vat` / `pit` / `zus` / `ordpu` / `ksef` / `cfc` / `all` (domyślnie `all`).

**Odpowiedź 200:** `thresholds[]` (`threshold_id`, `description`, `value_numeric`, `value_unit`, `legal_basis`, `valid_from`) + `total`.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/thresholds?scope=vat" -H "Authorization: Bearer $JWT"
```

### 4.7. GET `/jdg/manifest` — manifest reguł (R14)

**Parametr:** `format` (query): `json` / `summary` (domyślnie `json`).

**Odpowiedź 200:** `generated`, `total_files`, `files_with_matched`, `matched_blocks`, `unique_rule_ids`, `duplicates`, `enterprise_summary[]`.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/manifest?format=summary" -H "Authorization: Bearer $JWT"
```

### 4.8. GET `/jdg/coverage` — raport pokrycia (R14)

**Parametr:** `prefix` (query): `V`, `P`, `OP`, `K`, `Z`, `R`, `PP`, `U`, `Pcc`, `Akc`, `CB`, `Suk`, `Zdr`, `AML`, `RODO`, `all`.

**Odpowiedź 200:** `generated`, `total_points`, `covered`, `coverage_pct`, `by_prefix{act: {total, covered}}`.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/coverage?prefix=VAT" -H "Authorization: Bearer $JWT"
```

### 4.9. GET `/jdg/rules/{rule_id}` — szczegóły reguły (R14)

**Parametr:** `rule_id` (path) — np. `jdg.vat.substantive.fuel_pl`.

**Odpowiedź 200:** `rule_id`, `file`, `priority`, `legal_basis`, `routing`, `matched`. **404** — nie znaleziono.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/rules/jdg.vat.substantive.fuel_pl" \
  -H "Authorization: Bearer $JWT"
```

### 4.10. GET `/jdg/legal-coverage` — pokrycie per akt (R14)

**Parametr:** `act` (query): `vat` / `pit` / `zus` / `kks` / `ord` / `uor` / `pp` / `pcc` / `local` / `ryczalt` / `sukcesja` / `rodo` / `aml` / `all`.

**Odpowiedź 200:** `total_points`, `class_a_pct`, `class_b_pct`, `class_c_pct`, `last_updated`, `acts[]` (`act`, `name`, `points`, `class` (A/B/C), `coverage_pct`).

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/legal-coverage?act=vat" -H "Authorization: Bearer $JWT"
```

### 4.11. GET `/jdg/rules` — Policy Registry API (wyszukiwanie reguł)

**Parametry query:** `q` (fraza), `domain` (np. `vat`), `package`, `matched` (`true`/`false`), `page`, `page_size` (max 100).

**Odpowiedź 200:** `items[]` (`rule_id`, `package`, `file`, `priority`, `matched`, `legal_basis`), `total`, `page`, `page_size`.

```bash
curl -X GET "https://api.nexusai.pl/v1/jdg/rules?domain=vat&matched=true" -H "Authorization: Bearer $JWT"
```

### 4.12. POST `/jdg/change` — Declarative Change (ADR-021)

**Body:** `description` (zmiana w języku naturalnym, np. „stawka VAT 23% → 8% od 2027-01-01"), `domain`, `owner`, `change_ticket`.

**Odpowiedzi:** `201` — plan zmiany wygenerowany (`change_id`, `impact`, `tests_required`, `golden_replay_plan`); `409` — konflikt z istniejącą zmianą; `422` — opis niejednoznaczny.

```bash
curl -X POST "https://api.nexusai.pl/v1/jdg/change" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"description": "stawka VAT 23% → 8% od 2027-01-01", "domain": "vat", "owner": "doradca@firma.pl"}'
```

### 4.13. POST `/jdg/cert` — Issue Decision Certificate (F4, ADR-019)

**Body:** `verdict_id` (obowiązkowe), `format` (`pdf`/`xml`/`json`), `include_merkle_proof` (bool).

**Odpowiedź 200:** `certificate` (`verdict_id`, `certainty_class`, `decision_hash`, `seal`, `merkle_proof`, `export_url`, `valid_until`). Certyfikat weryfikowalny offline — do eksportu dla KAS.

```bash
curl -X POST "https://api.nexusai.pl/v1/jdg/cert" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"verdict_id": "v-2026-000123", "format": "pdf"}'
```

### 4.14. GET `/bundles` — katalog wersji bundle

**Odpowiedź 200:** `bundles[]` (`version`, `created_at`, `file_count`, `rule_count`, `signature_valid`, `deployment_state`, `soak_until`).

```bash
curl -X GET "https://api.nexusai.pl/v1/bundles" -H "Authorization: Bearer $JWT"
```

### 4.15. POST `/bundles/{version}/verify` — weryfikacja podpisu i SBOM

**Parametr path:** `version` (np. `v9.0.0`).

**Odpowiedź 200:** `verified` (bool), `signature_valid`, `sbom_ok`, `file_manifest_hash`, `details[]`. `409` — podpis niezgodny (bundle odrzucony).

```bash
curl -X POST "https://api.nexusai.pl/v1/bundles/v9.0.0/verify" -H "Authorization: Bearer $JWT"
```

### 4.16. GET `/bundles/{version}/health` — zdrowie rollout'u bundle

**Odpowiedź 200:** `state` (`canary`/`shadow`/`ramped`/`soak`/`active`/`rolled_back`), `error_rate`, `quality_score`, `verdict_delta_pct` (shadow vs prod), `soak_remaining_hours`.

```bash
curl -X GET "https://api.nexusai.pl/v1/bundles/v9.0.0/health" -H "Authorization: Bearer $JWT"
```

### 4.17. POST `/dr/restore` — Disaster Recovery (odtworzenie ostatniego zdrowego stanu)

**Body:** `restore_point` (`latest`/`pre_bundle`/timestamp), `verify_merkle` (bool, default `true`).

**Odpowiedzi:** `200` — przywrócono (`restore_id`, `restored_at`, `verdicts_restored`, `merkle_verified`); `409` — przywracanie już w toku; `503` — brak zdrowego punktu.

```bash
curl -X POST "https://api.nexusai.pl/v1/dr/restore" \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d '{"restore_point": "latest", "verify_merkle": true}'
```

---

## 5. Rate limiting i throttling

| Parametr | Wartość (domyślna) | Uwagi |
|---|---|---|
| Limit na klucz API | **60 req/min** (produkcja) | Per `tenant_id` + IP |
| Limit `/jdg/decide` | **20 req/min** | Najdroższy obliczeniowo |
| Limit `/jdg/simulate` | **10 req/min** | Uruchamia wszystkie reguły |
| Limit `/jdg/explain` | **30 req/min** | Koszty LLM; cache 30 dni |
| Burst (bucket) | 2× limit bazowy | Token bucket |
| Retry-After | sekundy (integer) | Nagłówek w odpowiedzi 429 |

> ⚠️ **Uwaga:** powyższe wartości to **zalecane ustawienia domyślne wdrożenia** — specyfikacja OpenAPI (`api/openapi.yaml`) definiuje tylko zachowanie przy 429 (`Retry-After`), nie konkretne limity. Wartości konfigurujesz w warstwie API Gateway (np. wg planu taryfowego licencji).

**Zachowanie:** po przekroczeniu limitu API zwraca **429** z nagłówkiem `Retry-After: <sekundy>`. Klient powinien wykonać backoff i ponowić po wskazanym czasie. Przy degradacji zewnętrznych API zwracany jest **503** z `DegradationResponse` (lista `degraded_apis`, `fallback_active`, `retry_after_seconds`).

**Dobre praktyki:**
- Wysyłaj `X-Request-Id` — ułatwia diagnozę po stronie serwera.
- Używaj `/jdg/simulate` zamiast `/jdg/decide` do analiz „co jeśli".
- Korzystaj z cache wyjaśnień (`/jdg/explain`): powtarzane pytania nie generują kosztów LLM.

---

## 6. Kody błędów

### 6.1. HTTP (transport)

| Kod | Znaczenie | Kiedy |
|---|---|---|
| 200 | OK | Sukces |
| 400 | Bad Request | Nieprawidłowe body / walidacja |
| 401 | Unauthorized | Brak/nieprawidłowy JWT |
| 403 | Forbidden | Brak uprawnień `decide`/`simulate`/`audit` |
| 404 | Not Found | Nieznany endpoint / brak werdyktu / brak reguły |
| 409 | Conflict | Konflikt reguł między domenami |
| 422 | Unprocessable | Brak reguły dla inputu → `BLOCK_AND_ALERT` |
| 429 | Too Many Requests | Przekroczony rate limit (`Retry-After`) |
| 500 | Internal Error | Błąd ewaluacji OPA/WASM |
| 503 | Service Unavailable | Degradacja API zewnętrznych |

### 6.2. Kody błędów własnych (`error` w `ErrorResponse`)

> 💡 Konwencja kodu `error` (ciąg znaków) — specyfikacja OpenAPI definiuje pole, nie zamknięty zbiór wartości; poniższa tabela to konwencja wdrożeniowa serwisu.

| Kod (`error`) | Znaczenie | Rozwiązanie |
|---|---|---|
| `validation_error` | Brak wymaganych pól / zły format | Sprawdź `details[]` i popraw body |
| `auth_invalid` | Token nieprawidłowy/wygasły | Odśwież JWT |
| `auth_forbidden` | Brak scope dla operacji | Poproś o uprawnienie |
| `rule_not_found` | Nieznany `rule_id` | Sprawdź `/jdg/manifest` |
| `verdict_not_found` | Brak werdyktu w audycie | Sprawdź `verdict_id` |
| `no_matching_rule` | 422 — brak reguły | Transakcja wymaga analizy człowieka (`BLOCK_AND_ALERT`) |
| `conflict_detected` | 409 — konflikt domen | Użyj `resolution_hint` z `ConflictResponse` |
| `external_degraded` | 503 — API zewnętrzne offline | Retry po `retry_after_seconds`; `fallback_active` może zwrócić werdykt degradowany |
| `opa_evaluation_error` | 500 — błąd OPA/WASM | Zgłoś z `request_id` |

### 6.3. Kody biznesowe (pola werdyktu `_routing` / `action`)

| Kod | Znaczenie | Przykład |
|---|---|---|
| `ALLOW` | Transakcja dozwolona | Zwykła faktura krajowa |
| `TRIAGE_QUEUE` | Wymagana weryfikacja manualna | Niska pewność `expense_type` |
| `BLOCK_AND_ALERT` | Transakcja zablokowana | Ryzyko fraud / brak reguły |

### 6.4. Przykład odpowiedzi błędu (400)

```json
{
  "error": "validation_error",
  "message": "Brak wymaganego pola: payload.invoice.invoice_number",
  "details": [
    { "field": "payload.invoice.invoice_number", "reason": "required" }
  ],
  "request_id": "req_8f3a2c1e"
}
```

---

## 7. Przykład pełnego przepływu integracji

```bash
# 1) Zdobądź token — ZEWNĘTRZNY NexusAI Auth Service (poza tym API)
#    (specyfikacja OpenAPI JDG nie zawiera /auth — to osobny serwis)
JWT=$(curl -s -X POST https://auth.nexusai.pl/v1/token \
  -H "Content-Type: application/json" \
  -d '{"client_id":"...","client_secret":"..."}' | jq -r .access_token)

# 2) Sprawdź zdrowie systemu
curl -s https://api.nexusai.pl/v1/jdg/health -H "Authorization: Bearer $JWT" | jq .

# 3) Ewaluuj fakturę
curl -s -X POST https://api.nexusai.pl/v1/jdg/decide \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d @faktura.json | jq '{action, vat_rate, pit_form, _legal_basis, _cost_ms}'

# 4) Symuluj ryzyko przed księgowaniem
curl -s -X POST https://api.nexusai.pl/v1/jdg/simulate \
  -H "Authorization: Bearer $JWT" -H "Content-Type: application/json" \
  -d @faktura.json | jq '{severity_score, potential_fine_pln, fine_probability}'
```

---

## 8. Schematy (skrót)

| Schemat | Wymagane | Kluczowe pola |
|---|---|---|
| `DecisionRequest` | `transaction_date`, `context`, `payload` | + `evaluation_datetime` |
| `JdgContext` | `tenant_id`, `tenant_type`, `pit_form` | + `transaction_type`, `pkpid_main`, `entity_status` |
| `VerdictResponse` | `matched`, `rule_id`, `_provenance`, `_cost_ms` | + `action`, `vat_rate`, `pit_form`, `zus_*`, `_routing`, `_legal_basis`, `_warnings`, `_cross_domain_conflicts`, `_shard_routed` |
| `ProvenanceTree` | `matched_at`, `conditions_evaluated`, `decision_hash` | + `path[]`, `root_hash`, `temporal_snapshot_used`, `rule_version_applied` |
| `DecisionStep` | — | `step`, `package`, `rule_id`, `priority`, `legal_basis`, `routing`, `threshold_refs`, `temporal_valid_from/to` |
| `EvaluatedCondition` | — | `condition_id`, `match_score`, `legal_basis[]`, `temporal_version`, `evaluation_time_us` |
| `CrossDomainConflict` | — | `rule_id`, `conflict_domains`, `conflict_severity` (INFO/WARNING/HIGH/CRITICAL), `conflict_resolution`, `conflict_message` |
| `SimulationResponse` | — | `severity_score`, `potential_fine_pln`, `fine_probability`, `kks_articles_triggered[]`, `recommendations[]`, `verdict` |
| `AuditResponse` | — | `original_verdict`, `temporal_snapshot`, `merkle_root`, `merkle_verified`, `ecdsa_signature` |
| `HealthResponse` | — | `status`, `opa_version`, `bundle_version`, `external_apis{}`, `shard_count`, `rules_count`, `uptime_seconds` |
| `ErrorResponse` | — | `error`, `message`, `details[]`, `request_id` |
| `DegradationResponse` | — | `error`, `message`, `degraded_apis[]`, `fallback_active`, `retry_after_seconds` |
| `ConflictResponse` | — | `error`, `message`, `conflicts[]`, `resolution_hint` |

Pełne definicje JSON Schema: **[../api/openapi.yaml](../api/openapi.yaml)** → `components/schemas`.

---

## 9. Uwagi wdrożeniowe

- Wersjonowanie API: prefiks `/v1` — zmiany breaking wymagają `/v2`.
- Idempotencja: `/jdg/decide` jest bezpieczny do ponawiania (nie zmienia stanu poza zapisem audytu; deduplikacja po `input_hash`).
- Bezpieczeństwo: JWT z `tenant_id` — nigdy nie przekazuj cudzego `tenant_id` w `context`.
- Monitoring: śledź `_cost_ms` i `_shard_routed` w werdyktach; 503 z `degraded_apis` sygnalizuje problemy integracji.

---

*Spójny z: api/openapi.yaml (v1.0.0) · docs/api.md (auto-generowany) · ARCHITEKTURA.md §5*
