# 🔌 OPA API Reference — NexusAI Integration

> **Status:** Dokumentacja techniczna v1.0
> **Data:** 2026-07-07
> **Powiązany:** `01_INPUT_SPEC.md`, `17_IMPLEMENTATION_ROADMAP.md`
> **OPA wersja:** ≥ 0.60.0

---

## 1. Architektura komunikacji

```
┌─────────────────┐     REST API (JSON)     ┌──────────────────┐
│  NexusAI Core   │ ──────────────────────► │   OPA Server     │
│  (Python)       │ ◄────────────────────── │   (Go, HTTP)     │
└─────────────────┘     Werdykt (JSON)       └──────────────────┘
        │                                            │
        │ NATS pub/sub                               │
        ▼                                            ▼
┌─────────────────┐                         ┌──────────────────┐
│  HotReload      │ ◄─── tax.thresholds ─── │  DuckDB RuleStore│
│  Listener       │       .updated          │                  │
└─────────────────┘                         └──────────────────┘
```

---

## 2. OPA REST API Endpoints

### 2.1 Policy Evaluation — `/v1/data/tax/{package}/decide`

**Metoda:** `POST`

**Nagłówek:** `Content-Type: application/json`

**Request body:**

```json
{
  "input": {
    "invoice": {
      "category_code": "FUEL",
      "transaction_date": "2026-07-07",
      "amount_net": 10000.00,
      "amount_net_grosze": 1000000,
      "amount_gross": 12300.00,
      "amount_gross_grosze": 1230000,
      "currency": "PLN",
      "procedure": "",
      "expense_type": "OPERATIONAL",
      "pkwiu_code": "",
      "is_cash_payment": false,
      "is_advance": false,
      "invoice_number": "FV/2026/07/042",
      "issue_date": "2026-07-07",
      "due_date": "2026-08-07",
      "is_paid": false,
      "days_overdue": 0,
      "vat_on_import": false
    },
    "vendor": {
      "nip": "1234567890",
      "country": "PL",
      "vat_status": "active",
      "on_whitelist": true,
      "whitelist_checked_at": "2026-07-07T10:00:00Z",
      "account_on_whitelist": true,
      "pkd": "47.30.Z",
      "is_related_party": false,
      "trust_score": 0.92,
      "fraud_flag": false,
      "is_new": false,
      "debt_to_equity_ratio": 0.0
    },
    "company": {
      "tax_form": "CIT_STANDARD",
      "zus_status": "STANDARD",
      "is_vat_payer": true,
      "is_small_taxpayer": false,
      "annual_turnover_net": 2000000.00,
      "has_rd_status": false,
      "fiscal_year_start": "2026-01-01",
      "employees_count": 12
    },
    "confidence": {
      "fc_minimum": 0.97,
      "fc_vat_rate": 0.99,
      "fc_total_net": 0.98,
      "fc_vendor_nip": 0.99,
      "fc_category_code": 0.97
    },
    "thresholds": {
      "mpp_limit": 15000,
      "vat_exemption_limit": 200000,
      "cash_transaction_limit": 15000,
      "bad_debt_days": 150,
      "rates": {
        "vat_standard": "0.23",
        "vat_reduced_8": "0.08",
        "vat_reduced_5": "0.05",
        "vat_zero": "0.00"
      }
    }
  }
}
```

**Response (200 OK):**

```json
{
  "result": {
    "matched": true,
    "rule_id": "tax.compliance.split_payment_mandatory",
    "package": "tax.compliance",
    "priority": 9,
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "deductible_full",
    "mpp_required": true,
    "_legal_basis": "Art. 108a ustawy o VAT",
    "_warnings": ["Obowiązkowy mechanizm podzielonej płatności (MPP)"]
  }
}
```

### 2.2 Full pipeline — `/v1/data/tax/decide`

**Metoda:** `POST`

Ewaluuje wszystkie pakiety w kolejności priorytetów (first-match-wins). Ten sam format `input` co wyżej.

---

### 2.3 Health Check — `/health`

**Metoda:** `GET`

**Response (200 OK):**

```json
{
  "status": "ok",
  "bundle": {
    "name": "nexusai/tax",
    "revision": "abc123def456"
  }
}
```

### 2.4 Bundle Status — `/v1/bundles/{name}`

**Metoda:** `GET`

Zwraca metadane aktualnie załadowanego bundle'a.

### 2.5 Policy Reload — `/v1/policies`

**Metoda:** `PUT` (full policy replacement)

**Nagłówek:** `Content-Type: application/json`

```json
{
  "policies": {
    "tax/risk.rego": "package tax.risk\n...",
    "tax/compliance.rego": "package tax.compliance\n..."
  }
}
```

---

## 3. Format werdyktu (Verdict Schema)

### 3.1 Pola standardowe (zawsze obecne)

| Pole | Typ | Opis | Przykład |
|---|---|---|---|
| `matched` | `boolean` | Czy reguła dopasowana | `true` |
| `rule_id` | `string` | Unikalny identyfikator reguły | `"tax.compliance.split_payment_mandatory"` |
| `package` | `string` | Pakiet źródłowy | `"tax.compliance"` |
| `priority` | `number` | Priorytet (0-310) | `9` |

### 3.2 Pola podatkowe (wypełniane przez reguły merytoryczne)

| Pole | Typ | Opis | Przykład |
|---|---|---|---|
| `vat_rate` | `string` | Stawka VAT | `"0.23"` |
| `rounding_level` | `string` | Poziom zaokrąglania | `"position"` / `"total"` |
| `gtu_code` | `string` | Kod GTU | `"GTU_04"` |
| `procedure` | `string` | Procedura specjalna | `"VAT_REVERSE_CHARGE"` |
| `income_tax_qualification` | `string` | Kwalifikacja KUP | `"deductible_full"` / `"non_deductible"` |
| `cit_rate` | `string` | Stawka CIT | `"0.19"` |
| `pit_rate` | `string` | Stawka PIT | `"0.12"` |

### 3.3 Pola routingu i ryzyka

| Pole | Typ | Opis | Wartości |
|---|---|---|---|
| `_routing` | `string` | Decyzja routingowa | `""` / `"BLOCK_AND_ALERT"` / `"TRIAGE_QUEUE"` |
| `_routing_reason` | `string` | Czytelny powód routingu | `"Brak kontrahenta na Białej Liście MF"` |
| `_legal_basis` | `string` | Podstawa prawna | `"Art. 108a ustawy o VAT"` |
| `_warnings` | `array[string]` | Ostrzeżenia | `["Obowiązkowy MPP"]` |

### 3.4 Przykład werdyktu NO_MATCH

```json
{
  "result": {
    "matched": false,
    "rule_id": "tax.fallback.no_match",
    "package": "tax.fallback",
    "priority": 1000,
    "error": "NO_MATCHING_RULE",
    "vat_rate": "0.23",
    "rounding_level": "position",
    "income_tax_qualification": "deductible_full",
    "_legal_basis": "Art. 41 ust. 1 VAT (domyślnie)"
  }
}
```

---

## 4. Python Client — NexusAI → OPA

### 4.1 Inicjalizacja

```python
import asyncio

import httpx
from typing import Any, Dict, Optional

class OpaClient:
    """Klient OPA dla NexusAI.

    Wymaga: pip install httpx
    """

    def __init__(
        self,
        base_url: str = "http://localhost:8181",
        timeout: float = 5.0,
        retries: int = 3,
    ):
        self.base_url = base_url.rstrip("/")
        self.client = httpx.AsyncClient(
            base_url=self.base_url,
            timeout=timeout,
            limits=httpx.Limits(max_keepalive_connections=20),
        )
        self.retries = retries

    async def evaluate(
        self,
        package: str,
        input_data: Dict[str, Any],
    ) -> Dict[str, Any]:
        """Ewaluuje politykę OPA dla danego pakietu."""
        url = f"/v1/data/{package.replace('.', '/')}/decide"

        for attempt in range(self.retries):
            try:
                response = await self.client.post(
                    url,
                    json={"input": input_data},
                )
                response.raise_for_status()
                result = response.json()
                return result.get("result", {})

            except httpx.HTTPStatusError as e:
                if attempt == self.retries - 1:
                    raise
                await asyncio.sleep(0.1 * (2 ** attempt))

            except httpx.TimeoutException:
                if attempt == self.retries - 1:
                    raise

        raise RuntimeError("OPA evaluation failed after retries")

    async def health(self) -> bool:
        """Sprawdza zdrowie serwera OPA."""
        try:
            response = await self.client.get("/health")
            return response.status_code == 200
        except Exception:
            return False

    async def reload_policy(self, policy_map: Dict[str, str]) -> bool:
        """Zastępuje polityki OPA (używane do hot-reload)."""
        try:
            response = await self.client.put(
                "/v1/policies",
                json={"policies": policy_map},
            )
            return response.status_code == 200
        except Exception:
            return False

    async def close(self):
        await self.client.aclose()
```

### 4.2 Użycie w Pipeline

```python
from nexus_ai.services.opa_client import OpaClient

async def evaluate_invoice(invoice_data: dict) -> dict:
    """Pełna ewaluacja faktury przez OPA."""

    async with OpaClient() as opa:
        # 1. Wzbogać input o dane z serwisów NexusAI
        enriched = await enrich_input(invoice_data)

        # 2. Ewaluuj wszystkie pakiety w kolejności
        for package in TAX_PACKAGES_PRIORITY_ORDER:  # P0 → P310
            verdict = await opa.evaluate(package, enriched)

            if verdict.get("matched"):
                # 3. First-match-wins — pierwszy pasujący werdykt
                return verdict

        # 4. Fallback — should never happen (no_match gwarantuje werdykt)
        return {"matched": False, "error": "NO_MATCHING_RULE"}


async def enrich_input(invoice_data: dict) -> dict:
    """Wzbogaca input o dane z zewnętrznych serwisów."""
    return {
        "invoice": invoice_data,
        "vendor": await get_vendor_data(invoice_data["nip"]),
        "company": await get_company_config(),
        "confidence": await get_ocr_confidence(invoice_data),
        "thresholds": await get_current_thresholds(),
    }
```

---

## 5. Decision Logging

### 5.1 Format logu decyzyjnego

```json
{
  "decision_id": "550e8400-e29b-41d4-a716-446655440000",
  "labels": {
    "system_type": "tax.pipeline",
    "app": "nexusai-tax-engine",
    "version": "1.0.0"
  },
  "decision": {
    "rule_id": "tax.compliance.split_payment_mandatory",
    "package": "tax.compliance",
    "priority": 9,
    "mpp_required": true
  },
  "input": {
    "invoice": {
      "category_code": "FUEL",
      "amount_gross": 15000.00
    },
    "vendor": {
      "country": "PL",
      "nip_hash": "sha256:abc123..."
    }
  },
  "result": {
    "matched": true,
    "vat_rate": "0.23",
    "gtu_code": "GTU_04"
  },
  "timestamp": "2026-07-07T12:34:56.789Z",
  "metrics": {
    "evaluation_time_ms": 2.4,
    "counter_server_query": 15432
  }
}
```

### 5.2 Konfiguracja OPA

```yaml
# opa/config.yaml
decision_logs:
  console: false
  reporting:
    min_delay_seconds: 0.5
    max_delay_seconds: 5
  plugin: nexusai_decision_logger
  service: nexusai_control_plane

services:
  nexusai_control_plane:
    url: http://nexusai-control:9090
    credentials:
      bearer:
        token: "${OPA_SERVICE_TOKEN}"

bundles:
  nexusai_tax:
    service: nexusai_control_plane
    resource: bundles/tax
    polling:
      min_delay_seconds: 30
      max_delay_seconds: 300
```

---

## 6. Bundle API

### 6.1 Struktura bundle'a

```
tax-bundle.tar.gz
├── .manifest
│   ├── revision      # "abc123def456"
│   └── roots         # ["tax"]
├── data.json         # Dane statyczne (thresholds)
└── tax/
    ├── _helpers.rego
    ├── _metadata.rego
    ├── risk.rego
    ├── routing.rego
    ├── compliance.rego
    ├── crossborder.rego
    ├── vat/
    │   ├── substantive.rego
    │   ├── gtu.rego
    │   └── exemptions.rego
    ├── direct/
    │   ├── cit.rego
    │   ├── pit.rego
    │   └── deductions.rego
    ├── allowances.rego
    ├── accounting.rego
    ├── zus.rego
    └── fallback.rego
```

### 6.2 Budowanie bundle'a

```bash
# Budowanie za pomocą opa build
opa build \
    --bundle policies/tax/ \
    --output tax-bundle.tar.gz \
    --revision "$(git rev-parse HEAD)" \
    --entrypoint tax/decide

# Weryfikacja bundle
opa inspect tax-bundle.tar.gz
```

### 6.3 Serwowanie bundle'a przez OCI Registry

```bash
# Push do OCI registry
opa build --bundle policies/tax/ --output /dev/stdout | \
    oras push registry.nexusai.internal/tax-bundle:v1.0.0 -

# OPA config do OCI
bundles:
  nexusai_tax:
    service: oci_registry
    resource: registry.nexusai.internal/tax-bundle:v1.0.0

services:
  oci_registry:
    url: https://registry.nexusai.internal
    type: oci
```

---

## 7. Status API — Monitoring

### 7.1 Metryki OPA (Prometheus)

OPA eksponuje metryki na `/metrics`:

| Metryka | Opis |
|---|---|
| `opa_policy_eval_latency_milliseconds` | Czas ewaluacji polityki |
| `opa_policy_eval_count` | Liczba ewaluacji |
| `opa_policy_eval_error_count` | Liczba błędów ewaluacji |
| `opa_bundle_activation_latency_milliseconds` | Czas aktywacji bundle'a |
| `opa_decision_log_buffer_length` | Długość bufora logów decyzyjnych |

### 7.2 Health Check w Kubernetes

```yaml
# deployment.yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8181
  initialDelaySeconds: 5
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health
    port: 8181
  initialDelaySeconds: 3
  periodSeconds: 5
```

---

## 8. Kody błędów

| HTTP Code | Znaczenie | Reakcja |
|---|---|---|
| `200` | Ewaluacja OK | Przetwórz werdykt |
| `400` | Nieprawidłowy input JSON | Sprawdź schemat input |
| `500` | Błąd wewnętrzny OPA | Retry z exponential backoff |
| `503` | OPA niedostępne | Circuit breaker, fallback do cache'a reguł |

---

## 9. Bezpieczeństwo

### 9.1 Token dostępu

```bash
# Uruchomienie OPA z tokenem
opa run \
    --server \
    --authentication=token \
    --authorization=basic \
    --set=decision_logs.reporting.min_delay_seconds=0.5 \
    policies/tax/
```

### 9.2 Komunikacja TLS

```bash
# OPA z TLS
opa run \
    --server \
    --tls-cert-file=/etc/opa/certs/tls.crt \
    --tls-private-key-file=/etc/opa/certs/tls.key \
    policies/tax/
```

---

## 10. Pełna konfiguracja OPA

```yaml
# opa/config.yaml — produkcja NexusAI
services:
  nexusai_control_plane:
    url: https://nexusai-control.internal:8443
    credentials:
      bearer:
        token: "${OPA_SERVICE_TOKEN}"
    tls:
      ca_cert: /etc/opa/certs/ca.crt

bundles:
  nexusai_tax:
    service: nexusai_control_plane
    resource: bundles/tax/v1
    polling:
      min_delay_seconds: 30
      max_delay_seconds: 300

decision_logs:
  console: false
  reporting:
    min_delay_seconds: 0.5
    max_delay_seconds: 5
    buffer_size_limit_bytes: 1048576  # 1 MB

status:
  service: nexusai_control_plane
  console: false

default_decision: /tax/fallback/no_match

server:
  encoding:
    gzip:
      min_length: 1024

distributed_tracing:
  type: grpc
  address: otel-collector:4317
  service_name: opa-nexusai
```

---

> **Następny dokument:** `19_DEPLOYMENT_GUIDE.md` — Przewodnik wdrożenia OPA w produkcji.
