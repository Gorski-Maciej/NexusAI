# NexusAI API Reference

> **Wersja:** 2.0
> **Data:** 2026-06-14
> **Framework:** Litestar 2.8+
> **Serializacja:** msgspec + MsgspecDTO

---

## Spis treści

1. [Versioning](#1-versioning)
2. [Authentication](#2-authentication)
3. [Endpoint Groups](#3-endpoint-groups)
4. [DTO Patterns](#4-dto-patterns)
5. [Error Handling](#5-error-handling)
6. [Security Headers](#6-security-headers)

---

## 1. Versioning

API używa warstwowej architektury wersji:

| Router | Path | Status | Tag |
|---|---|---|---|
| `v1_router` | `/api/v1/*` | **DEPRECATED** — Sunset: 2026-12-31 | `v1` |
| `v2_router` | `/api/v2/*` | **Current** | `v2` |
| `unversioned_router` | `/api/*` | **Stable** (auth, admin, version) | — |

### V1 — deprecated

- Wszystkie endpointy v1 mają nagłówek `Deprecation: true`
- Ostrzeżenie w logach przy każdym wywołaniu
- Nagłówek `Link: </api/v2>; rel="successor-version"`
- Sunset date: `Wed, 31 Dec 2026 23:59:59 GMT`

### V2 — current

- Wszystkie endpointy v2 mają nagłówek `X-API-Version: v2`
- Rekomendowany dla nowych integracji

### Unversioned — stable

- Auth, Admin, Version — dostępne bez prefiksu wersji
- Nie zmieniają się często

---

## 2. Authentication

### JWT Authentication

```bash
# Login
curl -X POST /api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin"}'

# Response
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 3600,
  "refreshTokenExpiresInDays": 7
}

# Use token
curl /api/v2/invoices \
  -H "Authorization: Bearer eyJ..."
```

### Endpointy auth

| Metoda | Path | Opis |
|---|---|---|
| POST | `/api/auth/register` | Rejestracja użytkownika |
| POST | `/api/auth/login` | Logowanie |
| POST | `/api/auth/refresh` | Refresh token (single-use rotation) |
| POST | `/api/auth/logout` | Wylogowanie |
| POST | `/api/auth/reset-password` | Wyślij email resetu hasła |
| POST | `/api/auth/reset-password/confirm` | Potwierdź reset hasła |
| POST | `/api/auth/change-password` | Zmiana hasła (zalogowany) |
| GET | `/api/auth/csrf-token` | Pobierz CSRF token |
| GET | `/api/auth/me` | Profil bieżącego użytkownika |

---

## 3. Endpoint Groups

### Health

| Metoda | Path | Wersja | Opis | Cache |
|---|---|---|---|---|
| GET | `/health` | v1, v2 | Basic health check | `max-age=300` |
| GET | `/health/live` | v1, v2 | Kubernetes liveness | `max-age=300` |
| GET | `/health/ready` | v1, v2 | Kubernetes readiness | `max-age=300` |
| GET | `/health/detailed` | v1, v2 | Szczegółowy health (DB, NATS, TB) | — |

### Invoices

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| GET | `/invoices` | v1, v2 | Lista faktur (cursor pagination) |
| POST | `/invoices` | v1, v2 | Utwórz fakturę ręcznie |
| GET | `/invoices/{id}` | v1, v2 | Szczegóły faktury |
| POST | `/invoices/{id}/resolve` | v1, v2 | Rozwiąż triage |
| POST | `/invoices/upload` | v1, v2 | Upload pliku faktury |
| POST | `/invoices/upload-large` | v1, v2 | Upload dużego załącznika |

### Dashboard

| Metoda | Path | Wersja | Opis | Cache |
|---|---|---|---|---|
| GET | `/dashboard/briefing` | v2 | Daily briefing | `max-age=300` |
| GET | `/dashboard/summary` | v2 | Podsumowanie dashboardu | `max-age=300` |

### Triage

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| GET | `/triage` | v1, v2 | Lista faktur do triage |
| POST | `/triage/{id}/resolve` | v1, v2 | Rozwiąż triage (korekta) |

### Admin

| Metoda | Path | Opis |
|---|---|---|
| GET | `/api/admin/failed-tasks` | Lista failed tasks (DLQ) |
| POST | `/api/admin/failed-tasks/{id}/retry` | Retry konkretnego taska |
| DELETE | `/api/admin/failed-tasks/{id}` | Usuń failed task |
| POST | `/api/admin/failed-tasks/retry-all` | Retry wszystkich |
| PUT | `/api/admin/users/{id}/role` | Zmień rolę użytkownika |
| GET | `/api/admin/risk-thresholds` | Lista progów ryzyka |
| POST | `/api/admin/risk-thresholds` | Utwórz próg ryzyka |
| PUT | `/api/admin/risk-thresholds/{id}/deprecate` | Dezaktywuj próg ryzyka |
| GET | `/api/admin/rules` | Lista reguł podatkowych |
| POST | `/api/admin/rules` | Utwórz regułę podatkową |
| GET | `/api/admin/rules/{id}` | Szczegóły reguły |
| GET | `/api/admin/rules/changelog` | Log zmian reguł |
| GET | `/api/admin/billing-rules` | Lista reguł billingowych |
| POST | `/api/admin/billing-rules` | Utwórz regułę billingową |
| GET | `/api/admin/ledger-rules` | Lista reguł ledger |
| POST | `/api/admin/ledger-rules` | Utwórz regułę ledger |
| GET | `/api/admin/fallback-events` | Lista fallback events |
| POST | `/api/admin/fallback-events/{id}/resolve` | Rozwiąż fallback event |
| POST | `/api/admin/audit/replay/{id}` | Replay decyzji podatkowej |
| POST | `/api/admin/audit/replay-batch` | Batch replay |
| POST | `/api/admin/audit/verify-integrity` | Weryfikacja łańcucha hash |
| GET | `/api/admin/system/health` | Health check administracyjny |
| GET | `/api/admin/hot-reload/health` | Status hot-reload listenera |

### Tax & Finance

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| POST | `/tax/calculate-money` | v2 | Kalkulacja podatkowa |
| POST | `/tax-policy/simulate` | v2 | Symulacja zmiany formy opodatkowania |
| GET | `/tax-policy/rule-sets` | v2 | Lista dostępnych zestawów reguł |
| GET | `/fx/rates` | v2 | Kursy walut |
| POST | `/fx/rates/upload` | v2 | Upload kursów CSV |

### Risk

| Metoda | Path | Opis |
|---|---|---|
| GET | `/api/admin/risk-thresholds` | Lista progów |
| POST | `/api/admin/risk-thresholds` | Utwórz próg |
| DELETE | `/api/admin/risk-thresholds/{id}` | Dezaktywuj próg |
| GET | `/api/admin/risk-thresholds/evaluate` | Ewaluacja pojedynczego pola |
| GET | `/api/admin/risk-thresholds/evaluate-batch` | Ewaluacja wielu pól |

### System

| Metoda | Path | Opis |
|---|---|---|
| GET | `/api/system/integrity/migration` | Integrity check migracji |
| GET | `/api/system/integrity/saga/{id}` | Stan sagi |
| POST | `/api/system/integrity/saga/{id}/transition` | Tranzycja sagi |
| GET | `/api/system/integrity/saga/stuck` | Lista stuck sag |
| POST | `/api/system/integrity/saga/{id}/compensate` | Wymuś kompensację sagi |
| POST | `/api/system/integrity/ui-drafts/cleanup` | Cleanup UI draftów |
| GET | `/api/system/telemetry/fallback-status` | Status fallback telemetry |
| POST | `/api/system/telemetry/fallback-replay` | Replay fallback spanów |

### Partner Hub

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| GET | `/partner/clients` | v2 | Lista klientów partnera |
| GET | `/partner/clients/{nip}/invoices` | v2 | Faktury klienta partnera |

### Autopilot

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| GET | `/autopilot/decisions` | v2 | Lista decyzji Autopilota |
| GET | `/autopilot/decisions/{id}` | v2 | Szczegóły decyzji |
| POST | `/autopilot/trigger/{invoice_id}` | v2 | Wymuś ewaluację |
| POST | `/autopilot/{id}/accept` | v2 | Akceptuj decyzję |
| POST | `/autopilot/{id}/reject` | v2 | Odrzuć decyzję |
| GET | `/autopilot/trust-score/{nip}` | v2 | Trend trust score |
| GET | `/autopilot/stats` | v2 | Statystyki Autopilota |

### Analytics

| Metoda | Path | Wersja | Opis |
|---|---|---|---|
| POST | `/analytics/vat-summary` | v2 | Podsumowanie VAT |
| POST | `/analytics/query` | v2 | Zapytanie analityczne |

### Audit

| Metoda | Path | Opis |
|---|---|---|
| GET | `/api/v2/audit/tax-decision/{id}` | Raport decyzji podatkowej |

### Inne

| Metoda | Path | Opis |
|---|---|---|
| POST | `/api/v2/export` | Eksport danych |
| GET | `/api/v2/export/{id}/download` | Pobierz eksport |
| GET | `/api/v2/finops/cost-per-invoice` | Koszt przetworzenia faktury |
| GET | `/api/v2/i18n/status` | Status tłumaczeń |
| POST | `/api/v2/privacy/pii-scan` | Skanowanie PII |
| GET | `/api/v2/security/posture` | Security posture |
| GET | `/api/v2/performance/locust-summary` | Podsumowanie wydajności (Locust) |
| GET | `/api/v2/stats/processing` | Statystyki przetwarzania |
| GET | `/api/v2/workers/status` | Status workerów |
| GET | `/api/v2/circuit-breakers/status` | Status circuit breakerów |
| POST | `/api/v2/billing/estimate` | Estymacja kosztów |
| GET | `/api/version` | Wersja API |
| GET | `/metrics` | Prometheus metrics |
| GET | `/schema/swagger` | Swagger UI (tylko debug) |
| GET | `/schema/openapi.json` | OpenAPI schema (tylko debug) |

---

## 4. DTO Patterns

### Konwencja nazewnictwa

| Warstwa | Konwencja | Przykład |
|---|---|---|
| Schema (Struct) | PascalCase | `LoginResponse`, `FailedTaskItem` |
| DTO klasa | PascalCase + `DTO` | `LoginResponseDTO`, `FailedTaskListDTO` |
| Rejestr | PascalCase | `DTO_REGISTRY["LoginResponse"]` |

### Konwersja camelCase

DTO automatycznie konwertują pola z snake_case (Python) na camelCase (JSON API):

```python
class InvoiceResponseDTO(NexusDTO):
    config = DTOConfig(
        rename_fields={
            "amount_net": "amountNet",
            "contractor_nip": "contractorNip",
            "created_at": "createdAt",
        },
    )
```

### GenericDTO (fallback)

`GenericDictDTO` jest używany tylko dla endpointów zwracających dynamiczne dane (np. szczegółowy health check z DuckDB). Docelowo wszystkie endpointy mają dedykowane DTO.

---

## 5. Error Handling

Wszystkie błędy HTTP są zwracane zgodnie z **RFC 9457** (Problem Details) przez `ProblemDetailsPlugin`:

```json
{
    "type": "https://httpstatuses.io/404",
    "title": "Not Found",
    "status": 404,
    "detail": "Invoice not found: inv-123",
    "instance": "/api/v2/invoices/inv-123"
}
```

| Status | Przyczyna |
|---|---|
| 400 | Validation error (ClientException) |
| 401 | Unauthorized (brak JWT) |
| 403 | Forbidden (brak uprawnień) |
| 404 | Not Found |
| 409 | Conflict (optimistic locking) |
| 413 | Payload Too Large |
| 422 | Unprocessable Entity (DTO validation) |
| 429 | Too Many Requests (rate limit) |
| 500 | Internal Server Error |

---

## 6. Security Headers

Każda odpowiedź HTTP zawiera nagłówki bezpieczeństwa dodane przez `_app_after_request`:

| Nagłówek | Wartość |
|---|---|
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` |
| `Referrer-Policy` | `no-referrer` |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=()` |
| `Content-Security-Policy` | `default-src 'self'; frame-ancestors 'none'; base-uri 'self'` |

---

> **Dokumentacja techniczna** — NexusAI API Reference v2.0
> **Ostatnia aktualizacja:** 2026-06-14
